//
//  DataConverter.swift
//  Sidekick
//
//  Created on 2025-01-13.
//

import Foundation

/// 数据转换器
/// 处理数据格式转换和导出
class DataConverter {
    
    // MARK: - CSV Conversion
    
    /// 将 DataFrame 转换为 CSV
    func convertToCSV(dataFrame: DataFrame) throws -> Data {
        var lines: [String] = []
        
        // Header row
        let header = dataFrame.columns.map { $0.name }.joined(separator: ",")
        lines.append(header)
        
        // Data rows
        for row in dataFrame.rows {
            let escapedRow = row.map { escapeCSVValue($0) }
            lines.append(escapedRow.joined(separator: ","))
        }
        
        let csvString = lines.joined(separator: "\n")
        guard let data = csvString.data(using: .utf8) else {
            throw ConversionError.invalidData
        }
        
        return data
    }
    
    /// 转义 CSV 值
    private func escapeCSVValue(_ value: String) -> String {
        // If value contains comma, quote, or newline, wrap in quotes
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            // Escape quotes by doubling them
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
    
    // MARK: - JSON Conversion
    
    /// 将 DataFrame 转换为 JSON
    func convertToJSON(dataFrame: DataFrame) throws -> Data {
        var jsonArray: [[String: String]] = []
        
        for row in dataFrame.rows {
            var jsonObject: [String: String] = [:]
            for (index, column) in dataFrame.columns.enumerated() {
                jsonObject[column.name] = row[index]
            }
            jsonArray.append(jsonObject)
        }
        
        return try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
    }
    
    // MARK: - INSERT Statement Generation
    
    /// 生成 INSERT 语句
    func generateInsertStatements(dataFrame: DataFrame, tableName: String) -> String {
        var statements: [String] = []
        
        for row in dataFrame.rows {
            let values = row.map { value in
                formatSQLValue(value)
            }
            
            let sql = "INSERT INTO \(tableName) VALUES (\(values.joined(separator: ", ")));"
            statements.append(sql)
        }
        
        return statements.joined(separator: "\n")
    }
    
    /// 格式化 SQL 值
    private func formatSQLValue(_ value: String) -> String {
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
    
    // MARK: - File Writing
    
    /// 写入数据到文件
    func writeToFile(data: Data, url: URL) throws {
        do {
            try data.write(to: url)
        } catch {
            throw ConversionError.fileWriteFailed(error.localizedDescription)
        }
    }
}

// MARK: - Error Types

/// 转换错误类型
enum ConversionError: Error, LocalizedError {
    case invalidData
    case emptyData
    case encodingFailed
    case fileWriteFailed(String)
    case serializationFailed(format: String, details: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "数据格式无效"
        case .emptyData:
            return "没有数据可导出"
        case .encodingFailed:
            return "数据编码失败"
        case .fileWriteFailed(let message):
            return "文件写入失败: \(message)"
        case .serializationFailed(let format, let details):
            return "\(format) 序列化失败: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidData:
            return "请检查数据格式"
        case .emptyData:
            return "请先执行查询获取数据"
        case .encodingFailed:
            return "请检查数据是否包含无效字符"
        case .fileWriteFailed:
            return "请检查文件路径和权限"
        case .serializationFailed:
            return "请检查数据格式是否正确"
        }
    }
}
