//
//  JSONToolsView.swift
//  Sidekick
//
//  Created on 2025-01-13.
//

import SwiftUI

// MARK: - JSON 扁平化视图（优化版）

struct JSONFlattenerView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        ToolIOView(
            title: "JSON 扁平化",
            description: "将列式 JSON 转换为行式 JSON",
            input: $input,
            output: $output,
            errorMessage: $errorMessage,
            onProcess: flattenJSON,
            onClear: clearAll
        )
    }
    
    private func flattenJSON() {
        errorMessage = nil
        output = ""
        
        do {
            output = try JSONFlattener.flatten(input)
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

// MARK: - JSON 格式化视图

struct JSONFormatterView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        ToolIOView(
            title: "JSON 格式化",
            description: "美化 JSON 格式，添加缩进和换行",
            input: $input,
            output: $output,
            errorMessage: $errorMessage,
            onProcess: formatJSON,
            onClear: clearAll
        )
    }
    
    private func formatJSON() {
        errorMessage = nil
        output = ""
        
        do {
            output = try JSONFormatter.format(input)
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

// MARK: - JSON 压缩视图

struct JSONCompressorView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        ToolIOView(
            title: "JSON 压缩",
            description: "移除空格和换行，压缩 JSON 大小",
            input: $input,
            output: $output,
            errorMessage: $errorMessage,
            onProcess: compressJSON,
            onClear: clearAll
        )
    }
    
    private func compressJSON() {
        errorMessage = nil
        output = ""
        
        do {
            output = try JSONFormatter.compress(input)
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

// MARK: - JSON 验证视图

struct JSONValidatorView: View {
    @State private var input: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        ToolIOView(
            title: "JSON 验证",
            description: "检查 JSON 格式是否有效",
            input: $input,
            output: $output,
            errorMessage: $errorMessage,
            onProcess: validateJSON,
            onClear: clearAll
        )
    }
    
    private func validateJSON() {
        errorMessage = nil
        output = ""
        
        do {
            let result = try JSONFormatter.validate(input)
            output = result
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

// MARK: - JSON 格式化工具

struct JSONFormatter {
    /// 格式化 JSON
    static func format(_ jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw JSONFormatterError.invalidInput
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
        
        guard let formattedString = String(data: formattedData, encoding: .utf8) else {
            throw JSONFormatterError.conversionFailed
        }
        
        return formattedString
    }
    
    /// 压缩 JSON
    static func compress(_ jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw JSONFormatterError.invalidInput
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let compressedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        
        guard let compressedString = String(data: compressedData, encoding: .utf8) else {
            throw JSONFormatterError.conversionFailed
        }
        
        return compressedString
    }
    
    /// 验证 JSON
    static func validate(_ jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw JSONFormatterError.invalidInput
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        
        // 分析 JSON 结构
        var info = "✅ JSON 格式有效\n\n"
        
        if let dict = jsonObject as? [String: Any] {
            info += "类型：对象 (Object)\n"
            info += "键数量：\(dict.keys.count)\n"
            info += "键列表：\(dict.keys.sorted().joined(separator: ", "))"
        } else if let array = jsonObject as? [Any] {
            info += "类型：数组 (Array)\n"
            info += "元素数量：\(array.count)"
        } else {
            info += "类型：基本类型"
        }
        
        return info
    }
}

enum JSONFormatterError: Error, LocalizedError {
    case invalidInput
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "无效的 JSON 输入"
        case .conversionFailed:
            return "转换失败"
        }
    }
}

// MARK: - JSON 路径查询视图

struct JSONPathQueryView: View {
    @State private var jsonInput: String = ""
    @State private var pathInput: String = ""
    @State private var output: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("JSON 路径查询")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("使用点号表示法查询 JSON 数据（例如：user.name 或 items[0].price）")
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
            HSplitView {
                // JSON 输入区域
                VStack(spacing: 0) {
                    HStack {
                        Text("JSON 数据")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(jsonInput.count) 字符")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textMuted)
                        
                        Button(action: pasteJSON) {
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
                    
                    TextEditor(text: $jsonInput)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(DesignSystem.Spacing.sm)
                }
                
                // 查询和结果区域
                VStack(spacing: 0) {
                    // 路径输入
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("查询路径")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("例如：user.name 或 items[0]", text: $pathInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, design: .monospaced))
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
                    
                    // 结果区域
                    VStack(spacing: 0) {
                        HStack {
                            Text("查询结果")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            if !output.isEmpty {
                                Button(action: copyToClipboard) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundColor(DesignSystem.Colors.success)
                                }
                                .buttonStyle(.plain)
                                .help("复制到剪贴板")
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.tableHeader)
                        
                        ScrollView {
                            Text(output.isEmpty ? "在上方输入路径并点击查询" : output)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(output.isEmpty ? DesignSystem.Colors.textMuted : DesignSystem.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(DesignSystem.Spacing.sm)
                        }
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
                
                // 清空按钮
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
                
                // 查询按钮
                Button(action: queryPath) {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                        Text("查询")
                            .font(DesignSystem.Typography.captionMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.accent)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .buttonStyle(.plain)
                .disabled(jsonInput.isEmpty || pathInput.isEmpty)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
        }
    }
    
    private func pasteJSON() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            jsonInput = string
            errorMessage = nil
        }
    }
    
    private func queryPath() {
        errorMessage = nil
        output = ""
        
        do {
            output = try JSONPathQuery.query(json: jsonInput, path: pathInput)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
    
    private func clearAll() {
        jsonInput = ""
        pathInput = ""
        output = ""
        errorMessage = nil
    }
}

// MARK: - JSON 路径查询工具

struct JSONPathQuery {
    /// 查询 JSON 路径
    /// 支持点号表示法：user.name, items[0].price
    static func query(json: String, path: String) throws -> String {
        guard let data = json.data(using: .utf8) else {
            throw JSONPathError.invalidJSON
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        
        // 解析路径
        let pathComponents = parsePath(path)
        
        // 遍历路径
        var current: Any = jsonObject
        for component in pathComponents {
            switch component {
            case .key(let key):
                guard let dict = current as? [String: Any],
                      let value = dict[key] else {
                    throw JSONPathError.pathNotFound(path)
                }
                current = value
                
            case .index(let index):
                guard let array = current as? [Any],
                      index >= 0 && index < array.count else {
                    throw JSONPathError.pathNotFound(path)
                }
                current = array[index]
            }
        }
        
        // 格式化输出
        if let dict = current as? [String: Any] {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? ""
        } else if let array = current as? [Any] {
            let data = try JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? ""
        } else {
            return "\(current)"
        }
    }
    
    /// 解析路径字符串
    private static func parsePath(_ path: String) -> [PathComponent] {
        var components: [PathComponent] = []
        var currentKey = ""
        var i = path.startIndex
        
        while i < path.endIndex {
            let char = path[i]
            
            if char == "." {
                if !currentKey.isEmpty {
                    components.append(.key(currentKey))
                    currentKey = ""
                }
            } else if char == "[" {
                if !currentKey.isEmpty {
                    components.append(.key(currentKey))
                    currentKey = ""
                }
                
                // 查找匹配的 ]
                var indexStr = ""
                i = path.index(after: i)
                while i < path.endIndex && path[i] != "]" {
                    indexStr.append(path[i])
                    i = path.index(after: i)
                }
                
                if let index = Int(indexStr) {
                    components.append(.index(index))
                }
            } else {
                currentKey.append(char)
            }
            
            i = path.index(after: i)
        }
        
        if !currentKey.isEmpty {
            components.append(.key(currentKey))
        }
        
        return components
    }
    
    enum PathComponent {
        case key(String)
        case index(Int)
    }
}

enum JSONPathError: Error, LocalizedError {
    case invalidJSON
    case pathNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "无效的 JSON 格式"
        case .pathNotFound(let path):
            return "路径不存在：\(path)"
        }
    }
}
