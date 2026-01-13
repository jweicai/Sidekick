//
//  JSONLoader.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import Foundation
import UniformTypeIdentifiers

/// JSON 文件加载器
/// 示例插件：展示如何扩展新的文件格式支持
class JSONLoader: FileLoaderProtocol {
    
    // MARK: - FileLoaderProtocol
    
    var name: String { "JSON Loader" }
    var version: String { "1.0.0" }
    var supportedTypes: [UTType] { [.json] }
    var supportedExtensions: [String] { ["json", "jsonl"] }
    
    // MARK: - Public Methods
    
    /// 从 URL 加载 JSON 文件
    func load(from url: URL) throws -> DataFrame {
        let data = try Data(contentsOf: url)
        
        // 尝试解析为 JSON 数组
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return try parseJSONArray(jsonArray)
        }
        
        // 尝试解析为 JSONL (每行一个 JSON 对象)
        let content = try String(contentsOf: url, encoding: .utf8)
        return try parseJSONLines(content)
    }
    
    // MARK: - Private Methods
    
    /// 解析 JSON 数组
    private func parseJSONArray(_ jsonArray: [[String: Any]]) throws -> DataFrame {
        guard !jsonArray.isEmpty else {
            throw JSONLoaderError.emptyFile
        }
        
        // 提取列名
        let columnNames = Array(jsonArray[0].keys).sorted()
        
        // 提取数据行
        let rows = jsonArray.map { dict in
            columnNames.map { key in
                if let value = dict[key] {
                    return String(describing: value)
                } else {
                    return ""
                }
            }
        }
        
        return DataFrame(columnNames: columnNames, rows: rows)
    }
    
    /// 解析 JSONL 格式
    private func parseJSONLines(_ content: String) throws -> DataFrame {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !lines.isEmpty else {
            throw JSONLoaderError.emptyFile
        }
        
        var jsonArray: [[String: Any]] = []
        
        for line in lines {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }
            jsonArray.append(json)
        }
        
        return try parseJSONArray(jsonArray)
    }
}

/// JSON 加载器错误
enum JSONLoaderError: Error, LocalizedError {
    case emptyFile
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "JSON 文件为空"
        case .invalidFormat:
            return "JSON 格式无效"
        }
    }
}
