//
//  SQLEngine.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import Foundation
import SQLite3

/// SQL 查询引擎
/// 管理 SQLite 内存数据库并执行 SQL 查询
class SQLEngine {
    
    // MARK: - Properties
    
    private var db: OpaquePointer?
    private var isOpen = false
    
    // MARK: - Initialization
    
    init() {
        // Database will be created when needed
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Management
    
    /// 创建内存数据库
    func createDatabase() throws {
        guard !isOpen else {
            return // Already open
        }
        
        let result = sqlite3_open(":memory:", &db)
        guard result == SQLITE_OK else {
            throw SQLError.databaseCreationFailed(getSQLiteErrorMessage())
        }
        
        isOpen = true
    }
    
    /// 关闭数据库
    func closeDatabase() {
        guard isOpen, let db = db else {
            return
        }
        
        sqlite3_close(db)
        self.db = nil
        isOpen = false
    }
    
    // MARK: - Table Management
    
    /// 从 DataFrame 创建表
    func createTable(name: String, dataFrame: DataFrame) throws {
        // Ensure database is open
        if !isOpen {
            try createDatabase()
        }
        
        // Generate CREATE TABLE statement
        let columnDefinitions = dataFrame.columns.map { column in
            "\(sanitizeIdentifier(column.name)) \(column.type.sqlType)"
        }
        
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS \(sanitizeIdentifier(name)) (
            \(columnDefinitions.joined(separator: ", "))
        )
        """
        
        // Execute CREATE TABLE
        try execute(createTableSQL)
        
        // Insert data rows
        for row in dataFrame.rows {
            let values = row.map { escapeValue($0) }
            let insertSQL = """
            INSERT INTO \(sanitizeIdentifier(name)) VALUES (\(values.joined(separator: ", ")))
            """
            try execute(insertSQL)
        }
    }
    
    /// 删除表
    func dropTable(name: String) throws {
        let dropSQL = "DROP TABLE IF EXISTS \(sanitizeIdentifier(name))"
        try execute(dropSQL)
    }
    
    /// 列出所有表
    func listTables() throws -> [String] {
        let sql = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
        let result = try executeQuery(sql: sql)
        return result.rows.map { $0[0] }
    }
    
    // MARK: - Query Execution
    
    /// 执行 SQL 查询
    func executeQuery(sql: String) throws -> QueryResult {
        // Ensure database is open
        if !isOpen {
            try createDatabase()
        }
        
        let startTime = Date()
        var statement: OpaquePointer?
        
        // Prepare statement
        let prepareResult = sqlite3_prepare_v2(db, sql, -1, &statement, nil)
        guard prepareResult == SQLITE_OK else {
            let errorMessage = getSQLiteErrorMessage()
            throw SQLError.queryPreparationFailed(errorMessage)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        // Extract column names
        let columnCount = sqlite3_column_count(statement)
        let columns = (0..<columnCount).map { index in
            String(cString: sqlite3_column_name(statement, index))
        }
        
        // Fetch rows
        var rows: [[String]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let row = (0..<columnCount).map { index -> String in
                if let cString = sqlite3_column_text(statement, index) {
                    return String(cString: cString)
                }
                return ""
            }
            rows.append(row)
        }
        
        let executionTime = Date().timeIntervalSince(startTime)
        return QueryResult(columns: columns, rows: rows, executionTime: executionTime)
    }
    
    // MARK: - Private Methods
    
    /// 执行 SQL 语句（不返回结果）
    private func execute(_ sql: String) throws {
        guard let db = db else {
            throw SQLError.databaseNotOpen
        }
        
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)
        
        if result != SQLITE_OK {
            let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            throw SQLError.executionFailed(error)
        }
    }
    
    /// 转义 SQL 值
    private func escapeValue(_ value: String) -> String {
        // Empty values are NULL
        if value.isEmpty {
            return "NULL"
        }
        
        // Try to parse as integer
        if Int(value) != nil {
            return value
        }
        
        // Try to parse as double
        if Double(value) != nil {
            return value
        }
        
        // Escape single quotes and wrap in quotes
        let escaped = value.replacingOccurrences(of: "'", with: "''")
        return "'\(escaped)'"
    }
    
    /// 清理标识符（表名、列名）
    private func sanitizeIdentifier(_ identifier: String) -> String {
        // Remove or replace invalid characters
        let sanitized = identifier.replacingOccurrences(of: " ", with: "_")
        
        // Wrap in quotes to handle special characters
        return "\"\(sanitized)\""
    }
    
    /// 获取 SQLite 错误消息
    private func getSQLiteErrorMessage() -> String {
        guard let db = db else {
            return "Database not initialized"
        }
        
        if let errorPointer = sqlite3_errmsg(db) {
            return String(cString: errorPointer)
        }
        
        return "Unknown SQLite error"
    }
}

// MARK: - Error Types

/// SQL 错误类型
enum SQLError: Error, LocalizedError {
    case databaseNotOpen
    case databaseCreationFailed(String)
    case queryPreparationFailed(String)
    case executionFailed(String)
    case tableNotFound(String)
    case tableCreationFailed(tableName: String, details: String)
    case tableDropFailed(tableName: String, details: String)
    
    var errorDescription: String? {
        switch self {
        case .databaseNotOpen:
            return "数据库未打开"
        case .databaseCreationFailed(let message):
            return "数据库创建失败: \(message)"
        case .queryPreparationFailed(let message):
            return "SQL 查询准备失败: \(message)"
        case .executionFailed(let message):
            return "SQL 执行失败: \(message)"
        case .tableNotFound(let tableName):
            return "表不存在: \(tableName)"
        case .tableCreationFailed(let tableName, let details):
            return "创建表失败: \(tableName)。\(details)"
        case .tableDropFailed(let tableName, let details):
            return "删除表失败: \(tableName)。\(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .databaseNotOpen:
            return "请重新加载数据"
        case .databaseCreationFailed:
            return "请重试或重启应用"
        case .queryPreparationFailed:
            return "请检查 SQL 语法是否正确"
        case .executionFailed:
            return "请检查 SQL 语法是否正确"
        case .tableNotFound:
            return "请先加载包含该表的数据文件"
        case .tableCreationFailed:
            return "请检查数据格式是否正确"
        case .tableDropFailed:
            return "请重试或重新加载数据"
        }
    }
}
