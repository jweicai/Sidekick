//
//  MarkdownLoader.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import Foundation
import UniformTypeIdentifiers

/// Markdown 表格加载器
/// 支持标准 Markdown 表格格式
class MarkdownLoader: FileLoaderProtocol {
    
    // MARK: - FileLoaderProtocol
    
    var name: String { "Markdown Table Loader" }
    var version: String { "1.0.0" }
    var supportedTypes: [UTType] { [.plainText] }
    var supportedExtensions: [String] { ["md", "markdown"] }
    
    // MARK: - Public Methods
    
    func load(from url: URL) throws -> DataFrame {
        // 读取文件内容
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw MarkdownLoaderError.readFailed("无法读取文件")
        }
        
        // 解析 Markdown 表格
        let tables = parseMarkdownTables(content)
        
        guard let firstTable = tables.first else {
            throw MarkdownLoaderError.noTableFound
        }
        
        return firstTable
    }
    
    // MARK: - Private Methods
    
    /// 解析 Markdown 表格
    private func parseMarkdownTables(_ content: String) -> [DataFrame] {
        var tables: [DataFrame] = []
        let lines = content.components(separatedBy: .newlines)
        
        var i = 0
        while i < lines.count {
            // 查找表格开始（包含 | 的行）
            if lines[i].contains("|") {
                if let table = parseTable(from: lines, startIndex: &i) {
                    tables.append(table)
                }
            }
            i += 1
        }
        
        return tables
    }
    
    /// 解析单个表格
    private func parseTable(from lines: [String], startIndex: inout Int) -> DataFrame? {
        var tableLines: [String] = []
        var i = startIndex
        
        // 收集连续的表格行
        while i < lines.count && lines[i].contains("|") {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if !line.isEmpty {
                tableLines.append(line)
            }
            i += 1
        }
        
        startIndex = i - 1
        
        guard tableLines.count >= 2 else { return nil }
        
        // 第一行是表头
        let headerLine = tableLines[0]
        let headers = parseRow(headerLine)
        
        // 第二行是分隔符（跳过）
        let separatorLine = tableLines[1]
        if !isSeparatorLine(separatorLine) {
            return nil
        }
        
        // 剩余行是数据
        var rows: [[String]] = []
        for i in 2..<tableLines.count {
            let row = parseRow(tableLines[i])
            // 确保列数匹配
            if row.count == headers.count {
                rows.append(row)
            }
        }
        
        // 创建列定义
        let columns = headers.map { Column(name: $0, type: .text) }
        
        return DataFrame(columns: columns, rows: rows)
    }
    
    /// 解析表格行
    private func parseRow(_ line: String) -> [String] {
        // 移除首尾的 |
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") {
            trimmed.removeFirst()
        }
        if trimmed.hasSuffix("|") {
            trimmed.removeLast()
        }
        
        // 分割单元格
        let cells = trimmed.components(separatedBy: "|")
        return cells.map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    /// 检查是否为分隔符行
    private func isSeparatorLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // 分隔符行应该只包含 |, -, : 和空格
        let allowedChars = CharacterSet(charactersIn: "|-: ")
        return trimmed.unicodeScalars.allSatisfy { allowedChars.contains($0) }
    }
}

// MARK: - Markdown Loader Errors

enum MarkdownLoaderError: Error, LocalizedError {
    case readFailed(String)
    case noTableFound
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .readFailed(let message):
            return "读取 Markdown 文件失败：\(message)"
        case .noTableFound:
            return "未找到有效的 Markdown 表格"
        case .invalidFormat:
            return "Markdown 表格格式无效"
        }
    }
}
