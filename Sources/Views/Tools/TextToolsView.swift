//
//  TextToolsView.swift
//  Sidekick
//
//  Created on 2025-01-13.
//

import SwiftUI
import CryptoKit
import AppKit

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

// MARK: - 文本对比视图（并排对比）

struct TextDiffView: View {
    @State private var leftText: String = ""
    @State private var rightText: String = ""
    @State private var diffLines: [DiffLine] = []
    @State private var isCompared: Bool = false
    @State private var isComparing: Bool = false
    @State private var scrollOffset: CGFloat = 0
    
    // 统计信息
    @State private var sameCount: Int = 0
    @State private var diffCount: Int = 0
    @State private var addedCount: Int = 0
    @State private var removedCount: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("文本对比")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("并排对比两段文本的差异")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // 统计信息
                if isCompared {
                    HStack(spacing: 12) {
                        StatBadge(label: "相同", count: sameCount, color: DesignSystem.Colors.textMuted)
                        StatBadge(label: "修改", count: diffCount, color: .orange)
                        StatBadge(label: "新增", count: addedCount, color: DesignSystem.Colors.success)
                        StatBadge(label: "删除", count: removedCount, color: DesignSystem.Colors.error)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            if isCompared {
                // 对比结果视图
                DiffResultView(diffLines: diffLines)
            } else {
                // 输入视图
                HSplitView {
                    // 左侧输入
                    DiffInputPane(
                        title: "原始文本",
                        text: $leftText,
                        onPaste: pasteLeft
                    )
                    
                    // 右侧输入
                    DiffInputPane(
                        title: "对比文本",
                        text: $rightText,
                        onPaste: pasteRight
                    )
                }
            }
            
            Divider()
            
            // 操作按钮栏
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isCompared {
                    Button(action: backToEdit) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 11))
                            Text("返回编辑")
                                .font(DesignSystem.Typography.caption)
                        }
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.sidebarHover)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                    .buttonStyle(.plain)
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
                
                if !isCompared {
                    Button(action: compareDiff) {
                        HStack(spacing: 4) {
                            if isComparing {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 11, height: 11)
                            } else {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 11))
                            }
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
                    .disabled(leftText.isEmpty && rightText.isEmpty || isComparing)
                }
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
        }
    }
    
    private func pasteRight() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            rightText = string
        }
    }
    
    private func compareDiff() {
        isComparing = true
        
        // 在后台线程执行对比
        DispatchQueue.global(qos: .userInitiated).async {
            let result = computeDiff(left: leftText, right: rightText)
            
            DispatchQueue.main.async {
                self.diffLines = result.lines
                self.sameCount = result.same
                self.diffCount = result.diff
                self.addedCount = result.added
                self.removedCount = result.removed
                self.isCompared = true
                self.isComparing = false
            }
        }
    }
    
    private func backToEdit() {
        isCompared = false
        diffLines = []
    }
    
    private func clearAll() {
        leftText = ""
        rightText = ""
        diffLines = []
        isCompared = false
        sameCount = 0
        diffCount = 0
        addedCount = 0
        removedCount = 0
    }
    
    // 计算差异（使用简单的 LCS 算法）
    private func computeDiff(left: String, right: String) -> (lines: [DiffLine], same: Int, diff: Int, added: Int, removed: Int) {
        let leftLines = left.components(separatedBy: "\n")
        let rightLines = right.components(separatedBy: "\n")
        
        // 使用简单的逐行对比（对于大文件更高效）
        var result: [DiffLine] = []
        var same = 0, diff = 0, added = 0, removed = 0
        
        let maxCount = max(leftLines.count, rightLines.count)
        
        for i in 0..<maxCount {
            let leftLine = i < leftLines.count ? leftLines[i] : nil
            let rightLine = i < rightLines.count ? rightLines[i] : nil
            
            if let l = leftLine, let r = rightLine {
                if l == r {
                    result.append(DiffLine(leftLineNum: i + 1, rightLineNum: i + 1, leftText: l, rightText: r, type: .same, charDiffs: nil))
                    same += 1
                } else {
                    // 计算字符级别的差异
                    let charDiffs = computeCharDiffs(left: l, right: r)
                    result.append(DiffLine(leftLineNum: i + 1, rightLineNum: i + 1, leftText: l, rightText: r, type: .modified, charDiffs: charDiffs))
                    diff += 1
                }
            } else if let l = leftLine {
                result.append(DiffLine(leftLineNum: i + 1, rightLineNum: nil, leftText: l, rightText: nil, type: .removed, charDiffs: nil))
                removed += 1
            } else if let r = rightLine {
                result.append(DiffLine(leftLineNum: nil, rightLineNum: i + 1, leftText: nil, rightText: r, type: .added, charDiffs: nil))
                added += 1
            }
        }
        
        return (result, same, diff, added, removed)
    }
    
    // 计算字符级别的差异（使用简单的字符对比）
    private func computeCharDiffs(left: String, right: String) -> [CharDiff] {
        var diffs: [CharDiff] = []
        
        let leftChars = Array(left)
        let rightChars = Array(right)
        
        // 使用动态规划找到最长公共子序列
        let lcs = longestCommonSubsequence(leftChars, rightChars)
        
        // 标记不在 LCS 中的字符
        var leftIndex = left.startIndex
        var rightIndex = right.startIndex
        var lcsIndex = 0
        
        while leftIndex < left.endIndex || rightIndex < right.endIndex {
            if lcsIndex < lcs.count {
                let lcsChar = lcs[lcsIndex]
                
                // 跳过左侧不匹配的字符
                while leftIndex < left.endIndex && left[leftIndex] != lcsChar {
                    let nextIndex = left.index(after: leftIndex)
                    diffs.append(CharDiff(range: leftIndex..<nextIndex, isLeft: true))
                    leftIndex = nextIndex
                }
                
                // 跳过右侧不匹配的字符
                while rightIndex < right.endIndex && right[rightIndex] != lcsChar {
                    let nextIndex = right.index(after: rightIndex)
                    diffs.append(CharDiff(range: rightIndex..<nextIndex, isLeft: false))
                    rightIndex = nextIndex
                }
                
                // 移动到下一个匹配字符
                if leftIndex < left.endIndex {
                    leftIndex = left.index(after: leftIndex)
                }
                if rightIndex < right.endIndex {
                    rightIndex = right.index(after: rightIndex)
                }
                lcsIndex += 1
            } else {
                // 剩余的都是差异
                while leftIndex < left.endIndex {
                    let nextIndex = left.index(after: leftIndex)
                    diffs.append(CharDiff(range: leftIndex..<nextIndex, isLeft: true))
                    leftIndex = nextIndex
                }
                while rightIndex < right.endIndex {
                    let nextIndex = right.index(after: rightIndex)
                    diffs.append(CharDiff(range: rightIndex..<nextIndex, isLeft: false))
                    rightIndex = nextIndex
                }
            }
        }
        
        return diffs
    }
    
    // 最长公共子序列算法
    private func longestCommonSubsequence(_ a: [Character], _ b: [Character]) -> [Character] {
        let m = a.count
        let n = b.count
        
        // 处理空数组的情况
        guard m > 0 && n > 0 else { return [] }
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 1...m {
            for j in 1...n {
                if a[i-1] == b[j-1] {
                    dp[i][j] = dp[i-1][j-1] + 1
                } else {
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])
                }
            }
        }
        
        // 回溯找到 LCS
        var result: [Character] = []
        var i = m, j = n
        while i > 0 && j > 0 {
            if a[i-1] == b[j-1] {
                result.insert(a[i-1], at: 0)
                i -= 1
                j -= 1
            } else if dp[i-1][j] > dp[i][j-1] {
                i -= 1
            } else {
                j -= 1
            }
        }
        
        return result
    }
}

// MARK: - 差异行数据模型

struct DiffLine: Identifiable {
    let id = UUID()
    let leftLineNum: Int?
    let rightLineNum: Int?
    let leftText: String?
    let rightText: String?
    let type: DiffType
    let charDiffs: [CharDiff]? // 字符级别的差异
}

// 字符级别的差异
struct CharDiff {
    let range: Range<String.Index>
    let isLeft: Bool // true 表示左侧，false 表示右侧
}

enum DiffType {
    case same
    case modified
    case added
    case removed
    
    var leftBackgroundColor: Color {
        switch self {
        case .same: return .clear
        case .modified: return Color.red.opacity(0.15)
        case .removed: return Color.red.opacity(0.15)
        case .added: return .clear
        }
    }
    
    var rightBackgroundColor: Color {
        switch self {
        case .same: return .clear
        case .modified: return Color.green.opacity(0.15)
        case .added: return Color.green.opacity(0.15)
        case .removed: return .clear
        }
    }
}

// MARK: - 统计徽章

struct StatBadge: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(label): \(count)")
                .font(.system(size: 11))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - 输入面板

struct DiffInputPane: View {
    let title: String
    @Binding var text: String
    let onPaste: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text("\(text.count) 字符")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textMuted)
                
                Button(action: onPaste) {
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
            
            TextEditor(text: $text)
                .font(.system(size: 12, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(DesignSystem.Spacing.sm)
        }
    }
}

// MARK: - 对比结果视图

struct DiffResultView: View {
    let diffLines: [DiffLine]
    @StateObject private var scrollController = DiffScrollController()
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 左侧面板
                DiffPanelView(
                    title: "原始文本",
                    diffLines: diffLines,
                    isLeft: true,
                    controller: scrollController
                )
                .frame(width: geometry.size.width / 2)
                
                // 分隔线
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(width: 1)
                
                // 右侧面板
                DiffPanelView(
                    title: "对比文本",
                    diffLines: diffLines,
                    isLeft: false,
                    controller: scrollController
                )
                .frame(width: geometry.size.width / 2 - 1)
            }
        }
    }
}

// MARK: - 同步滚动控制器

class DiffScrollController: ObservableObject {
    weak var leftScrollView: NSScrollView?
    weak var rightScrollView: NSScrollView?
    private var isSyncing = false
    
    func register(scrollView: NSScrollView, isLeft: Bool) {
        if isLeft {
            leftScrollView = scrollView
        } else {
            rightScrollView = scrollView
        }
    }
    
    func syncScroll(from source: NSScrollView) {
        guard !isSyncing else { return }
        isSyncing = true
        
        let target = (source === leftScrollView) ? rightScrollView : leftScrollView
        if let target = target {
            let offset = source.contentView.bounds.origin
            target.contentView.scroll(to: offset)
            target.reflectScrolledClipView(target.contentView)
        }
        
        // 使用 CATransaction 确保平滑
        DispatchQueue.main.async {
            self.isSyncing = false
        }
    }
}

// MARK: - 差异面板视图

struct DiffPanelView: View {
    let title: String
    let diffLines: [DiffLine]
    let isLeft: Bool
    let controller: DiffScrollController
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.tableHeader)
            
            // 内容区域
            SyncedDiffView(
                diffLines: diffLines,
                isLeft: isLeft,
                controller: controller
            )
        }
    }
}

// MARK: - 同步滚动差异视图

struct SyncedDiffView: NSViewRepresentable {
    let diffLines: [DiffLine]
    let isLeft: Bool
    let controller: DiffScrollController
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .overlay
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        
        // 使用翻转的 ClipView
        let clipView = DiffFlippedClipView()
        clipView.drawsBackground = false
        scrollView.contentView = clipView
        
        // 创建内容视图
        let contentView = DiffNativeContentView(diffLines: diffLines, isLeft: isLeft)
        scrollView.documentView = contentView
        
        // 注册到控制器
        controller.register(scrollView: scrollView, isLeft: isLeft)
        
        // 监听滚动
        clipView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollViewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: clipView
        )
        
        context.coordinator.scrollView = scrollView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let contentView = scrollView.documentView as? DiffNativeContentView {
            contentView.update(diffLines: diffLines, isLeft: isLeft)
        }
    }
    
    class Coordinator: NSObject {
        var parent: SyncedDiffView
        weak var scrollView: NSScrollView?
        
        init(_ parent: SyncedDiffView) {
            self.parent = parent
        }
        
        @objc func scrollViewDidScroll(_ notification: Notification) {
            guard let scrollView = scrollView else { return }
            parent.controller.syncScroll(from: scrollView)
        }
    }
}

// MARK: - 翻转的 ClipView

class DiffFlippedClipView: NSClipView {
    override var isFlipped: Bool { true }
}

// MARK: - 原生差异内容视图

class DiffNativeContentView: NSView {
    private var diffLines: [DiffLine] = []
    private var isLeft: Bool = true
    
    private let lineHeight: CGFloat = 22
    private let lineNumWidth: CGFloat = 50
    private let markerWidth: CGFloat = 24
    private let padding: CGFloat = 8
    
    override var isFlipped: Bool { true }
    
    init(diffLines: [DiffLine], isLeft: Bool) {
        self.diffLines = diffLines
        self.isLeft = isLeft
        super.init(frame: .zero)
        wantsLayer = true
        updateSize()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(diffLines: [DiffLine], isLeft: Bool) {
        self.diffLines = diffLines
        self.isLeft = isLeft
        updateSize()
        needsDisplay = true
    }
    
    private func updateSize() {
        let height = CGFloat(max(diffLines.count, 1)) * lineHeight
        let width = max(superview?.bounds.width ?? 800, 800)
        setFrameSize(NSSize(width: width, height: height))
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // 背景
        context.setFillColor(NSColor.textBackgroundColor.cgColor)
        context.fill(bounds)
        
        // 计算可见行范围（优化性能）
        let startLine = max(0, Int(dirtyRect.minY / lineHeight))
        let endLine = min(diffLines.count, Int(dirtyRect.maxY / lineHeight) + 1)
        
        let codeFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let lineNumFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        
        for i in startLine..<endLine {
            let line = diffLines[i]
            let y = CGFloat(i) * lineHeight
            let rowRect = NSRect(x: 0, y: y, width: bounds.width, height: lineHeight)
            
            // 绘制行背景
            drawRowBackground(context: context, rect: rowRect, line: line)
            
            // 绘制行号
            drawLineNumber(context: context, y: y, line: line, font: lineNumFont)
            
            // 绘制差异标记
            drawDiffMarker(context: context, y: y, line: line, font: lineNumFont)
            
            // 绘制内容
            drawContent(context: context, y: y, line: line, font: codeFont)
        }
    }
    
    private func drawRowBackground(context: CGContext, rect: NSRect, line: DiffLine) {
        let color: NSColor
        switch line.type {
        case .same:
            return // 不绘制背景
        case .modified:
            color = isLeft ? NSColor(red: 0.98, green: 0.92, blue: 0.92, alpha: 1.0) : NSColor(red: 0.92, green: 0.98, blue: 0.92, alpha: 1.0)
        case .added:
            color = isLeft ? .clear : NSColor(red: 0.90, green: 0.98, blue: 0.90, alpha: 1.0)
        case .removed:
            color = isLeft ? NSColor(red: 0.98, green: 0.90, blue: 0.90, alpha: 1.0) : .clear
        }
        
        if color != .clear {
            context.setFillColor(color.cgColor)
            context.fill(rect)
        }
    }
    
    private func drawLineNumber(context: CGContext, y: CGFloat, line: DiffLine, font: NSFont) {
        let lineNum = isLeft ? line.leftLineNum : line.rightLineNum
        guard let num = lineNum else { return }
        
        let str = String(num)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
        
        let size = str.size(withAttributes: attrs)
        let x = lineNumWidth - size.width - padding
        str.draw(at: NSPoint(x: x, y: y + 4), withAttributes: attrs)
    }
    
    private func drawDiffMarker(context: CGContext, y: CGFloat, line: DiffLine, font: NSFont) {
        let marker: String
        let color: NSColor
        
        switch line.type {
        case .same:
            return
        case .modified:
            marker = isLeft ? "−" : "+"
            color = isLeft ? NSColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0) : NSColor(red: 0.2, green: 0.55, blue: 0.2, alpha: 1.0)
        case .added:
            if isLeft { return }
            marker = "+"
            color = NSColor(red: 0.2, green: 0.55, blue: 0.2, alpha: 1.0)
        case .removed:
            if !isLeft { return }
            marker = "−"
            color = NSColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
        }
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        marker.draw(at: NSPoint(x: lineNumWidth + 4, y: y + 4), withAttributes: attrs)
    }
    
    private func drawContent(context: CGContext, y: CGFloat, line: DiffLine, font: NSFont) {
        let content = isLeft ? (line.leftText ?? "") : (line.rightText ?? "")
        let contentX = lineNumWidth + markerWidth
        
        // 如果有字符级差异，绘制高亮
        if line.type == .modified, let charDiffs = line.charDiffs, !charDiffs.isEmpty {
            drawHighlightedContent(context: context, content: content, charDiffs: charDiffs, x: contentX, y: y, font: font)
        } else {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.labelColor
            ]
            content.draw(at: NSPoint(x: contentX, y: y + 4), withAttributes: attrs)
        }
    }
    
    private func drawHighlightedContent(context: CGContext, content: String, charDiffs: [CharDiff], x: CGFloat, y: CGFloat, font: NSFont) {
        let relevantDiffs = charDiffs.filter { $0.isLeft == isLeft }
        
        var currentX = x
        var currentIndex = content.startIndex
        
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]
        
        while currentIndex < content.endIndex {
            let nextIndex = content.index(after: currentIndex)
            let char = String(content[currentIndex])
            let charSize = char.size(withAttributes: normalAttrs)
            
            // 检查是否在差异范围内
            let isDiff = relevantDiffs.contains { diff in
                diff.range.contains(currentIndex) || (currentIndex >= diff.range.lowerBound && currentIndex < diff.range.upperBound)
            }
            
            if isDiff {
                // 绘制高亮背景
                let highlightColor = isLeft ? 
                    NSColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0) : 
                    NSColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0)
                context.setFillColor(highlightColor.cgColor)
                context.fill(CGRect(x: currentX, y: y, width: charSize.width + 1, height: lineHeight))
            }
            
            // 绘制字符
            char.draw(at: NSPoint(x: currentX, y: y + 4), withAttributes: normalAttrs)
            currentX += charSize.width
            currentIndex = nextIndex
        }
    }
}

// MARK: - 删除旧的实现，保留 DiffLineRow 用于其他地方

// 注意：以下代码已被新的原生实现替代

// MARK: - 差异行

struct DiffLineRow: View {
    let line: DiffLine
    let isLeft: Bool
    
    private let lineHeight: CGFloat = 20
    private let lineNumWidth: CGFloat = 45
    
    var body: some View {
        HStack(spacing: 0) {
            // 行号
            Text(lineNumber)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.textMuted)
                .frame(width: lineNumWidth, alignment: .trailing)
                .padding(.trailing, 8)
            
            // 差异标记
            Text(diffMarker)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(markerColor)
                .frame(width: 16)
            
            // 内容 - 使用自定义视图来高亮字符差异
            if line.type == .modified && line.charDiffs != nil && !line.charDiffs!.isEmpty {
                HighlightedTextView(
                    text: content,
                    charDiffs: line.charDiffs!,
                    isLeft: isLeft
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: lineHeight)
            } else {
                Text(content)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 4)
        .frame(height: lineHeight)
        .background(backgroundColor)
    }
    
    private var lineNumber: String {
        if isLeft {
            return line.leftLineNum.map { String($0) } ?? ""
        } else {
            return line.rightLineNum.map { String($0) } ?? ""
        }
    }
    
    private var content: String {
        if isLeft {
            return line.leftText ?? ""
        } else {
            return line.rightText ?? ""
        }
    }
    
    private var diffMarker: String {
        switch line.type {
        case .same: return ""
        case .modified: return isLeft ? "-" : "+"
        case .added: return isLeft ? "" : "+"
        case .removed: return isLeft ? "-" : ""
        }
    }
    
    private var markerColor: Color {
        switch line.type {
        case .same: return .clear
        case .modified: return isLeft ? DesignSystem.Colors.error : DesignSystem.Colors.success
        case .added: return DesignSystem.Colors.success
        case .removed: return DesignSystem.Colors.error
        }
    }
    
    private var backgroundColor: Color {
        if isLeft {
            return line.type.leftBackgroundColor
        } else {
            return line.type.rightBackgroundColor
        }
    }
}

// MARK: - 高亮文本视图

struct HighlightedTextView: NSViewRepresentable {
    let text: String
    let charDiffs: [CharDiff]
    let isLeft: Bool
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isBordered = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.backgroundColor = .clear
        textField.lineBreakMode = .byTruncatingTail
        textField.maximumNumberOfLines = 1
        return textField
    }
    
    func updateNSView(_ textField: NSTextField, context: Context) {
        let attributedString = NSMutableAttributedString(string: text)
        
        // 设置默认属性
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        attributedString.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
        
        // 高亮差异字符
        let relevantDiffs = charDiffs.filter { $0.isLeft == isLeft }
        for diff in relevantDiffs {
            let nsRange = NSRange(diff.range, in: text)
            attributedString.addAttribute(.backgroundColor, value: isLeft ? NSColor.systemRed.withAlphaComponent(0.4) : NSColor.systemGreen.withAlphaComponent(0.4), range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: NSColor.white, range: nsRange)
        }
        
        textField.attributedStringValue = attributedString
    }
}
