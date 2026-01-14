//
//  ParquetLoader.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import Foundation
import UniformTypeIdentifiers
import DuckDB

/// Parquet 文件加载器
/// 使用 DuckDB 原生支持读取 Parquet 文件
class ParquetLoader: FileLoaderProtocol {
    
    // MARK: - FileLoaderProtocol
    
    var name: String { "Parquet Loader (DuckDB)" }
    var version: String { "1.0.0" }
    var supportedTypes: [UTType] { [] }
    var supportedExtensions: [String] { ["parquet"] }
    
    // MARK: - Public Methods
    
    func load(from url: URL) throws -> DataFrame {
        do {
            // 创建临时内存数据库
            let database = try Database(store: .inMemory)
            let connection = try database.connect()
            
            // 使用 DuckDB 读取 Parquet 文件
            // DuckDB 原生支持 Parquet 格式，无需外部依赖
            let tableName = "parquet_data"
            let query = """
            CREATE TABLE \(tableName) AS
            SELECT * FROM read_parquet('\(url.path)');
            """
            
            try connection.execute(query)
            
            // 查询所有数据
            let result = try connection.query("SELECT * FROM \(tableName)")
            
            // 转换为 DataFrame
            return try convertToDataFrame(result: result)
            
        } catch {
            throw ParquetLoaderError.readFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    /// 将 DuckDB 结果转换为 DataFrame
    private func convertToDataFrame(result: DuckDB.ResultSet) throws -> DataFrame {
        guard result.columnCount > 0 else {
            throw ParquetLoaderError.emptyFile
        }
        
        // 获取列信息（通过尝试不同类型的 cast 来推断）
        var columns: [Column] = []
        for columnIndex in 0..<result.columnCount {
            let columnName = result.columnName(at: columnIndex)
            let columnType = inferColumnTypeFromDuckDB(result: result, columnIndex: columnIndex)
            columns.append(Column(name: columnName, type: columnType))
        }
        
        // 获取行数据
        var rows: [[String]] = []
        for rowIndex in 0..<result.rowCount {
            var row: [String] = []
            for columnIndex in 0..<result.columnCount {
                let column = result[columnIndex].cast(to: String.self)
                let value = column[rowIndex] ?? ""
                row.append(value)
            }
            rows.append(row)
        }
        
        return DataFrame(columns: columns, rows: rows)
    }
    
    /// 通过 DuckDB 的类型推断列类型
    private func inferColumnTypeFromDuckDB(result: DuckDB.ResultSet, columnIndex: DBInt) -> ColumnType {
        // 尝试获取第一行数据来判断类型
        guard result.rowCount > 0 else { return .text }
        
        let column = result[columnIndex]
        
        // 尝试不同的类型转换，看哪个成功
        // 注意：DuckDB 会自动处理类型转换，所以我们需要检查原始值
        
        // 尝试布尔类型
        if let boolColumn = column.cast(to: Bool.self)[0], boolColumn != nil {
            // 检查是否真的是布尔值（而不是数字转换来的）
            let strColumn = column.cast(to: String.self)
            if let strValue = strColumn[0]?.lowercased(), 
               strValue == "true" || strValue == "false" {
                return .boolean
            }
        }
        
        // 尝试整数类型
        if let intColumn = column.cast(to: Int.self)[0], intColumn != nil {
            // 检查是否有小数点
            let strColumn = column.cast(to: String.self)
            if let strValue = strColumn[0], !strValue.contains(".") {
                return .integer
            }
        }
        
        // 尝试浮点数类型
        if let doubleColumn = column.cast(to: Double.self)[0], doubleColumn != nil {
            return .real
        }
        
        // 尝试日期类型
        let strColumn = column.cast(to: String.self)
        if let strValue = strColumn[0], isDateString(strValue) {
            return .date
        }
        
        // 默认为文本
        return .text
    }
    
    /// 检查字符串是否为日期格式
    private func isDateString(_ string: String) -> Bool {
        let datePatterns = [
            "^\\d{4}-\\d{1,2}-\\d{1,2}",           // 2024-01-15
            "^\\d{4}/\\d{1,2}/\\d{1,2}",           // 2024/01/15
            "^\\d{4}年\\d{1,2}月\\d{1,2}日"        // 2024年1月15日
        ]
        
        for pattern in datePatterns {
            if string.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }
}

// MARK: - Parquet Loader Errors

enum ParquetLoaderError: Error, LocalizedError {
    case readFailed(String)
    case emptyFile
    
    var errorDescription: String? {
        switch self {
        case .readFailed(let message):
            return "读取 Parquet 文件失败：\(message)"
        case .emptyFile:
            return "Parquet 文件为空或无法读取数据"
        }
    }
}
