//
//  FileDropZone.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import SwiftUI
import UniformTypeIdentifiers

/// 文件拖拽区域 (macOS 标准样式)
struct FileDropZone: View {
    @Binding var droppedFileURL: URL?
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // 图标
            Image(systemName: isTargeted ? "doc.badge.plus.fill" : "doc.badge.plus")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(isTargeted ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)

            
            // 文字提示
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("拖拽文件到这里")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("或点击下方按钮选择文件")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // 支持格式
            HStack(spacing: DesignSystem.Spacing.md) {
                FormatBadge(icon: "tablecells", label: "CSV")
                FormatBadge(icon: "curlybraces", label: "JSON")
            }
            
            // 选择文件按钮
            Button(action: selectFile) {
                Text("选择文件")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .strokeBorder(
                    isTargeted ? DesignSystem.Colors.accent : DesignSystem.Colors.separator,
                    style: StrokeStyle(lineWidth: 2, dash: [12, 8])
                )
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .fill(isTargeted ? DesignSystem.Colors.accent.opacity(0.05) : Color.clear)
                )
        )
        .padding(DesignSystem.Spacing.xxl)
        .animation(.easeInOut(duration: DesignSystem.Animation.fast), value: isTargeted)
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
            .plainText
        ]
        panel.message = "选择 CSV 或 JSON 数据文件"
        
        if panel.runModal() == .OK {
            droppedFileURL = panel.url
        }
    }
}

/// 格式徽章
struct FormatBadge: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(label)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, 4)
        .background(DesignSystem.Colors.secondaryBackground)
        .foregroundColor(DesignSystem.Colors.textSecondary)
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
}

#Preview {
    FileDropZone(droppedFileURL: .constant(nil))
        .frame(width: 600, height: 400)
}
