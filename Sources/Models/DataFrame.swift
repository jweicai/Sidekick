//
//  DataFrame.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import Foundation

/// 数据框架，用于存储表格数据
struct DataFrame {
    let columns: [Column]
    let rows: [[String]]
    
    var rowCount: Int { rows.count }
    var columnCount: Int { columns.count }
    
    init(columns: [Column], rows: [[String]]) {
        self.columns = columns
        self.rows = rows
    }
    
    /// 从列名和数据行创建 DataFrame
    init(columnNames: [String], rows: [[String]]) {
        self.columns = columnNames.map { Column(name: $0, type: .text) }
        self.rows = rows
    }
}

/// 列定义
struct Column {
    let name: String
    let type: ColumnType
}

/// 列数据类型
enum ColumnType {
    case integer
    case real
    case text
    case boolean
    case date
    case null
    
    var sqlType: String {
        switch self {
        case .integer: return "INTEGER"
        case .real: return "REAL"
        case .text: return "TEXT"
        case .boolean: return "INTEGER"
        case .date: return "TEXT"
        case .null: return "TEXT"
        }
    }
}

/// 查询结果
struct QueryResult {
    let columns: [String]
    let rows: [[String]]
    let executionTime: TimeInterval
    let rowCount: Int
    
    init(columns: [String], rows: [[String]], executionTime: TimeInterval) {
        self.columns = columns
        self.rows = rows
        self.executionTime = executionTime
        self.rowCount = rows.count
    }
}
