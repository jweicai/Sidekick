//
//  LoadedTablesView.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import SwiftUI

/// 已加载表列表视图
struct LoadedTablesView: View {
    @ObservedObject var viewModel: MainViewModel
    let onTableRemoved: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("已加载的表")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(viewModel.loadedTables.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Table list
            if viewModel.loadedTables.isEmpty {
                EmptyTablesView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.loadedTables) { table in
                            TableRowView(
                                table: table,
                                isSelected: viewModel.selectedTableId == table.id,
                                onSelect: { viewModel.selectTable(id: table.id) },
                                onRemove: {
                                    viewModel.removeTable(id: table.id)
                                    onTableRemoved(table.name)
                                }
                            )
                        }
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// 空表列表视图
struct EmptyTablesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tablecells")
                .font(.system(size: 30))
                .foregroundColor(.gray)
            
            Text("暂无数据表")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("拖放 CSV 或 JSON 文件到此处")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// 表行视图
struct TableRowView: View {
    let table: LoadedTable
    let isSelected: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void
    
    @State private var isHovering = false
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                // Table icon
                Image(systemName: "tablecells")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                // Table info
                VStack(alignment: .leading, spacing: 2) {
                    Text(table.name)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(table.rowCount) 行 × \(table.columnCount) 列")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Actions
                if isHovering || isSelected {
                    HStack(spacing: 4) {
                        Button(action: { showDetails.toggle() }) {
                            Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("显示列信息")
                        
                        Button(action: onRemove) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("移除表")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : (isHovering ? Color.gray.opacity(0.05) : Color.clear))
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
            .onHover { hovering in
                isHovering = hovering
            }
            
            // Column details
            if showDetails {
                ColumnDetailsView(columns: table.dataFrame.columns)
                    .padding(.leading, 36)
                    .padding(.trailing, 12)
                    .padding(.bottom, 8)
            }
            
            Divider()
                .padding(.leading, 36)
        }
    }
}

/// 列详情视图
struct ColumnDetailsView: View {
    let columns: [Column]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                HStack(spacing: 8) {
                    Text(column.name)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(column.type.sqlType)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor(for: column.type).opacity(0.1))
                        .cornerRadius(3)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
    
    private func typeColor(for type: ColumnType) -> Color {
        switch type {
        case .integer: return .blue
        case .real: return .green
        case .text: return .orange
        case .boolean: return .purple
        case .date: return .cyan
        case .null: return .gray
        }
    }
}

#Preview {
    LoadedTablesView(viewModel: MainViewModel(), onTableRemoved: { _ in })
        .frame(width: 250, height: 400)
}
