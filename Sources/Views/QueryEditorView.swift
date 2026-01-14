//
//  QueryEditorView.swift
//  Sidekick
//
//  Created on 2025-01-13.
//

import SwiftUI

/// SQL 查询编辑器视图 - 现代风格
struct QueryEditorView: View {
    @ObservedObject var viewModel: QueryViewModel
    @State private var editorHeight: CGFloat = 160
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // SQL 编辑区域
                VStack(alignment: .leading, spacing: 0) {
                    // 工具栏
                    HStack(spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            Text("SQL 查询")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        
                        Spacer()
                        
                        // 工具按钮
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            // 格式化按钮
                            ToolbarButton(icon: "wand.and.stars", tooltip: "格式化 SQL (⌘+Shift+F)") {
                                viewModel.formatSQL()
                            }
                            
                            // 保存查询按钮
                            ToolbarButton(icon: "square.and.arrow.down", tooltip: "保存查询") {
                                // TODO: Save query
                            }
                            
                            Divider()
                                .frame(height: 16)
                            
                            // 执行按钮
                            Button(action: { viewModel.executeQuery() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 10))
                                    Text("执行")
                                        .font(DesignSystem.Typography.captionMedium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        colors: [DesignSystem.Colors.success, DesignSystem.Colors.success.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isExecuting)
                            .keyboardShortcut(.return, modifiers: .command)
                            .help(viewModel.selectedSQLText.isEmpty ? "执行 SQL 查询 (⌘+Enter)" : "执行选中的 SQL 查询 (⌘+Enter)")
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.background)
                    
                    Divider()
                    
                    // SQL 编辑器
                    SQLTextEditor(text: $viewModel.sqlQuery, selectedText: $viewModel.selectedSQLText)
                        .frame(height: editorHeight)
                }
                
                // 只在有结果、错误或正在执行时显示分隔条和结果区域
                if viewModel.isExecuting || viewModel.errorMessage != nil || viewModel.queryResult != nil {
                    // 可拖动的分隔条
                    DraggableDivider(isDragging: $isDragging)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    let newHeight = editorHeight + value.translation.height
                                    // 限制编辑器高度在 100 到 geometry.size.height - 200 之间
                                    editorHeight = min(max(newHeight, 100), geometry.size.height - 200)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                    
                    // 结果区域
                    if viewModel.isExecuting {
                        LoadingResultsView()
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorResultView(message: errorMessage)
                    } else if let result = viewModel.queryResult {
                        QueryResultView(result: result, viewModel: viewModel)
                    }
                }
            }
            .background(DesignSystem.Colors.background)
        }
        .onAppear {
            // 注册格式化快捷键
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // ⌘+Shift+F
                if event.modifierFlags.contains([.command, .shift]) && event.charactersIgnoringModifiers == "f" {
                    viewModel.formatSQL()
                    return nil
                }
                return event
            }
        }
    }
}

/// 可拖动的分隔条
struct DraggableDivider: View {
    @Binding var isDragging: Bool
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isDragging ? DesignSystem.Colors.accent : (isHovering ? DesignSystem.Colors.border : DesignSystem.Colors.borderLight))
                .frame(height: isDragging ? 3 : 1)
            
            // 拖动手柄区域（增加可点击区域）
            Rectangle()
                .fill(Color.clear)
                .frame(height: 8)
                .contentShape(Rectangle())
        }
        .frame(height: 8)
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

/// 工具栏按钮
struct ToolbarButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(isHovering ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
                .frame(width: 28, height: 28)
                .background(isHovering ? DesignSystem.Colors.accent.opacity(0.1) : Color.clear)
                .cornerRadius(DesignSystem.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

/// 加载结果视图
struct LoadingResultsView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(DesignSystem.Colors.accent)
            
            Text("正在执行查询...")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

/// 错误结果视图
struct ErrorResultView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.warning.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundColor(DesignSystem.Colors.warning)
            }
            
            Text("查询错误")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.semibold)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

/// 空结果视图
struct EmptyResultView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.accent.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 28))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            
            Text("准备就绪")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.semibold)
            
            Text("输入 SQL 查询并点击执行")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

/// 查询结果视图
struct QueryResultView: View {
    let result: QueryResult
    @ObservedObject var viewModel: QueryViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 结果信息栏
            HStack {
                HStack(spacing: DesignSystem.Spacing.md) {
                    // 行数
                    HStack(spacing: 4) {
                        Image(systemName: "list.number")
                            .font(.system(size: 11))
                        Text("\(result.rowCount) 行")
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    // 执行时间
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(String(format: "%.3f 秒", result.executionTime))
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // 导出按钮
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ExportButton(title: "CSV", icon: "doc.text", color: DesignSystem.Colors.success) {
                        exportCSV()
                    }
                    
                    ExportButton(title: "JSON", icon: "curlybraces", color: DesignSystem.Colors.warning) {
                        exportJSON()
                    }
                    
                    ExportButton(title: "INSERT", icon: "text.insert", color: DesignSystem.Colors.info) {
                        generateInsert()
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.tableHeader)
            
            Divider()
            
            // 使用 List 实现固定表头的表格
            ResultTableView(result: result)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func exportCSV() {
        guard let data = viewModel.exportToCSV() else { return }
        saveFile(data: data, defaultName: "query_result.csv", fileType: "csv")
    }
    
    private func exportJSON() {
        guard let data = viewModel.exportToJSON() else { return }
        saveFile(data: data, defaultName: "query_result.json", fileType: "json")
    }
    
    private func generateInsert() {
        guard let sql = viewModel.generateInsertStatements(tableName: "table_name") else { return }
        guard let data = sql.data(using: .utf8) else { return }
        saveFile(data: data, defaultName: "insert_statements.sql", fileType: "sql")
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

/// 导出按钮
struct ExportButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(DesignSystem.Typography.captionMedium)
            }
            .foregroundColor(isHovering ? .white : color)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, 5)
            .background(isHovering ? color : color.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

/// 结果表头单元格
struct ResultHeaderCell: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .frame(minWidth: 100, maxWidth: 200, alignment: .leading)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.tableHeader)
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(DesignSystem.Colors.border),
                alignment: .trailing
            )
    }
}

/// 结果数据单元格
struct ResultDataCell: View {
    let text: String
    let isEvenRow: Bool
    
    @State private var isHovering = false
    
    var isNull: Bool {
        text.isEmpty
    }
    
    // 检测数据类型
    var cellType: CellType {
        if isNull { return .null }
        if isNumeric(text) { return .numeric }
        if isDate(text) { return .date }
        return .text
    }
    
    // 根据类型确定对齐方式
    var alignment: Alignment {
        switch cellType {
        case .numeric:
            return .trailing
        case .date, .text, .null:
            return .leading
        }
    }
    
    // 格式化显示文本
    var displayText: String {
        if isNull { return "NULL" }
        if cellType == .date {
            return formatDate(text)
        }
        return text
    }
    
    var body: some View {
        Text(displayText)
            .font(DesignSystem.Typography.code)
            .italic(isNull)
            .foregroundColor(isNull ? DesignSystem.Colors.textMuted : DesignSystem.Colors.textPrimary)
            .frame(minWidth: 100, maxWidth: 200, alignment: alignment)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, 6)
            .background(
                isHovering ? DesignSystem.Colors.tableRowHover :
                (isEvenRow ? DesignSystem.Colors.tableRowEven : DesignSystem.Colors.tableRowOdd)
            )
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(DesignSystem.Colors.borderLight),
                alignment: .trailing
            )
            .onHover { hovering in
                isHovering = hovering
            }
    }
    
    // 检测是否为数值
    private func isNumeric(_ string: String) -> Bool {
        return Double(string) != nil
    }
    
    // 检测是否为日期格式
    private func isDate(_ string: String) -> Bool {
        // 匹配常见日期格式：YYYY-MM-DD, YYYY/MM/DD, YYYY-M-D 等
        let datePatterns = [
            "^\\d{4}-\\d{1,2}-\\d{1,2}",  // 2025-1-2 或 2025-01-02
            "^\\d{4}/\\d{1,2}/\\d{1,2}",  // 2025/1/2 或 2025/01/02
            "^\\d{4}年\\d{1,2}月\\d{1,2}日" // 2025年1月2日
        ]
        
        for pattern in datePatterns {
            if string.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }
    
    // 格式化日期为 YYYY-MM-DD
    private func formatDate(_ string: String) -> String {
        // 尝试解析各种日期格式
        let dateFormatters = [
            "yyyy-M-d",
            "yyyy-MM-dd",
            "yyyy/M/d",
            "yyyy/MM/dd",
            "yyyy年M月d日"
        ]
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd"
        
        for format in dateFormatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return outputFormatter.string(from: date)
            }
        }
        
        // 如果无法解析，返回原始字符串
        return string
    }
}

/// 单元格类型
enum CellType {
    case text
    case numeric
    case date
    case null
}

/// 结果表格视图 - 使用 ScrollView 实现固定表头
struct ResultTableView: View {
    let result: QueryResult
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section(header: 
                        HStack(spacing: 0) {
                            // 行号列头
                            ResultLineNumberHeaderCell()
                            
                            // 数据列头
                            ForEach(Array(result.columns.enumerated()), id: \.offset) { index, column in
                                ResultHeaderCell(text: column)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ) {
                        ForEach(0..<result.rowCount, id: \.self) { rowIndex in
                            HStack(spacing: 0) {
                                // 行号列
                                ResultLineNumberCell(lineNumber: rowIndex + 1, isEvenRow: rowIndex % 2 == 0)
                                
                                // 数据列
                                ForEach(0..<result.columns.count, id: \.self) { colIndex in
                                    ResultDataCell(
                                        text: result.rows[rowIndex][colIndex],
                                        isEvenRow: rowIndex % 2 == 0
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .topLeading)
            }
            .background(Color.white)
        }
    }
}

/// 行号列头单元格
struct ResultLineNumberHeaderCell: View {
    var body: some View {
        Text("")
            .font(.system(size: 11, weight: .semibold))
            .frame(width: 50, alignment: .center)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.tableHeader)
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(DesignSystem.Colors.border),
                alignment: .trailing
            )
    }
}

/// 行号单元格
struct ResultLineNumberCell: View {
    let lineNumber: Int
    let isEvenRow: Bool
    
    var body: some View {
        Text("\(lineNumber)")
            .font(.system(size: 11, weight: .regular, design: .monospaced))
            .foregroundColor(DesignSystem.Colors.textMuted)
            .frame(width: 50, alignment: .center)
            .padding(.vertical, 6)
            .background(isEvenRow ? DesignSystem.Colors.tableRowEven : DesignSystem.Colors.tableRowOdd)
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(DesignSystem.Colors.borderLight),
                alignment: .trailing
            )
    }
}

#Preview {
    QueryEditorView(viewModel: QueryViewModel())
        .frame(width: 800, height: 600)
}
