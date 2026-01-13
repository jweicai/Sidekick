//
//  QueryViewModel.swift
//  TableQuery
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
    @Published var queryResult: QueryResult?
    @Published var isExecuting: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let sqlEngine = SQLEngine()
    private var loadedTables: [String: DataFrame] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Initialize SQL engine
        do {
            try sqlEngine.createDatabase()
        } catch {
            errorMessage = "Failed to initialize database: \(error.localizedDescription)"
        }
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
        guard !sqlQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "请输入 SQL 查询"
            return
        }
        
        isExecuting = true
        errorMessage = nil
        queryResult = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let result = try self.sqlEngine.executeQuery(sql: self.sqlQuery)
                
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
}
