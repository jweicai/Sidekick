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
        // 使用 Apple 推荐的方式创建可滚动的文本视图
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
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = NSColor.black
        textView.backgroundColor = NSColor.white
        textView.insertionPointColor = NSColor.black
        
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
        
        // 设置初始文本
        textView.string = text
        
        // 设置代理
        textView.delegate = context.coordinator
        
        // 配置滚动视图
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.white
        
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
        
        // 只有当文本不同时才更新
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
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
        
        init(_ parent: SQLTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            updateSelectedText(textView)
            
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
    SQLTextEditor(text: .constant("SELECT * FROM users;"), selectedText: .constant(""))
        .frame(height: 200)
}
