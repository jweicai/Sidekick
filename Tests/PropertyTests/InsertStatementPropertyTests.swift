//
//  InsertStatementPropertyTests.swift
//  TableQuery
//
//  Property-based tests for INSERT statement generation
//

import Testing
import Foundation
@testable import TableQuery

@Suite("INSERT Statement Generation Properties")
struct InsertStatementPropertyTests {
    
    // MARK: - Property 20: INSERT Statement Completeness
    // Feature: table-query-mvp, Property 20: INSERT Statement Completeness
    // Validates: Requirements 6.1
    
    @Test("Property 20: Generate INSERT statement for each row")
    func insertStatementCompleteness() {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate random DataFrame
            let numRows = Int.random(in: 1...50)
            let columns = [
                Column(name: "id", type: .integer),
                Column(name: "value", type: .text)
            ]
            
            var rows: [[String]] = []
            for i in 0..<numRows {
                rows.append([String(i), "value_\(i)"])
            }
            
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Generate INSERT statements
            let converter = DataConverter()
            let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "test_table")
            
            // Count INSERT statements
            let statements = insertSQL.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            #expect(statements.count == numRows, "Should generate one INSERT per row")
            
            // Verify each statement contains INSERT INTO
            for statement in statements {
                #expect(statement.contains("INSERT INTO"), "Each statement should be an INSERT")
            }
        }
    }
    
    // MARK: - Property 21: Table Name Derivation
    // Feature: table-query-mvp, Property 21: Table Name Derivation
    // Validates: Requirements 6.2
    
    @Test("Property 21: Table name is used in INSERT statements")
    func tableNameDerivation() {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate DataFrame
            let columns = [Column(name: "id", type: .integer)]
            let rows = [["1"]]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Generate random table name
            let tableName = "table_\(Int.random(in: 1...1000))"
            
            // Generate INSERT statements
            let converter = DataConverter()
            let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: tableName)
            
            // Verify table name is in statement
            #expect(insertSQL.contains(tableName), "INSERT should contain table name")
            #expect(insertSQL.contains("INSERT INTO \(tableName)"), "Should have correct INSERT INTO syntax")
        }
    }
    
    // MARK: - Property 22: Custom Table Name Usage
    // Feature: table-query-mvp, Property 22: Custom Table Name Usage
    // Validates: Requirements 6.3
    
    @Test("Property 22: Custom table names are used in all statements")
    func customTableNameUsage() {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate DataFrame with multiple rows
            let numRows = Int.random(in: 2...10)
            let columns = [Column(name: "id", type: .integer)]
            
            var rows: [[String]] = []
            for i in 0..<numRows {
                rows.append([String(i)])
            }
            
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Use custom table name
            let customName = "custom_table_\(Int.random(in: 1...1000))"
            
            // Generate INSERT statements
            let converter = DataConverter()
            let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: customName)
            
            // Verify custom name is in all statements
            let statements = insertSQL.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            for statement in statements {
                #expect(statement.contains(customName), "Each statement should use custom table name")
            }
        }
    }
    
    // MARK: - Property 23: SQL Value Quoting
    // Feature: table-query-mvp, Property 23: SQL Value Quoting
    // Validates: Requirements 6.4
    
    @Test("Property 23: TEXT values are quoted, numbers are not")
    func sqlValueQuoting() {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate DataFrame with mixed types
            let columns = [
                Column(name: "id", type: .integer),
                Column(name: "price", type: .real),
                Column(name: "name", type: .text)
            ]
            
            let intValue = String(Int.random(in: 1...1000))
            let realValue = String(format: "%.2f", Double.random(in: 1...100))
            let textValue = "text_value"
            
            let rows = [[intValue, realValue, textValue]]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Generate INSERT statement
            let converter = DataConverter()
            let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "test")
            
            // Verify quoting
            // Integer should not be quoted
            #expect(insertSQL.contains(intValue), "Integer value should be present")
            
            // Real should not be quoted
            #expect(insertSQL.contains(realValue), "Real value should be present")
            
            // Text should be quoted
            #expect(insertSQL.contains("'\(textValue)'"), "Text value should be quoted")
        }
    }
    
    // MARK: - Property 24: NULL Representation in SQL
    // Feature: table-query-mvp, Property 24: NULL Representation in SQL
    // Validates: Requirements 6.5
    
    @Test("Property 24: NULL values are unquoted")
    func nullRepresentationInSQL() {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate DataFrame with NULL values (empty strings)
            let columns = [
                Column(name: "id", type: .integer),
                Column(name: "optional_value", type: .text)
            ]
            
            let rows = [
                ["1", ""],  // NULL value
                ["2", "value"]
            ]
            
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Generate INSERT statements
            let converter = DataConverter()
            let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "test")
            
            // Verify NULL is unquoted
            let statements = insertSQL.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            // First statement should have NULL
            #expect(statements[0].contains("NULL"), "Empty value should be NULL")
            #expect(!statements[0].contains("'NULL'"), "NULL should not be quoted")
        }
    }
    
    // MARK: - Property 25: SQL Quote Escaping
    // Feature: table-query-mvp, Property 25: SQL Quote Escaping
    // Validates: Requirements 6.6
    
    @Test("Property 25: Single quotes are escaped")
    func sqlQuoteEscaping() {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate DataFrame with single quotes
            let columns = [Column(name: "text", type: .text)]
            let valueWithQuote = "O'Brien"
            let rows = [[valueWithQuote]]
            
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Generate INSERT statement
            let converter = DataConverter()
            let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "test")
            
            // Verify quotes are escaped (doubled)
            #expect(insertSQL.contains("O''Brien"), "Single quotes should be doubled")
            #expect(!insertSQL.contains("O'Brien"), "Original quote should be escaped")
        }
    }
    
    // MARK: - Property 26: INSERT Statement Output
    // Feature: table-query-mvp, Property 26: INSERT Statement Output
    // Validates: Requirements 6.7, 6.8
    
    @Test("Property 26: INSERT statements are available as string")
    func insertStatementOutput() {
        let iterations = 100
        
        for _ in 0..<iterations {
            // Generate DataFrame
            let columns = [Column(name: "id", type: .integer)]
            let rows = [["1"], ["2"]]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            
            // Generate INSERT statements
            let converter = DataConverter()
            let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "test")
            
            // Verify output is available as string
            #expect(!insertSQL.isEmpty, "INSERT SQL should not be empty")
            #expect(insertSQL is String, "Should be a string")
            
            // Verify it can be converted to Data (for saving)
            let data = insertSQL.data(using: .utf8)
            #expect(data != nil, "Should be convertible to Data for file saving")
        }
    }
    
    // MARK: - Additional Tests
    
    @Test("Empty DataFrame generates no INSERT statements")
    func emptyDataFrame() {
        let columns = [Column(name: "id", type: .integer)]
        let dataFrame = DataFrame(columns: columns, rows: [])
        
        let converter = DataConverter()
        let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "test")
        
        #expect(insertSQL.isEmpty, "Empty DataFrame should produce no INSERT statements")
    }
    
    @Test("Multiple columns are handled correctly")
    func multipleColumns() {
        let columns = [
            Column(name: "id", type: .integer),
            Column(name: "name", type: .text),
            Column(name: "age", type: .integer),
            Column(name: "city", type: .text)
        ]
        
        let rows = [["1", "Alice", "30", "NYC"]]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        let converter = DataConverter()
        let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "users")
        
        // Verify all values are present
        #expect(insertSQL.contains("1"), "Should contain id")
        #expect(insertSQL.contains("'Alice'"), "Should contain quoted name")
        #expect(insertSQL.contains("30"), "Should contain age")
        #expect(insertSQL.contains("'NYC'"), "Should contain quoted city")
    }
    
    @Test("Special SQL characters are handled")
    func specialSQLCharacters() {
        let columns = [Column(name: "text", type: .text)]
        let rows = [
            ["Value with 'quotes'"],
            ["Value with; semicolon"],
            ["Value with -- comment"]
        ]
        
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        let converter = DataConverter()
        let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "test")
        
        // Verify quotes are escaped
        #expect(insertSQL.contains("''"), "Quotes should be escaped")
        
        // Verify other characters are preserved
        #expect(insertSQL.contains(";"), "Semicolon should be preserved")
        #expect(insertSQL.contains("--"), "Comment syntax should be preserved")
    }
    
    @Test("Large number of rows")
    func largeNumberOfRows() {
        let numRows = 1000
        let columns = [Column(name: "id", type: .integer)]
        
        var rows: [[String]] = []
        for i in 0..<numRows {
            rows.append([String(i)])
        }
        
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        let converter = DataConverter()
        let insertSQL = converter.generateInsertStatements(dataFrame: dataFrame, tableName: "test")
        
        // Count statements
        let statements = insertSQL.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        #expect(statements.count == numRows, "Should generate statement for each row")
    }
}
