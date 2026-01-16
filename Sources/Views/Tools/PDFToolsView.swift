//
//  PDFToolsView.swift
//  Sidekick
//
//  Created on 2025-01-15.
//

import SwiftUI
import PDFKit

// MARK: - PDF 转文本视图

struct PDFToTextView: View {
    @State private var pdfDocument: PDFDocument?
    @State private var extractedText: String = ""
    @State private var fileName: String = ""
    @State private var pageCount: Int = 0
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PDF 转文本")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("提取 PDF 文件中的文本内容")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if !extractedText.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Text("\(pageCount) 页")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textMuted)
                        
                        Button(action: copyText) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                Text("复制")
                                    .font(DesignSystem.Typography.caption)
                            }
                            .foregroundColor(DesignSystem.Colors.accent)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, 6)
                            .background(DesignSystem.Colors.accent.opacity(0.1))
                            .cornerRadius(DesignSystem.CornerRadius.small)
                        }
                        .buttonStyle(.plain)
                        
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
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            if pdfDocument == nil {
                // 拖放区域
                dropZone
            } else {
                // 显示提取的文本
                HSplitView {
                    // 左侧：PDF 预览
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 11))
                                .foregroundColor(DesignSystem.Colors.accent)
                            Text(fileName)
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.tableHeader)
                        
                        if let doc = pdfDocument {
                            PDFKitView(document: doc)
                        }
                    }
                    .frame(minWidth: 300)
                    
                    // 右侧：提取的文本
                    VStack(spacing: 0) {
                        HStack {
                            Text("提取的文本")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Spacer()
                            Text("\(extractedText.count) 字符")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textMuted)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.tableHeader)
                        
                        ScrollView {
                            Text(extractedText)
                                .font(.system(size: 13, design: .default))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(DesignSystem.Spacing.md)
                        }
                    }
                    .frame(minWidth: 300)
                }
            }
        }
    }
    
    private var dropZone: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                Text("正在提取文本...")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            } else if let error = errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.Colors.warning)
                Text(error)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Button("重试") {
                    errorMessage = nil
                }
                .buttonStyle(.plain)
                .foregroundColor(DesignSystem.Colors.accent)
            } else {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 48))
                    .foregroundColor(isDragging ? DesignSystem.Colors.accent : DesignSystem.Colors.textMuted)
                
                Text("拖放 PDF 文件到这里")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("或")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textMuted)
                
                Button(action: selectFile) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                        Text("选择文件")
                            .font(DesignSystem.Typography.captionMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.accent)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .strokeBorder(
                    isDragging ? DesignSystem.Colors.accent : Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .background(isDragging ? DesignSystem.Colors.accent.opacity(0.05) : Color.clear)
        )
        .padding(DesignSystem.Spacing.lg)
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]
        
        if panel.runModal() == .OK, let url = panel.url {
            loadPDF(from: url)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            DispatchQueue.main.async {
                loadPDF(from: url)
            }
        }
        
        return true
    }
    
    private func loadPDF(from url: URL) {
        guard url.pathExtension.lowercased() == "pdf" else {
            errorMessage = "请选择 PDF 文件"
            return
        }
        
        isLoading = true
        errorMessage = nil
        fileName = url.lastPathComponent
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let document = PDFDocument(url: url) else {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "无法打开 PDF 文件"
                }
                return
            }
            
            let text = extractText(from: document)
            let pages = document.pageCount
            
            DispatchQueue.main.async {
                pdfDocument = document
                extractedText = text
                pageCount = pages
                isLoading = false
            }
        }
    }
    
    private func extractText(from document: PDFDocument) -> String {
        var text = ""
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                if let pageText = page.string {
                    if !text.isEmpty {
                        text += "\n\n--- 第 \(i + 1) 页 ---\n\n"
                    }
                    text += pageText
                }
            }
        }
        
        return text
    }
    
    private func copyText() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(extractedText, forType: .string)
    }
    
    private func clearAll() {
        pdfDocument = nil
        extractedText = ""
        fileName = ""
        pageCount = 0
        errorMessage = nil
    }
}

// MARK: - PDFKit View

struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}
