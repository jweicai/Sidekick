//
//  CSVLoader.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import Foundation
import UniformTypeIdentifiers

/// CSV 文件加载器
class CSVLoader: FileLoaderProtocol {
    
    // MARK: - FileLoaderProtocol
    
    var name: String { "CSV Loader" }
    var version: String { "1.0.0" }
    var supportedTypes: [UTType] { [.commaSeparatedText, .plainText] }
    var supportedExtensions: [String] { ["csv", "txt"] }
    
    // MARK: - Public Methods
    
    /// 从 URL 加载 CSV 文件
    func load(from url: URL) throws -> DataFrame {
        let content = try String(contentsOf: url, encoding: .utf8)
        return try parse(content: content)
    }
    
    /// 解析 CSV 内容
    private func parse(content: String) throws -> DataFrame {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !lines.isEmpty else {
            throw CSVError.emptyFile
        }
        
        // 解析表头
        let columnNames = parseRow(lines[0])
        
        // 解析数据行
        let rows = lines.dropFirst().map { parseRow($0) }
        
        // 推断列类型
        let columns = inferColumnTypes(columnNames: columnNames, rows: rows)
        
        return DataFrame(columns: columns, rows: rows)
    }
    
    /// 解析单行数据
    private func parseRow(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // 添加最后一个字段
        result.append(currentField.trimmingCharacters(in: .whitespaces))
        
        return result
    }
    
    /// 推断列类型
    private func inferColumnTypes(columnNames: [String], rows: [[String]]) -> [Column] {
        var columns: [Column] = []
        
        for (index, name) in columnNames.enumerated() {
            let columnValues = rows.compactMap { $0.indices.contains(index) ? $0[index] : nil }
            let type = inferType(from: columnValues)
            columns.append(Column(name: name, type: type))
        }
        
        return columns
    }
    
    /// 推断单列的数据类型
    private func inferType(from values: [String]) -> ColumnType {
        guard !values.isEmpty else { return .text }
        
        let nonEmptyValues = values.filter { !$0.isEmpty }
        guard !nonEmptyValues.isEmpty else { return .text }
        
        // 检查是否全是整数
        let allIntegers = nonEmptyValues.allSatisfy { Int($0) != nil }
        if allIntegers {
            return .integer
        }
        
        // 检查是否全是浮点数
        let allReals = nonEmptyValues.allSatisfy { Double($0) != nil }
        if allReals {
            return .real
        }
        
        // 检查是否全是布尔值
        let allBooleans = nonEmptyValues.allSatisfy { 
            $0.lowercased() == "true" || $0.lowercased() == "false" 
        }
        if allBooleans {
            return .boolean
        }
        
        // 默认为文本
        return .text
    }
}

/// CSV 错误类型
enum CSVError: Error, LocalizedError {
    case emptyFile
    case invalidFormat
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "CSV 文件为空"
        case .invalidFormat:
            return "CSV 格式无效"
        case .encodingError:
            return "文件编码错误"
        }
    }
}
