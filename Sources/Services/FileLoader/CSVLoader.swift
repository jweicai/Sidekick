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
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw CSVError.encodingError
        }
        return try parse(content: content)
    }
    
    /// 解析 CSV 内容
    private func parse(content: String) throws -> DataFrame {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !lines.isEmpty else {
            throw CSVError.emptyFile
        }
        
        // 解析第一行
        let firstRow = parseRow(lines[0])
        
        // 检测第一行是否为列名（如果第一行全是数据，则没有表头）
        let hasHeader = detectHeader(firstRow: firstRow, secondRow: lines.count > 1 ? parseRow(lines[1]) : nil)
        
        let columnNames: [String]
        let dataStartIndex: Int
        
        if hasHeader {
            // 第一行是列名
            columnNames = firstRow.map { name in
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty ? "Column\(firstRow.firstIndex(of: name)! + 1)" : trimmed
            }
            dataStartIndex = 1
        } else {
            // 第一行就是数据，生成列名
            columnNames = (1...firstRow.count).map { "Column\($0)" }
            dataStartIndex = 0
        }
        
        // 解析数据行
        let rows = lines.dropFirst(dataStartIndex).map { parseRow($0) }
        
        // 推断列类型
        let columns = inferColumnTypes(columnNames: columnNames, rows: rows)
        
        return DataFrame(columns: columns, rows: rows)
    }
    
    /// 检测第一行是否为表头
    /// 如果第一行全是数值，而第二行有文本，则第一行可能是数据
    /// 如果第一行有文本，则很可能是表头
    private func detectHeader(firstRow: [String], secondRow: [String]?) -> Bool {
        // 如果第一行有任何非数值的字段，认为是表头
        let hasNonNumeric = firstRow.contains { field in
            let trimmed = field.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && Double(trimmed) == nil
        }
        
        if hasNonNumeric {
            return true
        }
        
        // 如果第一行全是数值，检查第二行
        // 如果没有第二行，假设第一行是表头
        guard let secondRow = secondRow else {
            return true
        }
        
        // 如果第二行也全是数值，假设第一行是数据
        let secondRowAllNumeric = secondRow.allSatisfy { field in
            let trimmed = field.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty || Double(trimmed) != nil
        }
        
        return !secondRowAllNumeric
    }
    
    /// 解析单行数据
    private func parseRow(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        var previousChar: Character?
        
        for char in line {
            if char == "\"" {
                // Handle escaped quotes (double quotes)
                if insideQuotes && previousChar == "\"" {
                    currentField.append(char)
                    previousChar = nil // Reset to avoid double processing
                    continue
                }
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                // Remove surrounding quotes if present
                let trimmed = currentField.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count >= 2 {
                    let startIndex = trimmed.index(after: trimmed.startIndex)
                    let endIndex = trimmed.index(before: trimmed.endIndex)
                    result.append(String(trimmed[startIndex..<endIndex]))
                } else {
                    result.append(trimmed)
                }
                currentField = ""
            } else {
                currentField.append(char)
            }
            previousChar = char
        }
        
        // 添加最后一个字段
        let trimmed = currentField.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count >= 2 {
            let startIndex = trimmed.index(after: trimmed.startIndex)
            let endIndex = trimmed.index(before: trimmed.endIndex)
            result.append(String(trimmed[startIndex..<endIndex]))
        } else {
            result.append(trimmed)
        }
        
        return result
    }
    
    /// 推断列类型
    private func inferColumnTypes(columnNames: [String], rows: [[String]]) -> [Column] {
        var columns: [Column] = []
        let typeInferrer = TypeInferrer()
        
        for (index, name) in columnNames.enumerated() {
            let columnValues = rows.compactMap { $0.indices.contains(index) ? $0[index] : nil }
            let type = typeInferrer.inferType(from: columnValues)
            columns.append(Column(name: name, type: type))
        }
        
        return columns
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
