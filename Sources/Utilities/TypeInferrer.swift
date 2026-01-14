//
//  TypeInferrer.swift
//  Sidekick
//
//  Created on 2025-01-13.
//

import Foundation

/// 类型推断工具类
/// 用于从字符串值推断数据类型
class TypeInferrer {
    
    /// 推断单列的数据类型
    func inferType(from values: [String]) -> ColumnType {
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
