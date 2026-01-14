//
//  FileDropZone.swift
//  Sidekick
//
//  Created on 2025-01-12.
//

import SwiftUI
import UniformTypeIdentifiers

/// 文件拖拽区域 - 现代风格
struct FileDropZone: View {
    @Binding var droppedFileURL: URL?
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxl) {
            // 图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.accent.opacity(0.1),
                                DesignSystem.Colors.accent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: isTargeted ? "arrow.down.doc.fill" : "doc.badge.plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(isTargeted ? DesignSystem.Colors.accent : DesignSystem.Colors.accent.opacity(0.7))
            }
            .scaleEffect(isTargeted ? 1.1 : 1.0)
            
            // 文字提示
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("拖拽文件到这里")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("或点击下方按钮选择文件")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // 支持格式
            HStack(spacing: DesignSystem.Spacing.md) {
                FormatBadge(icon: "tablecells", label: "CSV", color: DesignSystem.Colors.success)
                FormatBadge(icon: "curlybraces", label: "JSON", color: DesignSystem.Colors.warning)
            }
            
            // 选择文件按钮
            Button(action: selectFile) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "folder")
                        .font(.system(size: 14))
                    Text("选择文件")
                        .font(DesignSystem.Typography.bodyMedium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accentDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(DesignSystem.CornerRadius.large)
                .shadow(color: DesignSystem.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                .strokeBorder(
                    isTargeted ? DesignSystem.Colors.accent : DesignSystem.Colors.border,
                    style: StrokeStyle(lineWidth: 2, dash: [10, 6])
                )
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                        .fill(isTargeted ? DesignSystem.Colors.accent.opacity(0.03) : Color.white.opacity(0.5))
                )
        )
        .padding(DesignSystem.Spacing.xxxl)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }
    
    /// 处理文件拖拽
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            DispatchQueue.main.async {
                self.droppedFileURL = url
            }
        }
        
        return true
    }
    
    /// 选择文件
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .commaSeparatedText,
            .json,
            .plainText,
            .init(filenameExtension: "xlsx")!,
            .init(filenameExtension: "parquet")!,
            .init(filenameExtension: "md")!,
            .init(filenameExtension: "markdown")!
        ]
        panel.message = "选择数据文件 (CSV, JSON, XLSX, Parquet, Markdown)"
        
        if panel.runModal() == .OK {
            droppedFileURL = panel.url
        }
    }
}

/// 格式徽章
struct FormatBadge: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(label)
                .font(DesignSystem.Typography.captionMedium)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

#Preview {
    FileDropZone(droppedFileURL: .constant(nil))
        .frame(width: 600, height: 400)
}
