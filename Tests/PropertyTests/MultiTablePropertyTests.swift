//
//  MultiTablePropertyTests.swift
//  TableQuery
//
//  Property-based tests for multi-table management
//

import Testing
import Foundation
@testable import TableQuery

@Suite("Multi-Table Management Properties")
struct MultiTablePropertyTests {
    
    // MARK: - Property 27: Table Registration
    // Feature: table-query-mvp, Property 27: Table Registration
    // Validates: Requirements 7.1, 7.2
    
    @Test("Property 27: Multiple tables can be loaded and queried via SQL")
    func tableRegistration() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            let sqlEngine = SQLEngine()
            try sqlEngine.createDatabase()
            
            // Generate random number of tables
            let numTables = Int.random(in: 2...5)
            var tableNames: [String] = []
            var tableRowCounts: [String: Int] = [:]
            
            for i in 0..<numTables {
                let tableName = "table_\(i)"
                let numRows = Int.random(in: 1...20)
                let numCols = Int.random(in: 2...5)
                
                // Create DataFrame
                let columns = (0..<numCols).map { Column(name: "col_\($0)", type: .text) }
                let rows = (0..<numRows).map { row in
                    (0..<numCols).map { col in "value_\(row)_\(col)" }
                }
                let dataFrame = DataFrame(columns: columns, rows: rows)
                
                // Load table
                try sqlEngine.createTable(name: tableName, dataFrame: dataFrame)
                tableNames.append(tableName)
                tableRowCounts[tableName] = numRows
            }
            
            // Verify all tables are queryable
            for tableName in tableNames {
                let result = try sqlEngine.executeQuery(sql: "SELECT * FROM \(tableName)")
                #expect(result.rowCount == tableRowCounts[tableName], "Table \(tableName) should have correct row count")
            }
            
            sqlEngine.closeDatabase()
        }
    }
    
    // MARK: - Property 28: Schema Information Availability
    // Feature: table-query-mvp, Property 28: Schema Information Availability
    // Validates: Requirements 7.3
    
    @Test("Property 28: Schema information is accessible for all tables")
    func schemaAvailability() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            let viewModel = MainViewModel()
            
            // Generate random tables
            let numTables = Int.random(in: 2...4)
            
            for i in 0..<numTables {
                let numCols = Int.random(in: 2...6)
                let numRows = Int.random(in: 1...10)
                
                // Create DataFrame with mixed types
                var columns: [Column] = []
                var rows: [[String]] = []
                
                for c in 0..<numCols {
                    let type: ColumnType = [.integer, .real, .text, .boolean].randomElement()!
                    columns.append(Column(name: "col_\(c)", type: type))
                }
                
                for _ in 0..<numRows {
                    let row = columns.map { col -> String in
                        switch col.type {
                        case .integer: return String(Int.random(in: 1...100))
                        case .real: return String(Double.random(in: 1.0...100.0))
                        case .text: return "text_\(Int.random(in: 1...100))"
                        case .boolean: return Bool.random() ? "true" : "false"
                        case .date: return "2025-01-13"
                        case .null: return ""
                        }
                    }
                    rows.append(row)
                }
                
                let dataFrame = DataFrame(columns: columns, rows: rows)
                let table = LoadedTable(
                    name: "table_\(i)",
                    displayName: "table_\(i).csv",
                    dataFrame: dataFrame,
                    sourceURL: URL(fileURLWithPath: "/tmp/table_\(i).csv"),
                    isTruncated: false,
                    originalRowCount: nil
                )
                viewModel.loadedTables.append(table)
            }
            
            // Verify schema info is accessible for all tables
            for table in viewModel.loadedTables {
                #expect(!table.name.isEmpty, "Table name should be available")
                #expect(table.rowCount >= 0, "Row count should be available")
                #expect(table.columnCount > 0, "Column count should be available")
                #expect(table.columnNames.count == table.columnCount, "Column names should be available")
                #expect(table.columnTypes.count == table.columnCount, "Column types should be available")
                
                // Verify column details
                for (index, colName) in table.columnNames.enumerated() {
                    #expect(!colName.isEmpty, "Column name should not be empty")
                    // Column type is always available (non-optional)
                    let _ = table.columnTypes[index]
                }
            }
        }
    }
    
    // MARK: - Property 29: Table Removal Completeness
    // Feature: table-query-mvp, Property 29: Table Removal Completeness
    // Validates: Requirements 7.4, 7.5
    
    @Test("Property 29: Removed tables are gone from database and list")
    func tableRemoval() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            let sqlEngine = SQLEngine()
            try sqlEngine.createDatabase()
            
            // Create multiple tables
            let numTables = Int.random(in: 3...6)
            var tableNames: [String] = []
            
            for i in 0..<numTables {
                let tableName = "table_\(i)"
                let columns = [Column(name: "id", type: .integer), Column(name: "value", type: .text)]
                let rows = [[String(i), "value_\(i)"]]
                let dataFrame = DataFrame(columns: columns, rows: rows)
                
                try sqlEngine.createTable(name: tableName, dataFrame: dataFrame)
                tableNames.append(tableName)
            }
            
            // Remove a random table
            let tableToRemove = tableNames.randomElement()!
            try sqlEngine.dropTable(name: tableToRemove)
            tableNames.removeAll { $0 == tableToRemove }
            
            // Verify removed table is not queryable
            do {
                _ = try sqlEngine.executeQuery(sql: "SELECT * FROM \(tableToRemove)")
                Issue.record("Query on removed table should fail")
            } catch {
                // Expected - table should not exist
                #expect(true, "Query on removed table should fail")
            }
            
            // Verify other tables still work
            for tableName in tableNames {
                let result = try sqlEngine.executeQuery(sql: "SELECT * FROM \(tableName)")
                #expect(result.rowCount >= 0, "Other tables should still be queryable")
            }
            
            sqlEngine.closeDatabase()
        }
    }
    
    // MARK: - Additional Tests
    
    @Test("MainViewModel tracks multiple tables correctly")
    func mainViewModelMultipleTables() {
        let viewModel = MainViewModel()
        
        // Add multiple tables
        for i in 0..<3 {
            let columns = [Column(name: "id", type: .integer)]
            let rows = [[String(i)]]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            let table = LoadedTable(
                name: "table_\(i)",
                displayName: "table_\(i).csv",
                dataFrame: dataFrame,
                sourceURL: URL(fileURLWithPath: "/tmp/table_\(i).csv"),
                isTruncated: false,
                originalRowCount: nil
            )
            viewModel.loadedTables.append(table)
        }
        
        #expect(viewModel.loadedTables.count == 3, "Should have 3 tables")
        #expect(viewModel.hasLoadedTables, "Should have loaded tables")
        #expect(viewModel.getTableNames().count == 3, "Should return 3 table names")
    }
    
    @Test("Table selection works correctly")
    func tableSelection() {
        let viewModel = MainViewModel()
        
        // Add tables
        var tableIds: [UUID] = []
        for i in 0..<3 {
            let columns = [Column(name: "id", type: .integer)]
            let rows = [[String(i)]]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            let table = LoadedTable(
                name: "table_\(i)",
                displayName: "table_\(i).csv",
                dataFrame: dataFrame,
                sourceURL: URL(fileURLWithPath: "/tmp/table_\(i).csv"),
                isTruncated: false,
                originalRowCount: nil
            )
            viewModel.loadedTables.append(table)
            tableIds.append(table.id)
        }
        
        // Select second table
        viewModel.selectTable(id: tableIds[1])
        #expect(viewModel.selectedTableId == tableIds[1], "Should select correct table")
        #expect(viewModel.selectedTable?.name == "table_1", "Selected table should be table_1")
    }
    
    @Test("Table removal updates selection")
    func tableRemovalUpdatesSelection() {
        let viewModel = MainViewModel()
        
        // Add tables
        var tableIds: [UUID] = []
        for i in 0..<3 {
            let columns = [Column(name: "id", type: .integer)]
            let rows = [[String(i)]]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            let table = LoadedTable(
                name: "table_\(i)",
                displayName: "table_\(i).csv",
                dataFrame: dataFrame,
                sourceURL: URL(fileURLWithPath: "/tmp/table_\(i).csv"),
                isTruncated: false,
                originalRowCount: nil
            )
            viewModel.loadedTables.append(table)
            tableIds.append(table.id)
        }
        
        // Select and remove second table
        viewModel.selectTable(id: tableIds[1])
        viewModel.removeTable(id: tableIds[1])
        
        #expect(viewModel.loadedTables.count == 2, "Should have 2 tables after removal")
        #expect(viewModel.selectedTableId != tableIds[1], "Selection should change after removal")
    }
    
    @Test("Clear data removes all tables")
    func clearDataRemovesAllTables() {
        let viewModel = MainViewModel()
        
        // Add tables
        for i in 0..<3 {
            let columns = [Column(name: "id", type: .integer)]
            let rows = [[String(i)]]
            let dataFrame = DataFrame(columns: columns, rows: rows)
            let table = LoadedTable(
                name: "table_\(i)",
                displayName: "table_\(i).csv",
                dataFrame: dataFrame,
                sourceURL: URL(fileURLWithPath: "/tmp/table_\(i).csv"),
                isTruncated: false,
                originalRowCount: nil
            )
            viewModel.loadedTables.append(table)
        }
        
        viewModel.clearData()
        
        #expect(viewModel.loadedTables.isEmpty, "All tables should be removed")
        #expect(!viewModel.hasLoadedTables, "Should have no loaded tables")
        #expect(viewModel.selectedTableId == nil, "Selection should be nil")
    }
}
