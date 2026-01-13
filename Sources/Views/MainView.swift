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

/// 顶部工具栏
struct TopToolbar: View {
    let fileName: String
    let tableCount: Int
    let onClear: () -> Void
    let onAddFile: () -> Void
    
    var body: some View {
        HStack {
            // Logo 和标题
            HStack(spacing: 12) {
                Image(systemName: "tablecells")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("TableQuery")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 12) {
                if tableCount > 0 {
                    // 表计数
                    HStack(spacing: 6) {
                        Image(systemName: "tablecells")
                            .foregroundColor(.secondary)
                        
                        Text("\(tableCount) 个表")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    
                    // 添加文件按钮
                    Button(action: onAddFile) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("添加文件")
                        }
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("添加更多数据文件")
                    
                    // 清除按钮
                    Button(action: onClear) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("清除所有数据")
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
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
