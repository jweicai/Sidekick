//
//  IPToolsView.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import SwiftUI

// MARK: - IP 格式转换视图

struct IPConverterView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP 格式转换")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("IP 地址 ↔ 整数 ↔ 十六进制 ↔ 二进制")
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
                        Text("输入")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            TextField("例如：192.168.1.1 或 3232235777", text: $input)
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
                    
                    // 转换按钮
                    Button(action: convertIP) {
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
    
    private func convertIP() {
        errorMessage = nil
        output = ""
        
        do {
            output = try IPConverter.convert(input)
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

// MARK: - 子网计算视图

struct SubnetCalculatorView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("子网计算")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("输入 CIDR 格式（例如：192.168.1.0/24）")
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
                        Text("CIDR 地址")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            TextField("例如：192.168.1.0/24", text: $input)
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
                    
                    // 计算按钮
                    Button(action: calculateSubnet) {
                        HStack(spacing: 6) {
                            Image(systemName: "function")
                                .font(.system(size: 12))
                            Text("计算")
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
                                Text("子网信息")
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
    
    private func calculateSubnet() {
        errorMessage = nil
        output = ""
        
        do {
            output = try IPConverter.calculateSubnet(input)
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

// MARK: - IP 地址验证视图

struct IPValidatorView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP 地址验证")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("验证 IPv4 和 IPv6 地址格式")
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
                        Text("IP 地址")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            TextField("例如：192.168.1.1 或 2001:db8::1", text: $input)
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
                    
                    // 验证按钮
                    Button(action: validateIP) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield")
                                .font(.system(size: 12))
                            Text("验证")
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
                    
                    // 验证结果
                    if !output.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("验证结果")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
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
    
    private func validateIP() {
        errorMessage = nil
        output = ""
        
        do {
            output = try IPConverter.validate(input)
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
    
    private func clearAll() {
        input = ""
        output = ""
        errorMessage = nil
    }
}

// MARK: - IP 批量处理视图

struct IPBatchProcessorView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP 批量处理")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("批量转换 IP 地址列表（每行一个）")
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
                        HStack {
                            Text("IP 地址列表")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Button(action: pasteFromClipboard) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 10))
                                    Text("粘贴")
                                        .font(DesignSystem.Typography.caption)
                                }
                                .foregroundColor(DesignSystem.Colors.accent)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(DesignSystem.Colors.accent.opacity(0.1))
                                .cornerRadius(DesignSystem.CornerRadius.small)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        TextEditor(text: $input)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(height: 120)
                            .padding(DesignSystem.Spacing.sm)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    }
                    
                    // 转换按钮
                    Button(action: batchProcess) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12))
                            Text("批量转换")
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
                            
                            ScrollView {
                                Text(output)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(DesignSystem.Spacing.md)
                                    .textSelection(.enabled)
                            }
                            .frame(height: 150)
                            .background(DesignSystem.Colors.success.opacity(0.05))
                            .cornerRadius(DesignSystem.CornerRadius.small)
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
    
    private func batchProcess() {
        errorMessage = nil
        output = ""
        
        do {
            output = try IPConverter.batchConvert(input)
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
