//
//  TranslateView.swift
//  Sidekick
//
//  Created on 2025-01-22.
//

import SwiftUI

// MARK: - 翻译视图

struct TranslateView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isTranslating: Bool = false
    @State private var errorMessage: String?
    @State private var sourceLanguage: String = "auto"
    @State private var targetLanguage: String = "zh"
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("翻译")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("文本翻译工具")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            // 主内容区域
            VStack(spacing: 0) {
                // 语言选择栏
                HStack(spacing: DesignSystem.Spacing.md) {
                    // 源语言
                    VStack(alignment: .leading, spacing: 4) {
                        Text("源语言")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Picker("源语言", selection: $sourceLanguage) {
                            Text("自动检测").tag("auto")
                            Text("中文").tag("zh")
                            Text("英文").tag("en")
                            Text("日文").tag("ja")
                            Text("韩文").tag("ko")
                            Text("法文").tag("fr")
                            Text("德文").tag("de")
                            Text("西班牙文").tag("es")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    
                    // 交换按钮
                    Button(action: swapLanguages) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(sourceLanguage == "auto")
                    
                    // 目标语言
                    VStack(alignment: .leading, spacing: 4) {
                        Text("目标语言")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Picker("目标语言", selection: $targetLanguage) {
                            Text("中文").tag("zh")
                            Text("英文").tag("en")
                            Text("日文").tag("ja")
                            Text("韩文").tag("ko")
                            Text("法文").tag("fr")
                            Text("德文").tag("de")
                            Text("西班牙文").tag("es")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.tableHeader)
                
                Divider()
                
                // 输入区域
                VStack(spacing: 0) {
                    HStack {
                        Text("输入文本")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(inputText.count) 字符")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textMuted)
                        
                        Button(action: pasteText) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        .buttonStyle(.plain)
                        .help("粘贴")
                        
                        Button(action: clearInput) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .help("清空")
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tableHeader)
                    
                    TextEditor(text: $inputText)
                        .font(.system(size: 13))
                        .frame(height: 150)
                        .padding(DesignSystem.Spacing.sm)
                        .onChange(of: inputText) {
                            // 清除之前的错误信息
                            errorMessage = nil
                        }
                }
                
                Divider()
                
                // 翻译结果区域
                VStack(spacing: 0) {
                    HStack {
                        Text("翻译结果")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        if !outputText.isEmpty {
                            Button(action: copyResult) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 10))
                                    Text("复制")
                                        .font(DesignSystem.Typography.caption)
                                }
                                .foregroundColor(DesignSystem.Colors.success)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(DesignSystem.Colors.success.opacity(0.1))
                                .cornerRadius(DesignSystem.CornerRadius.small)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tableHeader)
                    
                    ScrollView {
                        if isTranslating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("翻译中...")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Spacer()
                            }
                            .padding(DesignSystem.Spacing.md)
                        } else {
                            Text(outputText.isEmpty ? "输入文本后点击翻译" : outputText)
                                .font(.system(size: 13))
                                .foregroundColor(outputText.isEmpty ? DesignSystem.Colors.textMuted : DesignSystem.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(DesignSystem.Spacing.sm)
                                .textSelection(.enabled)
                        }
                    }
                    .frame(height: 150)
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
                // 系统要求提示
                if #unavailable(macOS 15.0) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(DesignSystem.Colors.warning)
                        
                        Text("需要 macOS 15.0+ 支持系统翻译")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.warning)
                    }
                }
                
                Spacer()
                
                Button(action: clearAll) {
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
                
                Button(action: translate) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                        Text("翻译")
                            .font(DesignSystem.Typography.captionMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.accent)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTranslating)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
        }
    }
    
    private func translate() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isTranslating = true
        errorMessage = nil
        outputText = ""
        
        // 检查系统版本
        if #available(macOS 15.0, *) {
            // 使用系统翻译 API
            translateWithSystemAPI()
        } else {
            // 降级方案：显示提示信息
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isTranslating = false
                errorMessage = "此功能需要 macOS 15.0 或更高版本。请升级系统后使用。"
            }
        }
    }
    
    @available(macOS 15.0, *)
    private func translateWithSystemAPI() {
        // 这里将来可以集成系统翻译 API
        // 目前先用模拟实现
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isTranslating = false
            
            // 简单的模拟翻译（实际应该调用系统 API）
            if sourceLanguage == "en" && targetLanguage == "zh" {
                outputText = "这是一个模拟翻译结果。实际功能需要集成系统翻译 API。"
            } else if sourceLanguage == "zh" && targetLanguage == "en" {
                outputText = "This is a simulated translation result. The actual feature requires integration with system translation API."
            } else {
                outputText = "模拟翻译结果：\(inputText)"
            }
        }
    }
    
    private func swapLanguages() {
        guard sourceLanguage != "auto" else { return }
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
    }
    
    private func pasteText() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            inputText = string
            errorMessage = nil
        }
    }
    
    private func clearInput() {
        inputText = ""
        errorMessage = nil
    }
    
    private func copyResult() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(outputText, forType: .string)
    }
    
    private func clearAll() {
        inputText = ""
        outputText = ""
        errorMessage = nil
    }
}

#Preview {
    TranslateView()
}