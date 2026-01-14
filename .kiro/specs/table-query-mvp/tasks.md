# Implementation Plan: Sidekick MVP

## Overview

This implementation plan breaks down the Sidekick MVP into discrete coding tasks. The plan follows an incremental approach: build core functionality first, add SQL query capabilities, then add conversion features. Each task includes property-based tests to validate correctness.

## Tasks

- [x] 1. Enhance File Loading System
  - Improve CSV parser to handle edge cases
  - Improve JSON parser to handle JSONL format
  - Add comprehensive error handling
  - _Requirements: 1.1, 1.2, 1.3, 1.5, 1.6_

- [x] 1.1 Write property test for CSV parsing
  - **Property 1: CSV Parsing Completeness**
  - **Validates: Requirements 1.1, 1.3**
  - Generate random CSV files with varying structures
  - Verify DataFrame has correct dimensions (N-1 rows, M columns)

- [x] 1.2 Write property test for JSON parsing
  - **Property 2: JSON Parsing Completeness**
  - **Validates: Requirements 1.2, 1.5**
  - Generate random JSON arrays of objects
  - Verify DataFrame dimensions match input

- [x] 1.3 Write property test for parse error handling
  - **Property 3: Parse Error Handling**
  - **Validates: Requirements 1.6**
  - Generate invalid/corrupted file content
  - Verify errors are returned without crashes

- [x] 1.4 Write property test for metadata availability
  - **Property 4: Metadata Availability**
  - **Validates: Requirements 1.7, 1.8**
  - Verify table name, counts, column names, and types are accessible

- [x] 2. Implement Type Inference System
  - Enhance type inference algorithm in CSVLoader
  - Add support for detecting REAL, BOOLEAN types
  - Handle NULL values correctly
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 2.1 Write property test for integer type inference
  - **Property 5: Integer Type Inference**
  - **Validates: Requirements 2.1**
  - Generate columns with only integer values
  - Verify INTEGER type is inferred

- [x] 2.2 Write property test for real type inference
  - **Property 6: Real Type Inference**
  - **Validates: Requirements 2.2**
  - Generate columns with decimal numbers
  - Verify REAL type is inferred

- [x] 2.3 Write property test for text type inference
  - **Property 7: Text Type Inference**
  - **Validates: Requirements 2.3, 2.4**
  - Generate columns with strings or mixed types
  - Verify TEXT type is inferred

- [x] 2.4 Write property test for NULL handling
  - **Property 8: NULL Value Handling**
  - **Validates: Requirements 2.5**
  - Generate data with empty values
  - Verify they are treated as NULL

- [x] 3. Build SQL Query Engine
  - Create SQLEngine class with SQLite integration
  - Implement database creation (in-memory)
  - Implement table creation from DataFrame
  - Implement query execution
  - Add error handling for SQL errors
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 3.1 Create SQLEngine class structure
  - Define SQLEngine class with SQLite database handle
  - Implement createDatabase() method
  - Implement closeDatabase() method
  - Add proper resource cleanup

- [x] 3.2 Implement table creation from DataFrame
  - Implement createTable(name:dataFrame:) method
  - Generate CREATE TABLE SQL with correct types
  - Insert all rows from DataFrame
  - Handle SQL escaping for values

- [x] 3.3 Implement query execution
  - Implement executeQuery(sql:) method
  - Prepare and execute SQL statements
  - Extract column names from result
  - Fetch all result rows
  - Measure execution time
  - Return QueryResult object

- [x] 3.4 Write property test for data accessibility via SQL
  - **Property 9: Data Accessibility via SQL**
  - **Validates: Requirements 3.1, 3.2**
  - Load random DataFrames into database
  - Execute SELECT * queries
  - Verify all data is retrievable

- [x] 3.5 Write property test for query result correctness
  - **Property 10: Query Result Correctness**
  - **Validates: Requirements 3.3, 3.4**
  - Generate random valid SQL queries
  - Verify results match SQLite's output

- [x] 3.6 Write property test for result metadata
  - **Property 11: Result Metadata Accuracy**
  - **Validates: Requirements 3.5**
  - Verify rowCount matches actual row count

- [x] 3.7 Write property test for SQL error propagation
  - **Property 12: SQL Error Propagation**
  - **Validates: Requirements 3.6**
  - Generate invalid SQL queries
  - Verify errors are returned without crashes

- [x] 4. Create QueryViewModel
  - Create QueryViewModel class
  - Add SQL query state management
  - Integrate with SQLEngine
  - Handle query execution and results
  - _Requirements: 3.3, 3.4, 3.5_

- [x] 4.1 Implement QueryViewModel structure
  - Define @Published properties for query state
  - Add sqlQuery, queryResult, isExecuting, errorMessage
  - Create SQLEngine instance

- [x] 4.2 Implement executeQuery() method
  - Load DataFrame into SQLEngine
  - Execute SQL query
  - Update queryResult on success
  - Update errorMessage on failure
  - Handle loading states

- [x] 4.3 Write unit tests for QueryViewModel
  - Test successful query execution
  - Test error handling
  - Test state transitions

- [x] 5. Build Query Editor UI
  - Create QueryEditorView component
  - Add SQL text editor
  - Add execute button
  - Display query results
  - Show execution time and row count
  - _Requirements: 3.4, 3.5, 4.1, 4.2, 4.5, 9.5, 9.6_

- [x] 5.1 Create QueryEditorView structure
  - Create SwiftUI view with text editor
  - Add TextEditor for SQL input
  - Add "Execute Query" button
  - Bind to QueryViewModel

- [x] 5.2 Implement result display
  - Show QueryResult in DataTableView
  - Display row count and execution time
  - Handle NULL values in display
  - Show error messages when queries fail

- [x] 5.3 Write property test for query result structure
  - **Property 13: Query Result Structure**
  - **Validates: Requirements 4.1, 4.2**
  - Verify column headers match column names
  - Verify all rows have correct number of elements

- [x] 5.4 Write property test for NULL display
  - **Property 14: NULL Display Handling**
  - **Validates: Requirements 4.5**
  - Generate results with NULL values
  - Verify consistent NULL representation

- [x] 6. Checkpoint - Ensure SQL query functionality works
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implement Data Conversion System
  - Create DataConverter class
  - Implement CSV export
  - Implement JSON export
  - Handle special character escaping
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.7_

- [x] 7.1 Create DataConverter class
  - Define DataConverter class structure
  - Add convertToJSON(dataFrame:) method
  - Add convertToCSV(dataFrame:) method
  - Add file writing utilities

- [x] 7.2 Implement JSON export
  - Convert DataFrame to array of objects
  - Use column names as JSON keys
  - Serialize to JSON with pretty printing
  - Return Data object

- [x] 7.3 Implement CSV export
  - Generate header row with column names
  - Generate data rows with proper escaping
  - Escape values containing commas, quotes, newlines
  - Return Data object

- [x] 7.4 Write property test for format conversion round trip
  - **Property 15: Format Conversion Round Trip**
  - **Validates: Requirements 5.1, 5.2**
  - Convert DataFrame to JSON, parse back
  - Convert DataFrame to CSV, parse back
  - Verify data equivalence

- [x] 7.5 Write property test for JSON structure
  - **Property 16: JSON Structure Correctness**
  - **Validates: Requirements 5.3**
  - Verify JSON is array of objects
  - Verify keys match column names

- [x] 7.6 Write property test for CSV header preservation
  - **Property 17: CSV Header Preservation**
  - **Validates: Requirements 5.4**
  - Verify first line contains column names

- [x] 7.7 Write property test for CSV escaping
  - **Property 18: CSV Escaping Correctness**
  - **Validates: Requirements 5.5**
  - Generate values with commas, quotes, newlines
  - Verify proper escaping in output

- [x] 7.8 Write property test for file write success
  - **Property 19: File Write Success**
  - **Validates: Requirements 5.7**
  - Write data to temporary file
  - Read back and verify content matches

- [x] 8. Implement INSERT Statement Generator
  - Add generateInsertStatements() method to DataConverter
  - Handle table name derivation
  - Implement SQL value quoting and escaping
  - Handle NULL values correctly
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_

- [x] 8.1 Implement INSERT statement generation
  - Create generateInsertStatements(dataFrame:tableName:) method
  - Generate one INSERT per row
  - Quote TEXT values with single quotes
  - Don't quote INTEGER/REAL values
  - Represent NULL as unquoted NULL
  - Escape single quotes by doubling

- [x] 8.2 Implement table name derivation
  - Extract filename without extension
  - Use as default table name
  - Allow custom table name override

- [x] 8.3 Write property test for INSERT completeness
  - **Property 20: INSERT Statement Completeness**
  - **Validates: Requirements 6.1**
  - Verify N rows produce N INSERT statements

- [x] 8.4 Write property test for table name derivation
  - **Property 21: Table Name Derivation**
  - **Validates: Requirements 6.2**
  - Verify filename.ext becomes "filename"

- [x] 8.5 Write property test for custom table names
  - **Property 22: Custom Table Name Usage**
  - **Validates: Requirements 6.3**
  - Verify custom names are used in all statements

- [x] 8.6 Write property test for SQL value quoting
  - **Property 23: SQL Value Quoting**
  - **Validates: Requirements 6.4**
  - Verify TEXT values are quoted
  - Verify numbers are not quoted

- [x] 8.7 Write property test for NULL representation
  - **Property 24: NULL Representation in SQL**
  - **Validates: Requirements 6.5**
  - Verify NULLs appear as unquoted NULL

- [x] 8.8 Write property test for SQL quote escaping
  - **Property 25: SQL Quote Escaping**
  - **Validates: Requirements 6.6**
  - Generate values with single quotes
  - Verify they are doubled in output

- [x] 8.9 Write property test for INSERT output availability
  - **Property 26: INSERT Statement Output**
  - **Validates: Requirements 6.7, 6.8**
  - Verify statements are available as string
  - Verify they can be saved to file

- [x] 9. Build Export UI
  - Add export buttons to UI
  - Implement file save dialogs
  - Connect to DataConverter
  - Show success/error messages
  - _Requirements: 5.6, 5.7, 6.7, 6.8, 9.7_

- [x] 9.1 Create ExportView component
  - Add "Export to CSV" button
  - Add "Export to JSON" button
  - Add "Generate INSERT Statements" button
  - Bind to QueryViewModel or MainViewModel

- [x] 9.2 Implement export actions
  - Show NSSavePanel for file selection
  - Call DataConverter methods
  - Write data to selected file
  - Show success/error alerts

- [x] 9.3 Write property test for export options availability
  - **Property 34: Export Options Availability**
  - **Validates: Requirements 9.7**
  - Verify all export options are available for results

- [x] 10. Implement Multi-Table Management
  - Enhance MainViewModel to track multiple tables
  - Add table list UI component
  - Implement table removal
  - Update SQL queries to support multiple tables
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 10.1 Add multi-table support to MainViewModel
  - Change dataFrame to loadedTables array
  - Track table names and DataFrames
  - Update loadFile() to add to list
  - Add removeTable(name:) method

- [x] 10.2 Create LoadedTablesView component
  - Display list of loaded tables
  - Show table name, row count, column count
  - Show column names and types on selection
  - Add remove button for each table

- [x] 10.3 Implement table removal
  - Remove from loadedTables array
  - Drop table from SQLEngine
  - Update UI to reflect removal

- [x] 10.4 Write property test for table registration
  - **Property 27: Table Registration**
  - **Validates: Requirements 7.1, 7.2**
  - Load multiple files
  - Verify all are queryable via SQL

- [x] 10.5 Write property test for schema availability
  - **Property 28: Schema Information Availability**
  - **Validates: Requirements 7.3**
  - Verify schema info is accessible for all tables

- [x] 10.6 Write property test for table removal
  - **Property 29: Table Removal Completeness**
  - **Validates: Requirements 7.4, 7.5**
  - Remove table
  - Verify it's gone from database and list
  - Verify queries fail with "table not found"

- [x] 11. Enhance Error Handling
  - Improve error messages across all components
  - Add specific error types
  - Implement error recovery mechanisms
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [x] 11.1 Define comprehensive error types
  - Create FileLoaderError enum
  - Create SQLError enum
  - Create ConversionError enum
  - Add localized error descriptions

- [x] 11.2 Improve error messages
  - Include file names in file errors
  - List supported formats in unsupported format errors
  - Pass through SQLite error messages
  - Provide actionable error messages

- [x] 11.3 Write property test for file read errors
  - **Property 30: File Read Error Messages**
  - **Validates: Requirements 8.1**
  - Verify error messages include file name

- [x] 11.4 Write property test for unsupported format errors
  - **Property 31: Unsupported Format Error Messages**
  - **Validates: Requirements 8.2**
  - Verify error lists supported formats

- [x] 11.5 Write property test for SQLite error propagation
  - **Property 32: SQLite Error Propagation**
  - **Validates: Requirements 8.4**
  - Verify SQLite errors are passed through

- [x] 11.6 Write property test for export errors
  - **Property 33: Export Error Messages**
  - **Validates: Requirements 8.5**
  - Verify export failures provide error messages

- [x] 12. Integrate All Components
  - Wire QueryViewModel into MainView
  - Connect export functionality
  - Add keyboard shortcuts (⌘+Enter for execute)
  - Polish UI transitions
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [x] 12.1 Update MainView to show query editor
  - Add QueryEditorView when file is loaded
  - Show LoadedTablesView in sidebar
  - Add export buttons to results view
  - Handle state transitions

- [x] 12.2 Add keyboard shortcuts
  - Add ⌘+Enter to execute query
  - Add ⌘+N to load new file
  - Add ⌘+W to close/clear

- [x] 12.3 Write unit tests for UI state transitions
  - Test initial state (file drop zone)
  - Test loaded state (query editor visible)
  - Test result state (results displayed)
  - Test error state (error message shown)

- [x] 13. Final Testing and Polish
  - Run all property tests
  - Fix any failing tests
  - Test end-to-end workflows
  - Optimize performance
  - Polish UI/UX
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 13.1 Run comprehensive test suite
  - Execute all unit tests
  - Execute all property tests (100+ iterations each)
  - Fix any failures
  - Achieve >90% code coverage

- [x] 13.2 Performance testing
  - Test with 10MB CSV file
  - Test with 10MB JSON file
  - Verify loading times < 2 seconds
  - Verify query execution < 1 second

- [x] 13.3 End-to-end workflow testing
  - Test: Load CSV → Query → Export CSV
  - Test: Load JSON → Query → Export JSON
  - Test: Load file → Generate INSERT statements
  - Test: Load multiple files → Query → Remove tables

- [x] 13.4 UI/UX polish
  - Ensure smooth animations
  - Verify error messages are clear
  - Test drag-and-drop experience
  - Verify keyboard shortcuts work
  - Test on different screen sizes

- [x] 14. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- All tests are required for comprehensive quality assurance
- Each property test should run with minimum 100 iterations
- Property tests should use random data generators
- Unit tests should cover specific examples and edge cases
- All tasks reference specific requirements for traceability
- Checkpoints ensure incremental validation
- Focus on core functionality first, then add polish
