//
//  OtherToolsView.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import SwiftUI

// MARK: - UUID 生成器视图

struct UUIDGeneratorView: View {
    @State private var output: String = ""
    @State private var count: Int = 1
    @State private var uppercase: Bool = true
    @State private var withHyphens: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("UUID 生成器")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("生成通用唯一标识符 (UUID)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            // 配置区域
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // 生成数量
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("生成数量")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack {
                            Stepper(value: $count, in: 1...100) {
                                Text("\(count) 个")
                                    .font(DesignSystem.Typography.body)
                            }
                        }
                    }
                    
                    // 格式选项
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("格式选项")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Toggle("大写字母", isOn: $uppercase)
                            .font(DesignSystem.Typography.body)
                        
                        Toggle("包含连字符", isOn: $withHyphens)
                            .font(DesignSystem.Typography.body)
                    }
                    
                    // 生成按钮
                    Button(action: generateUUID) {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 12))
                            Text("生成 UUID")
                                .font(DesignSystem.Typography.bodyMedium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(DesignSystem.Colors.accent)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                    
                    // 输出结果
                    if !output.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("生成结果")
                                    .font(DesignSystem.Typography.captionMedium)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Spacer()
                                
                                Button(action: copyToClipboard) {
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
                            
                            ScrollView {
                                Text(output)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(DesignSystem.Spacing.md)
                                    .textSelection(.enabled)
                            }
                            .frame(height: 200)
                            .background(DesignSystem.Colors.success.opacity(0.05))
                            .cornerRadius(DesignSystem.CornerRadius.small)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
            
            Spacer()
        }
    }
    
    private func generateUUID() {
        output = OtherTools.generateUUID(count: count, uppercase: uppercase, withHyphens: withHyphens)
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
}

// MARK: - 颜色转换器视图

struct ColorConverterView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("颜色转换")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("HEX ↔ RGB ↔ HSL 互转")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            // 表单区域
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // 输入框
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("颜色值")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            TextField("例如：#FF5733 或 rgb(255,87,51)", text: $input)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                                .padding(DesignSystem.Spacing.sm)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                )
                            
                            Button(action: pasteFromClipboard) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .frame(width: 32, height: 32)
                                    .background(DesignSystem.Colors.accent.opacity(0.1))
                                    .cornerRadius(DesignSystem.CornerRadius.small)
                            }
                            .buttonStyle(.plain)
                            .help("从剪贴板粘贴")
                        }
                    }
                    
                    // 快速选择
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("快速选择")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                            ForEach(presetColors, id: \.self) { color in
                                Button(action: { input = color }) {
                                    Text(color)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(DesignSystem.Colors.sidebarHover)
                                        .cornerRadius(DesignSystem.CornerRadius.small)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 转换按钮
                    Button(action: convertColor) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12))
                            Text("转换")
                                .font(DesignSystem.Typography.bodyMedium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(DesignSystem.Colors.accent)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                    .disabled(input.isEmpty)
                    
                    // 输出结果
                    if !output.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Text("转换结果")
                                    .font(DesignSystem.Typography.captionMedium)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Spacer()
                                
                                Button(action: copyToClipboard) {
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
                            
                            Text(output)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(DesignSystem.Spacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DesignSystem.Colors.success.opacity(0.05))
                                .cornerRadius(DesignSystem.CornerRadius.small)
                                .textSelection(.enabled)
                        }
                    }
                    
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
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.error.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
            
            Spacer()
        }
    }
    
    private let presetColors = [
        "#FF0000", "#00FF00", "#0000FF",
        "#FFFF00", "#FF00FF", "#00FFFF",
        "#000000", "#FFFFFF", "#808080"
    ]
    
    private func convertColor() {
        errorMessage = nil
        output = ""
        
        do {
            output = try OtherTools.convertColor(input)
        } catch {
            errorMessage = error.localizedDescription
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

// MARK: - 正则表达式测试器视图

struct RegexTesterView: View {
    @State private var pattern: String = ""
    @State private var testText: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    @State private var caseInsensitive: Bool = false
    @State private var multiline: Bool = false
    @State private var dotMatchesLineSeparators: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("正则表达式测试")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("测试正则表达式匹配")
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
                // 正则表达式输入
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text("正则表达式")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        // 选项
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Toggle("忽略大小写", isOn: $caseInsensitive)
                                .font(DesignSystem.Typography.caption)
                            Toggle("多行", isOn: $multiline)
                                .font(DesignSystem.Typography.caption)
                            Toggle(". 匹配换行", isOn: $dotMatchesLineSeparators)
                                .font(DesignSystem.Typography.caption)
                        }
                    }
                    
                    TextField("例如：\\d{3}-\\d{4}", text: $pattern)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(DesignSystem.Spacing.sm)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.tableHeader)
                
                Divider()
                
                // 测试文本输入
                VStack(spacing: 0) {
                    HStack {
                        Text("测试文本")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(testText.count) 字符")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textMuted)
                        
                        Button(action: pasteText) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        .buttonStyle(.plain)
                        .help("粘贴")
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tableHeader)
                    
                    TextEditor(text: $testText)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(height: 120)
                        .padding(DesignSystem.Spacing.sm)
                }
                
                Divider()
                
                // 匹配结果
                VStack(spacing: 0) {
                    HStack {
                        Text("匹配结果")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        if !output.isEmpty {
                            Button(action: copyResult) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                    .foregroundColor(DesignSystem.Colors.success)
                            }
                            .buttonStyle(.plain)
                            .help("复制")
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tableHeader)
                    
                    ScrollView {
                        Text(output.isEmpty ? "输入正则表达式和测试文本，然后点击测试" : output)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(output.isEmpty ? DesignSystem.Colors.textMuted : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.Spacing.sm)
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
                
                Button(action: testRegex) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                        Text("测试")
                            .font(DesignSystem.Typography.captionMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.accent)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .buttonStyle(.plain)
                .disabled(pattern.isEmpty || testText.isEmpty)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
        }
    }
    
    private func testRegex() {
        errorMessage = nil
        output = ""
        
        do {
            let options = RegexOptions(
                caseInsensitive: caseInsensitive,
                multiline: multiline,
                dotMatchesLineSeparators: dotMatchesLineSeparators
            )
            output = try OtherTools.testRegex(pattern: pattern, text: testText, options: options)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func pasteText() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            testText = string
            errorMessage = nil
        }
    }
    
    private func copyResult() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
    
    private func clearAll() {
        pattern = ""
        testText = ""
        output = ""
        errorMessage = nil
    }
}
