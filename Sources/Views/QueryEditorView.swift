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
    @State private var editorHeight: CGFloat? = nil
    @State private var isDragging = false
    
    // 计算编辑器应该占用的高度
    private func calculateEditorHeight(geometry: GeometryProxy) -> CGFloat {
        let availableHeight = geometry.size.height - 40 // 减去 Tab 栏高度
        
        // 如果没有结果、错误或正在执行，编辑器占据所有可用空间
        if !viewModel.isExecuting && viewModel.errorMessage == nil && viewModel.queryResults.isEmpty {
            return availableHeight
        }
        
        // 如果用户手动调整过高度，使用用户设置的高度
        if let height = editorHeight {
            return height
        }
        
        // 首次显示结果时，编辑器占 2/3，结果占 1/3
        return availableHeight * 2 / 3
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Console Tab 栏（包含工具按钮）
                ConsoleTabBar(viewModel: viewModel)
                
                // SQL 编辑器
                SQLEditorBinding(viewModel: viewModel)
                    .frame(height: calculateEditorHeight(geometry: geometry))
                
                // 只在有结果、错误或正在执行时显示分隔条和结果区域
                if viewModel.isExecuting || viewModel.errorMessage != nil || !viewModel.queryResults.isEmpty {
                    // 可拖动的分隔条
                    DraggableDivider(isDragging: $isDragging)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    let currentHeight = editorHeight ?? (geometry.size.height - 40) * 2 / 3
                                    let newHeight = currentHeight + value.translation.height
                                    editorHeight = min(max(newHeight, 100), geometry.size.height - 200)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                    
                    // 结果区域（带 Tab）
                    ResultAreaView(viewModel: viewModel)
                }
            }
            .background(DesignSystem.Colors.background)
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains([.command, .shift]) && event.charactersIgnoringModifiers == "f" {
                    viewModel.formatSQL()
                    return nil
                }
                return event
            }
        }
    }
}

/// Console Tab 栏（包含工具按钮）
struct ConsoleTabBar: View {
    @ObservedObject var viewModel: QueryViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            // Console Tabs
            ForEach(viewModel.consoleTabs) { tab in
                ConsoleTabButton(
                    title: tab.displayName,
                    isSelected: viewModel.selectedConsoleId == tab.id,
                    showClose: viewModel.consoleTabs.count > 1,
                    onClose: {
                        viewModel.closeConsole(id: tab.id)
                    }
                ) {
                    viewModel.selectConsole(id: tab.id)
                }
            }
            
            // 添加新 Tab 按钮
            Button(action: { viewModel.addNewConsole() }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("新建 SQL Console")
            
            Spacer()
            
            // 工具按钮（右侧）
            HStack(spacing: DesignSystem.Spacing.sm) {
                // 格式化按钮
                ToolbarButton(icon: "wand.and.stars", tooltip: "格式化 SQL (⌘+Shift+F)") {
                    viewModel.formatSQL()
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
            .padding(.trailing, DesignSystem.Spacing.md)
        }
        .padding(.leading, DesignSystem.Spacing.md)
        .frame(height: 36)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.border)
                .frame(height: 1),
            alignment: .bottom
        )
        .zIndex(1)
    }
}

/// Console Tab 按钮
struct ConsoleTabButton: View {
    let title: String
    let isSelected: Bool
    var showClose: Bool = false
    var onClose: (() -> Void)? = nil
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
                
                // 删除按钮始终显示（当可关闭时）
                if showClose {
                    Button(action: { onClose?() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                VStack(spacing: 0) {
                    Spacer()
                    if isSelected {
                        Rectangle()
                            .fill(DesignSystem.Colors.accent)
                            .frame(height: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// SQL 编辑器绑定包装器
struct SQLEditorBinding: View {
    @ObservedObject var viewModel: QueryViewModel
    
    var body: some View {
        SQLTextEditor(
            text: Binding(
                get: { viewModel.sqlQuery },
                set: { viewModel.sqlQuery = $0 }
            ),
            selectedText: Binding(
                get: { viewModel.selectedSQLText },
                set: { viewModel.selectedSQLText = $0 }
            )
        )
    }
}

/// 结果区域视图（包含 Tab 切换）
struct ResultAreaView: View {
    @ObservedObject var viewModel: QueryViewModel
    @State private var showHistory = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab 栏
            HStack(spacing: 0) {
                // 执行历史 Tab（固定在最左边）
                ResultTabButton(
                    title: "执行历史",
                    isSelected: showHistory,
                    showClose: false
                ) {
                    showHistory = true
                }
                
                // 分隔线
                if !viewModel.queryResults.isEmpty {
                    Rectangle()
                        .fill(DesignSystem.Colors.border)
                        .frame(width: 1, height: 20)
                        .padding(.horizontal, 4)
                }
                
                // 查询结果 Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(viewModel.queryResults) { result in
                            ResultTabButton(
                                title: "执行结果\(result.number)",
                                isSelected: !showHistory && viewModel.selectedResultId == result.id,
                                showClose: true,
                                onClose: {
                                    viewModel.closeResult(id: result.id)
                                }
                            ) {
                                showHistory = false
                                viewModel.selectedResultId = result.id
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 右侧信息/操作（仅在结果 Tab 显示）
                if !showHistory, let result = viewModel.currentResult {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        // 行数
                        HStack(spacing: 4) {
                            Image(systemName: "list.number")
                                .font(.system(size: 11))
                            Text("\(result.result.rowCount) 行")
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        // 执行时间
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(String(format: "%.3f 秒", result.result.executionTime))
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        // 导出按钮
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            ExportButton(title: "CSV", icon: "doc.text", color: DesignSystem.Colors.success) {
                                exportCSV(result: result.result)
                            }
                            
                            ExportButton(title: "JSON", icon: "curlybraces", color: DesignSystem.Colors.warning) {
                                exportJSON(result: result.result)
                            }
                            
                            ExportButton(title: "INSERT", icon: "text.insert", color: DesignSystem.Colors.info) {
                                generateInsert(result: result.result)
                            }
                        }
                    }
                    .padding(.trailing, DesignSystem.Spacing.lg)
                }
            }
            .padding(.leading, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.tableHeader)
            
            Divider()
            
            // 内容区域
            if showHistory {
                // 历史内容
                ExecutionHistoryListView(viewModel: viewModel)
            } else if viewModel.isExecuting {
                LoadingResultsView()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorResultView(message: errorMessage)
            } else if let result = viewModel.currentResult {
                ResultTableView(result: result.result)
            } else {
                // 空状态
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(DesignSystem.Colors.textMuted)
                    Text("执行查询后结果将显示在这里")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func exportCSV(result: QueryResult) {
        let columns = result.columns.map { Column(name: $0, type: .text) }
        let dataFrame = DataFrame(columns: columns, rows: result.rows)
        let converter = DataConverter()
        guard let data = try? converter.convertToCSV(dataFrame: dataFrame) else { return }
        saveFile(data: data, defaultName: "query_result.csv", fileType: "csv")
    }
    
    private func exportJSON(result: QueryResult) {
        let columns = result.columns.map { Column(name: $0, type: .text) }
        let dataFrame = DataFrame(columns: columns, rows: result.rows)
        let converter = DataConverter()
        guard let data = try? converter.convertToJSON(dataFrame: dataFrame) else { return }
        saveFile(data: data, defaultName: "query_result.json", fileType: "json")
    }
    
    private func generateInsert(result: QueryResult) {
        let columns = result.columns.map { Column(name: $0, type: .text) }
        let dataFrame = DataFrame(columns: columns, rows: result.rows)
        let converter = DataConverter()
        let sql = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "table_name")
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

/// 结果区域 Tab 按钮
struct ResultTabButton: View {
    let title: String
    let isSelected: Bool
    var showClose: Bool = false
    var onClose: (() -> Void)? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
                
                if showClose {
                    Button(action: { onClose?() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                VStack(spacing: 0) {
                    Spacer()
                    if isSelected {
                        Rectangle()
                            .fill(DesignSystem.Colors.accent)
                            .frame(height: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

/// 执行历史列表视图（表格样式）
struct ExecutionHistoryListView: View {
    @ObservedObject var viewModel: QueryViewModel
    @State private var histories: [QueryHistory] = []
    
    var body: some View {
        GeometryReader { geometry in
            if histories.isEmpty {
                // 空状态
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(DesignSystem.Colors.textMuted)
                    
                    Text("暂无执行历史")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            } else {
                // 表格 - 使用与 ResultTableView 相同的布局方式
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section(header: historyTableHeader) {
                            ForEach(histories) { history in
                                HistoryTableRow(
                                    history: history,
                                    onLoad: {
                                        viewModel.loadQueryFromHistory(history)
                                    }
                                )
                            }
                        }
                    }
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .topLeading)
                }
                .background(Color.white)
            }
        }
        .onAppear { refreshHistories() }
    }
    
    private var historyTableHeader: some View {
        HStack(spacing: 0) {
            Text("执行时间")
                .frame(width: 150, alignment: .leading)
            Text("SQL")
                .frame(width: 400, alignment: .leading)
            Text("状态")
                .frame(width: 70, alignment: .center)
            Text("行数")
                .frame(width: 80, alignment: .trailing)
            Text("耗时")
                .frame(width: 80, alignment: .trailing)
            Text("操作")
                .frame(width: 60, alignment: .center)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(DesignSystem.Colors.textSecondary)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.tableHeader)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func refreshHistories() {
        histories = viewModel.getQueryHistories()
    }
}

/// 历史记录表格行
struct HistoryTableRow: View {
    let history: QueryHistory
    let onLoad: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 0) {
            // 执行时间
            Text(history.formattedDateFull)
                .frame(width: 150, alignment: .leading)
            
            // SQL（双击加载）
            Text(history.preview)
                .frame(width: 400, alignment: .leading)
                .lineLimit(1)
                .help(history.query)
            
            // 状态
            HStack(spacing: 4) {
                Circle()
                    .fill(history.isSuccess ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                    .frame(width: 8, height: 8)
                Text(history.isSuccess ? "成功" : "失败")
            }
            .frame(width: 70, alignment: .center)
            
            // 行数
            Text(history.rowCount != nil ? "\(history.rowCount!)" : "-")
                .frame(width: 80, alignment: .trailing)
            
            // 耗时
            Text(history.formattedExecutionTimeMs)
                .frame(width: 80, alignment: .trailing)
            
            // 操作
            Button(action: onLoad) {
                Text("加载")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .buttonStyle(.plain)
            .frame(width: 60, alignment: .center)
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundColor(DesignSystem.Colors.textPrimary)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovering ? DesignSystem.Colors.tableRowHover : Color.white)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture(count: 2) {
            onLoad()
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
    var isActive: Bool = false
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor((isHovering || isActive) ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
                .frame(width: 28, height: 28)
                .background((isHovering || isActive) ? DesignSystem.Colors.accent.opacity(0.1) : Color.clear)
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
            .textSelection(.enabled)
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
            .textSelection(.enabled)
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
