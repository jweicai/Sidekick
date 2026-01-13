//
//  MainViewModel.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import Foundation
import Combine

/// 已加载的表信息
struct LoadedTable: Identifiable {
    let id = UUID()
    let name: String
    let dataFrame: DataFrame
    let sourceURL: URL
    
    var rowCount: Int { dataFrame.rows.count }
    var columnCount: Int { dataFrame.columns.count }
    var columnNames: [String] { dataFrame.columns.map { $0.name } }
    var columnTypes: [ColumnType] { dataFrame.columns.map { $0.type } }
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
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// 加载文件
    func loadFile(url: URL) {
        isLoading = true
        errorMessage = nil
        fileName = url.lastPathComponent
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let dataFrame = try self?.loaderManager.loadFile(from: url)
                
                DispatchQueue.main.async {
                    if let df = dataFrame {
                        let tableName = url.deletingPathExtension().lastPathComponent
                        let table = LoadedTable(name: tableName, dataFrame: df, sourceURL: url)
                        self?.loadedTables.append(table)
                        self?.selectedTableId = table.id
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
    
    /// 移除表
    func removeTable(id: UUID) {
        loadedTables.removeAll { $0.id == id }
        
        // 如果移除的是当前选中的表，选择第一个表
        if selectedTableId == id {
            selectedTableId = loadedTables.first?.id
        }
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
    }
}
