//
//  FileLoadingPropertyTests.swift
//  Sidekick
//
//  Property-based tests for file loading functionality
//

import Testing
import Foundation
@testable import Sidekick

@Suite("File Loading Properties")
struct FileLoadingPropertyTests {
    
    // MARK: - Property 1: CSV Parsing Completeness
    // Feature: table-query-mvp, Property 1: CSV Parsing Completeness
    // Validates: Requirements 1.1, 1.3
    
    @Test("Property 1: CSV parsing produces correct DataFrame dimensions")
    func csvParsingCompleteness() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate random CSV data
            let numColumns = Int.random(in: 2...10)
            let numRows = Int.random(in: 1...50)
            
            let columnNames = (0..<numColumns).map { "col_\($0)" }
            var csvLines = [columnNames.joined(separator: ",")]
            
            for _ in 0..<numRows {
                let row = (0..<numColumns).map { _ in generateRandomValue() }
                csvLines.append(row.joined(separator: ","))
            }
            
            let csvContent = csvLines.joined(separator: "\n")
            
            // Parse CSV
            let loader = CSVLoader()
            let dataFrame = try loader.load(from: createTempFile(content: csvContent, extension: "csv"))
            
            // Verify dimensions
            #expect(dataFrame.columnCount == numColumns, "Column count should match")
            #expect(dataFrame.rowCount == numRows, "Row count should match (excluding header)")
            
            // Verify column names
            for (index, expectedName) in columnNames.enumerated() {
                #expect(dataFrame.columns[index].name == expectedName, "Column name should match")
            }
        }
    }
    
    // MARK: - Property 2: JSON Parsing Completeness
    // Feature: table-query-mvp, Property 2: JSON Parsing Completeness
    // Validates: Requirements 1.2, 1.5
    
    @Test("Property 2: JSON parsing produces correct DataFrame dimensions")
    func jsonParsingCompleteness() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate random JSON array
            let numObjects = Int.random(in: 1...50)
            let numKeys = Int.random(in: 2...10)
            
            let keys = (0..<numKeys).map { "key_\($0)" }
            var jsonArray: [[String: Any]] = []
            
            for _ in 0..<numObjects {
                var obj: [String: Any] = [:]
                for key in keys {
                    obj[key] = generateRandomJSONValue()
                }
                jsonArray.append(obj)
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
            
            // Parse JSON
            let loader = JSONLoader()
            let dataFrame = try loader.load(from: createTempFile(data: jsonData, extension: "json"))
            
            // Verify dimensions
            #expect(dataFrame.rowCount == numObjects, "Row count should match array length")
            #expect(dataFrame.columnCount == numKeys, "Column count should match number of keys")
            
            // Verify all keys are present as columns
            let columnNames = Set(dataFrame.columns.map { $0.name })
            for key in keys {
                #expect(columnNames.contains(key), "Column should exist for key: \(key)")
            }
        }
    }
    
    // MARK: - Property 3: Parse Error Handling
    // Feature: table-query-mvp, Property 3: Parse Error Handling
    // Validates: Requirements 1.6
    
    @Test("Property 3: Invalid files produce errors without crashing")
    func parseErrorHandling() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate invalid content
            let invalidContent = generateInvalidContent()
            
            // Try CSV parsing
            let csvLoader = CSVLoader()
            let csvResult = Result {
                try csvLoader.load(from: createTempFile(content: invalidContent, extension: "csv"))
            }
            
            // Should either succeed or fail gracefully (no crash)
            switch csvResult {
            case .success:
                // Valid parse is okay
                break
            case .failure(let error):
                // Error is expected and acceptable
                #expect(error is CSVError || error is CocoaError, "Should return appropriate error type")
            }
            
            // Try JSON parsing
            let jsonLoader = JSONLoader()
            let jsonResult = Result {
                try jsonLoader.load(from: createTempFile(content: invalidContent, extension: "json"))
            }
            
            // Should either succeed or fail gracefully (no crash)
            switch jsonResult {
            case .success:
                // Valid parse is okay
                break
            case .failure(let error):
                // Error is expected and acceptable
                #expect(error is JSONLoaderError || error is CocoaError, "Should return appropriate error type")
            }
        }
    }
    
    // MARK: - Property 4: Metadata Availability
    // Feature: table-query-mvp, Property 4: Metadata Availability
    // Validates: Requirements 1.7, 1.8
    
    @Test("Property 4: Loaded files provide complete metadata")
    func metadataAvailability() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate random CSV
            let numColumns = Int.random(in: 2...10)
            let numRows = Int.random(in: 1...50)
            
            let columnNames = (0..<numColumns).map { "col_\($0)" }
            var csvLines = [columnNames.joined(separator: ",")]
            
            for _ in 0..<numRows {
                let row = (0..<numColumns).map { _ in String(Int.random(in: 1...100)) }
                csvLines.append(row.joined(separator: ","))
            }
            
            let csvContent = csvLines.joined(separator: "\n")
            let tempURL = createTempFile(content: csvContent, extension: "csv")
            
            // Load file
            let loader = CSVLoader()
            let dataFrame = try loader.load(from: tempURL)
            
            // Verify metadata is available
            #expect(dataFrame.rowCount >= 0, "Row count should be accessible")
            #expect(dataFrame.columnCount > 0, "Column count should be accessible")
            #expect(dataFrame.columns.count == numColumns, "Columns array should be accessible")
            
            // Verify column metadata
            for column in dataFrame.columns {
                #expect(!column.name.isEmpty, "Column name should be accessible")
                #expect(column.type != .null, "Column type should be inferred")
            }
            
            // Verify table name can be derived from URL
            let tableName = tempURL.deletingPathExtension().lastPathComponent
            #expect(!tableName.isEmpty, "Table name should be derivable from filename")
        }
    }
    
    // MARK: - Helper Functions
    
    private func generateRandomValue() -> String {
        let types = ["int", "string", "empty"]
        let type = types.randomElement()!
        
        switch type {
        case "int":
            return String(Int.random(in: 1...1000))
        case "string":
            let letters = "abcdefghijklmnopqrstuvwxyz"
            let length = Int.random(in: 3...10)
            return String((0..<length).map { _ in letters.randomElement()! })
        case "empty":
            return ""
        default:
            return "value"
        }
    }
    
    private func generateRandomJSONValue() -> Any {
        let types = ["int", "string", "bool", "null"]
        let type = types.randomElement()!
        
        switch type {
        case "int":
            return Int.random(in: 1...1000)
        case "string":
            let letters = "abcdefghijklmnopqrstuvwxyz"
            let length = Int.random(in: 3...10)
            return String((0..<length).map { _ in letters.randomElement()! })
        case "bool":
            return Bool.random()
        case "null":
            return NSNull()
        default:
            return "value"
        }
    }
    
    private func generateInvalidContent() -> String {
        let invalidTypes = [
            "binary_garbage",
            "empty",
            "special_chars",
            "unclosed_quotes"
        ]
        
        let type = invalidTypes.randomElement()!
        
        switch type {
        case "binary_garbage":
            let bytes = (0..<100).map { _ in UInt8.random(in: 0...255) }
            return String(bytes: bytes, encoding: .utf8) ?? ""
        case "empty":
            return ""
        case "special_chars":
            return "���������������"
        case "unclosed_quotes":
            return "\"unclosed,quote,field\n\"another,\"unclosed"
        default:
            return "invalid"
        }
    }
    
    private func createTempFile(content: String, extension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + ext
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private func createTempFile(data: Data, extension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + ext
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try? data.write(to: fileURL)
        
        return fileURL
    }
}
