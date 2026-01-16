//
//  MainViewModel.swift
//  Sidekick
//
//  Created on 2025-01-12.
//
//  职责：
//  1. 管理表的元数据和 UI 状态
//  2. 协调文件加载
//  3. 管理持久化（元数据 + 数据文件）
//
//  不直接操作 DuckDB，通过 QueryViewModel 间接操作
//

import Foundation
import Combine

// MARK: - 表状态

/// 表加载状态
enum TableLoadStatus: Equatable {
    case loading         // 加载中
    case ready           // 正常可查询
    case error(String)   // 加载失败
    
    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
    
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
    
    static func == (lhs: TableLoadStatus, rhs: TableLoadStatus) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.ready, .ready): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - 表信息

/// 已加载的表信息
struct LoadedTable: Identifiable {
    let id = UUID()
    let name: String           // SQL 表名 (table1, table2, ...)
    let displayName: String    // 原始文件名（用于显示）
    let dataFrame: DataFrame   // 数据（用于显示列信息）
    let sourceURL: URL
    let isTruncated: Bool
    let originalRowCount: Int?
    var status: TableLoadStatus = .loading
    
    var rowCount: Int { dataFrame.rows.count }
    var columnCount: Int { dataFrame.columns.count }
    var columnNames: [String] { dataFrame.columns.map { $0.name } }
    var columnTypes: [ColumnType] { dataFrame.columns.map { $0.type } }
    
    var rowCountDisplay: String {
        if isTruncated, let original = originalRowCount {
            return "\(rowCount)/\(original)"
        }
        return "\(rowCount)"
    }
}

/// 持久化的表信息
struct PersistedTableInfo: Codable {
    let name: String
    let displayName: String
    let sourceURLPath: String
}

// MARK: - MainViewModel

class MainViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var loadedTables: [LoadedTable] = []
    @Published var selectedTableId: UUID?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    
    var selectedTable: LoadedTable? {
        guard let id = selectedTableId else { return loadedTables.first }
        return loadedTables.first { $0.id == id }
    }
    
    var dataFrame: DataFrame? { selectedTable?.dataFrame }
    var hasLoadedTables: Bool { !loadedTables.isEmpty }
    
    // MARK: - Private Properties
    
    private let loaderManager = FileLoaderManager.shared
    private let persistenceKey = "Sidekick.LoadedTables"
    
    private var dataStorageDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Sidekick/Tables", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    // MARK: - Initialization
    
    init() {
        // 异步加载持久化的表
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadPersistedTables()
        }
    }
    
    // MARK: - Public Methods
    
    /// 获取下一个可用的表名
    private func getNextTableName() -> String {
        // 获取当前所有表的编号，找最大值
        let maxNumber = loadedTables.compactMap { table -> Int? in
            guard table.name.hasPrefix("table") else { return nil }
            return Int(table.name.dropFirst(5))
        }.max() ?? 0
        
        return "table\(maxNumber + 1)"
    }
    
    /// 加载文件
    func loadFile(url: URL) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let dataFrame = try self.loaderManager.loadFile(from: url)
                
                DispatchQueue.main.async {
                    let tableName = self.getNextTableName()
                    let displayName = url.deletingPathExtension().lastPathComponent
                    
                    let table = LoadedTable(
                        name: tableName,
                        displayName: displayName,
                        dataFrame: dataFrame,
                        sourceURL: url,
                        isTruncated: false,
                        originalRowCount: nil,
                        status: .loading  // 初始状态为 loading，等待加载到 DuckDB
                    )
                    
                    self.loadedTables.append(table)
                    self.selectedTableId = table.id
                    self.isLoading = false
                    
                    // 保存元数据
                    self.saveTableMetadata()
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    logError(.fileLoader, "Failed to load file: \(url.lastPathComponent)", error: error)
                }
            }
        }
    }
    
    /// 从剪贴板加载
    func loadFromClipboard() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let (dataFrame, isTruncated, originalRowCount) = try ClipboardLoader.loadFromClipboard()
                
                DispatchQueue.main.async {
                    let tableName = self.getNextTableName()
                    let displayName = "剪贴板数据"
                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("clipboard_\(tableName).txt")
                    
                    let table = LoadedTable(
                        name: tableName,
                        displayName: displayName,
                        dataFrame: dataFrame,
                        sourceURL: tempURL,
                        isTruncated: isTruncated,
                        originalRowCount: isTruncated ? originalRowCount : nil,
                        status: .loading
                    )
                    
                    self.loadedTables.append(table)
                    self.selectedTableId = table.id
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    /// 更新表状态
    func updateTableStatus(name: String, status: TableLoadStatus) {
        if let index = loadedTables.firstIndex(where: { $0.name == name }) {
            loadedTables[index].status = status
            
            // 如果加载成功，保存数据
            if status.isReady {
                saveTableData(loadedTables[index])
            }
        }
    }
    
    /// 移除表
    func removeTable(id: UUID) {
        guard let table = loadedTables.first(where: { $0.id == id }) else { return }
        
        // 删除数据文件
        deleteTableFiles(table.name)
        
        // 从列表移除
        loadedTables.removeAll { $0.id == id }
        
        // 更新选中
        if selectedTableId == id {
            selectedTableId = loadedTables.first?.id
        }
        
        // 更新元数据
        saveTableMetadata()
        
        logInfo(.app, "Removed table: \(table.name)")
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
    
    /// 清除所有数据
    func clearData() {
        // 删除所有文件
        for table in loadedTables {
            deleteTableFiles(table.name)
        }
        
        loadedTables.removeAll()
        selectedTableId = nil
        errorMessage = nil
        
        UserDefaults.standard.removeObject(forKey: persistenceKey)
        logInfo(.app, "Cleared all data")
    }

    
    // MARK: - Persistence
    
    /// 保存表元数据到 UserDefaults
    private func saveTableMetadata() {
        let infos = loadedTables.map { table in
            PersistedTableInfo(
                name: table.name,
                displayName: table.displayName,
                sourceURLPath: table.sourceURL.path
            )
        }
        
        if let data = try? JSONEncoder().encode(infos) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
        
        logDebug(.persistence, "Saved metadata for \(infos.count) tables")
    }
    
    /// 保存单个表的数据
    private func saveTableData(_ table: LoadedTable) {
        guard table.status.isReady else { return }
        
        let parquetPath = dataStorageDirectory.appendingPathComponent("\(table.name).parquet").path
        
        DispatchQueue.global(qos: .utility).async {
            do {
                try DuckDBEngine.shared.exportToParquet(tableName: table.name, filePath: parquetPath)
                logInfo(.persistence, "Saved '\(table.name)' to Parquet")
            } catch {
                logWarning(.persistence, "Failed to save '\(table.name)' to Parquet, trying JSON...")
                self.saveTableDataAsJSON(table)
            }
        }
    }
    
    /// 回退：保存为 JSON
    private func saveTableDataAsJSON(_ table: LoadedTable) {
        let jsonPath = dataStorageDirectory.appendingPathComponent("\(table.name).json")
        
        let data: [String: Any] = [
            "columns": table.dataFrame.columns.map { ["name": $0.name, "type": columnTypeString($0.type)] },
            "rows": table.dataFrame.rows
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: data) {
            try? jsonData.write(to: jsonPath)
            logInfo(.persistence, "Saved '\(table.name)' to JSON")
        }
    }
    
    /// 删除表的数据文件
    private func deleteTableFiles(_ name: String) {
        let parquetPath = dataStorageDirectory.appendingPathComponent("\(name).parquet")
        let jsonPath = dataStorageDirectory.appendingPathComponent("\(name).json")
        let csvPath = dataStorageDirectory.appendingPathComponent("\(name).csv")
        
        try? FileManager.default.removeItem(at: parquetPath)
        try? FileManager.default.removeItem(at: jsonPath)
        try? FileManager.default.removeItem(at: csvPath)
    }
    
    /// 加载持久化的表
    private func loadPersistedTables() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let infos = try? JSONDecoder().decode([PersistedTableInfo].self, from: data) else {
            logInfo(.persistence, "No persisted tables found")
            return
        }
        
        logInfo(.persistence, "Loading \(infos.count) persisted tables...")
        
        // 确保数据库已打开
        do {
            try DuckDBEngine.shared.openDatabase()
        } catch {
            logError(.persistence, "Failed to open database", error: error)
            return
        }
        
        var loadedList: [LoadedTable] = []
        
        for info in infos {
            let result = loadTableFromStorage(info)
            loadedList.append(result.table)
        }
        
        // 更新 UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.loadedTables = loadedList
            
            // 选择第一个正常的表
            if let firstReady = loadedList.first(where: { $0.status.isReady }) {
                self.selectedTableId = firstReady.id
            } else if let first = loadedList.first {
                self.selectedTableId = first.id
            }
            
            logInfo(.persistence, "Loaded \(loadedList.count) tables")
        }
    }
    
    /// 从存储加载单个表
    private func loadTableFromStorage(_ info: PersistedTableInfo) -> (table: LoadedTable, success: Bool) {
        let parquetPath = dataStorageDirectory.appendingPathComponent("\(info.name).parquet")
        let jsonPath = dataStorageDirectory.appendingPathComponent("\(info.name).json")
        
        // 尝试 Parquet
        if FileManager.default.fileExists(atPath: parquetPath.path) {
            do {
                // 先读取 schema 和行数，判断是否为大表
                let (columns, rowCount) = try DuckDBEngine.shared.readParquetSchema(filePath: parquetPath.path)
                
                let isLargeTable = rowCount >= 100_000
                
                if isLargeTable {
                    // 大表：直接创建视图，不读取数据
                    let error = DuckDBEngine.shared.registerTableFromParquet(name: info.name, filePath: parquetPath.path)
                    
                    // 创建一个只有 schema 的 DataFrame（用于 UI 显示列信息）
                    let df = DataFrame(columns: columns, rows: [])
                    
                    let table = LoadedTable(
                        name: info.name,
                        displayName: info.displayName,
                        dataFrame: df,
                        sourceURL: URL(fileURLWithPath: info.sourceURLPath),
                        isTruncated: true,
                        originalRowCount: rowCount,
                        status: error == nil ? .ready : .error(error!)
                    )
                    
                    logInfo(.persistence, "Loaded large table '\(info.name)' from Parquet (\(rowCount) rows, view only)")
                    return (table, error == nil)
                    
                } else {
                    // 小表：读取全部数据
                    let df = try DuckDBEngine.shared.readParquetAsDataFrame(filePath: parquetPath.path)
                    let error = DuckDBEngine.shared.registerTable(name: info.name, dataFrame: df)
                    
                    let table = LoadedTable(
                        name: info.name,
                        displayName: info.displayName,
                        dataFrame: df,
                        sourceURL: URL(fileURLWithPath: info.sourceURLPath),
                        isTruncated: false,
                        originalRowCount: nil,
                        status: error == nil ? .ready : .error(error!)
                    )
                    
                    logInfo(.persistence, "Loaded '\(info.name)' from Parquet (\(df.rowCount) rows)")
                    return (table, error == nil)
                }
                
            } catch {
                logWarning(.persistence, "Failed to load Parquet for '\(info.name)': \(error.localizedDescription)")
            }
        }
        
        // 尝试 JSON
        if FileManager.default.fileExists(atPath: jsonPath.path) {
            if let df = loadDataFrameFromJSON(jsonPath) {
                let error = DuckDBEngine.shared.registerTable(name: info.name, dataFrame: df)
                
                let table = LoadedTable(
                    name: info.name,
                    displayName: info.displayName,
                    dataFrame: df,
                    sourceURL: URL(fileURLWithPath: info.sourceURLPath),
                    isTruncated: false,
                    originalRowCount: nil,
                    status: error == nil ? .ready : .error(error!)
                )
                
                logInfo(.persistence, "Loaded '\(info.name)' from JSON (\(df.rowCount) rows)")
                return (table, error == nil)
            }
        }
        
        // 加载失败
        logWarning(.persistence, "No data file found for '\(info.name)'")
        
        let emptyTable = LoadedTable(
            name: info.name,
            displayName: info.displayName,
            dataFrame: DataFrame(columns: [], rows: []),
            sourceURL: URL(fileURLWithPath: info.sourceURLPath),
            isTruncated: false,
            originalRowCount: nil,
            status: .error("数据文件不存在")
        )
        
        return (emptyTable, false)
    }
    
    /// 从 JSON 加载 DataFrame
    private func loadDataFrameFromJSON(_ url: URL) -> DataFrame? {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let columnsData = json["columns"] as? [[String: String]],
              let rowsData = json["rows"] as? [[String]] else {
            return nil
        }
        
        let columns = columnsData.compactMap { info -> Column? in
            guard let name = info["name"], let typeStr = info["type"] else { return nil }
            return Column(name: name, type: columnTypeFromString(typeStr))
        }
        
        return DataFrame(columns: columns, rows: rowsData)
    }
    
    // MARK: - Helpers
    
    private func columnTypeString(_ type: ColumnType) -> String {
        switch type {
        case .integer: return "integer"
        case .real: return "real"
        case .text: return "text"
        case .boolean: return "boolean"
        case .date: return "date"
        case .null: return "null"
        }
    }
    
    private func columnTypeFromString(_ str: String) -> ColumnType {
        switch str {
        case "integer": return .integer
        case "real": return .real
        case "boolean": return .boolean
        case "date": return .date
        default: return .text
        }
    }
}
