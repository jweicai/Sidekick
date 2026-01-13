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
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            TopToolbar(
                fileName: viewModel.fileName,
                onClear: viewModel.clearData
            )
            
            Divider()
            
            // 主内容区
            ZStack {
                if viewModel.isLoading {
                    LoadingView()
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage, onRetry: nil)
                } else if let dataFrame = viewModel.dataFrame {
                    DataTableView(dataFrame: dataFrame)
                } else {
                    FileDropZone(droppedFileURL: $viewModel.fileURL)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

/// 顶部工具栏
struct TopToolbar: View {
    let fileName: String
    let onClear: () -> Void
    
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
            
            // 文件名
            if !fileName.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                    
                    Text(fileName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("清除数据")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
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
