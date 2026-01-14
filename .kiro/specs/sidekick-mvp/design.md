# Sidekick MVP - Design Document

## Overview

Sidekick is a native macOS application built with Swift and SwiftUI that enables users to query data files using SQL without importing them into a database. The system loads data files (CSV, JSON) into an in-memory SQLite database, executes SQL queries, and provides data conversion capabilities.

The architecture follows the MVVM (Model-View-ViewModel) pattern with a plugin-based file loader system. The core workflow is: File Drop → Parse → Load to SQLite → Query → Display Results → Export.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                        │
│  (MainView, FileDropZone, DataTableView, QueryEditor)       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                        ViewModels                            │
│              (MainViewModel, QueryViewModel)                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  ┌──────────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │ FileLoaderManager│  │  SQLEngine   │  │ DataConverter │ │
│  └──────────────────┘  └──────────────┘  └───────────────┘ │
│           │                    │                  │          │
│           ▼                    ▼                  ▼          │
│  ┌──────────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │  CSV/JSON Loaders│  │SQLite (Memory)│  │Export Engines │ │
│  └──────────────────┘  └──────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Models                            │
│         (DataFrame, Column, QueryResult)                     │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

**View Layer (SwiftUI)**:
- MainView: Root view coordinating all UI components
- FileDropZone: Handles file drag-and-drop and file selection
- DataTableView: Displays tabular data with scrolling
- QueryEditorView: SQL query input and execution controls
- ExportView: Export options and file saving

**ViewModel Layer**:
- MainViewModel: Manages application state, file loading, and coordination
- QueryViewModel: Manages SQL query execution and result state

**Service Layer**:
- FileLoaderManager: Plugin registry for file loaders
- FileLoaderProtocol: Interface for file format parsers
- CSVLoader: Parses CSV files into DataFrames
- JSONLoader: Parses JSON files into DataFrames
- SQLEngine: Manages SQLite database and query execution
- DataConverter: Handles format conversion and export

**Model Layer**:
- DataFrame: In-memory representation of tabular data
- Column: Column metadata (name, type)
- QueryResult: Query execution results with metadata

## Components and Interfaces

### 1. File Loading System

#### FileLoaderProtocol

```swift
protocol FileLoaderProtocol {
    var name: String { get }
    var version: String { get }
    var supportedTypes: [UTType] { get }
    var supportedExtensions: [String] { get }
    
    func canLoad(url: URL) -> Bool
    func load(from url: URL) throws -> DataFrame
}
```

**Purpose**: Defines the interface for all file format parsers, enabling a plugin architecture.

**Key Methods**:
- `canLoad(url:)`: Checks if the loader supports the file extension
- `load(from:)`: Parses the file and returns a DataFrame

#### FileLoaderManager

```swift
class FileLoaderManager {
    static let shared: FileLoaderManager
    
    func register(loader: FileLoaderProtocol)
    func unregister(loaderName: String)
    func findLoader(for url: URL) -> FileLoaderProtocol?
    func loadFile(from url: URL) throws -> DataFrame
    func supportedExtensions() -> [String]
}
```

**Purpose**: Central registry for file loaders, routes files to appropriate parsers.

**Key Responsibilities**:
- Maintains a list of registered loaders
- Finds the appropriate loader for a given file
- Delegates file loading to the correct loader

#### CSVLoader

```swift
class CSVLoader: FileLoaderProtocol {
    func load(from url: URL) throws -> DataFrame
    private func parse(content: String) throws -> DataFrame
    private func parseRow(_ line: String) -> [String]
    private func inferColumnTypes(columnNames: [String], rows: [[String]]) -> [Column]
    private func inferType(from values: [String]) -> ColumnType
}
```

**Purpose**: Parses CSV files with proper quote handling and type inference.

**Parsing Algorithm**:
1. Read file content as UTF-8 string
2. Split into lines, filter empty lines
3. Parse first line as column names
4. Parse remaining lines as data rows
5. Handle quoted fields containing commas
6. Infer data types for each column
7. Return DataFrame with typed columns

**Type Inference Logic**:
- Check if all non-empty values are integers → INTEGER
- Check if all non-empty values are decimals → REAL
- Check if all non-empty values are booleans → BOOLEAN
- Default to TEXT

#### JSONLoader

```swift
class JSONLoader: FileLoaderProtocol {
    func load(from url: URL) throws -> DataFrame
    private func parseJSONArray(_ jsonArray: [[String: Any]]) throws -> DataFrame
    private func parseJSONLines(_ content: String) throws -> DataFrame
}
```

**Purpose**: Parses JSON files in two formats: JSON array and JSONL (line-delimited JSON).

**Parsing Algorithm**:
1. Read file content as Data
2. Attempt to parse as JSON array of objects
3. If that fails, attempt to parse as JSONL (one JSON object per line)
4. Extract column names from object keys (sorted alphabetically)
5. Extract values for each row, converting to strings
6. Return DataFrame with column names and rows

### 2. SQL Query Engine

#### SQLEngine

```swift
class SQLEngine {
    private var db: OpaquePointer?
    
    func createDatabase() throws
    func closeDatabase()
    func createTable(name: String, dataFrame: DataFrame) throws
    func executeQuery(sql: String) throws -> QueryResult
    func dropTable(name: String) throws
    func listTables() throws -> [String]
}
```

**Purpose**: Manages SQLite in-memory database and executes SQL queries.

**Key Operations**:

**Database Creation**:
```swift
func createDatabase() throws {
    var db: OpaquePointer?
    let result = sqlite3_open(":memory:", &db)
    guard result == SQLITE_OK else {
        throw SQLError.databaseCreationFailed
    }
    self.db = db
}
```

**Table Creation**:
```swift
func createTable(name: String, dataFrame: DataFrame) throws {
    // Generate CREATE TABLE statement
    let columns = dataFrame.columns.map { "\($0.name) \($0.type.sqlType)" }
    let sql = "CREATE TABLE \(name) (\(columns.joined(separator: ", ")))"
    
    // Execute CREATE TABLE
    try execute(sql)
    
    // Insert data rows
    for row in dataFrame.rows {
        let values = row.map { escapeValue($0) }
        let insertSQL = "INSERT INTO \(name) VALUES (\(values.joined(separator: ", ")))"
        try execute(insertSQL)
    }
}
```

**Query Execution**:
```swift
func executeQuery(sql: String) throws -> QueryResult {
    let startTime = Date()
    var statement: OpaquePointer?
    
    // Prepare statement
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
        throw SQLError.queryPreparationFailed(sqlite3_errmsg(db))
    }
    
    // Extract column names
    let columnCount = sqlite3_column_count(statement)
    let columns = (0..<columnCount).map { 
        String(cString: sqlite3_column_name(statement, $0)) 
    }
    
    // Fetch rows
    var rows: [[String]] = []
    while sqlite3_step(statement) == SQLITE_ROW {
        let row = (0..<columnCount).map { index in
            if let cString = sqlite3_column_text(statement, index) {
                return String(cString: cString)
            }
            return ""
        }
        rows.append(row)
    }
    
    sqlite3_finalize(statement)
    
    let executionTime = Date().timeIntervalSince(startTime)
    return QueryResult(columns: columns, rows: rows, executionTime: executionTime)
}
```

### 3. Data Conversion System

#### DataConverter

```swift
class DataConverter {
    func convertToJSON(dataFrame: DataFrame) throws -> Data
    func convertToCSV(dataFrame: DataFrame) throws -> Data
    func generateInsertStatements(dataFrame: DataFrame, tableName: String) -> String
}
```

**Purpose**: Converts DataFrames to different output formats.

**CSV Export**:
```swift
func convertToCSV(dataFrame: DataFrame) throws -> Data {
    var lines: [String] = []
    
    // Header row
    let header = dataFrame.columns.map { $0.name }.joined(separator: ",")
    lines.append(header)
    
    // Data rows
    for row in dataFrame.rows {
        let escapedRow = row.map { escapeCSVValue($0) }
        lines.append(escapedRow.joined(separator: ","))
    }
    
    let csvString = lines.joined(separator: "\n")
    return csvString.data(using: .utf8)!
}

private func escapeCSVValue(_ value: String) -> String {
    if value.contains(",") || value.contains("\"") || value.contains("\n") {
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    return value
}
```

**JSON Export**:
```swift
func convertToJSON(dataFrame: DataFrame) throws -> Data {
    var jsonArray: [[String: String]] = []
    
    for row in dataFrame.rows {
        var jsonObject: [String: String] = [:]
        for (index, column) in dataFrame.columns.enumerated() {
            jsonObject[column.name] = row[index]
        }
        jsonArray.append(jsonObject)
    }
    
    return try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
}
```

**INSERT Statement Generation**:
```swift
func generateInsertStatements(dataFrame: DataFrame, tableName: String) -> String {
    var statements: [String] = []
    
    for row in dataFrame.rows {
        let values = row.map { value in
            if value.isEmpty {
                return "NULL"
            } else if let _ = Int(value) {
                return value
            } else if let _ = Double(value) {
                return value
            } else {
                return "'\(value.replacingOccurrences(of: "'", with: "''"))'"
            }
        }
        
        let sql = "INSERT INTO \(tableName) VALUES (\(values.joined(separator: ", ")));"
        statements.append(sql)
    }
    
    return statements.joined(separator: "\n")
}
```

### 4. ViewModel Layer

#### MainViewModel

```swift
class MainViewModel: ObservableObject {
    @Published var fileURL: URL?
    @Published var dataFrame: DataFrame?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var fileName: String = ""
    @Published var loadedTables: [LoadedTable] = []
    
    private let loaderManager = FileLoaderManager.shared
    
    func loadFile(url: URL)
    func clearData()
    func removeTable(name: String)
}
```

**Purpose**: Manages file loading state and coordinates between views and services.

#### QueryViewModel

```swift
class QueryViewModel: ObservableObject {
    @Published var sqlQuery: String = ""
    @Published var queryResult: QueryResult?
    @Published var isExecuting: Bool = false
    @Published var errorMessage: String?
    
    private let sqlEngine = SQLEngine()
    
    func executeQuery()
    func clearResults()
    func exportToCSV()
    func exportToJSON()
    func generateInsertStatements()
}
```

**Purpose**: Manages SQL query execution and result state.

## Data Models

### DataFrame

```swift
struct DataFrame {
    let columns: [Column]
    let rows: [[String]]
    
    var rowCount: Int { rows.count }
    var columnCount: Int { columns.count }
}
```

**Purpose**: In-memory representation of tabular data.

**Invariants**:
- All rows must have the same number of elements as columns
- Column names must be unique
- Rows contain string representations of values

### Column

```swift
struct Column {
    let name: String
    let type: ColumnType
}

enum ColumnType {
    case integer
    case real
    case text
    case boolean
    case date
    case null
    
    var sqlType: String {
        switch self {
        case .integer: return "INTEGER"
        case .real: return "REAL"
        case .text: return "TEXT"
        case .boolean: return "INTEGER"
        case .date: return "TEXT"
        case .null: return "TEXT"
        }
    }
}
```

**Purpose**: Represents column metadata with name and inferred type.

### QueryResult

```swift
struct QueryResult {
    let columns: [String]
    let rows: [[String]]
    let executionTime: TimeInterval
    let rowCount: Int
}
```

**Purpose**: Encapsulates query execution results with performance metadata.


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### File Loading Properties

**Property 1: CSV Parsing Completeness**
*For any* valid CSV file with N rows and M columns, parsing the file should produce a DataFrame with N-1 data rows (excluding header) and M columns.
**Validates: Requirements 1.1, 1.3**

**Property 2: JSON Parsing Completeness**
*For any* valid JSON array of objects, parsing the file should produce a DataFrame where the number of rows equals the array length and the number of columns equals the number of unique keys across all objects.
**Validates: Requirements 1.2, 1.5**

**Property 3: Parse Error Handling**
*For any* invalid or corrupted file content, attempting to parse should return an error rather than producing an incorrect DataFrame or crashing.
**Validates: Requirements 1.6**

**Property 4: Metadata Availability**
*For any* successfully loaded file, the system should provide access to table name, column count, row count, column names, and inferred types.
**Validates: Requirements 1.7, 1.8**

### Type Inference Properties

**Property 5: Integer Type Inference**
*For any* column where all non-empty values can be parsed as integers, the inferred type should be INTEGER.
**Validates: Requirements 2.1**

**Property 6: Real Type Inference**
*For any* column where all non-empty values can be parsed as decimal numbers (but not all as integers), the inferred type should be REAL.
**Validates: Requirements 2.2**

**Property 7: Text Type Inference**
*For any* column containing at least one value that cannot be parsed as a number, the inferred type should be TEXT.
**Validates: Requirements 2.3, 2.4**

**Property 8: NULL Value Handling**
*For any* column containing empty string values, those values should be treated as NULL in the resulting DataFrame.
**Validates: Requirements 2.5**

### SQL Query Execution Properties

**Property 9: Data Accessibility via SQL**
*For any* DataFrame loaded into the Memory_Database, executing "SELECT * FROM table_name" should return all rows and columns from the original DataFrame.
**Validates: Requirements 3.1, 3.2**

**Property 10: Query Result Correctness**
*For any* valid SQL query executed against loaded data, the Query_Result should contain the correct columns and rows as determined by SQLite's query engine.
**Validates: Requirements 3.3, 3.4**

**Property 11: Result Metadata Accuracy**
*For any* Query_Result, the rowCount field should equal the actual number of rows in the result.
**Validates: Requirements 3.5**

**Property 12: SQL Error Propagation**
*For any* SQL query with syntax errors, the system should return an error message from SQLite rather than crashing or returning incorrect results.
**Validates: Requirements 3.6**

**Property 13: Query Result Structure**
*For any* Query_Result, the column names should be displayed as headers and all rows should have the same number of elements as there are columns.
**Validates: Requirements 4.1, 4.2**

**Property 14: NULL Display Handling**
*For any* Query_Result containing NULL values, those values should be represented consistently (either as empty strings or a NULL indicator).
**Validates: Requirements 4.5**

### Data Conversion Properties

**Property 15: Format Conversion Round Trip**
*For any* DataFrame, converting to JSON then parsing back to DataFrame, or converting to CSV then parsing back to DataFrame, should produce a DataFrame with equivalent data (same columns and rows).
**Validates: Requirements 5.1, 5.2**

**Property 16: JSON Structure Correctness**
*For any* DataFrame converted to JSON, the result should be a JSON array where each element is an object with keys matching the column names.
**Validates: Requirements 5.3**

**Property 17: CSV Header Preservation**
*For any* DataFrame converted to CSV, the first line should contain the column names separated by commas.
**Validates: Requirements 5.4**

**Property 18: CSV Escaping Correctness**
*For any* DataFrame containing values with commas, quotes, or newlines, converting to CSV should properly escape those values with quotes and quote-doubling.
**Validates: Requirements 5.5**

**Property 19: File Write Success**
*For any* converted data and valid file path, writing the data to disk should create a file that can be read back with identical content.
**Validates: Requirements 5.7**

### INSERT Statement Generation Properties

**Property 20: INSERT Statement Completeness**
*For any* DataFrame with N rows, generating INSERT statements should produce exactly N INSERT statements.
**Validates: Requirements 6.1**

**Property 21: Table Name Derivation**
*For any* file with name "filename.ext", the default table name for INSERT statements should be "filename".
**Validates: Requirements 6.2**

**Property 22: Custom Table Name Usage**
*For any* custom table name provided by the user, all generated INSERT statements should use that table name.
**Validates: Requirements 6.3**

**Property 23: SQL Value Quoting**
*For any* DataFrame, TEXT values in generated INSERT statements should be wrapped in single quotes, while INTEGER and REAL values should not be quoted.
**Validates: Requirements 6.4**

**Property 24: NULL Representation in SQL**
*For any* DataFrame containing NULL values, those values should appear as unquoted "NULL" in generated INSERT statements.
**Validates: Requirements 6.5**

**Property 25: SQL Quote Escaping**
*For any* TEXT value containing single quotes, the generated INSERT statement should escape them by doubling ('' instead of ').
**Validates: Requirements 6.6**

**Property 26: INSERT Statement Output**
*For any* generated INSERT statements, they should be available as a string that can be copied or saved to a .sql file.
**Validates: Requirements 6.7, 6.8**

### Table Management Properties

**Property 27: Table Registration**
*For any* successfully loaded file, the table should be added to the list of loaded tables and be queryable via SQL.
**Validates: Requirements 7.1, 7.2**

**Property 28: Schema Information Availability**
*For any* loaded table, its schema information (column names and types) should be accessible.
**Validates: Requirements 7.3**

**Property 29: Table Removal Completeness**
*For any* loaded table that is removed, it should be removed from both the Memory_Database and the loaded tables list, and subsequent queries should fail with a "table not found" error.
**Validates: Requirements 7.4, 7.5**

### Error Handling Properties

**Property 30: File Read Error Messages**
*For any* file that cannot be read, the error message should include the file name.
**Validates: Requirements 8.1**

**Property 31: Unsupported Format Error Messages**
*For any* file with an unsupported extension, the error message should list the supported formats.
**Validates: Requirements 8.2**

**Property 32: SQLite Error Propagation**
*For any* failed SQL query, the error message from SQLite should be passed through to the user.
**Validates: Requirements 8.4**

**Property 33: Export Error Messages**
*For any* failed export operation, an error message should be provided explaining the failure reason.
**Validates: Requirements 8.5**

**Property 34: Export Options Availability**
*For any* Query_Result, export options for CSV, JSON, and INSERT statements should be available.
**Validates: Requirements 9.7**

## Error Handling

### Error Types

**File Loading Errors**:
- `FileLoaderError.unsupportedFileType`: File extension not supported
- `CSVError.emptyFile`: CSV file contains no data
- `CSVError.invalidFormat`: CSV file has malformed structure
- `CSVError.encodingError`: File encoding is not UTF-8
- `JSONLoaderError.emptyFile`: JSON file contains no data
- `JSONLoaderError.invalidFormat`: JSON is not an array of objects

**SQL Execution Errors**:
- `SQLError.databaseCreationFailed`: Cannot create in-memory database
- `SQLError.queryPreparationFailed`: SQL syntax error
- `SQLError.tableNotFound`: Referenced table does not exist
- `SQLError.executionFailed`: Query execution failed

**Conversion Errors**:
- `ConversionError.invalidData`: Data cannot be converted to target format
- `ConversionError.fileWriteFailed`: Cannot write to output file

### Error Handling Strategy

**Graceful Degradation**:
- All errors should be caught and converted to user-friendly messages
- No errors should cause application crashes
- Error messages should be specific and actionable

**Error Recovery**:
- File loading errors: Allow user to try a different file
- SQL errors: Allow user to correct the query
- Export errors: Allow user to choose a different location

**Error Logging**:
- Log all errors to console for debugging
- Include stack traces in debug builds
- Sanitize error messages in release builds

## Testing Strategy

### Dual Testing Approach

The testing strategy employs both unit tests and property-based tests to ensure comprehensive coverage:

**Unit Tests**: Verify specific examples, edge cases, and error conditions
- Test specific CSV files with known content
- Test specific JSON structures
- Test edge cases like empty files, single-row files, files with special characters
- Test error conditions with invalid input
- Test UI state transitions

**Property-Based Tests**: Verify universal properties across all inputs
- Generate random CSV content and verify parsing correctness
- Generate random JSON arrays and verify conversion
- Generate random DataFrames and verify round-trip conversions
- Generate random SQL queries and verify execution
- Test with 100+ iterations per property to catch edge cases

### Property-Based Testing Configuration

**Testing Library**: Swift Testing with custom property-based testing utilities (or swift-check if available)

**Test Configuration**:
- Minimum 100 iterations per property test
- Each test tagged with feature name and property number
- Tag format: `@Test(.tags(.property(1, "CSV Parsing Completeness")))`

**Generator Strategy**:
- CSV Generator: Random rows/columns, various data types, special characters
- JSON Generator: Random object arrays with varying keys
- DataFrame Generator: Random dimensions and content
- SQL Generator: Valid SELECT/WHERE/GROUP BY queries with random conditions

### Test Organization

```
Tests/
├── UnitTests/
│   ├── FileLoaderTests.swift
│   ├── SQLEngineTests.swift
│   ├── DataConverterTests.swift
│   └── ViewModelTests.swift
├── PropertyTests/
│   ├── FileLoadingPropertyTests.swift
│   ├── TypeInferencePropertyTests.swift
│   ├── SQLQueryPropertyTests.swift
│   ├── ConversionPropertyTests.swift
│   └── TableManagementPropertyTests.swift
└── Generators/
    ├── CSVGenerator.swift
    ├── JSONGenerator.swift
    ├── DataFrameGenerator.swift
    └── SQLGenerator.swift
```

### Key Test Scenarios

**File Loading Tests**:
- Load valid CSV files with various structures
- Load valid JSON files (array and JSONL formats)
- Handle files with UTF-8, special characters, emojis
- Handle empty files, single-row files, large files
- Handle malformed CSV (unclosed quotes, inconsistent columns)
- Handle malformed JSON (invalid syntax, non-array structure)

**Type Inference Tests**:
- Infer INTEGER for pure integer columns
- Infer REAL for decimal columns
- Infer TEXT for string columns
- Infer TEXT for mixed-type columns
- Handle NULL values correctly
- Handle empty columns

**SQL Query Tests**:
- Execute SELECT queries with various clauses
- Execute aggregate queries (COUNT, SUM, AVG)
- Execute JOIN queries (when multi-table support is added)
- Handle syntax errors gracefully
- Handle non-existent tables gracefully
- Handle empty result sets

**Conversion Tests**:
- Convert CSV to JSON and back (round-trip)
- Convert JSON to CSV and back (round-trip)
- Preserve data types through conversions
- Handle special characters in CSV export
- Generate valid INSERT statements
- Escape SQL values correctly

**Error Handling Tests**:
- Verify error messages are clear and actionable
- Verify no crashes occur on invalid input
- Verify error recovery mechanisms work
- Verify all error types are handled

### Performance Testing

While not part of the core property-based testing, performance should be validated:
- Load 10MB CSV file in < 2 seconds
- Load 10MB JSON file in < 2 seconds
- Execute simple queries in < 1 second
- Render large result sets smoothly

### Integration Testing

Test end-to-end workflows:
1. Drag CSV file → View data → Execute query → Export results
2. Drag JSON file → View data → Generate INSERT statements → Save to file
3. Load multiple files → Query across tables → Export combined results
4. Load file → Remove table → Verify cleanup

## Implementation Notes

### Technology Choices

**SQLite for Query Engine**:
- Mature, well-tested SQL engine
- In-memory mode for fast queries
- No external dependencies
- Full SQL support

**SwiftUI for UI**:
- Native macOS appearance
- Declarative syntax
- Reactive data binding
- Built-in drag-and-drop support

**Plugin Architecture for File Loaders**:
- Easy to add new file formats
- Separation of concerns
- Testable in isolation
- Third-party plugin support (future)

### Performance Considerations

**Lazy Loading**:
- Display first 100 rows by default
- Load additional rows on scroll
- Avoid loading entire large files into memory at once

**Streaming for Large Files**:
- Read files in chunks
- Process incrementally
- Show progress indicator

**Query Optimization**:
- Use SQLite indexes for large tables
- Limit result sets by default
- Provide pagination for large results

### Future Enhancements

**Multi-Table Support**:
- Load multiple files simultaneously
- Support JOIN queries across tables
- Manage table relationships

**Excel Support**:
- Add ExcelLoader plugin
- Support .xlsx and .xls formats
- Handle multiple sheets

**Advanced Features**:
- Query history and favorites
- SQL auto-completion
- Data visualization
- Export to more formats (Parquet, Avro)
- Data profiling and statistics
