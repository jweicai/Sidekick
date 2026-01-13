//
//  FileDropZone.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import SwiftUI
import UniformTypeIdentifiers

/// 文件拖拽区域
struct FileDropZone: View {
    @Binding var droppedFileURL: URL?
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(isTargeted ? .blue : .gray)
                .animation(.easeInOut(duration: 0.2), value: isTargeted)
            
            VStack(spacing: 8) {
                Text("拖拽文件到这里")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("或点击选择文件")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Text("支持 CSV, Excel, JSON, TSV")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            Button(action: selectFile) {
                Text("选择文件")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.blue : Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [10])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ? Color.blue.opacity(0.05) : Color.clear)
                )
        )
        .padding()
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
        
        if panel.runModal() == .OK {
            droppedFileURL = panel.url
        }
    }
}

#Preview {
    FileDropZone(droppedFileURL: .constant(nil))
        .frame(width: 600, height: 400)
}
