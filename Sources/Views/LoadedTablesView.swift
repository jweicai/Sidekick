//
//  LoadedTablesView.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import SwiftUI

/// 已加载表列表视图 (macOS Source List 风格)
struct LoadedTablesView: View {
    @ObservedObject var viewModel: MainViewModel
    let onTableRemoved: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("已加载的表")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if !viewModel.loadedTables.isEmpty {
                    Text("\(viewModel.loadedTables.count)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.secondaryBackground)
            
            Divider()
            
            // Table list
            if viewModel.loadedTables.isEmpty {
                EmptyTablesView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
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
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }
            }
        }
        .background(DesignSystem.Colors.background)
    }
}

/// 空表列表视图
struct EmptyTablesView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "tablecells.badge.ellipsis")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("暂无数据表")
                .font(DesignSystem.Typography.body)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("拖放 CSV 或 JSON 文件到窗口")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.lg)
    }
}

/// 表行视图 (Source List Item 风格)
struct TableRowView: View {
    let table: LoadedTable
    let isSelected: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void
    
    @State private var isHovering = false
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主行
            HStack(spacing: DesignSystem.Spacing.sm) {
                // 展开/折叠箭头
                Image(systemName: showDetails ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 12)
                    .onTapGesture { showDetails.toggle() }
                
                // 表图标
                Image(systemName: "tablecells")
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
                
                // 表信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(table.name)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(isSelected ? .medium : .regular)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(table.rowCount) 行 × \(table.columnCount) 列")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // 悬停时显示删除按钮
                if isHovering || isSelected {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .buttonStyle(.borderless)
                    .help("移除表")
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(isSelected ? DesignSystem.Colors.accent.opacity(0.15) : 
                          (isHovering ? DesignSystem.Colors.secondaryBackground : Color.clear))
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: DesignSystem.Animation.fast)) {
                    isHovering = hovering
                }
            }
            
            // 列详情
            if showDetails {
                ColumnDetailsView(columns: table.dataFrame.columns)
                    .padding(.leading, 32)
                    .padding(.trailing, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
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
