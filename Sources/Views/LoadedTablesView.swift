//
//  LoadedTablesView.swift
//  Sidekick
//
//  Created on 2025-01-13.
//

import SwiftUI

/// 已加载表列表视图 - 浅色风格
struct LoadedTablesView: View {
    @ObservedObject var viewModel: MainViewModel
    let onTableRemoved: (String) -> Void
    let onAddFile: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("数据表")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                // 按钮组
                HStack(spacing: 4) {
                    // 从剪贴板导入按钮
                    Button(action: { viewModel.loadFromClipboard() }) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(DesignSystem.Colors.sidebarHover)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("从剪贴板导入 (⌘+V)")
                    
                    // 添加文件按钮
                    Button(action: onAddFile) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(DesignSystem.Colors.sidebarHover)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("添加数据文件 (⌘+N)")
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)
            
            Divider()
            
            // Table list
            if viewModel.loadedTables.isEmpty {
                EmptyTablesView(onAddFile: onAddFile)
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
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
            }
        }
        .background(DesignSystem.Colors.sidebarBackground)
    }
}

/// 空表列表视图
struct EmptyTablesView: View {
    let onAddFile: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(DesignSystem.Colors.textMuted)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("暂无数据表")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("拖放文件或点击添加")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textMuted)
            }
            
            Button(action: onAddFile) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                    Text("添加文件")
                        .font(DesignSystem.Typography.captionMedium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, 6)
                .background(DesignSystem.Colors.accent)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
    }
}

/// 表行视图 - 浅色风格
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
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showDetails.toggle() } }) {
                    Image(systemName: showDetails ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textMuted)
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                
                // 表图标
                Image(systemName: "tablecells")
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
                
                // 表信息
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(table.name)
                            .font(DesignSystem.Typography.body)
                            .fontWeight(isSelected ? .medium : .regular)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                        
                        // 截断提示标记
                        if table.isTruncated {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(DesignSystem.Colors.warning)
                                .help("数据已截断：仅显示前 \(table.rowCount) 行，共 \(table.originalRowCount ?? 0) 行")
                        }
                    }
                    
                    Text("\(table.displayName) · \(table.rowCountDisplay) × \(table.columnCount)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textMuted)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 悬停时显示操作按钮
                if isHovering {
                    HStack(spacing: 4) {
                        // 导出菜单
                        Menu {
                            Button("导出为 CSV") {
                                exportTable(format: .csv)
                            }
                            Button("导出为 JSON") {
                                exportTable(format: .json)
                            }
                            Button("生成 INSERT 语句") {
                                exportTable(format: .sql)
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textMuted)
                                .frame(width: 18, height: 18)
                                .background(DesignSystem.Colors.sidebarHover)
                                .cornerRadius(4)
                        }
                        .menuStyle(.borderlessButton)
                        .help("导出表")
                        
                        // 删除按钮
                        Button(action: onRemove) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textMuted)
                                .frame(width: 18, height: 18)
                                .background(DesignSystem.Colors.sidebarHover)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .help("移除表")
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(isSelected ? DesignSystem.Colors.accent.opacity(0.1) : 
                          (isHovering ? DesignSystem.Colors.sidebarHover : Color.clear))
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
                    .padding(.leading, 28)
                    .padding(.trailing, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.xs)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
    }
    
    // MARK: - Export Functions
    
    private enum ExportFormat {
        case csv, json, sql
    }
    
    private func exportTable(format: ExportFormat) {
        let converter = DataConverter()
        
        do {
            let data: Data
            let defaultName: String
            let fileType: String
            
            switch format {
            case .csv:
                data = try converter.convertToCSV(dataFrame: table.dataFrame)
                defaultName = "\(table.displayName).csv"
                fileType = "csv"
                
            case .json:
                data = try converter.convertToJSON(dataFrame: table.dataFrame)
                defaultName = "\(table.displayName).json"
                fileType = "json"
                
            case .sql:
                let sql = converter.generateInsertStatements(dataFrame: table.dataFrame, tableName: table.name)
                guard let sqlData = sql.data(using: .utf8) else { return }
                data = sqlData
                defaultName = "\(table.displayName)_insert.sql"
                fileType = "sql"
            }
            
            saveFile(data: data, defaultName: defaultName, fileType: fileType)
        } catch {
            print("导出失败: \(error.localizedDescription)")
        }
    }
    
    private func saveFile(data: Data, defaultName: String, fileType: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = [.init(filenameExtension: fileType)!]
        
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
}

/// 列详情视图 - 浅色风格
struct ColumnDetailsView: View {
    let columns: [Column]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                HStack(spacing: 8) {
                    Text(column.name)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(column.type.sqlType)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(typeColor(for: column.type))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor(for: column.type).opacity(0.1))
                        .cornerRadius(3)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.sidebarHover)
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
    
    private func typeColor(for type: ColumnType) -> Color {
        switch type {
        case .integer: return DesignSystem.Colors.typeInteger
        case .real: return DesignSystem.Colors.typeReal
        case .text: return DesignSystem.Colors.typeText
        case .boolean: return DesignSystem.Colors.typeBoolean
        case .date: return DesignSystem.Colors.typeDate
        case .null: return DesignSystem.Colors.typeNull
        }
    }
}

#Preview {
    LoadedTablesView(viewModel: MainViewModel(), onTableRemoved: { _ in }, onAddFile: {})
        .frame(width: 240, height: 500)
}
