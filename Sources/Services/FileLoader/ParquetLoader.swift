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
        
        // 获取列信息
        var columns: [Column] = []
        for columnIndex in 0..<result.columnCount {
            let columnName = result.columns[columnIndex].name
            let columnType = inferColumnType(from: result, columnIndex: columnIndex)
            columns.append(Column(name: columnName, type: columnType))
        }
        
        // 获取行数据
        var rows: [[String]] = []
        for rowIndex in 0..<result.rowCount {
            var row: [String] = []
            for columnIndex in 0..<result.columnCount {
                let value = result[rowIndex][columnIndex]
                row.append(stringValue(from: value))
            }
            rows.append(row)
        }
        
        return DataFrame(columns: columns, rows: rows)
    }
    
    /// 推断列类型
    private func inferColumnType(from result: DuckDB.ResultSet, columnIndex: Int) -> ColumnType {
        // 检查前几行数据来推断类型
        let sampleSize = min(10, result.rowCount)
        var hasInteger = false
        var hasDecimal = false
        var hasDate = false
        
        for rowIndex in 0..<sampleSize {
            let value = result[rowIndex][columnIndex]
            let stringValue = self.stringValue(from: value)
            
            if stringValue.isEmpty { continue }
            
            // 检查是否为整数
            if Int(stringValue) != nil {
                hasInteger = true
            }
            // 检查是否为小数
            else if Double(stringValue) != nil {
                hasDecimal = true
            }
            // 检查是否为日期
            else if isDateString(stringValue) {
                hasDate = true
            }
        }
        
        if hasDate { return .date }
        if hasDecimal { return .decimal }
        if hasInteger { return .integer }
        return .text
    }
    
    /// 将 DuckDB 值转换为字符串
    private func stringValue(from value: DatabaseValue) -> String {
        switch value {
        case .null:
            return ""
        case .boolean(let bool):
            return bool ? "true" : "false"
        case .tinyInt(let int):
            return String(int)
        case .smallInt(let int):
            return String(int)
        case .integer(let int):
            return String(int)
        case .bigInt(let int):
            return String(int)
        case .hugeInt(let int):
            return String(int)
        case .uTinyInt(let uint):
            return String(uint)
        case .uSmallInt(let uint):
            return String(uint)
        case .uInteger(let uint):
            return String(uint)
        case .uBigInt(let uint):
            return String(uint)
        case .float(let float):
            return String(float)
        case .double(let double):
            return String(double)
        case .decimal(let decimal):
            return decimal.description
        case .varchar(let string):
            return string
        case .blob(let data):
            return data.base64EncodedString()
        case .date(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        case .time(let time):
            return time.description
        case .timestamp(let timestamp):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: timestamp)
        case .interval(let interval):
            return interval.description
        case .uuid(let uuid):
            return uuid.uuidString
        case .list(let array):
            return array.map { stringValue(from: $0) }.joined(separator: ", ")
        case .struct(let dict):
            return dict.map { "\($0.key): \(stringValue(from: $0.value))" }.joined(separator: ", ")
        }
    }
    
    /// 检查字符串是否为日期格式
    private func isDateString(_ string: String) -> Bool {
        let datePatterns = [
            "^\\d{4}-\\d{1,2}-\\d{1,2}",
            "^\\d{4}/\\d{1,2}/\\d{1,2}",
            "^\\d{4}年\\d{1,2}月\\d{1,2}日"
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
