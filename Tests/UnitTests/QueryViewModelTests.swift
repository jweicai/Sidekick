//
//  QueryViewModelTests.swift
//  Sidekick
//
//  Unit tests for QueryViewModel
//

import Testing
import Foundation
@testable import Sidekick

@Suite("QueryViewModel Tests")
struct QueryViewModelTests {
    
    @Test("QueryViewModel initializes correctly")
    func initialization() {
        let viewModel = QueryViewModel()
        
        #expect(viewModel.sqlQuery.isEmpty, "SQL query should be empty initially")
        #expect(viewModel.queryResult == nil, "Query result should be nil initially")
        #expect(viewModel.isExecuting == false, "Should not be executing initially")
        #expect(viewModel.errorMessage == nil, "Error message should be nil initially")
    }
    
    @Test("Load table successfully")
    func loadTable() {
        let viewModel = QueryViewModel()
        
        // Create test DataFrame
        let columns = [
            Column(name: "id", type: .integer),
            Column(name: "name", type: .text)
        ]
        let rows = [
            ["1", "Alice"],
            ["2", "Bob"]
        ]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        // Load table
        viewModel.loadTable(name: "users", dataFrame: dataFrame)
        
        // Verify table is loaded
        let loadedTables = viewModel.getLoadedTables()
        #expect(loadedTables.contains("users"), "Table should be loaded")
        
        // Verify DataFrame can be retrieved
        let retrievedDF = viewModel.getDataFrame(for: "users")
        #expect(retrievedDF != nil, "Should be able to retrieve DataFrame")
        #expect(retrievedDF?.rowCount == 2, "Row count should match")
    }
    
    @Test("Execute query successfully")
    func executeQuerySuccess() async {
        let viewModel = QueryViewModel()
        
        // Load test data
        let columns = [Column(name: "id", type: .integer)]
        let rows = [["1"], ["2"], ["3"]]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        viewModel.loadTable(name: "test", dataFrame: dataFrame)
        
        // Set query
        viewModel.sqlQuery = "SELECT * FROM test"
        
        // Execute query
        viewModel.executeQuery()
        
        // Wait for execution to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify result
        #expect(viewModel.queryResult != nil, "Query result should not be nil")
        #expect(viewModel.queryResult?.rowCount == 3, "Should return 3 rows")
        #expect(viewModel.errorMessage == nil, "Should not have error")
    }
    
    @Test("Execute query with error")
    func executeQueryError() async {
        let viewModel = QueryViewModel()
        
        // Set invalid query
        viewModel.sqlQuery = "SELECT * FROM nonexistent_table"
        
        // Execute query
        viewModel.executeQuery()
        
        // Wait for execution to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify error
        #expect(viewModel.queryResult == nil, "Query result should be nil")
        #expect(viewModel.errorMessage != nil, "Should have error message")
    }
    
    @Test("Clear results")
    func clearResults() {
        let viewModel = QueryViewModel()
        
        // Set some state
        viewModel.sqlQuery = "SELECT * FROM test"
        viewModel.errorMessage = "Some error"
        
        // Clear results
        viewModel.clearResults()
        
        // Verify cleared
        #expect(viewModel.queryResult == nil, "Query result should be nil")
        #expect(viewModel.errorMessage == nil, "Error message should be nil")
        #expect(!viewModel.sqlQuery.isEmpty, "SQL query should not be cleared")
    }
    
    @Test("Clear all")
    func clearAll() {
        let viewModel = QueryViewModel()
        
        // Load table and set state
        let df = DataFrame(columns: [Column(name: "id", type: .integer)], rows: [["1"]])
        viewModel.loadTable(name: "test", dataFrame: df)
        viewModel.sqlQuery = "SELECT * FROM test"
        
        // Clear all
        viewModel.clearAll()
        
        // Verify everything is cleared
        #expect(viewModel.sqlQuery.isEmpty, "SQL query should be empty")
        #expect(viewModel.queryResult == nil, "Query result should be nil")
        #expect(viewModel.errorMessage == nil, "Error message should be nil")
        #expect(viewModel.getLoadedTables().isEmpty, "Loaded tables should be empty")
    }
    
    @Test("Remove table")
    func removeTable() {
        let viewModel = QueryViewModel()
        
        // Load table
        let df = DataFrame(columns: [Column(name: "id", type: .integer)], rows: [["1"]])
        viewModel.loadTable(name: "test", dataFrame: df)
        
        // Verify table exists
        #expect(viewModel.getLoadedTables().contains("test"), "Table should exist")
        
        // Remove table
        viewModel.removeTable(name: "test")
        
        // Verify table is removed
        #expect(!viewModel.getLoadedTables().contains("test"), "Table should be removed")
    }
    
    @Test("Export to CSV")
    func exportToCSV() async {
        let viewModel = QueryViewModel()
        
        // Load test data
        let columns = [
            Column(name: "id", type: .integer),
            Column(name: "name", type: .text)
        ]
        let rows = [["1", "Alice"], ["2", "Bob"]]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        viewModel.loadTable(name: "users", dataFrame: dataFrame)
        viewModel.sqlQuery = "SELECT * FROM users"
        viewModel.executeQuery()
        
        // Wait for execution
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Export to CSV
        let csvData = viewModel.exportToCSV()
        
        #expect(csvData != nil, "CSV data should not be nil")
        
        if let csvData = csvData, let csvString = String(data: csvData, encoding: .utf8) {
            #expect(csvString.contains("id,name"), "CSV should contain header")
            #expect(csvString.contains("Alice"), "CSV should contain data")
        }
    }
    
    @Test("Export to JSON")
    func exportToJSON() async {
        let viewModel = QueryViewModel()
        
        // Load test data
        let columns = [Column(name: "id", type: .integer)]
        let rows = [["1"], ["2"]]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        viewModel.loadTable(name: "test", dataFrame: dataFrame)
        viewModel.sqlQuery = "SELECT * FROM test"
        viewModel.executeQuery()
        
        // Wait for execution
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Export to JSON
        let jsonData = viewModel.exportToJSON()
        
        #expect(jsonData != nil, "JSON data should not be nil")
        
        if let jsonData = jsonData {
            let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
            #expect(jsonArray != nil, "Should be valid JSON array")
            #expect(jsonArray?.count == 2, "Should have 2 objects")
        }
    }
    
    @Test("Generate INSERT statements")
    func generateInsertStatements() async {
        let viewModel = QueryViewModel()
        
        // Load test data
        let columns = [Column(name: "id", type: .integer), Column(name: "name", type: .text)]
        let rows = [["1", "Alice"]]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        
        viewModel.loadTable(name: "users", dataFrame: dataFrame)
        viewModel.sqlQuery = "SELECT * FROM users"
        viewModel.executeQuery()
        
        // Wait for execution
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Generate INSERT statements
        let insertSQL = viewModel.generateInsertStatements(tableName: "users")
        
        #expect(insertSQL != nil, "INSERT SQL should not be nil")
        
        if let insertSQL = insertSQL {
            #expect(insertSQL.contains("INSERT INTO users"), "Should contain INSERT statement")
            #expect(insertSQL.contains("Alice"), "Should contain data")
        }
    }
    
    @Test("Empty query shows error")
    func emptyQueryError() {
        let viewModel = QueryViewModel()
        
        // Try to execute empty query
        viewModel.sqlQuery = ""
        viewModel.executeQuery()
        
        // Should show error
        #expect(viewModel.errorMessage != nil, "Should have error for empty query")
    }
    
    @Test("Multiple tables can be loaded")
    func multipleTables() {
        let viewModel = QueryViewModel()
        
        // Load first table
        let df1 = DataFrame(columns: [Column(name: "id", type: .integer)], rows: [["1"]])
        viewModel.loadTable(name: "table1", dataFrame: df1)
        
        // Load second table
        let df2 = DataFrame(columns: [Column(name: "name", type: .text)], rows: [["Alice"]])
        viewModel.loadTable(name: "table2", dataFrame: df2)
        
        // Verify both tables are loaded
        let tables = viewModel.getLoadedTables()
        #expect(tables.count == 2, "Should have 2 tables")
        #expect(tables.contains("table1"), "Should have table1")
        #expect(tables.contains("table2"), "Should have table2")
    }
}
