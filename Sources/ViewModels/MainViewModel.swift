//
//  MainViewModel.swift
//  Sidekick
//
//  Created on 2025-01-12.
//

import Foundation
import Combine

/// 已加载的表信息
struct LoadedTable: Identifiable {
    let id = UUID()
    let name: String           // SQL 表名 (table1, table2, ...)
    let displayName: String    // 原始文件名（用于显示）
    let dataFrame: DataFrame
    let sourceURL: URL
    let isTruncated: Bool      // 是否被截断
    let originalRowCount: Int? // 原始行数（如果被截断）
    
    var rowCount: Int { dataFrame.rows.count }
    var columnCount: Int { dataFrame.columns.count }
    var columnNames: [String] { dataFrame.columns.map { $0.name } }
    var columnTypes: [ColumnType] { dataFrame.columns.map { $0.type } }
    
    // 显示的行数信息
    var rowCountDisplay: String {
        if isTruncated, let original = originalRowCount {
            return "\(rowCount)/\(original)"
        }
        return "\(rowCount)"
    }
}

/// 持久化的表信息（用于保存到 UserDefaults）
struct PersistedTableInfo: Codable {
    let name: String
    let displayName: String
    let sourceURLPath: String
}

/// 主视图的 ViewModel
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var fileURL: URL? {
        didSet {
            if let url = fileURL {
                loadFile(url: url)
            }
        }
    }
    
    @Published var loadedTables: [LoadedTable] = []
    @Published var selectedTableId: UUID?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var fileName: String = ""
    
    // MARK: - Computed Properties
    
    /// 当前选中的表
    var selectedTable: LoadedTable? {
        guard let id = selectedTableId else { return loadedTables.first }
        return loadedTables.first { $0.id == id }
    }
    
    /// 当前 DataFrame（兼容旧代码）
    var dataFrame: DataFrame? {
        selectedTable?.dataFrame
    }
    
    /// 是否有已加载的表
    var hasLoadedTables: Bool {
        !loadedTables.isEmpty
    }
    
    // MARK: - Private Properties
    
    private let loaderManager = FileLoaderManager.shared
    private let licenseManager = LicenseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var tableCounter = 0  // 用于生成 table1, table2, ...
    
    private let persistenceKey = "Sidekick.LoadedTables"
    
    // MARK: - Initialization
    
    init() {
        loadPersistedTables()
    }
    
    // MARK: - Public Methods
    
    /// 加载文件
    func loadFile(url: URL) {
        // 检查表数量限制
        if !licenseManager.canAddMoreTables(currentCount: loadedTables.count) {
            errorMessage = licenseManager.getLimitMessage(for: "tables")
            return
        }
        
        isLoading = true
        errorMessage = nil
        fileName = url.lastPathComponent
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let dataFrame = try self?.loaderManager.loadFile(from: url)
                
                DispatchQueue.main.async {
                    if let df = dataFrame, let self = self {
                        self.tableCounter += 1
                        let tableName = "table\(self.tableCounter)"
                        let displayName = url.deletingPathExtension().lastPathComponent
                        let table = LoadedTable(
                            name: tableName,
                            displayName: displayName,
                            dataFrame: df,
                            sourceURL: url,
                            isTruncated: false,
                            originalRowCount: nil
                        )
                        self.loadedTables.append(table)
                        self.selectedTableId = table.id
                        self.saveTables()  // 保存到持久化存储
                    }
                    self?.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
            }
        }
    }
    
    /// 从剪贴板加载数据
    func loadFromClipboard() {
        // 检查表数量限制
        if !licenseManager.canAddMoreTables(currentCount: loadedTables.count) {
            errorMessage = licenseManager.getLimitMessage(for: "tables")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let (dataFrame, isTruncated, originalRowCount) = try ClipboardLoader.loadFromClipboard()
                
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.tableCounter += 1
                    let tableName = "table\(self.tableCounter)"
                    let displayName = "剪贴板数据_\(self.tableCounter)"
                    
                    // 创建一个临时 URL（用于持久化，但实际不存在）
                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("clipboard_\(self.tableCounter).txt")
                    
                    let table = LoadedTable(
                        name: tableName,
                        displayName: displayName,
                        dataFrame: dataFrame,
                        sourceURL: tempURL,
                        isTruncated: isTruncated,
                        originalRowCount: isTruncated ? originalRowCount : nil
                    )
                    self.loadedTables.append(table)
                    self.selectedTableId = table.id
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
            }
        }
    }
    
    /// 移除表
    func removeTable(id: UUID) {
        loadedTables.removeAll { $0.id == id }
        
        // 如果移除的是当前选中的表，选择第一个表
        if selectedTableId == id {
            selectedTableId = loadedTables.first?.id
        }
        
        saveTables()  // 更新持久化存储
    }
    
    /// 移除表（按名称）
    func removeTable(name: String) {
        if let table = loadedTables.first(where: { $0.name == name }) {
            removeTable(id: table.id)
        }
    }
    
    /// 选择表
    func selectTable(id: UUID) {
        selectedTableId = id
    }
    
    /// 获取表名列表
    func getTableNames() -> [String] {
        loadedTables.map { $0.name }
    }
    
    /// 获取表信息
    func getTable(name: String) -> LoadedTable? {
        loadedTables.first { $0.name == name }
    }
    
    /// 清除当前数据
    func clearData() {
        loadedTables.removeAll()
        selectedTableId = nil
        fileURL = nil
        fileName = ""
        errorMessage = nil
        tableCounter = 0  // 重置计数器
        clearPersistedTables()
    }
    
    // MARK: - Private Methods - Persistence
    
    /// 保存已加载的表信息到 UserDefaults
    private func saveTables() {
        let persistedTables = loadedTables.map { table in
            PersistedTableInfo(
                name: table.name,
                displayName: table.displayName,
                sourceURLPath: table.sourceURL.path
            )
        }
        
        if let encoded = try? JSONEncoder().encode(persistedTables) {
            UserDefaults.standard.set(encoded, forKey: persistenceKey)
            print("💾 Saved \(persistedTables.count) tables to persistence")
        }
    }
    
    /// 从 UserDefaults 加载已保存的表
    private func loadPersistedTables() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let persistedTables = try? JSONDecoder().decode([PersistedTableInfo].self, from: data) else {
            print("📂 No persisted tables found")
            return
        }
        
        print("📂 Loading \(persistedTables.count) persisted tables...")
        
        for persistedTable in persistedTables {
            let url = URL(fileURLWithPath: persistedTable.sourceURLPath)
            
            // 检查文件是否还存在
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("⚠️ File not found: \(url.path)")
                continue
            }
            
            // 重新加载文件
            do {
                let dataFrame = try loaderManager.loadFile(from: url)
                
                // 使用保存的表名，而不是重新生成
                let table = LoadedTable(
                    name: persistedTable.name,
                    displayName: persistedTable.displayName,
                    dataFrame: dataFrame,
                    sourceURL: url,
                    isTruncated: false,
                    originalRowCount: nil
                )
                loadedTables.append(table)
                
                // 更新 tableCounter 以确保新表不会重复
                // 从表名中提取数字（如 "table3" -> 3）
                let numberString = persistedTable.name.replacingOccurrences(of: "table", with: "")
                if let number = Int(numberString) {
                    tableCounter = max(tableCounter, number)
                }
                
                print("✅ Loaded persisted table: \(persistedTable.name)")
            } catch {
                print("❌ Failed to load persisted table \(persistedTable.name): \(error.localizedDescription)")
            }
        }
        
        // 选择第一个表
        if let firstTable = loadedTables.first {
            selectedTableId = firstTable.id
        }
    }
    
    /// 清除持久化的表信息
    private func clearPersistedTables() {
        UserDefaults.standard.removeObject(forKey: persistenceKey)
        print("🗑️ Cleared persisted tables")
    }
}
