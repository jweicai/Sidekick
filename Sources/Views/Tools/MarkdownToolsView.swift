//
//  MarkdownToolsView.swift
//  Sidekick
//
//  Created on 2025-01-15.
//

import SwiftUI
import WebKit

// MARK: - Markdown 预览视图

struct MarkdownPreviewView: View {
    @State private var input: String = """
# Markdown 预览

这是一个 **Markdown** 实时预览工具。

## 功能特性

- 支持标题、列表、代码块
- 支持 *斜体* 和 **粗体**
- 支持 [链接](https://example.com)
- 支持表格

## 代码示例

```swift
let message = "Hello, World!"
print(message)
```

## 表格示例

| 名称 | 类型 | 描述 |
|------|------|------|
| id | Int | 唯一标识 |
| name | String | 名称 |

> 引用文本示例

---

*开始编辑左侧内容，右侧将实时预览*
"""
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Markdown 预览")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("左侧编辑，右侧实时预览")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
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
                    .padding(.vertical, 6)
                    .background(DesignSystem.Colors.sidebarHover)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            // 编辑器和预览区域
            HSplitView {
                // 左侧：Markdown 编辑器
                VStack(spacing: 0) {
                    HStack {
                        Text("Markdown")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Button(action: pasteFromClipboard) {
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
                    
                    TextEditor(text: $input)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: 300)
                
                // 右侧：渲染预览
                VStack(spacing: 0) {
                    HStack {
                        Text("预览")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Button(action: copyHTML) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        .buttonStyle(.plain)
                        .help("复制 HTML")
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tableHeader)
                    
                    MarkdownWebView(markdown: input)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: 300)
            }
        }
    }
    
    private func pasteFromClipboard() {
        if let string = NSPasteboard.general.string(forType: .string) {
            input = string
        }
    }
    
    private func copyHTML() {
        let html = MarkdownRenderer.render(input)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(html, forType: .string)
    }
    
    private func clearAll() {
        input = ""
    }
}

// MARK: - Markdown WebView

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = MarkdownRenderer.renderFullHTML(markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Markdown 渲染器

enum MarkdownRenderer {
    static func render(_ markdown: String) -> String {
        var html = markdown
        
        // 代码块 (需要先处理，避免内部内容被其他规则影响)
        html = processCodeBlocks(html)
        
        // 标题
        html = html.replacingOccurrences(of: "(?m)^###### (.+)$", with: "<h6>$1</h6>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^##### (.+)$", with: "<h5>$1</h5>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^#### (.+)$", with: "<h4>$1</h4>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^### (.+)$", with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^## (.+)$", with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^# (.+)$", with: "<h1>$1</h1>", options: .regularExpression)
        
        // 粗体和斜体
        html = html.replacingOccurrences(of: "\\*\\*\\*(.+?)\\*\\*\\*", with: "<strong><em>$1</em></strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*(.+?)\\*", with: "<em>$1</em>", options: .regularExpression)
        
        // 行内代码
        html = html.replacingOccurrences(of: "`([^`]+)`", with: "<code>$1</code>", options: .regularExpression)
        
        // 链接
        html = html.replacingOccurrences(of: "\\[([^\\]]+)\\]\\(([^)]+)\\)", with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        
        // 图片
        html = html.replacingOccurrences(of: "!\\[([^\\]]*)]\\(([^)]+)\\)", with: "<img src=\"$2\" alt=\"$1\">", options: .regularExpression)
        
        // 引用
        html = html.replacingOccurrences(of: "(?m)^> (.+)$", with: "<blockquote>$1</blockquote>", options: .regularExpression)
        
        // 水平线
        html = html.replacingOccurrences(of: "(?m)^---+$", with: "<hr>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^\\*\\*\\*+$", with: "<hr>", options: .regularExpression)
        
        // 无序列表
        html = processUnorderedLists(html)
        
        // 有序列表
        html = processOrderedLists(html)
        
        // 表格
        html = processTables(html)
        
        // 段落 (处理剩余的普通文本行)
        html = processParagraphs(html)
        
        return html
    }
    
    static func renderFullHTML(_ markdown: String) -> String {
        let body = render(markdown)
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    color: #333;
                    padding: 16px;
                    max-width: 100%;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 16px;
                    font-weight: 600;
                    line-height: 1.25;
                }
                h1 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
                h2 { font-size: 1.5em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
                h3 { font-size: 1.25em; }
                h4 { font-size: 1em; }
                code {
                    background: #f4f4f4;
                    padding: 2px 6px;
                    border-radius: 3px;
                    font-family: "SF Mono", Menlo, Monaco, monospace;
                    font-size: 0.9em;
                }
                pre {
                    background: #f6f8fa;
                    padding: 16px;
                    border-radius: 6px;
                    overflow-x: auto;
                }
                pre code {
                    background: none;
                    padding: 0;
                }
                blockquote {
                    margin: 0;
                    padding: 0 1em;
                    color: #666;
                    border-left: 4px solid #ddd;
                }
                a { color: #0366d6; text-decoration: none; }
                a:hover { text-decoration: underline; }
                hr {
                    border: none;
                    border-top: 1px solid #eee;
                    margin: 24px 0;
                }
                ul, ol { padding-left: 2em; }
                li { margin: 4px 0; }
                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin: 16px 0;
                }
                th, td {
                    border: 1px solid #ddd;
                    padding: 8px 12px;
                    text-align: left;
                }
                th {
                    background: #f6f8fa;
                    font-weight: 600;
                }
                tr:nth-child(even) { background: #fafafa; }
                img { max-width: 100%; }
            </style>
        </head>
        <body>
            \(body)
        </body>
        </html>
        """
    }
    
    private static func processCodeBlocks(_ text: String) -> String {
        var result = text
        let pattern = "```(\\w*)\\n([\\s\\S]*?)```"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(text.startIndex..., in: text)
            result = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "<pre><code class=\"language-$1\">$2</code></pre>")
        }
        return result
    }
    
    private static func processUnorderedLists(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var result: [String] = []
        var inList = false
        
        for line in lines {
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                if !inList {
                    result.append("<ul>")
                    inList = true
                }
                let content = String(line.dropFirst(2))
                result.append("<li>\(content)</li>")
            } else {
                if inList {
                    result.append("</ul>")
                    inList = false
                }
                result.append(line)
            }
        }
        
        if inList {
            result.append("</ul>")
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func processOrderedLists(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var result: [String] = []
        var inList = false
        let pattern = "^\\d+\\. "
        
        for line in lines {
            if line.range(of: pattern, options: .regularExpression) != nil {
                if !inList {
                    result.append("<ol>")
                    inList = true
                }
                let content = line.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
                result.append("<li>\(content)</li>")
            } else {
                if inList {
                    result.append("</ol>")
                    inList = false
                }
                result.append(line)
            }
        }
        
        if inList {
            result.append("</ol>")
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func processTables(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            
            // 检测表格开始
            if line.contains("|") && i + 1 < lines.count && lines[i + 1].contains("|") && lines[i + 1].contains("-") {
                result.append("<table>")
                
                // 表头
                let headers = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                result.append("<thead><tr>")
                for header in headers {
                    result.append("<th>\(header)</th>")
                }
                result.append("</tr></thead>")
                
                i += 2 // 跳过分隔行
                result.append("<tbody>")
                
                // 数据行
                while i < lines.count && lines[i].contains("|") {
                    let cells = lines[i].split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    result.append("<tr>")
                    for cell in cells {
                        result.append("<td>\(cell)</td>")
                    }
                    result.append("</tr>")
                    i += 1
                }
                
                result.append("</tbody></table>")
            } else {
                result.append(line)
                i += 1
            }
        }
        
        return result.joined(separator: "\n")
    }
    
    private static func processParagraphs(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var result: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // 跳过已经是 HTML 标签的行或空行
            if trimmed.isEmpty || trimmed.hasPrefix("<") {
                result.append(line)
            } else {
                result.append("<p>\(line)</p>")
            }
        }
        
        return result.joined(separator: "\n")
    }
}
