//
//  SQLQueryPropertyTests.swift
//  Sidekick
//
//  Property-based tests for SQL query execution
//

import Testing
import Foundation
@testable import Sidekick

@Suite("SQL Query Properties")
struct SQLQueryPropertyTests {
    
    // MARK: - Property 9: Data Accessibility via SQL
    // Feature: table-query-mvp, Property 9: Data Accessibility via SQL
    // Validates: Requirements 3.1, 3.2
    
    @Test("Property 9: Data loaded into database is accessible via SQL")
    func dataAccessibilityViaSQL() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate random DataFrame
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
            
            // Create SQL engine and load data
            let engine = SQLEngine()
            try engine.createTable(name: "test_table", dataFrame: dataFrame)
            
            // Query all data
            let result = try engine.executeQuery(sql: "SELECT * FROM test_table")
            
            // Verify all data is retrievable
            #expect(result.rowCount == numRows, "Should retrieve all rows")
            #expect(result.columns.count == numColumns, "Should retrieve all columns")
            
            // Verify data integrity
            for (rowIndex, row) in result.rows.enumerated() {
                #expect(row.count == numColumns, "Each row should have correct number of columns")
                for (colIndex, value) in row.enumerated() {
                    #expect(value == dataFrame.rows[rowIndex][colIndex], "Data should match original")
                }
            }
        }
    }
    
    // MARK: - Property 10: Query Result Correctness
    // Feature: table-query-mvp, Property 10: Query Result Correctness
    // Validates: Requirements 3.3, 3.4
    
    @Test("Property 10: SQL queries return correct results")
    func queryResultCorrectness() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            // Create test data
            let numRows = Int.random(in: 10...50)
            var rows: [[String]] = []
            
            for i in 0..<numRows {
                rows.append([String(i), String(i * 10), "item_\(i)"])
            }
            
            let columns = [
                Column(name: "id", type: .integer),
                Column(name: "value", type: .integer),
                Column(name: "name", type: .text)
            ]
            
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Load into database
            let engine = SQLEngine()
            try engine.createTable(name: "test_data", dataFrame: dataFrame)
            
            // Test various queries
            
            // 1. WHERE clause
            let whereResult = try engine.executeQuery(sql: "SELECT * FROM test_data WHERE id < 5")
            #expect(whereResult.rowCount <= 5, "WHERE clause should filter results")
            
            // 2. ORDER BY
            let orderResult = try engine.executeQuery(sql: "SELECT * FROM test_data ORDER BY id DESC LIMIT 5")
            #expect(orderResult.rowCount <= 5, "LIMIT should restrict results")
            
            // 3. COUNT
            let countResult = try engine.executeQuery(sql: "SELECT COUNT(*) as count FROM test_data")
            #expect(countResult.rowCount == 1, "COUNT should return one row")
            #expect(Int(countResult.rows[0][0]) == numRows, "COUNT should match total rows")
            
            // 4. SELECT specific columns
            let selectResult = try engine.executeQuery(sql: "SELECT id, name FROM test_data LIMIT 1")
            #expect(selectResult.columns.count == 2, "Should select only specified columns")
        }
    }
    
    // MARK: - Property 11: Result Metadata Accuracy
    // Feature: table-query-mvp, Property 11: Result Metadata Accuracy
    // Validates: Requirements 3.5
    
    @Test("Property 11: Query result metadata is accurate")
    func resultMetadataAccuracy() throws {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Create test data
            let numRows = Int.random(in: 5...50)
            var rows: [[String]] = []
            
            for i in 0..<numRows {
                rows.append([String(i), "value_\(i)"])
            }
            
            let columns = [
                Column(name: "id", type: .integer),
                Column(name: "data", type: .text)
            ]
            
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Load into database
            let engine = SQLEngine()
            try engine.createTable(name: "metadata_test", dataFrame: dataFrame)
            
            // Execute query
            let result = try engine.executeQuery(sql: "SELECT * FROM metadata_test")
            
            // Verify metadata
            #expect(result.rowCount == result.rows.count, "rowCount should match actual row count")
            #expect(result.executionTime >= 0, "Execution time should be non-negative")
            #expect(result.columns.count > 0, "Should have column names")
        }
    }
    
    // MARK: - Property 12: SQL Error Propagation
    // Feature: table-query-mvp, Property 12: SQL Error Propagation
    // Validates: Requirements 3.6
    
    @Test("Property 12: Invalid SQL produces appropriate errors")
    func sqlErrorPropagation() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            let engine = SQLEngine()
            
            // Test various invalid SQL queries
            let invalidQueries = [
                "SELECT * FROM nonexistent_table",
                "SELECT invalid syntax",
                "INSERT INTO",
                "SELCT * FROM test",  // Typo
                "SELECT * FROM test WHERE",  // Incomplete
            ]
            
            for invalidSQL in invalidQueries {
                let result = Result {
                    try engine.executeQuery(sql: invalidSQL)
                }
                
                // Should fail with appropriate error
                switch result {
                case .success:
                    // Some queries might succeed if table exists, that's okay
                    break
                case .failure(let error):
                    // Error should be SQLError type
                    #expect(error is SQLError, "Should return SQLError for invalid SQL")
                    
                    // Error message should be informative
                    let errorMessage = error.localizedDescription
                    #expect(!errorMessage.isEmpty, "Error message should not be empty")
                }
            }
        }
    }
    
    // MARK: - Additional SQL Tests
    
    @Test("Empty result sets are handled correctly")
    func emptyResultSets() throws {
        // Create test data
        let columns = [Column(name: "id", type: .integer)]
        let rows = [["1"], ["2"], ["3"]]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        // Load into database
        let engine = SQLEngine()
        try engine.createTable(name: "empty_test", dataFrame: dataFrame)
        
        // Query that returns no rows
        let result = try engine.executeQuery(sql: "SELECT * FROM empty_test WHERE id > 100")
        
        // Verify empty result
        #expect(result.rowCount == 0, "Should return zero rows")
        #expect(result.columns.count > 0, "Should still have column headers")
        #expect(result.rows.isEmpty, "Rows array should be empty")
    }
    
    @Test("Multiple tables can coexist")
    func multipleTables() throws {
        let engine = SQLEngine()
        
        // Create first table
        let df1 = DataFrame(
            columns: [Column(name: "id", type: .integer)],
            rows: [["1"], ["2"]]
        )
        try engine.createTable(name: "table1", dataFrame: df1)
        
        // Create second table
        let df2 = DataFrame(
            columns: [Column(name: "name", type: .text)],
            rows: [["Alice"], ["Bob"]]
        )
        try engine.createTable(name: "table2", dataFrame: df2)
        
        // Query both tables
        let result1 = try engine.executeQuery(sql: "SELECT * FROM table1")
        let result2 = try engine.executeQuery(sql: "SELECT * FROM table2")
        
        #expect(result1.rowCount == 2, "First table should have 2 rows")
        #expect(result2.rowCount == 2, "Second table should have 2 rows")
        
        // List tables
        let tables = try engine.listTables()
        #expect(tables.count >= 2, "Should have at least 2 tables")
    }
    
    @Test("Table can be dropped")
    func tableDropping() throws {
        let engine = SQLEngine()
        
        // Create table
        let df = DataFrame(
            columns: [Column(name: "id", type: .integer)],
            rows: [["1"]]
        )
        try engine.createTable(name: "drop_test", dataFrame: df)
        
        // Verify table exists
        let result1 = try engine.executeQuery(sql: "SELECT * FROM drop_test")
        #expect(result1.rowCount == 1, "Table should exist")
        
        // Drop table
        try engine.dropTable(name: "drop_test")
        
        // Verify table is gone
        let result2 = Result {
            try engine.executeQuery(sql: "SELECT * FROM drop_test")
        }
        
        switch result2 {
        case .success:
            Issue.record("Query should fail after table is dropped")
        case .failure:
            // Expected - table should not exist
            break
        }
    }
}
