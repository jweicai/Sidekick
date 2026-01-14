//
//  TextToolsView.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import SwiftUI
import CryptoKit

// MARK: - Base64 编码/解码视图

struct Base64ToolView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    @State private var mode: Base64Mode = .encode
    
    enum Base64Mode: String, CaseIterable {
        case encode = "编码"
        case decode = "解码"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Base64 编码/解码")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Base64 编码和解码文本")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // 模式切换
                Picker("", selection: $mode) {
                    ForEach(Base64Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            // 主内容区域
            HSplitView {
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(DesignSystem.Spacing.sm)
                }
                
                // 输出区域
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
                        .disabled(output.isEmpty)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tableHeader)
                    
                    TextEditor(text: .constant(output))
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(DesignSystem.Spacing.sm)
                        .disabled(true)
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
                
                Button(action: process) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text(mode == .encode ? "编码" : "解码")
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
    
    private func process() {
        errorMessage = nil
        output = ""
        
        do {
            if mode == .encode {
                output = try TextTools.base64Encode(input)
            } else {
                output = try TextTools.base64Decode(input)
            }
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
    
    private func clearAll() {
        input = ""
        output = ""
        errorMessage = nil
    }
}

// MARK: - URL 编码/解码视图

struct URLEncodeToolView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    @State private var mode: URLMode = .encode
    
    enum URLMode: String, CaseIterable {
        case encode = "编码"
        case decode = "解码"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("URL 编码/解码")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("URL 编码和解码文本")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // 模式切换
                Picker("", selection: $mode) {
                    ForEach(URLMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            // 主内容区域
            HSplitView {
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(DesignSystem.Spacing.sm)
                }
                
                // 输出区域
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
                        .disabled(output.isEmpty)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tableHeader)
                    
                    TextEditor(text: .constant(output))
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(DesignSystem.Spacing.sm)
                        .disabled(true)
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
                
                Button(action: process) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text(mode == .encode ? "编码" : "解码")
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
    
    private func process() {
        errorMessage = nil
        output = ""
        
        do {
            if mode == .encode {
                output = try TextTools.urlEncode(input)
            } else {
                output = try TextTools.urlDecode(input)
            }
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
    
    private func clearAll() {
        input = ""
        output = ""
        errorMessage = nil
    }
}

// MARK: - Hash 计算视图

struct HashToolView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        ToolIOView(
            title: "Hash 计算",
            description: "计算文本的 MD5、SHA256、SHA512 哈希值",
            input: $input,
            output: $output,
            errorMessage: $errorMessage,
            onProcess: calculateHash,
            onClear: clearAll
        )
    }
    
    private func calculateHash() {
        errorMessage = nil
        output = ""
        
        do {
            output = try TextTools.calculateHash(input)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func clearAll() {
        input = ""
        output = ""
        errorMessage = nil
    }
}

// MARK: - 文本对比视图

struct TextDiffView: View {
    @State private var leftText: String = ""
    @State private var rightText: String = ""
    @State private var diffResult: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("文本对比")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("逐行对比两段文本的差异")
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
                // 输入区域（左右对比）
                HSplitView {
                    // 左侧文本
                    VStack(spacing: 0) {
                        HStack {
                            Text("原始文本")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(leftText.count) 字符")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textMuted)
                            
                            Button(action: pasteLeft) {
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
                        
                        TextEditor(text: $leftText)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(DesignSystem.Spacing.sm)
                    }
                    
                    // 右侧文本
                    VStack(spacing: 0) {
                        HStack {
                            Text("对比文本")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(rightText.count) 字符")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textMuted)
                            
                            Button(action: pasteRight) {
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
                        
                        TextEditor(text: $rightText)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(DesignSystem.Spacing.sm)
                    }
                }
                .frame(height: 250)
                
                Divider()
                
                // 差异结果区域
                VStack(spacing: 0) {
                    HStack {
                        Text("差异结果")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        if !diffResult.isEmpty {
                            Button(action: copyDiff) {
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
                        Text(diffResult.isEmpty ? "点击对比按钮查看差异" : diffResult)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(diffResult.isEmpty ? DesignSystem.Colors.textMuted : DesignSystem.Colors.textPrimary)
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
                
                Button(action: compareDiff) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 11))
                        Text("对比")
                            .font(DesignSystem.Typography.captionMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.accent)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .buttonStyle(.plain)
                .disabled(leftText.isEmpty && rightText.isEmpty)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
        }
    }
    
    private func pasteLeft() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            leftText = string
            errorMessage = nil
        }
    }
    
    private func pasteRight() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            rightText = string
            errorMessage = nil
        }
    }
    
    private func compareDiff() {
        errorMessage = nil
        diffResult = ""
        
        do {
            diffResult = try TextTools.compareText(left: leftText, right: rightText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func copyDiff() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(diffResult, forType: .string)
    }
    
    private func clearAll() {
        leftText = ""
        rightText = ""
        diffResult = ""
        errorMessage = nil
    }
}
