//
//  MainView.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import SwiftUI

/// 主视图
struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @StateObject private var queryViewModel = QueryViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            TopToolbar(
                fileName: viewModel.fileName,
                tableCount: viewModel.loadedTables.count,
                onClear: {
                    viewModel.clearData()
                    queryViewModel.clearAll()
                },
                onAddFile: {
                    openFilePicker()
                }
            )
            
            Divider()
            
            // 主内容区
            if viewModel.hasLoadedTables {
                HSplitView {
                    // 左侧：已加载表列表
                    LoadedTablesView(
                        viewModel: viewModel,
                        onTableRemoved: { tableName in
                            queryViewModel.removeTable(name: tableName)
                        }
                    )
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 350)
                    
                    // 右侧：查询编辑器
                    QueryEditorView(viewModel: queryViewModel)
                }
                .onAppear {
                    loadAllTablesToQueryEngine()
                }
                .onChange(of: viewModel.loadedTables.count) { _ in
                    loadAllTablesToQueryEngine()
                }
            } else {
                // 文件拖放区
                ZStack {
                    if viewModel.isLoading {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorView(message: errorMessage, onRetry: nil)
                    } else {
                        FileDropZone(droppedFileURL: $viewModel.fileURL)
                    }
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        // Keyboard shortcuts
        .keyboardShortcut("n", modifiers: .command) // ⌘+N to add file
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenFile"))) { _ in
            openFilePicker()
        }
    }
    
    private func loadAllTablesToQueryEngine() {
        for table in viewModel.loadedTables {
            queryViewModel.loadTable(name: table.name, dataFrame: table.dataFrame)
        }
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .init(filenameExtension: "csv")!,
            .init(filenameExtension: "json")!
        ]
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                viewModel.loadFile(url: url)
            }
        }
    }
}

/// 顶部工具栏 (macOS 标准样式)
struct TopToolbar: View {
    let fileName: String
    let tableCount: Int
    let onClear: () -> Void
    let onAddFile: () -> Void
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Logo和标题 (左侧)
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "tablecells")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.accent)
                
                Text("TableQuery")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // 操作按钮 (右侧)
            HStack(spacing: DesignSystem.Spacing.sm) {
                // 表计数标签
                if tableCount > 0 {
                    Text("\(tableCount) 个表")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                    
                    // 添加文件按钮
                    Button(action: onAddFile) {
                        Label("添加文件", systemImage: "plus")
                            .font(DesignSystem.Typography.body)
                    }
                    .buttonStyle(.borderless)
                    .help("添加更多数据文件 (⌘+N)")
                    
                    // 清除按钮
                    Button(action: onClear) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("清除所有数据 (⌘+W)")
                }
                
                Divider()
                    .frame(height: 20)
                
                // 设置按钮
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .help("设置")
                .popover(isPresented: $showingSettings) {
                    SettingsView()
                }
                
                // 帮助按钮
                Button(action: { showingHelp = true }) {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.borderless)
                .help("帮助")
                .popover(isPresented: $showingHelp) {
                    HelpView()
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.background)
    }
}

/// 设置视图 (简单版本)
struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("设置")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.semibold)
            
            Divider()
            
            Text("将来版本中提供更多设置选项")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding()
        .frame(width: 300)
    }
}

/// 帮助视图 (简单版本)
struct HelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("快捷键")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.semibold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HelpRow(key: "⌘+N", description: "添加文件")
                HelpRow(key: "⌘+Enter", description: "执行查询")
                HelpRow(key: "⌘+W", description: "清除数据")
            }
            .font(DesignSystem.Typography.body)
        }
        .padding()
        .frame(width: 250)
    }
}

struct HelpRow: View {
    let key: String
    let description: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(DesignSystem.Typography.code)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(description)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

/// 加载视图
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("正在加载...")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

/// 错误视图
struct ErrorView: View {
    let message: String
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("出错了")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("重试")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

#Preview {
    MainView()
}
