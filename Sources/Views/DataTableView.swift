//
//  DataTableView.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import SwiftUI

/// 数据表格视图
struct DataTableView: View {
    let dataFrame: DataFrame
    let maxDisplayRows: Int = 100
    
    var body: some View {
        VStack(spacing: 0) {
            // 表格信息
            HStack {
                Text("\(dataFrame.rowCount) 行 × \(dataFrame.columnCount) 列")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if dataFrame.rowCount > maxDisplayRows {
                    Text("显示前 \(maxDisplayRows) 行")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 表格内容
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    // 表头
                    HStack(spacing: 0) {
                        ForEach(Array(dataFrame.columns.enumerated()), id: \.offset) { index, column in
                            TableHeaderCell(
                                text: column.name,
                                type: column.type
                            )
                        }
                    }
                    
                    // 数据行
                    ForEach(0..<min(maxDisplayRows, dataFrame.rowCount), id: \.self) { rowIndex in
                        HStack(spacing: 0) {
                            ForEach(0..<dataFrame.columnCount, id: \.self) { colIndex in
                                TableDataCell(
                                    text: dataFrame.rows[rowIndex][colIndex],
                                    isEvenRow: rowIndex % 2 == 0
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/// 表头单元格
struct TableHeaderCell: View {
    let text: String
    let type: ColumnType
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            
            Image(systemName: typeIcon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(width: 150, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(width: 1, height: nil, alignment: .trailing)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .trailing
        )
    }
    
    private var typeIcon: String {
        switch type {
        case .integer: return "number"
        case .real: return "number"
        case .text: return "textformat"
        case .boolean: return "checkmark.circle"
        case .date: return "calendar"
        case .null: return "questionmark"
        }
    }
}

/// 数据单元格
struct TableDataCell: View {
    let text: String
    let isEvenRow: Bool
    
    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.primary)
            .frame(width: 150, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isEvenRow ? Color.clear : Color.gray.opacity(0.03))
            .overlay(
                Rectangle()
                    .frame(width: 1, height: nil, alignment: .trailing)
                    .foregroundColor(Color.gray.opacity(0.1)),
                alignment: .trailing
            )
    }
}

#Preview {
    DataTableView(
        dataFrame: DataFrame(
            columnNames: ["ID", "Name", "Age", "City"],
            rows: [
                ["1", "张三", "25", "北京"],
                ["2", "李四", "30", "上海"],
                ["3", "王五", "28", "深圳"]
            ]
        )
    )
    .frame(width: 800, height: 400)
}
