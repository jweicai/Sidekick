//
//  JSONFlattener.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import Foundation

/// JSON 扁平化工具
struct JSONFlattener {
    /// 将列式 JSON 转换为行式 JSON
    /// 支持两种格式：
    /// 1. 简单列式：{"name":["A","B"]} → [{"name":"A"},{"name":"B"}]
    /// 2. Schema+Values格式：[{"schema":[...],"values":[...]}] → [{"col1":"val1",...}]
    static func flatten(_ jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw JSONFlattenerError.invalidInput
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        
        // 尝试识别格式
        if let array = jsonObject as? [[String: Any]] {
            // 可能是 Schema+Values 格式
            return try flattenSchemaValuesFormat(array)
        } else if let dict = jsonObject as? [String: Any] {
            // 简单列式格式
            return try flattenSimpleColumnFormat(dict)
        } else {
            throw JSONFlattenerError.notColumnFormat
        }
    }
    
    /// 处理简单列式格式：{"name":["A","B"], "age":[1,2]}
    private static func flattenSimpleColumnFormat(_ dict: [String: Any]) throws -> String {
        // 检查是否是列式格式
        var arrays: [[Any]] = []
        var keys: [String] = []
        var maxLength = 0
        
        for (key, value) in dict {
            guard let array = value as? [Any] else {
                throw JSONFlattenerError.notColumnFormat
            }
            keys.append(key)
            arrays.append(array)
            maxLength = max(maxLength, array.count)
        }
        
        // 转换为行式格式
        var result: [[String: Any]] = []
        for i in 0..<maxLength {
            var row: [String: Any] = [:]
            for (index, key) in keys.enumerated() {
                if i < arrays[index].count {
                    row[key] = arrays[index][i]
                } else {
                    row[key] = NSNull()
                }
            }
            result.append(row)
        }
        
        let outputData = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        guard let outputString = String(data: outputData, encoding: .utf8) else {
            throw JSONFlattenerError.conversionFailed
        }
        
        return outputString
    }
    
    /// 处理 Schema+Values 格式：[{"schema":[{"name":"col1"}],"values":[val1,val2]}]
    private static func flattenSchemaValuesFormat(_ array: [[String: Any]]) throws -> String {
        var result: [[String: Any]] = []
        
        for item in array {
            // 检查是否有 schema 和 values 字段
            guard let schema = item["schema"] as? [[String: Any]],
                  let values = item["values"] as? [Any] else {
                throw JSONFlattenerError.notColumnFormat
            }
            
            // 提取列名
            var columnNames: [String] = []
            for schemaItem in schema {
                if let name = schemaItem["name"] as? String {
                    columnNames.append(name)
                }
            }
            
            // 确保列名数量和值数量匹配
            guard columnNames.count == values.count else {
                throw JSONFlattenerError.schemaMismatch
            }
            
            // 创建行对象
            var row: [String: Any] = [:]
            for (index, columnName) in columnNames.enumerated() {
                row[columnName] = values[index]
            }
            
            result.append(row)
        }
        
        let outputData = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        guard let outputString = String(data: outputData, encoding: .utf8) else {
            throw JSONFlattenerError.conversionFailed
        }
        
        return outputString
    }
}

enum JSONFlattenerError: Error, LocalizedError {
    case invalidInput
    case notColumnFormat
    case conversionFailed
    case schemaMismatch
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "无效的 JSON 输入"
        case .notColumnFormat:
            return "输入不是列式 JSON 格式。支持格式：\n1. {\"name\":[\"A\",\"B\"]} \n2. [{\"schema\":[...],\"values\":[...]}]"
        case .conversionFailed:
            return "转换失败"
        case .schemaMismatch:
            return "Schema 和 Values 数量不匹配"
        }
    }
}
