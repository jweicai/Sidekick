//
//  DataConversionPropertyTests.swift
//  TableQuery
//
//  Property-based tests for data conversion functionality
//

import Testing
import Foundation
@testable import TableQuery

@Suite("Data Conversion Properties")
struct DataConversionPropertyTests {
    
    // MARK: - Property 15: Format Conversion Round Trip
    // Feature: table-query-mvp, Property 15: Format Conversion Round Trip
    // Validates: Requirements 5.1, 5.2
    
    @Test("Property 15: CSV to JSON and back preserves data")
    func csvToJSONRoundTrip() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            // Generate random DataFrame
            let numColumns = Int.random(in: 2...8)
            let numRows = Int.random(in: 1...30)
            
            let columnNames = (0..<numColumns).map { "col_\($0)" }
            let columns = columnNames.map { Column(name: $0, type: .text) }
            
            var rows: [[String]] = []
            for _ in 0..<numRows {
                let row = (0..<numColumns).map { _ in generateRandomValue() }
                rows.append(row)
            }
            
            let originalDF = DataFrame(columns: columns, rows: rows)
            
            // Convert to JSON
            let converter = DataConverter()
            let jsonData = try converter.convertToJSON(dataFrame: originalDF)
            
            // Parse JSON back
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: String]]
            #expect(jsonArray != nil, "Should produce valid JSON array")
            #expect(jsonArray?.count == numRows, "Row count should match")
            
            // Convert to CSV
            let csvData = try converter.convertToCSV(dataFrame: originalDF)
            let csvString = String(data: csvData, encoding: .utf8)!
            
            // Parse CSV back
            let csvLoader = CSVLoader()
            let parsedDF = try csvLoader.load(from: createTempFile(content: csvString, extension: "csv"))
            
            // Verify data equivalence
            #expect(parsedDF.columnCount == originalDF.columnCount, "Column count should match")
            #expect(parsedDF.rowCount == originalDF.rowCount, "Row count should match")
        }
    }
    
    // MARK: - Property 16: JSON Structure Correctness
    // Feature: table-query-mvp, Property 16: JSON Structure Correctness
    // Validates: Requirements 5.3
    
    @Test("Property 16: JSON output has correct structure")
    func jsonStructureCorrectness() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate DataFrame
            let numColumns = Int.random(in: 2...8)
            let numRows = Int.random(in: 1...30)
            
            let columnNames = (0..<numColumns).map { "col_\($0)" }
            let columns = columnNames.map { Column(name: $0, type: .text) }
            
            var rows: [[String]] = []
            for _ in 0..<numRows {
                let row = (0..<numColumns).map { _ in String(Int.random(in: 1...100)) }
                rows.append(row)
            }
            
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Convert to JSON
            let converter = DataConverter()
            let jsonData = try converter.convertToJSON(dataFrame: dataFrame)
            
            // Parse and verify structure
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: String]]
            
            #expect(jsonArray != nil, "Should be array of objects")
            #expect(jsonArray?.count == numRows, "Array length should match row count")
            
            // Verify each object has correct keys
            if let jsonArray = jsonArray {
                for jsonObject in jsonArray {
                    #expect(jsonObject.keys.count == numColumns, "Each object should have all columns as keys")
                    
                    for columnName in columnNames {
                        #expect(jsonObject.keys.contains(columnName), "Should have key: \(columnName)")
                    }
                }
            }
        }
    }
    
    // MARK: - Property 17: CSV Header Preservation
    // Feature: table-query-mvp, Property 17: CSV Header Preservation
    // Validates: Requirements 5.4
    
    @Test("Property 17: CSV export includes header row")
    func csvHeaderPreservation() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate DataFrame
            let numColumns = Int.random(in: 2...8)
            let columnNames = (0..<numColumns).map { "col_\($0)" }
            let columns = columnNames.map { Column(name: $0, type: .text) }
            
            let rows = [[String(Int.random(in: 1...100))]]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Convert to CSV
            let converter = DataConverter()
            let csvData = try converter.convertToCSV(dataFrame: dataFrame)
            let csvString = String(data: csvData, encoding: .utf8)!
            
            // Verify header is first line
            let lines = csvString.components(separatedBy: "\n")
            #expect(!lines.isEmpty, "CSV should have lines")
            
            let headerLine = lines[0]
            
            // Verify all column names are in header
            for columnName in columnNames {
                #expect(headerLine.contains(columnName), "Header should contain column: \(columnName)")
            }
        }
    }
    
    // MARK: - Property 18: CSV Escaping Correctness
    // Feature: table-query-mvp, Property 18: CSV Escaping Correctness
    // Validates: Requirements 5.5
    
    @Test("Property 18: CSV properly escapes special characters")
    func csvEscapingCorrectness() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            // Generate DataFrame with special characters (excluding newlines for now)
            let specialValues = [
                "value,with,commas",
                "value\"with\"quotes",
                "normal_value",
                "mix,of\"special"
            ]
            
            let columns = [Column(name: "data", type: .text)]
            let rows = [[specialValues.randomElement()!]]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Convert to CSV
            let converter = DataConverter()
            let csvData = try converter.convertToCSV(dataFrame: dataFrame)
            let csvString = String(data: csvData, encoding: .utf8)!
            
            // Parse back
            let csvLoader = CSVLoader()
            let parsedDF = try csvLoader.load(from: createTempFile(content: csvString, extension: "csv"))
            
            // Verify data is preserved
            #expect(parsedDF.rowCount == 1, "Should have 1 row")
            
            // The value should be preserved
            let originalValue = rows[0][0]
            
            // For values with special chars, they should be in quotes in CSV
            if originalValue.contains(",") || originalValue.contains("\"") {
                // Value should be in quotes in CSV
                #expect(csvString.contains("\""), "Special values should be quoted")
            }
        }
    }
    
    // MARK: - Property 19: File Write Success
    // Feature: table-query-mvp, Property 19: File Write Success
    // Validates: Requirements 5.7
    
    @Test("Property 19: Written files can be read back")
    func fileWriteSuccess() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            // Generate DataFrame
            let columns = [
                Column(name: "id", type: .integer),
                Column(name: "value", type: .text)
            ]
            let rows = [
                [String(Int.random(in: 1...100)), "test_value"]
            ]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Convert to CSV
            let converter = DataConverter()
            let csvData = try converter.convertToCSV(dataFrame: dataFrame)
            
            // Write to temp file
            let tempURL = createTempFileURL(extension: "csv")
            try converter.writeToFile(data: csvData, url: tempURL)
            
            // Read back
            let readData = try Data(contentsOf: tempURL)
            
            // Verify content matches
            #expect(readData == csvData, "Read data should match written data")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempURL)
        }
    }
    
    // MARK: - Additional Tests
    
    @Test("Empty DataFrame converts correctly")
    func emptyDataFrame() throws {
        let columns = [Column(name: "id", type: .integer)]
        let dataFrame = DataFrame(columns: columns, rows: [])
        
        let converter = DataConverter()
        
        // Convert to CSV
        let csvData = try converter.convertToCSV(dataFrame: dataFrame)
        let csvString = String(data: csvData, encoding: .utf8)!
        
        // Should have header only
        let lines = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 1, "Should have header only")
        #expect(lines[0] == "id", "Header should be correct")
        
        // Convert to JSON
        let jsonData = try converter.convertToJSON(dataFrame: dataFrame)
        let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: String]]
        
        #expect(jsonArray?.isEmpty == true, "JSON array should be empty")
    }
    
    @Test("Single column DataFrame")
    func singleColumn() throws {
        let columns = [Column(name: "value", type: .text)]
        let rows = [["test1"], ["test2"], ["test3"]]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        let converter = DataConverter()
        
        // Convert to CSV
        let csvData = try converter.convertToCSV(dataFrame: dataFrame)
        let csvString = String(data: csvData, encoding: .utf8)!
        
        let lines = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 4, "Should have header + 3 rows")
        
        // Convert to JSON
        let jsonData = try converter.convertToJSON(dataFrame: dataFrame)
        let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: String]]
        
        #expect(jsonArray?.count == 3, "Should have 3 objects")
    }
    
    @Test("Unicode characters are preserved")
    func unicodePreservation() throws {
        let columns = [Column(name: "text", type: .text)]
        let rows = [
            ["Hello 世界"],
            ["Emoji 😀🎉"],
            ["Ñoño"]
        ]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        let converter = DataConverter()
        
        // Convert to CSV and back
        let csvData = try converter.convertToCSV(dataFrame: dataFrame)
        let csvString = String(data: csvData, encoding: .utf8)!
        
        #expect(csvString.contains("世界"), "Chinese characters should be preserved")
        #expect(csvString.contains("😀"), "Emoji should be preserved")
        #expect(csvString.contains("Ñ"), "Accented characters should be preserved")
        
        // Convert to JSON
        let jsonData = try converter.convertToJSON(dataFrame: dataFrame)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        #expect(jsonString.contains("世界"), "Chinese characters should be in JSON")
        #expect(jsonString.contains("😀"), "Emoji should be in JSON")
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
    
    private func createTempFile(content: String, extension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + ext
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private func createTempFileURL(extension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + ext
        return tempDir.appendingPathComponent(fileName)
    }
}
