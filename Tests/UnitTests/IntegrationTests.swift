//
//  IntegrationTests.swift
//  TableQuery
//
//  Integration tests for UI state transitions and component integration
//

import Testing
import Foundation
@testable import TableQuery

@Suite("Integration Tests")
struct IntegrationTests {
    
    // MARK: - UI State Transition Tests
    
    @Test("Initial state shows file drop zone")
    func initialState() {
        let viewModel = MainViewModel()
        
        #expect(viewModel.loadedTables.isEmpty, "Should have no loaded tables initially")
        #expect(!viewModel.hasLoadedTables, "hasLoadedTables should be false")
        #expect(viewModel.selectedTableId == nil, "No table should be selected")
        #expect(viewModel.errorMessage == nil, "No error message initially")
        #expect(!viewModel.isLoading, "Should not be loading initially")
    }
    
    @Test("Query editor state after loading data")
    func loadedState() {
        let viewModel = MainViewModel()
        let queryViewModel = QueryViewModel()
        
        // Simulate loading a table
        let columns = [
            Column(name: "id", type: .integer),
            Column(name: "name", type: .text)
        ]
        let rows = [["1", "Alice"], ["2", "Bob"]]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        let table = LoadedTable(
            name: "users",
            dataFrame: dataFrame,
            sourceURL: URL(fileURLWithPath: "/tmp/users.csv")
        )
        viewModel.loadedTables.append(table)
        
        // Load into query engine
        queryViewModel.loadTable(name: table.name, dataFrame: dataFrame)
        
        #expect(viewModel.hasLoadedTables, "Should have loaded tables")
        #expect(viewModel.loadedTables.count == 1, "Should have 1 table")
        #expect(queryViewModel.getLoadedTables().contains("users"), "Query engine should have table")
    }
    
    @Test("Result state after query execution")
    func resultState() throws {
        let queryViewModel = QueryViewModel()
        
        // Load test data
        let columns = [
            Column(name: "id", type: .integer),
            Column(name: "value", type: .text)
        ]
        let rows = [["1", "test1"], ["2", "test2"]]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        queryViewModel.loadTable(name: "test", dataFrame: dataFrame)
        
        // Execute query
        queryViewModel.sqlQuery = "SELECT * FROM test"
        queryViewModel.executeQuery()
        
        // Wait for async execution
        Thread.sleep(forTimeInterval: 0.5)
        
        #expect(queryViewModel.queryResult != nil, "Should have query result")
        #expect(queryViewModel.errorMessage == nil, "Should have no error")
        #expect(queryViewModel.queryResult?.rowCount == 2, "Should have 2 rows")
    }
    
    @Test("Error state after invalid query")
    func errorState() throws {
        let queryViewModel = QueryViewModel()
        
        // Execute invalid query
        queryViewModel.sqlQuery = "SELECT * FROM nonexistent_table"
        queryViewModel.executeQuery()
        
        // Wait for async execution
        Thread.sleep(forTimeInterval: 0.5)
        
        #expect(queryViewModel.errorMessage != nil, "Should have error message")
        #expect(queryViewModel.queryResult == nil, "Should have no result")
    }
    
    // MARK: - Component Integration Tests
    
    @Test("MainViewModel and QueryViewModel integration")
    func viewModelIntegration() throws {
        let mainViewModel = MainViewModel()
        let queryViewModel = QueryViewModel()
        
        // Add multiple tables
        for i in 0..<3 {
            let columns = [Column(name: "id", type: .integer)]
            let rows = [[String(i)]]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            let table = LoadedTable(
                name: "table_\(i)",
                dataFrame: dataFrame,
                sourceURL: URL(fileURLWithPath: "/tmp/table_\(i).csv")
            )
            mainViewModel.loadedTables.append(table)
            queryViewModel.loadTable(name: table.name, dataFrame: dataFrame)
        }
        
        #expect(mainViewModel.loadedTables.count == 3, "MainViewModel should have 3 tables")
        #expect(queryViewModel.getLoadedTables().count == 3, "QueryViewModel should have 3 tables")
        
        // Remove a table
        let tableToRemove = mainViewModel.loadedTables[1]
        mainViewModel.removeTable(id: tableToRemove.id)
        queryViewModel.removeTable(name: tableToRemove.name)
        
        #expect(mainViewModel.loadedTables.count == 2, "MainViewModel should have 2 tables")
        #expect(queryViewModel.getLoadedTables().count == 2, "QueryViewModel should have 2 tables")
    }
    
    @Test("Full workflow: Load -> Query -> Export")
    func fullWorkflow() throws {
        let queryViewModel = QueryViewModel()
        let converter = DataConverter()
        
        // 1. Load data
        let columns = [
            Column(name: "id", type: .integer),
            Column(name: "name", type: .text),
            Column(name: "score", type: .real)
        ]
        let rows = [
            ["1", "Alice", "95.5"],
            ["2", "Bob", "87.3"],
            ["3", "Charlie", "92.1"]
        ]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        queryViewModel.loadTable(name: "students", dataFrame: dataFrame)
        
        // 2. Execute query
        queryViewModel.sqlQuery = "SELECT * FROM students WHERE score > 90"
        queryViewModel.executeQuery()
        
        // Wait for async execution
        Thread.sleep(forTimeInterval: 0.5)
        
        #expect(queryViewModel.queryResult != nil, "Should have query result")
        #expect(queryViewModel.queryResult?.rowCount == 2, "Should have 2 rows (Alice and Charlie)")
        
        // 3. Export to CSV
        if let result = queryViewModel.queryResult {
            let resultColumns = result.columns.map { Column(name: $0, type: .text) }
            let resultDataFrame = DataFrame(columns: resultColumns, rows: result.rows)
            
            let csvData = try converter.convertToCSV(dataFrame: resultDataFrame)
            let csvString = String(data: csvData, encoding: .utf8)!
            
            #expect(csvString.contains("id,name,score"), "CSV should have headers")
            #expect(csvString.contains("Alice"), "CSV should contain Alice")
            #expect(csvString.contains("Charlie"), "CSV should contain Charlie")
        }
        
        // 4. Export to JSON
        if let result = queryViewModel.queryResult {
            let resultColumns = result.columns.map { Column(name: $0, type: .text) }
            let resultDataFrame = DataFrame(columns: resultColumns, rows: result.rows)
            
            let jsonData = try converter.convertToJSON(dataFrame: resultDataFrame)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            #expect(jsonString.contains("\"name\""), "JSON should have name key")
            #expect(jsonString.contains("Alice"), "JSON should contain Alice")
        }
        
        // 5. Generate INSERT statements
        if let result = queryViewModel.queryResult {
            let resultColumns = result.columns.map { Column(name: $0, type: .text) }
            let resultDataFrame = DataFrame(columns: resultColumns, rows: result.rows)
            
            let insertSQL = converter.generateInsertStatements(dataFrame: resultDataFrame, tableName: "students")
            
            #expect(insertSQL.contains("INSERT INTO students"), "Should have INSERT statements")
            #expect(insertSQL.contains("Alice"), "Should contain Alice")
        }
    }
    
    @Test("Multi-table query workflow")
    func multiTableQueryWorkflow() throws {
        let queryViewModel = QueryViewModel()
        
        // Load users table
        let usersColumns = [
            Column(name: "id", type: .integer),
            Column(name: "name", type: .text)
        ]
        let usersRows = [["1", "Alice"], ["2", "Bob"]]
        let usersDataFrame = DataFrame(columns: usersColumns, rows: usersRows)
        queryViewModel.loadTable(name: "users", dataFrame: usersDataFrame)
        
        // Load orders table
        let ordersColumns = [
            Column(name: "id", type: .integer),
            Column(name: "user_id", type: .integer),
            Column(name: "amount", type: .real)
        ]
        let ordersRows = [["1", "1", "100.0"], ["2", "1", "200.0"], ["3", "2", "150.0"]]
        let ordersDataFrame = DataFrame(columns: ordersColumns, rows: ordersRows)
        queryViewModel.loadTable(name: "orders", dataFrame: ordersDataFrame)
        
        // Query with JOIN
        queryViewModel.sqlQuery = """
            SELECT users.name, orders.amount 
            FROM users 
            JOIN orders ON users.id = orders.user_id
            """
        queryViewModel.executeQuery()
        
        // Wait for async execution
        Thread.sleep(forTimeInterval: 0.5)
        
        #expect(queryViewModel.queryResult != nil, "Should have query result")
        #expect(queryViewModel.queryResult?.rowCount == 3, "Should have 3 rows")
        #expect(queryViewModel.queryResult?.columns.contains("name") == true, "Should have name column")
        #expect(queryViewModel.queryResult?.columns.contains("amount") == true, "Should have amount column")
    }
    
    @Test("Clear all resets state")
    func clearAllResetsState() {
        let mainViewModel = MainViewModel()
        let queryViewModel = QueryViewModel()
        
        // Add data
        let columns = [Column(name: "id", type: .integer)]
        let rows = [["1"]]
        let dataFrame = DataFrame(columns: columns, rows: rows)
        let table = LoadedTable(
            name: "test",
            dataFrame: dataFrame,
            sourceURL: URL(fileURLWithPath: "/tmp/test.csv")
        )
        mainViewModel.loadedTables.append(table)
        queryViewModel.loadTable(name: "test", dataFrame: dataFrame)
        queryViewModel.sqlQuery = "SELECT * FROM test"
        
        // Clear all
        mainViewModel.clearData()
        queryViewModel.clearAll()
        
        #expect(mainViewModel.loadedTables.isEmpty, "MainViewModel should have no tables")
        #expect(queryViewModel.getLoadedTables().isEmpty, "QueryViewModel should have no tables")
        #expect(queryViewModel.sqlQuery.isEmpty, "SQL query should be empty")
        #expect(queryViewModel.queryResult == nil, "Query result should be nil")
    }
}
