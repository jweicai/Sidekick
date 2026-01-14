//
//  ToolViews.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import SwiftUI

// MARK: - 通用工具视图组件

/// 工具输入输出视图
struct ToolIOView: View {
    let title: String
    let description: String
    @Binding var input: String
    @Binding var output: String
    @Binding var errorMessage: String?
    let onProcess: () -> Void
    let onClear: () -> Void
    let additionalButtons: [ToolButton]
    
    init(
        title: String,
        description: String,
        input: Binding<String>,
        output: Binding<String>,
        errorMessage: Binding<String?>,
        onProcess: @escaping () -> Void,
        onClear: @escaping () -> Void,
        additionalButtons: [ToolButton] = []
    ) {
        self.title = title
        self.description = description
        self._input = input
        self._output = output
        self._errorMessage = errorMessage
        self.onProcess = onProcess
        self.onClear = onClear
        self.additionalButtons = additionalButtons
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            // 主内容区域 - 垂直布局
            VStack(spacing: 0) {
                // 输入区域
                VStack(spacing: 0) {
                    HStack {
                        Text("输入")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(input.count) 字符")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textMuted)
                        
                        Button(action: pasteFromClipboard) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        .buttonStyle(.plain)
                        .help("从剪贴板粘贴")
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tableHeader)
                    
                    TextEditor(text: $input)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .padding(DesignSystem.Spacing.sm)
                }
                .frame(maxHeight: .infinity)
                
                Divider()
                
                // 输出区域 - 紧凑显示
                if !output.isEmpty {
                    VStack(spacing: 0) {
                        HStack {
                            Text("输出")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(output.count) 字符")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textMuted)
                            
                            Button(action: copyToClipboard) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                    .foregroundColor(DesignSystem.Colors.success)
                            }
                            .buttonStyle(.plain)
                            .help("复制到剪贴板")
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.tableHeader)
                        
                        ScrollView {
                            Text(output)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(DesignSystem.Spacing.md)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 200)
                        .background(DesignSystem.Colors.success.opacity(0.05))
                    }
                }
            }
            
            Divider()
            
            // 错误信息
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.error)
                    
                    Text(error)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.error.opacity(0.1))
            }
            
            // 操作按钮栏
            HStack(spacing: DesignSystem.Spacing.sm) {
                // 附加按钮
                ForEach(additionalButtons) { button in
                    Button(action: button.action) {
                        HStack(spacing: 4) {
                            Image(systemName: button.icon)
                                .font(.system(size: 11))
                            Text(button.title)
                                .font(DesignSystem.Typography.caption)
                        }
                        .foregroundColor(button.color)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, 8)
                        .background(button.color.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // 清空按钮
                Button(action: onClear) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("清空")
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.sidebarHover)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .buttonStyle(.plain)
                
                // 处理按钮
                Button(action: onProcess) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text("转换")
                            .font(DesignSystem.Typography.captionMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.accent)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .buttonStyle(.plain)
                .disabled(input.isEmpty)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
        }
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            input = string
            errorMessage = nil
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
}

/// 工具按钮配置
struct ToolButton: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}
