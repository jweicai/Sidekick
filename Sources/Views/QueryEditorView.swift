//
//  QueryEditorView.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import SwiftUI

/// SQL 查询编辑器视图
struct QueryEditorView: View {
    @ObservedObject var viewModel: QueryViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Query input area
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("SQL 查询")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.executeQuery()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("执行查询")
                        }
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.isExecuting ? Color.gray : Color.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isExecuting)
                    .keyboardShortcut(.return, modifiers: .command)
                    .help("执行 SQL 查询 (⌘+Enter)")
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Text editor for SQL
                TextEditor(text: $viewModel.sqlQuery)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                // Placeholder text when empty
                if viewModel.sqlQuery.isEmpty {
                    Text("输入 SQL 查询，例如: SELECT * FROM table_name")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.top, -100)
                        .allowsHitTesting(false)
                }
            }
            .padding(.bottom, 12)
            
            Divider()
            
            // Results area
            if viewModel.isExecuting {
                LoadingResultsView()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorResultView(message: errorMessage)
            } else if let result = viewModel.queryResult {
                QueryResultView(result: result, viewModel: viewModel)
            } else {
                EmptyResultView()
            }
        }
    }
}

/// 加载结果视图
struct LoadingResultsView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("正在执行查询...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 错误结果视图
struct ErrorResultView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("查询错误")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// 空结果视图
struct EmptyResultView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("准备就绪")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("输入 SQL 查询并点击执行")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 查询结果视图
struct QueryResultView: View {
    let result: QueryResult
    @ObservedObject var viewModel: QueryViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Result info bar
            HStack {
                HStack(spacing: 12) {
                    Text("\(result.rowCount) 行")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.3f 秒", result.executionTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Export buttons
                HStack(spacing: 8) {
                    ExportButton(title: "导出 CSV", icon: "doc.text") {
                        exportCSV()
                    }
                    
                    ExportButton(title: "导出 JSON", icon: "curlybraces") {
                        exportJSON()
                    }
                    
                    ExportButton(title: "生成 INSERT", icon: "text.insert") {
                        generateInsert()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Result table
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        ForEach(Array(result.columns.enumerated()), id: \.offset) { index, column in
                            ResultHeaderCell(text: column)
                        }
                    }
                    
                    // Data rows
                    ForEach(0..<result.rowCount, id: \.self) { rowIndex in
                        HStack(spacing: 0) {
                            ForEach(0..<result.columns.count, id: \.self) { colIndex in
                                ResultDataCell(
                                    text: result.rows[rowIndex][colIndex],
                                    isEvenRow: rowIndex % 2 == 0
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func exportCSV() {
        guard let data = viewModel.exportToCSV() else { return }
        saveFile(data: data, defaultName: "query_result.csv", fileType: "csv")
    }
    
    private func exportJSON() {
        guard let data = viewModel.exportToJSON() else { return }
        saveFile(data: data, defaultName: "query_result.json", fileType: "json")
    }
    
    private func generateInsert() {
        guard let sql = viewModel.generateInsertStatements(tableName: "table_name") else { return }
        guard let data = sql.data(using: .utf8) else { return }
        saveFile(data: data, defaultName: "insert_statements.sql", fileType: "sql")
    }
    
    private func saveFile(data: Data, defaultName: String, fileType: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = [.init(filenameExtension: fileType)!]
        
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
}

/// 导出按钮
struct ExportButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

/// 结果表头单元格
struct ResultHeaderCell: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.primary)
            .frame(width: 150, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(width: 1, height: nil, alignment: .trailing)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .trailing
            )
    }
}

/// 结果数据单元格
struct ResultDataCell: View {
    let text: String
    let isEvenRow: Bool
    
    var body: some View {
        Text(text.isEmpty ? "NULL" : text)
            .font(.system(size: 12))
            .foregroundColor(text.isEmpty ? .secondary : .primary)
            .frame(width: 150, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isEvenRow ? Color.clear : Color.gray.opacity(0.03))
            .overlay(
                Rectangle()
                    .frame(width: 1, height: nil, alignment: .trailing)
                    .foregroundColor(Color.gray.opacity(0.1)),
                alignment: .trailing
            )
    }
}

#Preview {
    QueryEditorView(viewModel: QueryViewModel())
        .frame(width: 800, height: 600)
}
