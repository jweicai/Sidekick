//
//  ClipboardLoader.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import Foundation
import AppKit

/// 剪贴板数据加载器 - 支持 Tab 分隔的表格数据
struct ClipboardLoader {
    
    /// 从剪贴板加载数据
    static func loadFromClipboard() throws -> DataFrame {
        let pasteboard = NSPasteboard.general
        
        guard let string = pasteboard.string(forType: .string), !string.isEmpty else {
            throw ClipboardLoaderError.emptyClipboard
        }
        
        return try parseTabDelimitedData(string)
    }
    
    /// 解析 Tab 分隔的数据
    private static func parseTabDelimitedData(_ data: String) throws -> DataFrame {
        let lines = data.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw ClipboardLoaderError.noData
        }
        
        // 解析所有行
        var rows: [[String]] = []
        for line in lines {
            let cells = line.components(separatedBy: "\t")
            rows.append(cells)
        }
        
        guard !rows.isEmpty else {
            throw ClipboardLoaderError.noData
        }
        
        // 确定列数（使用第一行的列数）
        let columnCount = rows[0].count
        
        // 检查所有行是否有相同的列数，如果不同则填充空值
        for i in 0..<rows.count {
            if rows[i].count < columnCount {
                // 填充空值
                rows[i].append(contentsOf: Array(repeating: "", count: columnCount - rows[i].count))
            } else if rows[i].count > columnCount {
                // 截断多余的列
                rows[i] = Array(rows[i].prefix(columnCount))
            }
        }
        
        // 生成列名
        let columnNames = (0..<columnCount).map { "column_\($0 + 1)" }
        
        // 推断列类型
        // 转置数据以便按列推断类型
        var columnData: [[String]] = Array(repeating: [], count: columnCount)
        for row in rows {
            for (colIndex, value) in row.enumerated() {
                columnData[colIndex].append(value)
            }
        }
        
        // 创建列定义
        let typeInferrer = TypeInferrer()
        var columns: [Column] = []
        for (index, values) in columnData.enumerated() {
            let inferredType = typeInferrer.inferType(from: values)
            let column = Column(name: columnNames[index], type: inferredType)
            columns.append(column)
        }
        
        return DataFrame(columns: columns, rows: rows)
    }
}

enum ClipboardLoaderError: Error, LocalizedError {
    case emptyClipboard
    case noData
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .emptyClipboard:
            return "剪贴板为空"
        case .noData:
            return "剪贴板中没有有效数据"
        case .invalidFormat:
            return "剪贴板数据格式无效"
        }
    }
}
