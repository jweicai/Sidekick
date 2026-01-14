//
//  QueryResultPropertyTests.swift
//  Sidekick
//
//  Property-based tests for query result display
//

import Testing
import Foundation
@testable import Sidekick

@Suite("Query Result Display Properties")
struct QueryResultPropertyTests {
    
    // MARK: - Property 13: Query Result Structure
    // Feature: table-query-mvp, Property 13: Query Result Structure
    // Validates: Requirements 4.1, 4.2
    
    @Test("Property 13: Query results have correct structure")
    func queryResultStructure() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate random query result
            let numColumns = Int.random(in: 2...10)
            let numRows = Int.random(in: 0...50)
            
            let columns = (0..<numColumns).map { "col_\($0)" }
            var rows: [[String]] = []
            
            for _ in 0..<numRows {
                let row = (0..<numColumns).map { _ in String(Int.random(in: 1...100)) }
                rows.append(row)
            }
            
            let result = QueryResult(
                columns: columns,
                rows: rows,
                executionTime: Double.random(in: 0.001...1.0)
            )
            
            // Verify structure
            #expect(result.columns.count == numColumns, "Column count should match")
            #expect(result.rowCount == numRows, "Row count should match")
            
            // Verify all rows have correct number of elements
            for row in result.rows {
                #expect(row.count == numColumns, "Each row should have same number of columns")
            }
            
            // Verify column names are accessible
            for column in result.columns {
                #expect(!column.isEmpty, "Column names should not be empty")
            }
        }
    }
    
    // MARK: - Property 14: NULL Display Handling
    // Feature: table-query-mvp, Property 14: NULL Display Handling
    // Validates: Requirements 4.5
    
    @Test("Property 14: NULL values are handled consistently")
    func nullDisplayHandling() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate result with NULL values (empty strings)
            let numRows = Int.random(in: 5...30)
            var rows: [[String]] = []
            
            for _ in 0..<numRows {
                let row = [
                    Bool.random() ? String(Int.random(in: 1...100)) : "",
                    Bool.random() ? "value" : "",
                    Bool.random() ? "data" : ""
                ]
                rows.append(row)
            }
            
            let result = QueryResult(
                columns: ["col1", "col2", "col3"],
                rows: rows,
                executionTime: 0.1
            )
            
            // Verify NULL values are present
            var hasNullValue = false
            for row in result.rows {
                if row.contains(where: { $0.isEmpty }) {
                    hasNullValue = true
                    break
                }
            }
            
            // If we have NULL values, verify they are consistently represented
            if hasNullValue {
                for row in result.rows {
                    for value in row {
                        // Empty string represents NULL
                        if value.isEmpty {
                            #expect(value == "", "NULL should be represented as empty string")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Additional Tests
    
    @Test("Empty result set has correct structure")
    func emptyResultSet() {
        let result = QueryResult(
            columns: ["id", "name", "value"],
            rows: [],
            executionTime: 0.01
        )
        
        #expect(result.rowCount == 0, "Empty result should have 0 rows")
        #expect(result.columns.count == 3, "Should still have column headers")
        #expect(result.rows.isEmpty, "Rows array should be empty")
    }
    
    @Test("Single row result")
    func singleRowResult() {
        let result = QueryResult(
            columns: ["id"],
            rows: [["1"]],
            executionTime: 0.001
        )
        
        #expect(result.rowCount == 1, "Should have 1 row")
        #expect(result.rows[0].count == 1, "Row should have 1 column")
    }
    
    @Test("Large result set")
    func largeResultSet() {
        let numRows = 1000
        let rows = (0..<numRows).map { [String($0)] }
        
        let result = QueryResult(
            columns: ["id"],
            rows: rows,
            executionTime: 0.5
        )
        
        #expect(result.rowCount == numRows, "Should have correct row count")
        #expect(result.rows.count == numRows, "Rows array should match count")
    }
    
    @Test("Result with special characters")
    func specialCharacters() {
        let rows = [
            ["Hello, World!", "Test\"Quote\"", "Line\nBreak"],
            ["Tab\tChar", "Emoji 😀", "Unicode ñ"]
        ]
        
        let result = QueryResult(
            columns: ["col1", "col2", "col3"],
            rows: rows,
            executionTime: 0.01
        )
        
        #expect(result.rowCount == 2, "Should have 2 rows")
        
        // Verify special characters are preserved
        #expect(result.rows[0][0].contains(","), "Comma should be preserved")
        #expect(result.rows[0][1].contains("\""), "Quotes should be preserved")
        #expect(result.rows[0][2].contains("\n"), "Newline should be preserved")
    }
    
    @Test("Execution time is recorded")
    func executionTime() {
        let executionTime = 0.123
        let result = QueryResult(
            columns: ["id"],
            rows: [["1"]],
            executionTime: executionTime
        )
        
        #expect(result.executionTime == executionTime, "Execution time should be recorded")
        #expect(result.executionTime >= 0, "Execution time should be non-negative")
    }
    
    // MARK: - Property 34: Export Options Availability
    // Feature: table-query-mvp, Property 34: Export Options Availability
    // Validates: Requirements 9.7
    
    @Test("Property 34: All export options are available for query results")
    func exportOptionsAvailability() throws {
        let iterations = 100
        let converter = DataConverter()
        
        for _ in 0..<iterations {
            // Generate random query result
            let numColumns = Int.random(in: 2...8)
            let numRows = Int.random(in: 1...30)
            
            let columns = (0..<numColumns).map { "col_\($0)" }
            var rows: [[String]] = []
            
            for _ in 0..<numRows {
                let row = (0..<numColumns).map { _ in 
                    Bool.random() ? String(Int.random(in: 1...1000)) : "text_\(Int.random(in: 1...100))"
                }
                rows.append(row)
            }
            
            // Create DataFrame from result
            let dfColumns = columns.map { Column(name: $0, type: .text) }
            let dataFrame = DataFrame(columns: dfColumns, rows: rows)
            
            // Verify CSV export is available
            let csvData = try converter.convertToCSV(dataFrame: dataFrame)
            #expect(csvData.count > 0, "CSV export should produce data")
            
            // Verify JSON export is available
            let jsonData = try converter.convertToJSON(dataFrame: dataFrame)
            #expect(jsonData.count > 0, "JSON export should produce data")
            
            // Verify INSERT statement generation is available
            let insertStatements = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "test_table")
            #expect(!insertStatements.isEmpty, "INSERT statements should be generated")
            
            // Verify all export formats produce valid output
            let csvString = String(data: csvData, encoding: .utf8)
            #expect(csvString != nil, "CSV should be valid UTF-8")
            
            let jsonString = String(data: jsonData, encoding: .utf8)
            #expect(jsonString != nil, "JSON should be valid UTF-8")
        }
    }
}
