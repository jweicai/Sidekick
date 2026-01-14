//
//  QueryViewModel.swift
//  Sidekick
//
//  Created on 2025-01-13.
//

import Foundation
import Combine

/// 查询视图的 ViewModel
/// 管理 SQL 查询执行和结果状态
class QueryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var sqlQuery: String = ""
    @Published var selectedSQLText: String = ""
    @Published var queryResult: QueryResult?
    @Published var isExecuting: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let sqlEngine = SQLEngine()
    private var loadedTables: [String: DataFrame] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private let sqlQueryPersistenceKey = "Sidekick.LastSQLQuery"
    
    // MARK: - Initialization
    
    init() {
        // Initialize SQL engine
        do {
            try sqlEngine.createDatabase()
        } catch {
            errorMessage = "Failed to initialize database: \(error.localizedDescription)"
        }
        
        // Load persisted SQL query
        loadPersistedQuery()
        
        // Save SQL query when it changes
        $sqlQuery
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.saveQuery(query)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 加载表到数据库
    func loadTable(name: String, dataFrame: DataFrame) {
        do {
            // Store DataFrame reference
            loadedTables[name] = dataFrame
            
            // Create table in database
            try sqlEngine.createTable(name: name, dataFrame: dataFrame)
            
            // Clear any previous errors
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load table: \(error.localizedDescription)"
        }
    }
    
    /// 执行 SQL 查询
    func executeQuery() {
        // 优先执行选中的文本，如果没有选中则执行全部
        let queryToExecute = selectedSQLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
            ? sqlQuery 
            : selectedSQLText
        
        guard !queryToExecute.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "请输入 SQL 查询"
            return
        }
        
        isExecuting = true
        errorMessage = nil
        queryResult = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let result = try self.sqlEngine.executeQuery(sql: queryToExecute)
                
                DispatchQueue.main.async {
                    self.queryResult = result
                    self.isExecuting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isExecuting = false
                }
            }
        }
    }
    
    /// 清除查询结果
    func clearResults() {
        queryResult = nil
        errorMessage = nil
    }
    
    /// 清除所有数据
    func clearAll() {
        sqlQuery = ""
        queryResult = nil
        errorMessage = nil
        loadedTables.removeAll()
        
        // Clear persisted query
        clearPersistedQuery()
        
        // Recreate database
        sqlEngine.closeDatabase()
        do {
            try sqlEngine.createDatabase()
        } catch {
            errorMessage = "Failed to reset database: \(error.localizedDescription)"
        }
    }
    
    /// 移除表
    func removeTable(name: String) {
        do {
            try sqlEngine.dropTable(name: name)
            loadedTables.removeValue(forKey: name)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to remove table: \(error.localizedDescription)"
        }
    }
    
    /// 获取已加载的表列表
    func getLoadedTables() -> [String] {
        return Array(loadedTables.keys).sorted()
    }
    
    /// 获取表的 DataFrame
    func getDataFrame(for tableName: String) -> DataFrame? {
        return loadedTables[tableName]
    }
    
    /// 格式化 SQL 查询
    func formatSQL() {
        // 如果有选中的文本，只格式化选中的部分
        if !selectedSQLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let formatted = SQLFormatter.format(selectedSQLText)
            // 替换选中的文本
            sqlQuery = sqlQuery.replacingOccurrences(of: selectedSQLText, with: formatted)
        } else {
            // 格式化整个查询
            sqlQuery = SQLFormatter.format(sqlQuery)
        }
    }
    
    // MARK: - Export Methods
    
    /// 导出为 CSV
    func exportToCSV() -> Data? {
        guard let result = queryResult else { return nil }
        
        // Convert QueryResult to DataFrame
        let columns = result.columns.map { Column(name: $0, type: .text) }
        let dataFrame = DataFrame(columns: columns, rows: result.rows)
        
        // Use DataConverter to export
        let converter = DataConverter()
        return try? converter.convertToCSV(dataFrame: dataFrame)
    }
    
    /// 导出为 JSON
    func exportToJSON() -> Data? {
        guard let result = queryResult else { return nil }
        
        // Convert QueryResult to DataFrame
        let columns = result.columns.map { Column(name: $0, type: .text) }
        let dataFrame = DataFrame(columns: columns, rows: result.rows)
        
        // Use DataConverter to export
        let converter = DataConverter()
        return try? converter.convertToJSON(dataFrame: dataFrame)
    }
    
    /// 生成 INSERT 语句
    func generateInsertStatements(tableName: String) -> String? {
        guard let result = queryResult else { return nil }
        
        // Convert QueryResult to DataFrame
        let columns = result.columns.map { Column(name: $0, type: .text) }
        let dataFrame = DataFrame(columns: columns, rows: result.rows)
        
        // Use DataConverter to generate INSERT statements
        let converter = DataConverter()
        return converter.generateInsertStatements(dataFrame: dataFrame, tableName: tableName)
    }
    
    // MARK: - Private Methods - Persistence
    
    /// 保存 SQL 查询到 UserDefaults
    private func saveQuery(_ query: String) {
        UserDefaults.standard.set(query, forKey: sqlQueryPersistenceKey)
    }
    
    /// 从 UserDefaults 加载 SQL 查询
    private func loadPersistedQuery() {
        if let savedQuery = UserDefaults.standard.string(forKey: sqlQueryPersistenceKey) {
            sqlQuery = savedQuery
            print("📝 Loaded persisted SQL query")
        }
    }
    
    /// 清除持久化的 SQL 查询
    private func clearPersistedQuery() {
        UserDefaults.standard.removeObject(forKey: sqlQueryPersistenceKey)
        print("🗑️ Cleared persisted SQL query")
    }
}
