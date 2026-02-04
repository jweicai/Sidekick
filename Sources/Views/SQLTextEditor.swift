//
//  SQLTextEditor.swift
//  Sidekick
//
//  Created on 2025-01-13.
//

import SwiftUI
import AppKit

/// SQL 文本编辑器 - 使用 NSTextView 确保键盘输入正常工作
struct SQLTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedText: String
    @AppStorage("showLineNumbers") private var showLineNumbers = true
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        // 基本配置
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        
        // 字体和颜色
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.font = font
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.labelColor
        
        // 设置行高（固定行高，文字垂直居中）
        let lineHeight: CGFloat = 18
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        
        // 计算 baselineOffset 使文字垂直居中
        let fontLineHeight = font.ascender - font.descender + font.leading
        let baselineOffset = (lineHeight - fontLineHeight) / 2
        
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle,
            .baselineOffset: baselineOffset
        ]
        
        // 禁用自动替换功能
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        
        // 内边距
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        // 设置初始文本并应用高亮
        textView.string = text
        SQLSyntaxHighlighter.highlight(textView: textView)
        
        // 设置代理
        textView.delegate = context.coordinator
        
        // 确保可以成为第一响应者
        textView.window?.makeFirstResponder(textView)
        
        // 配置滚动视图
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.textBackgroundColor
        
        // 添加行号视图
        if showLineNumbers {
            let lineNumberView = LineNumberRulerView(textView: textView)
            scrollView.verticalRulerView = lineNumberView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // 如果正在进行 IME 输入，不要更新文本
        if textView.markedRange().length > 0 {
            return
        }
        
        // 只有当文本不同时才更新
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            SQLSyntaxHighlighter.highlight(textView: textView)
            textView.selectedRanges = selectedRanges
        }
        
        // 更新行号显示
        if showLineNumbers && nsView.verticalRulerView == nil {
            let lineNumberView = LineNumberRulerView(textView: textView)
            nsView.verticalRulerView = lineNumberView
            nsView.hasVerticalRuler = true
            nsView.rulersVisible = true
        } else if !showLineNumbers && nsView.verticalRulerView != nil {
            nsView.verticalRulerView = nil
            nsView.hasVerticalRuler = false
            nsView.rulersVisible = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: SQLTextEditor
        private var highlightWorkItem: DispatchWorkItem?
        
        init(_ parent: SQLTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // 如果正在进行 IME 输入（中文等），不要更新
            if textView.markedRange().length > 0 {
                return
            }
            
            parent.text = textView.string
            updateSelectedText(textView)
            
            // 防抖高亮更新
            highlightWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak textView] in
                guard let textView = textView else { return }
                // 再次检查是否在 IME 输入中
                if textView.markedRange().length == 0 {
                    SQLSyntaxHighlighter.highlight(textView: textView)
                }
            }
            highlightWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
            
            // 更新行号
            if let scrollView = textView.enclosingScrollView,
               let lineNumberView = scrollView.verticalRulerView as? LineNumberRulerView {
                lineNumberView.needsDisplay = true
            }
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            updateSelectedText(textView)
        }
        
        private func updateSelectedText(_ textView: NSTextView) {
            let selectedRange = textView.selectedRange()
            if selectedRange.length > 0 {
                let selectedText = (textView.string as NSString).substring(with: selectedRange)
                parent.selectedText = selectedText
            } else {
                parent.selectedText = ""
            }
        }
    }
}

// MARK: - SQL 语法高亮器

enum SQLSyntaxHighlighter {
    
    // 颜色定义 - 现代配色（类似 VS Code One Dark）
    private static let keywordColor = NSColor(red: 0.78, green: 0.47, blue: 0.86, alpha: 1.0)   // 紫色 - 关键字
    private static let functionColor = NSColor(red: 0.38, green: 0.71, blue: 0.93, alpha: 1.0)  // 蓝色 - 函数
    private static let stringColor = NSColor(red: 0.59, green: 0.78, blue: 0.47, alpha: 1.0)    // 绿色 - 字符串
    private static let numberColor = NSColor(red: 0.82, green: 0.58, blue: 0.40, alpha: 1.0)    // 橙色 - 数字
    private static let commentColor = NSColor(red: 0.50, green: 0.55, blue: 0.60, alpha: 1.0)   // 灰色 - 注释
    private static let operatorColor = NSColor(red: 0.87, green: 0.75, blue: 0.49, alpha: 1.0)  // 黄色 - 操作符
    private static let defaultColor = NSColor(red: 0.22, green: 0.24, blue: 0.28, alpha: 1.0)   // 深灰 - 默认
    
    // SQL 关键字
    private static let keywords: Set<String> = [
        "select", "from", "where", "and", "or", "not", "in", "between", "like", "is", "null",
        "as", "on", "using", "join", "inner", "left", "right", "full", "cross", "outer",
        "group", "by", "having", "order", "asc", "desc", "limit", "offset",
        "union", "intersect", "except", "all", "distinct",
        "insert", "into", "values", "update", "set", "delete",
        "create", "alter", "drop", "truncate", "table", "index", "view",
        "case", "when", "then", "else", "end",
        "with", "recursive", "over", "partition", "rows", "range",
        "unbounded", "preceding", "following", "current", "row",
        "exists", "any", "some", "true", "false",
        "primary", "key", "foreign", "references", "unique", "default", "constraint",
        "if", "nulls", "first", "last"
    ]
    
    // SQL 函数
    private static let functions: Set<String> = [
        "count", "sum", "avg", "min", "max", "abs", "round", "floor", "ceil", "ceiling",
        "length", "len", "upper", "lower", "trim", "ltrim", "rtrim", "substring", "substr",
        "concat", "replace", "reverse", "left", "right", "lpad", "rpad",
        "coalesce", "nullif", "ifnull", "isnull", "nvl", "nvl2",
        "cast", "convert", "date", "time", "datetime", "timestamp",
        "year", "month", "day", "hour", "minute", "second",
        "now", "current_date", "current_time", "current_timestamp",
        "row_number", "rank", "dense_rank", "ntile", "lag", "lead",
        "first_value", "last_value", "nth_value",
        "listagg", "string_agg", "group_concat", "array_agg"
    ]
    
    static func highlight(textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        
        let text = textView.string
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        
        // 保存当前选择
        let selectedRanges = textView.selectedRanges
        
        // 创建段落样式（固定行高，文字垂直居中）
        let lineHeight: CGFloat = 18
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        
        let fontLineHeight = font.ascender - font.descender + font.leading
        let baselineOffset = (lineHeight - fontLineHeight) / 2
        
        // 开始编辑
        textStorage.beginEditing()
        
        // 重置为默认样式（包含行高和垂直居中）
        textStorage.setAttributes([
            .font: font,
            .foregroundColor: defaultColor,
            .paragraphStyle: paragraphStyle,
            .baselineOffset: baselineOffset
        ], range: fullRange)
        
        // 高亮注释 (先处理，避免被其他规则覆盖)
        highlightComments(textStorage: textStorage, text: text)
        
        // 高亮字符串
        highlightStrings(textStorage: textStorage, text: text)
        
        // 高亮数字
        highlightNumbers(textStorage: textStorage, text: text)
        
        // 高亮关键字和函数
        highlightKeywordsAndFunctions(textStorage: textStorage, text: text)
        
        // 结束编辑
        textStorage.endEditing()
        
        // 恢复选择
        textView.selectedRanges = selectedRanges
    }
    
    private static func highlightComments(textStorage: NSTextStorage, text: String) {
        // 单行注释 --
        let singleLinePattern = "--[^\n]*"
        applyPattern(singleLinePattern, to: textStorage, text: text, color: commentColor)
        
        // 多行注释 /* */
        let multiLinePattern = "/\\*[\\s\\S]*?\\*/"
        applyPattern(multiLinePattern, to: textStorage, text: text, color: commentColor)
    }
    
    private static func highlightStrings(textStorage: NSTextStorage, text: String) {
        // 单引号字符串
        let singleQuotePattern = "'(?:[^'\\\\]|\\\\.)*'"
        applyPattern(singleQuotePattern, to: textStorage, text: text, color: stringColor)
        
        // 双引号字符串
        let doubleQuotePattern = "\"(?:[^\"\\\\]|\\\\.)*\""
        applyPattern(doubleQuotePattern, to: textStorage, text: text, color: stringColor)
    }
    
    private static func highlightNumbers(textStorage: NSTextStorage, text: String) {
        let numberPattern = "\\b\\d+\\.?\\d*\\b"
        applyPattern(numberPattern, to: textStorage, text: text, color: numberColor)
    }
    
    private static func highlightKeywordsAndFunctions(textStorage: NSTextStorage, text: String) {
        // 匹配单词
        let wordPattern = "\\b[a-zA-Z_][a-zA-Z0-9_]*\\b"
        guard let regex = try? NSRegularExpression(pattern: wordPattern, options: []) else { return }
        
        let range = NSRange(location: 0, length: (text as NSString).length)
        let matches = regex.matches(in: text, options: [], range: range)
        
        for match in matches {
            let matchRange = match.range
            let word = (text as NSString).substring(with: matchRange).lowercased()
            
            // 检查是否在注释或字符串中 (简单检查)
            if isInCommentOrString(range: matchRange, textStorage: textStorage) {
                continue
            }
            
            if keywords.contains(word) {
                textStorage.addAttribute(.foregroundColor, value: keywordColor, range: matchRange)
            } else if functions.contains(word) {
                textStorage.addAttribute(.foregroundColor, value: functionColor, range: matchRange)
            }
        }
    }
    
    private static func applyPattern(_ pattern: String, to textStorage: NSTextStorage, text: String, color: NSColor) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return }
        
        let range = NSRange(location: 0, length: (text as NSString).length)
        let matches = regex.matches(in: text, options: [], range: range)
        
        for match in matches {
            textStorage.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }
    
    private static func isInCommentOrString(range: NSRange, textStorage: NSTextStorage) -> Bool {
        // 检查该位置的颜色是否已经是注释或字符串颜色
        guard range.location < textStorage.length else { return false }
        
        let attrs = textStorage.attributes(at: range.location, effectiveRange: nil)
        if let color = attrs[.foregroundColor] as? NSColor {
            return color == commentColor || color == stringColor
        }
        return false
    }
}

// MARK: - 行号视图

class LineNumberRulerView: NSRulerView {
    var textView: NSTextView
    
    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView!, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 40
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // 背景色
        NSColor(white: 0.95, alpha: 1.0).setFill()
        context.fill(bounds)
        
        // 右边框
        NSColor(white: 0.85, alpha: 1.0).setStroke()
        context.setLineWidth(1)
        context.move(to: CGPoint(x: bounds.maxX - 0.5, y: bounds.minY))
        context.addLine(to: CGPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
        context.strokePath()
        
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        let visibleRect = textView.visibleRect
        let textString = textView.string as NSString
        
        // 计算可见范围
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        // 绘制行号
        var lineNumber = 1
        var index = 0
        
        while index < textString.length {
            let lineRange = textString.lineRange(for: NSRange(location: index, length: 0))
            
            if NSLocationInRange(lineRange.location, characterRange) {
                let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
                let lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                
                let yPosition = lineRect.origin.y + textView.textContainerInset.height - visibleRect.origin.y
                
                let numberString = "\(lineNumber)" as NSString
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
                
                let size = numberString.size(withAttributes: attributes)
                let xPosition = bounds.width - size.width - 8
                
                numberString.draw(at: NSPoint(x: xPosition, y: yPosition), withAttributes: attributes)
            }
            
            index = NSMaxRange(lineRange)
            lineNumber += 1
        }
    }
}

#Preview {
    SQLTextEditor(text: .constant("SELECT * FROM users WHERE id = 1;"), selectedText: .constant(""))
        .frame(height: 200)
}
