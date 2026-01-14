//
//  QueryHistoryView.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import SwiftUI

/// 查询历史视图
struct QueryHistoryView: View {
    @ObservedObject var viewModel: QueryViewModel
    @State private var histories: [QueryHistory] = []
    @State private var showClearConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.accent)
                    
                    Text("查询历史")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("(\(histories.count))")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textMuted)
                }
                
                Spacer()
                
                // 清空按钮
                if !histories.isEmpty {
                    Button(action: { showClearConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                    .buttonStyle(.plain)
                    .help("清空历史")
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            // 历史记录列表
            if histories.isEmpty {
                EmptyHistoryView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(histories) { history in
                            QueryHistoryRow(
                                history: history,
                                onLoad: {
                                    viewModel.loadQueryFromHistory(history)
                                },
                                onDelete: {
                                    viewModel.deleteHistory(id: history.id)
                                    refreshHistories()
                                }
                            )
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
                .background(DesignSystem.Colors.sidebarBackground)
            }
        }
        .frame(width: 280)
        .onAppear {
            refreshHistories()
        }
        .alert("清空历史记录", isPresented: $showClearConfirmation) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                viewModel.clearAllHistories()
                refreshHistories()
            }
        } message: {
            Text("确定要清空所有查询历史吗？此操作无法撤销。")
        }
    }
    
    private func refreshHistories() {
        histories = viewModel.getQueryHistories()
    }
}

/// 查询历史行
struct QueryHistoryRow: View {
    let history: QueryHistory
    let onLoad: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                // 状态图标
                Image(systemName: history.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(history.isSuccess ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                
                // 日期时间
                Text(history.formattedDate)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textMuted)
                
                Spacer()
                
                // 执行时间
                if let _ = history.executionTime {
                    Text(history.formattedExecutionTime)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.textMuted)
                }
                
                // 操作按钮（悬停时显示）
                if isHovering {
                    HStack(spacing: 4) {
                        Button(action: onLoad) {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        .buttonStyle(.plain)
                        .help("加载查询")
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                        .buttonStyle(.plain)
                        .help("删除")
                    }
                }
            }
            
            // 查询预览
            Text(history.preview)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // 结果信息
            if history.isSuccess, let rowCount = history.rowCount {
                Text("\(rowCount) 行")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.textMuted)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(isHovering ? DesignSystem.Colors.sidebarHover : Color.clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onLoad()
        }
    }
}

/// 空历史视图
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(DesignSystem.Colors.textMuted)
            
            Text("暂无历史记录")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("执行查询后会自动保存")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.sidebarBackground)
    }
}

#Preview {
    QueryHistoryView(viewModel: QueryViewModel())
        .frame(width: 280, height: 600)
}
