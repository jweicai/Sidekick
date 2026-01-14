//
//  XLSXLoader.swift
//  Sidekick
//
//  Created on 2025-01-13.
//

import Foundation
import UniformTypeIdentifiers
import CoreXLSX

/// XLSX 文件加载器
class XLSXLoader: FileLoaderProtocol {
    
    var name: String { "XLSX Loader" }
    var version: String { "1.0.0" }
    var supportedTypes: [UTType] { [.spreadsheet] }
    var supportedExtensions: [String] { ["xlsx"] }
    
    func canLoad(url: URL) -> Bool {
        return url.pathExtension.lowercased() == "xlsx"
    }
    
    func load(from url: URL) throws -> DataFrame {
        guard let file = XLSXFile(filepath: url.path) else {
            throw FileLoaderError.parseError(fileName: url.lastPathComponent, details: "无法打开 XLSX 文件")
        }
        
        // 获取第一个工作表
        guard let workbook = try file.parseWorkbooks().first,
              let worksheetInfo = try file.parseWorksheetPathsAndNames(workbook: workbook).first else {
            throw FileLoaderError.parseError(fileName: url.lastPathComponent, details: "XLSX 文件中没有工作表")
        }
        
        let worksheet = try file.parseWorksheet(at: worksheetInfo.path)
        
        // 获取共享字符串（用于解析单元格文本）
        let sharedStrings = try file.parseSharedStrings()
        
        // 解析所有行
        guard let rows = worksheet.data?.rows, !rows.isEmpty else {
            throw FileLoaderError.emptyFile(fileName: url.lastPathComponent)
        }
        
        // 确定最大列数
        let maxColumns = rows.map { $0.cells.count }.max() ?? 0
        
        // 解析第一行
        let firstRow = rows[0]
        var firstRowValues: [String] = []
        for colIndex in 0..<maxColumns {
            if colIndex < firstRow.cells.count {
                let value = getCellValue(cell: firstRow.cells[colIndex], sharedStrings: sharedStrings)
                firstRowValues.append(value)
            } else {
                firstRowValues.append("")
            }
        }
        
        // 检测第一行是否为表头
        let hasHeader = detectHeader(firstRow: firstRowValues, rows: rows, sharedStrings: sharedStrings, maxColumns: maxColumns)
        
        let columnNames: [String]
        let dataStartIndex: Int
        
        if hasHeader {
            // 第一行是列名
            columnNames = firstRowValues.enumerated().map { index, name in
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty ? "Column\(index + 1)" : trimmed
            }
            dataStartIndex = 1
        } else {
            // 第一行就是数据，生成列名
            columnNames = (1...maxColumns).map { "Column\($0)" }
            dataStartIndex = 0
        }
        
        // 解析数据行
        var dataRows: [[String]] = []
        for rowIndex in dataStartIndex..<rows.count {
            let row = rows[rowIndex]
            var rowData: [String] = []
            
            for colIndex in 0..<maxColumns {
                if colIndex < row.cells.count {
                    let value = getCellValue(cell: row.cells[colIndex], sharedStrings: sharedStrings)
                    rowData.append(value)
                } else {
                    rowData.append("")
                }
            }
            
            // 跳过全空行
            if !rowData.allSatisfy({ $0.isEmpty }) {
                dataRows.append(rowData)
            }
        }
        
        // 推断列类型
        let typeInferrer = TypeInferrer()
        var columns: [Column] = []
        
        for (index, name) in columnNames.enumerated() {
            let columnValues = dataRows.map { row in
                index < row.count ? row[index] : ""
            }
            let inferredType = typeInferrer.inferType(from: columnValues)
            columns.append(Column(name: name, type: inferredType))
        }
        
        return DataFrame(columns: columns, rows: dataRows)
    }
    
    /// 获取单元格的值
    private func getCellValue(cell: Cell, sharedStrings: SharedStrings?) -> String {
        // 如果是共享字符串引用
        if cell.type == .sharedString,
           let sharedStrings = sharedStrings,
           let index = cell.value.flatMap({ Int($0) }),
           index < sharedStrings.items.count {
            return sharedStrings.items[index].text ?? ""
        }
        
        // 直接返回值
        return cell.value ?? ""
    }
    
    /// 检测第一行是否为表头
    private func detectHeader(firstRow: [String], rows: [Row], sharedStrings: SharedStrings?, maxColumns: Int) -> Bool {
        // 如果第一行有任何非数值的字段，认为是表头
        let hasNonNumeric = firstRow.contains { field in
            let trimmed = field.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && Double(trimmed) == nil
        }
        
        if hasNonNumeric {
            return true
        }
        
        // 如果第一行全是数值，检查第二行
        guard rows.count > 1 else {
            return true // 只有一行，假设是表头
        }
        
        // 解析第二行
        let secondRow = rows[1]
        var secondRowValues: [String] = []
        for colIndex in 0..<maxColumns {
            if colIndex < secondRow.cells.count {
                let value = getCellValue(cell: secondRow.cells[colIndex], sharedStrings: sharedStrings)
                secondRowValues.append(value)
            } else {
                secondRowValues.append("")
            }
        }
        
        // 如果第二行也全是数值，假设第一行是数据
        let secondRowAllNumeric = secondRowValues.allSatisfy { field in
            let trimmed = field.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty || Double(trimmed) != nil
        }
        
        return !secondRowAllNumeric
    }
}
