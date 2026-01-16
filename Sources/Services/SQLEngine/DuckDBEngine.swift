//
//  DuckDBEngine.swift
//  Sidekick
//
//  Created on 2025-01-15.
//
//  数据管理架构：
//  ┌─────────────────────────────────────────────────────────────────┐
//  │                        DuckDBEngine                             │
//  │  职责：                                                          │
//  │  1. 管理 DuckDB 内存数据库连接                                    │
//  │  2. 小表（<10万行）：导入内存，缓存 DataFrame 用于恢复             │
//  │  3. 大表（>=10万行）：创建视图指向文件，不占用内存                  │
//  │  4. 数据库崩溃时自动恢复所有表                                    │
//  │  5. 持久化：导出为 Parquet 文件（ZSTD 压缩）                      │
//  └─────────────────────────────────────────────────────────────────┘
//
//  错误处理策略：
//  - 单表加载失败：记录错误，不影响其他表
//  - 查询失败：自动重启数据库，恢复所有表，重试查询
//  - 持久化失败：回退到 JSON 格式
//

import Foundation
import DuckDB
import AppKit

// MARK: - 表信息结构

/// 表的存储类型
enum TableStorageType {
    case memory      // 小表，数据在内存中
    case fileView    // 大表，视图指向文件
}

/// 表的运行时信息（DuckDB 内部管理）
struct TableRuntimeInfo {
    let name: String
    let storageType: TableStorageType
    var dataFrame: DataFrame?      // 小表的数据缓存
    var filePath: String?          // 大表的文件路径
    var isLoaded: Bool = false     // 是否已加载到 DuckDB
    var loadError: String?         // 加载错误信息
}

// MARK: - DuckDBEngine

/// DuckDB 查询引擎
/// 使用 DuckDB 内存数据库，支持高性能分析查询
class DuckDBEngine {
    
    // MARK: - Singleton
    
    static let shared = DuckDBEngine()
    
    // MARK: - Properties
    
    private var database: Database?
    private var connection: Connection?
    private var isOpen = false
    private let lock = NSLock()
    
    /// 所有表的运行时信息
    private var tables: [String: TableRuntimeInfo] = [:]
    
    /// 大表阈值（超过此行数直接查询文件，不导入内存）
    private let largeTableThreshold = 100_000
    
    /// 数据存储目录
    private var storageDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Sidekick/Tables", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    // MARK: - Initialization
    
    private init() {
        logInfo(.database, "DuckDBEngine initializing...")
        cleanupOldDatabaseFiles()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        
        logInfo(.database, "DuckDBEngine initialized")
    }
    
    deinit {
        closeDatabase()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationWillTerminate() {
        logInfo(.database, "Application terminating, closing database...")
        closeDatabase()
    }
    
    /// 清理旧的数据库文件（不清理数据文件）
    private func cleanupOldDatabaseFiles() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sidekickDir = appSupport.appendingPathComponent("Sidekick", isDirectory: true)
        
        // 只清理数据库文件，不清理数据文件
        let filesToClean = [
            sidekickDir.appendingPathComponent("sidekick.duckdb"),
            sidekickDir.appendingPathComponent("sidekick.duckdb.wal")
        ]
        
        for file in filesToClean {
            if FileManager.default.fileExists(atPath: file.path) {
                try? FileManager.default.removeItem(at: file)
                logDebug(.database, "Cleaned up: \(file.lastPathComponent)")
            }
        }
    }
    
    // MARK: - Database Lifecycle
    
    /// 打开数据库（线程安全）
    func openDatabase() throws {
        lock.lock()
        defer { lock.unlock() }
        
        try openDatabaseInternal()
    }
    
    /// 内部方法：打开数据库（调用前必须持有锁）
    private func openDatabaseInternal() throws {
        guard !isOpen else { return }
        
        logInfo(.database, "Opening in-memory database...")
        
        do {
            database = try Database(store: .inMemory)
            connection = try database?.connect()
            isOpen = true
            logInfo(.database, "Database opened successfully")
        } catch {
            logError(.database, "Failed to open database", error: error)
            throw SQLError.databaseCreationFailed(error.localizedDescription)
        }
    }
    
    /// 关闭数据库
    func closeDatabase() {
        lock.lock()
        defer { lock.unlock() }
        
        connection = nil
        database = nil
        isOpen = false
        
        // 标记所有表为未加载
        for key in tables.keys {
            tables[key]?.isLoaded = false
        }
        
        logInfo(.database, "Database closed")
    }
    
    /// 重启数据库并恢复所有表（调用前必须持有锁）
    private func restartAndRecover() throws {
        logWarning(.database, "Restarting database...")
        
        // 关闭
        connection = nil
        database = nil
        isOpen = false
        
        // 重新打开
        try openDatabaseInternal()
        
        // 恢复所有表
        reloadAllTables()
    }
    
    /// 确保连接可用（调用前必须持有锁）
    private func ensureConnection() throws -> Connection {
        if !isOpen || connection == nil {
            try openDatabaseInternal()
        }
        
        guard let conn = connection else {
            throw SQLError.databaseNotOpen
        }
        return conn
    }

    
    // MARK: - Table Management (Public API)
    
    /// 注册并加载表
    /// - Returns: 错误信息，nil 表示成功
    @discardableResult
    func registerTable(name: String, dataFrame: DataFrame) -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        logInfo(.database, "Registering table '\(name)' (\(dataFrame.rowCount) rows, \(dataFrame.columnCount) cols)")
        
        // 确定存储类型
        let isLargeTable = dataFrame.rowCount >= largeTableThreshold
        let storageType: TableStorageType = isLargeTable ? .fileView : .memory
        
        // 创建表信息
        var tableInfo = TableRuntimeInfo(
            name: name,
            storageType: storageType,
            dataFrame: isLargeTable ? nil : dataFrame,
            filePath: nil,
            isLoaded: false
        )
        
        // 加载到 DuckDB
        do {
            let conn = try ensureConnection()
            
            if isLargeTable {
                // 大表：写入文件，创建视图
                let filePath = try createLargeTableView(conn: conn, name: name, dataFrame: dataFrame)
                tableInfo.filePath = filePath
            } else {
                // 小表：导入内存
                try createMemoryTable(conn: conn, name: name, dataFrame: dataFrame)
            }
            
            tableInfo.isLoaded = true
            tableInfo.loadError = nil
            tables[name] = tableInfo
            
            logInfo(.database, "Table '\(name)' registered successfully (\(storageType))")
            return nil
            
        } catch {
            tableInfo.loadError = error.localizedDescription
            tables[name] = tableInfo
            
            logError(.database, "Failed to register table '\(name)'", error: error)
            return "加载失败: \(error.localizedDescription)"
        }
    }
    
    /// 移除表
    func removeTable(name: String) {
        lock.lock()
        defer { lock.unlock() }
        
        logInfo(.database, "Removing table '\(name)'")
        
        // 从 DuckDB 删除
        if let conn = connection {
            try? conn.execute("DROP VIEW IF EXISTS \(sanitizeIdentifier(name))")
            try? conn.execute("DROP TABLE IF EXISTS \(sanitizeIdentifier(name))")
        }
        
        // 从缓存移除（文件由 MainViewModel 管理）
        tables.removeValue(forKey: name)
        
        logInfo(.database, "Table '\(name)' removed")
    }
    
    /// 检查表是否已加载且可用
    func isTableReady(name: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return tables[name]?.isLoaded == true && tables[name]?.loadError == nil
    }
    
    /// 获取表的错误信息
    func getTableError(name: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return tables[name]?.loadError
    }
    
    /// 获取所有已注册的表名
    func getRegisteredTableNames() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(tables.keys).sorted()
    }
    
    // MARK: - Query Execution
    
    /// 默认结果集限制
    private let defaultResultLimit = 3000
    
    /// 执行 SQL 查询
    func executeQuery(sql: String) throws -> QueryResult {
        lock.lock()
        defer { lock.unlock() }
        
        // 对 SELECT 查询自动添加 LIMIT（如果没有的话）
        let processedSQL = addDefaultLimit(to: sql)
        
        let sqlPreview = processedSQL.prefix(100).replacingOccurrences(of: "\n", with: " ")
        logInfo(.query, "Executing: \(sqlPreview)...")
        
        // 第一次尝试
        do {
            return try executeQueryInternal(sql: processedSQL)
        } catch let error as SQLError {
            // SQL 错误直接抛出，不重启
            throw error
        } catch {
            // 其他错误（可能是数据库崩溃），尝试恢复
            let errorDesc = error.localizedDescription.lowercased()
            
            // 语法错误不需要重启
            if errorDesc.contains("syntax") || errorDesc.contains("parse") {
                throw SQLError.executionFailed(error.localizedDescription)
            }
            
            logWarning(.query, "Query failed with unexpected error, attempting recovery...")
            
            // 重启并恢复
            do {
                try restartAndRecover()
            } catch {
                throw SQLError.executionFailed("数据库恢复失败: \(error.localizedDescription)")
            }
            
            // 重试
            logInfo(.query, "Retrying query after recovery...")
            return try executeQueryInternal(sql: processedSQL)
        }
    }
    
    /// 对 SELECT 查询自动添加 LIMIT（如果没有的话）
    private func addDefaultLimit(to sql: String) -> String {
        let trimmed = sql.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.uppercased()
        
        // 检测中文分号，提示用户
        if trimmed.contains("；") {
            // 不处理，让 DuckDB 报错，用户会看到错误信息
            return sql
        }
        
        // 只处理 SELECT 语句
        guard upper.hasPrefix("SELECT") else { return sql }
        
        // 如果已经有 LIMIT，不添加
        if upper.contains(" LIMIT ") { return sql }
        
        // 移除末尾的英文分号
        var processed = trimmed
        if processed.hasSuffix(";") {
            processed = String(processed.dropLast())
        }
        
        // 添加 LIMIT
        return "\(processed) LIMIT \(defaultResultLimit)"
    }
    
    private func executeQueryInternal(sql: String) throws -> QueryResult {
        guard let conn = connection else {
            throw SQLError.databaseNotOpen
        }
        
        let startTime = Date()
        
        do {
            let result = try conn.query(sql)
            
            var columns: [String] = []
            for i in 0..<result.columnCount {
                columns.append(result.columnName(at: i))
            }
            
            var rows: [[String]] = []
            for rowIndex in 0..<result.rowCount {
                var row: [String] = []
                for colIndex in 0..<result.columnCount {
                    let column = result[colIndex].cast(to: String.self)
                    row.append(column[rowIndex] ?? "")
                }
                rows.append(row)
            }
            
            let executionTime = Date().timeIntervalSince(startTime)
            logInfo(.query, "Query completed: \(rows.count) rows in \(String(format: "%.3f", executionTime))s")
            
            return QueryResult(columns: columns, rows: rows, executionTime: executionTime)
            
        } catch let dbError as DatabaseError {
            let executionTime = Date().timeIntervalSince(startTime)
            // 获取详细错误信息
            var errorMessage = "\(dbError)"
            
            // 提取 reason 中的具体错误
            if errorMessage.contains("reason: Optional(\"") {
                if let start = errorMessage.range(of: "reason: Optional(\""),
                   let end = errorMessage.range(of: "\")", range: start.upperBound..<errorMessage.endIndex) {
                    errorMessage = String(errorMessage[start.upperBound..<end.lowerBound])
                }
            }
            
            // 检测常见错误并给出友好提示
            if errorMessage.contains("；") || sql.contains("；") {
                errorMessage = "SQL 语法错误：请使用英文分号 ; 而不是中文分号 ；"
            }
            
            logError(.query, "Query failed after \(String(format: "%.3f", executionTime))s: \(errorMessage)", error: dbError)
            throw SQLError.executionFailed(errorMessage)
        } catch {
            let executionTime = Date().timeIntervalSince(startTime)
            logError(.query, "Query failed after \(String(format: "%.3f", executionTime))s", error: error)
            throw SQLError.executionFailed(error.localizedDescription)
        }
    }

    
    // MARK: - Persistence (Public API)
    
    /// 导出表为 Parquet 文件
    func exportToParquet(tableName: String, filePath: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        logInfo(.persistence, "Exporting '\(tableName)' to Parquet...")
        
        let conn = try ensureConnection()
        let sql = "COPY \(sanitizeIdentifier(tableName)) TO '\(filePath)' (FORMAT PARQUET, COMPRESSION ZSTD)"
        try conn.execute(sql)
        
        logInfo(.persistence, "Exported '\(tableName)' to Parquet")
    }
    
    /// 从 Parquet 文件读取 DataFrame
    func readParquetAsDataFrame(filePath: String) throws -> DataFrame {
        lock.lock()
        defer { lock.unlock() }
        
        logInfo(.persistence, "Reading Parquet: \(URL(fileURLWithPath: filePath).lastPathComponent)")
        
        let conn = try ensureConnection()
        let result = try conn.query("SELECT * FROM read_parquet('\(filePath)')")
        
        var columns: [Column] = []
        for i in 0..<result.columnCount {
            columns.append(Column(name: result.columnName(at: i), type: .text))
        }
        
        var rows: [[String]] = []
        for rowIndex in 0..<result.rowCount {
            var row: [String] = []
            for colIndex in 0..<result.columnCount {
                let column = result[colIndex].cast(to: String.self)
                row.append(column[rowIndex] ?? "")
            }
            rows.append(row)
        }
        
        logInfo(.persistence, "Read \(rows.count) rows from Parquet")
        return DataFrame(columns: columns, rows: rows)
    }
    
    /// 从 Parquet 文件只读取 schema（不读取数据），用于大表
    func readParquetSchema(filePath: String) throws -> (columns: [Column], rowCount: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        logInfo(.persistence, "Reading Parquet schema: \(URL(fileURLWithPath: filePath).lastPathComponent)")
        
        let conn = try ensureConnection()
        
        // 只读取 schema，不读取数据
        let schemaResult = try conn.query("DESCRIBE SELECT * FROM read_parquet('\(filePath)')")
        
        var columns: [Column] = []
        for rowIndex in 0..<schemaResult.rowCount {
            let nameCol = schemaResult[0].cast(to: String.self)
            if let name = nameCol[rowIndex] {
                columns.append(Column(name: name, type: .text))
            }
        }
        
        // 获取行数
        let countResult = try conn.query("SELECT COUNT(*) FROM read_parquet('\(filePath)')")
        let countCol = countResult[0].cast(to: Int.self)
        let rowCount = countCol[0] ?? 0
        
        logInfo(.persistence, "Parquet schema: \(columns.count) columns, \(rowCount) rows")
        return (columns, rowCount)
    }
    
    /// 直接从 Parquet 文件创建视图（大表用，不加载数据到内存）
    func registerTableFromParquet(name: String, filePath: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        logInfo(.database, "Registering table '\(name)' from Parquet file")
        
        do {
            let conn = try ensureConnection()
            
            // 创建视图
            try? conn.execute("DROP VIEW IF EXISTS \(sanitizeIdentifier(name))")
            try? conn.execute("DROP TABLE IF EXISTS \(sanitizeIdentifier(name))")
            
            let sql = "CREATE VIEW \(sanitizeIdentifier(name)) AS SELECT * FROM read_parquet('\(filePath)')"
            try conn.execute(sql)
            
            // 记录到大表映射
            var info = TableRuntimeInfo(
                name: name,
                storageType: .fileView,
                dataFrame: nil,
                filePath: filePath,
                isLoaded: true
            )
            tables[name] = info
            
            logInfo(.database, "Registered table '\(name)' from Parquet")
            return nil
            
        } catch {
            logError(.database, "Failed to register table '\(name)' from Parquet", error: error)
            return "加载失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Internal: Table Creation
    
    /// 创建内存表（小表）
    private func createMemoryTable(conn: Connection, name: String, dataFrame: DataFrame) throws {
        // 删除已存在的表
        try? conn.execute("DROP VIEW IF EXISTS \(sanitizeIdentifier(name))")
        try? conn.execute("DROP TABLE IF EXISTS \(sanitizeIdentifier(name))")
        
        // 创建表结构
        let columnDefs = dataFrame.columns.map { col in
            "\(sanitizeIdentifier(col.name)) \(duckDBType(for: col.type))"
        }.joined(separator: ", ")
        
        try conn.execute("CREATE TABLE \(sanitizeIdentifier(name)) (\(columnDefs))")
        
        // 批量插入数据
        guard !dataFrame.rows.isEmpty else {
            logInfo(.database, "Created empty table '\(name)'")
            return
        }
        
        try conn.execute("BEGIN TRANSACTION")
        
        do {
            let batchSize = 10000
            var rowIndex = 0
            
            while rowIndex < dataFrame.rowCount {
                let endIndex = min(rowIndex + batchSize, dataFrame.rowCount)
                let batch = dataFrame.rows[rowIndex..<endIndex]
                
                var valuesList: [String] = []
                for row in batch {
                    let paddedRow = padRow(row, to: dataFrame.columnCount)
                    let values = paddedRow.map { escapeValue($0) }.joined(separator: ", ")
                    valuesList.append("(\(values))")
                }
                
                let sql = "INSERT INTO \(sanitizeIdentifier(name)) VALUES \(valuesList.joined(separator: ", "))"
                
                do {
                    try conn.execute(sql)
                } catch {
                    // 批量失败，逐行插入找出问题
                    logWarning(.database, "Batch insert failed, trying row by row...")
                    try insertRowByRow(conn: conn, name: name, batch: Array(batch), startIndex: rowIndex, columnCount: dataFrame.columnCount)
                }
                
                rowIndex = endIndex
                if rowIndex % 100000 == 0 {
                    logDebug(.database, "Inserted \(rowIndex)/\(dataFrame.rowCount) rows")
                }
            }
            
            try conn.execute("COMMIT")
            logInfo(.database, "Created table '\(name)' with \(dataFrame.rowCount) rows")
            
        } catch {
            try? conn.execute("ROLLBACK")
            throw error
        }
    }
    
    /// 逐行插入（用于调试问题行）
    private func insertRowByRow(conn: Connection, name: String, batch: [[String]], startIndex: Int, columnCount: Int) throws {
        for (i, row) in batch.enumerated() {
            let paddedRow = padRow(row, to: columnCount)
            let values = paddedRow.map { escapeValue($0) }.joined(separator: ", ")
            let sql = "INSERT INTO \(sanitizeIdentifier(name)) VALUES (\(values))"
            
            do {
                try conn.execute(sql)
            } catch {
                let rowNum = startIndex + i
                logError(.database, "Failed at row \(rowNum): \(row.prefix(3))...", error: error)
                throw error
            }
        }
    }
    
    /// 创建大表视图
    private func createLargeTableView(conn: Connection, name: String, dataFrame: DataFrame) throws -> String {
        logInfo(.database, "Large table (\(dataFrame.rowCount) rows), creating file view...")
        
        let csvPath = storageDirectory.appendingPathComponent("\(name).csv").path
        let parquetPath = storageDirectory.appendingPathComponent("\(name).parquet").path
        
        // 如果已有 Parquet 文件，直接使用
        if FileManager.default.fileExists(atPath: parquetPath) {
            logInfo(.database, "Using existing Parquet file")
            try createViewFromFile(conn: conn, name: name, filePath: parquetPath, format: "parquet")
            return parquetPath
        }
        
        // 写入 CSV
        try writeCSV(dataFrame: dataFrame, to: csvPath)
        
        // 创建视图
        try createViewFromFile(conn: conn, name: name, filePath: csvPath, format: "csv")
        
        // 后台转换为 Parquet
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.convertToParquetAsync(tableName: name, csvPath: csvPath, parquetPath: parquetPath)
        }
        
        return csvPath
    }
    
    /// 从文件创建视图
    private func createViewFromFile(conn: Connection, name: String, filePath: String, format: String) throws {
        try? conn.execute("DROP VIEW IF EXISTS \(sanitizeIdentifier(name))")
        try? conn.execute("DROP TABLE IF EXISTS \(sanitizeIdentifier(name))")
        
        let sql: String
        if format == "parquet" {
            sql = "CREATE VIEW \(sanitizeIdentifier(name)) AS SELECT * FROM read_parquet('\(filePath)')"
        } else {
            sql = "CREATE VIEW \(sanitizeIdentifier(name)) AS SELECT * FROM read_csv('\(filePath)', header=true, auto_detect=true)"
        }
        
        try conn.execute(sql)
    }
    
    /// 后台转换 CSV 到 Parquet
    private func convertToParquetAsync(tableName: String, csvPath: String, parquetPath: String) {
        logInfo(.database, "Background: Converting '\(tableName)' to Parquet...")
        
        do {
            let tempDB = try Database(store: .inMemory)
            let tempConn = try tempDB.connect()
            
            let sql = """
            COPY (SELECT * FROM read_csv('\(csvPath)', header=true, auto_detect=true)) 
            TO '\(parquetPath)' (FORMAT PARQUET, COMPRESSION ZSTD)
            """
            try tempConn.execute(sql)
            
            logInfo(.database, "Parquet conversion completed for '\(tableName)'")
            
            // 转换完成，立即切换视图（加锁，但很快）
            switchToParquet(tableName: tableName, parquetPath: parquetPath, csvPath: csvPath)
            
        } catch {
            logError(.database, "Parquet conversion failed for '\(tableName)'", error: error)
        }
    }
    
    /// 切换视图到 Parquet（加锁但很快）
    private func switchToParquet(tableName: String, parquetPath: String, csvPath: String) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let conn = connection, isOpen else { return }
        
        do {
            try createViewFromFile(conn: conn, name: tableName, filePath: parquetPath, format: "parquet")
            tables[tableName]?.filePath = parquetPath
            try? FileManager.default.removeItem(atPath: csvPath)
            logInfo(.database, "Switched '\(tableName)' to Parquet")
        } catch {
            logError(.database, "Failed to switch '\(tableName)' to Parquet", error: error)
        }
    }

    
    // MARK: - Internal: Recovery
    
    /// 重新加载所有表
    private func reloadAllTables() {
        guard let conn = connection else { return }
        
        logInfo(.database, "Reloading \(tables.count) tables...")
        
        for (name, info) in tables {
            do {
                switch info.storageType {
                case .memory:
                    if let df = info.dataFrame {
                        try createMemoryTable(conn: conn, name: name, dataFrame: df)
                        tables[name]?.isLoaded = true
                        tables[name]?.loadError = nil
                        logInfo(.database, "Reloaded memory table '\(name)'")
                    }
                    
                case .fileView:
                    if let filePath = info.filePath {
                        let format = filePath.hasSuffix(".parquet") ? "parquet" : "csv"
                        try createViewFromFile(conn: conn, name: name, filePath: filePath, format: format)
                        tables[name]?.isLoaded = true
                        tables[name]?.loadError = nil
                        logInfo(.database, "Reloaded file view '\(name)'")
                    }
                }
            } catch {
                tables[name]?.isLoaded = false
                tables[name]?.loadError = error.localizedDescription
                logError(.database, "Failed to reload '\(name)'", error: error)
            }
        }
    }
    
    // MARK: - Internal: Utilities
    
    /// 写入 CSV 文件
    private func writeCSV(dataFrame: DataFrame, to path: String) throws {
        logInfo(.database, "Writing \(dataFrame.rowCount) rows to CSV...")
        
        var content = ""
        
        // 表头
        content += dataFrame.columns.map { escapeCSVField($0.name) }.joined(separator: ",") + "\n"
        
        // 数据
        for (index, row) in dataFrame.rows.enumerated() {
            let paddedRow = padRow(row, to: dataFrame.columnCount)
            content += paddedRow.map { escapeCSVField($0) }.joined(separator: ",") + "\n"
            
            // 分批写入避免内存过大
            if index > 0 && index % 500000 == 0 {
                if index == 500000 {
                    try content.write(toFile: path, atomically: true, encoding: .utf8)
                } else {
                    try appendToFile(content, path: path)
                }
                content = ""
                logDebug(.database, "Written \(index)/\(dataFrame.rowCount) rows")
            }
        }
        
        // 写入剩余
        if !content.isEmpty {
            if dataFrame.rowCount <= 500000 {
                try content.write(toFile: path, atomically: true, encoding: .utf8)
            } else {
                try appendToFile(content, path: path)
            }
        }
        
        logInfo(.database, "CSV written: \(path)")
    }
    
    private func appendToFile(_ content: String, path: String) throws {
        guard let data = content.data(using: .utf8),
              let handle = FileHandle(forWritingAtPath: path) else {
            throw SQLError.executionFailed("Cannot write to file")
        }
        handle.seekToEndOfFile()
        handle.write(data)
        handle.closeFile()
    }
    
    private func padRow(_ row: [String], to count: Int) -> [String] {
        var result = row
        while result.count < count {
            result.append("")
        }
        if result.count > count {
            result = Array(result.prefix(count))
        }
        return result
    }
    
    private func escapeCSVField(_ value: String) -> String {
        // 空字符串、包含逗号、引号、换行的字段都需要用引号包围
        if value.isEmpty || value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
    
    private func escapeValue(_ value: String) -> String {
        if value.isEmpty { return "NULL" }
        if Int(value) != nil { return value }
        if Double(value) != nil { return value }
        
        let lower = value.lowercased()
        if lower == "true" || lower == "false" { return lower }
        
        // 清理控制字符，转义引号
        var escaped = value.unicodeScalars.filter { scalar in
            scalar == "\n" || scalar == "\t" || scalar == "\r" || !CharacterSet.controlCharacters.contains(scalar)
        }.map { String($0) }.joined()
        
        escaped = escaped.replacingOccurrences(of: "\\", with: "\\\\")
        escaped = escaped.replacingOccurrences(of: "'", with: "''")
        
        return "'\(escaped)'"
    }
    
    private func sanitizeIdentifier(_ identifier: String) -> String {
        "\"\(identifier.replacingOccurrences(of: " ", with: "_"))\""
    }
    
    private func duckDBType(for type: ColumnType) -> String {
        switch type {
        case .integer: return "BIGINT"
        case .real: return "DOUBLE"
        case .text: return "VARCHAR"
        case .boolean: return "BOOLEAN"
        case .date: return "VARCHAR"
        case .null: return "VARCHAR"
        }
    }
    
    // MARK: - Legacy API (兼容旧代码)
    
    /// 创建表（兼容旧 API）
    func createTable(name: String, dataFrame: DataFrame) throws {
        if let error = registerTable(name: name, dataFrame: dataFrame) {
            throw SQLError.executionFailed(error)
        }
    }
    
    /// 删除表（兼容旧 API）
    func dropTable(name: String) throws {
        removeTable(name: name)
    }
    
    /// 列出所有表
    func listTables() throws -> [String] {
        let result = try executeQuery(sql: "SHOW TABLES")
        return result.rows.map { $0[0] }
    }
    
    /// 从 Parquet 创建表
    func createTableFromParquet(tableName: String, filePath: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let conn = try ensureConnection()
        try? conn.execute("DROP TABLE IF EXISTS \(sanitizeIdentifier(tableName))")
        try conn.execute("CREATE TABLE \(sanitizeIdentifier(tableName)) AS SELECT * FROM read_parquet('\(filePath)')")
    }
}
