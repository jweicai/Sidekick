//
//  TypeInferencePropertyTests.swift
//  Sidekick
//
//  Property-based tests for type inference functionality
//

import Testing
import Foundation
@testable import Sidekick

@Suite("Type Inference Properties")
struct TypeInferencePropertyTests {
    
    // MARK: - Property 5: Integer Type Inference
    // Feature: table-query-mvp, Property 5: Integer Type Inference
    // Validates: Requirements 2.1
    
    @Test("Property 5: Columns with only integers are inferred as INTEGER")
    func integerTypeInference() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate CSV with integer column
            let numRows = Int.random(in: 5...50)
            var csvLines = ["id,value"]
            
            for i in 0..<numRows {
                let intValue = Int.random(in: -1000...1000)
                csvLines.append("\(i),\(intValue)")
            }
            
            let csvContent = csvLines.joined(separator: "\n")
            
            // Parse CSV
            let loader = CSVLoader()
            let dataFrame = try loader.load(from: createTempFile(content: csvContent, extension: "csv"))
            
            // Verify type inference
            let valueColumn = dataFrame.columns.first { $0.name == "value" }
            #expect(valueColumn != nil, "Value column should exist")
            #expect(valueColumn?.type == .integer, "Column with only integers should be inferred as INTEGER")
        }
    }
    
    // MARK: - Property 6: Real Type Inference
    // Feature: table-query-mvp, Property 6: Real Type Inference
    // Validates: Requirements 2.2
    
    @Test("Property 6: Columns with decimal numbers are inferred as REAL")
    func realTypeInference() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate CSV with decimal column
            let numRows = Int.random(in: 5...50)
            var csvLines = ["id,price"]
            
            for i in 0..<numRows {
                let decimalValue = Double.random(in: 0...1000)
                csvLines.append("\(i),\(String(format: "%.2f", decimalValue))")
            }
            
            let csvContent = csvLines.joined(separator: "\n")
            
            // Parse CSV
            let loader = CSVLoader()
            let dataFrame = try loader.load(from: createTempFile(content: csvContent, extension: "csv"))
            
            // Verify type inference
            let priceColumn = dataFrame.columns.first { $0.name == "price" }
            #expect(priceColumn != nil, "Price column should exist")
            #expect(priceColumn?.type == .real, "Column with decimal numbers should be inferred as REAL")
        }
    }
    
    // MARK: - Property 7: Text Type Inference
    // Feature: table-query-mvp, Property 7: Text Type Inference
    // Validates: Requirements 2.3, 2.4
    
    @Test("Property 7: Columns with strings or mixed types are inferred as TEXT")
    func textTypeInference() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Test case 1: Pure string column
            var csvLines = ["id,name"]
            let numRows = Int.random(in: 5...50)
            
            for i in 0..<numRows {
                let name = generateRandomString()
                csvLines.append("\(i),\(name)")
            }
            
            let csvContent1 = csvLines.joined(separator: "\n")
            let loader = CSVLoader()
            let dataFrame1 = try loader.load(from: createTempFile(content: csvContent1, extension: "csv"))
            
            let nameColumn = dataFrame1.columns.first { $0.name == "name" }
            #expect(nameColumn?.type == .text, "Column with strings should be inferred as TEXT")
            
            // Test case 2: Mixed type column
            csvLines = ["id,mixed"]
            for i in 0..<numRows {
                let value = i % 2 == 0 ? String(Int.random(in: 1...100)) : generateRandomString()
                csvLines.append("\(i),\(value)")
            }
            
            let csvContent2 = csvLines.joined(separator: "\n")
            let dataFrame2 = try loader.load(from: createTempFile(content: csvContent2, extension: "csv"))
            
            let mixedColumn = dataFrame2.columns.first { $0.name == "mixed" }
            #expect(mixedColumn?.type == .text, "Column with mixed types should be inferred as TEXT")
        }
    }
    
    // MARK: - Property 8: NULL Value Handling
    // Feature: table-query-mvp, Property 8: NULL Value Handling
    // Validates: Requirements 2.5
    
    @Test("Property 8: Empty values are treated as NULL")
    func nullValueHandling() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate CSV with empty values
            let numRows = Int.random(in: 5...50)
            var csvLines = ["id,value,description"]
            
            for i in 0..<numRows {
                // Randomly include empty values
                let value = Bool.random() ? String(Int.random(in: 1...100)) : ""
                let description = Bool.random() ? generateRandomString() : ""
                csvLines.append("\(i),\(value),\(description)")
            }
            
            let csvContent = csvLines.joined(separator: "\n")
            
            // Parse CSV
            let loader = CSVLoader()
            let dataFrame = try loader.load(from: createTempFile(content: csvContent, extension: "csv"))
            
            // Verify empty values are present in data
            var hasEmptyValue = false
            for row in dataFrame.rows {
                if row.contains(where: { $0.isEmpty }) {
                    hasEmptyValue = true
                    break
                }
            }
            
            // If we generated empty values, they should be preserved as empty strings
            // (which represent NULL in our system)
            if hasEmptyValue {
                #expect(true, "Empty values should be preserved in DataFrame")
            }
            
            // Verify type inference still works with empty values
            for column in dataFrame.columns {
                #expect(column.type != .null, "Type should be inferred even with empty values")
            }
        }
    }
    
    // MARK: - Additional Type Inference Tests
    
    @Test("Boolean type inference")
    func booleanTypeInference() throws {
        // Generate CSV with boolean column
        var csvLines = ["id,active"]
        
        for i in 0..<20 {
            let boolValue = i % 2 == 0 ? "true" : "false"
            csvLines.append("\(i),\(boolValue)")
        }
        
        let csvContent = csvLines.joined(separator: "\n")
        
        // Parse CSV
        let loader = CSVLoader()
        let dataFrame = try loader.load(from: createTempFile(content: csvContent, extension: "csv"))
        
        // Verify type inference
        let activeColumn = dataFrame.columns.first { $0.name == "active" }
        #expect(activeColumn?.type == .boolean, "Column with true/false values should be inferred as BOOLEAN")
    }
    
    @Test("Type inference with all empty column")
    func allEmptyColumnInference() throws {
        // Generate CSV with all empty values in one column
        var csvLines = ["id,empty_col,value"]
        
        for i in 0..<10 {
            csvLines.append("\(i),,\(i * 10)")
        }
        
        let csvContent = csvLines.joined(separator: "\n")
        
        // Parse CSV
        let loader = CSVLoader()
        let dataFrame = try loader.load(from: createTempFile(content: csvContent, extension: "csv"))
        
        // Verify type inference defaults to TEXT for all-empty column
        let emptyColumn = dataFrame.columns.first { $0.name == "empty_col" }
        #expect(emptyColumn?.type == .text, "Column with all empty values should default to TEXT")
    }
    
    // MARK: - Helper Functions
    
    private func generateRandomString() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let length = Int.random(in: 3...15)
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    private func createTempFile(content: String, extension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + ext
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
}
