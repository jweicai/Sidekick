//
//  SQLTextEditor.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import SwiftUI
import AppKit

/// SQL 文本编辑器 - 使用 NSTextView 确保键盘输入正常工作
struct SQLTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedText: String
    
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
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.textColor
        
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
        scrollView.backgroundColor = NSColor.textBackgroundColor
        
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

#Preview {
    SQLTextEditor(text: .constant("SELECT * FROM users;"), selectedText: .constant(""))
        .frame(height: 200)
}
