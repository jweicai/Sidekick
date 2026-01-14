# Requirements Document

## Introduction

Sidekick is a lightweight Mac application that enables users to query data files (CSV, JSON, Excel) using SQL without importing them into a database. The system provides instant data querying, format conversion, and SQL statement generation capabilities. This document specifies the requirements for the MVP version focusing on core functionality: file loading, SQL querying, and data conversion.

## Glossary

- **System**: The Sidekick Mac application
- **Data_File**: A file containing structured data in CSV, JSON, or Excel format
- **DataFrame**: An in-memory representation of tabular data with rows and columns
- **SQL_Engine**: The component that executes SQL queries against loaded data
- **File_Loader**: The component responsible for parsing and loading data files
- **Query_Result**: The output of executing a SQL query, containing rows and columns
- **Data_Converter**: The component that transforms data between different formats
- **Memory_Database**: An SQLite in-memory database used for query execution
- **Column_Type**: The inferred data type of a column (INTEGER, TEXT, REAL, BLOB)

## Requirements

### Requirement 1: File Loading and Parsing

**User Story:** As a data analyst, I want to drag and drop data files into the application, so that I can quickly load data for querying without manual import steps.

#### Acceptance Criteria

1. WHEN a user drags a CSV file into the application, THE System SHALL parse the file and load it into a DataFrame
2. WHEN a user drags a JSON file into the application, THE System SHALL parse the file and load it into a DataFrame
3. WHEN a CSV file contains a header row, THE System SHALL use the header values as column names
4. WHEN a CSV file does not contain a header row, THE System SHALL generate column names (column_1, column_2, etc.)
5. WHEN a JSON file contains an array of objects, THE System SHALL extract keys as column names and values as row data
6. IF a file cannot be parsed, THEN THE System SHALL display an error message indicating the parsing failure
7. WHEN a file is successfully loaded, THE System SHALL display the table name, column count, and row count
8. WHEN a file is successfully loaded, THE System SHALL display the column names and inferred data types

### Requirement 2: Data Type Inference

**User Story:** As a developer, I want the system to automatically infer data types from file content, so that SQL queries work correctly with appropriate type handling.

#### Acceptance Criteria

1. WHEN analyzing column data, THE System SHALL infer INTEGER type for columns containing only integer values
2. WHEN analyzing column data, THE System SHALL infer REAL type for columns containing decimal numbers
3. WHEN analyzing column data, THE System SHALL infer TEXT type for columns containing string values
4. WHEN a column contains mixed numeric and text values, THE System SHALL infer TEXT type
5. WHEN a column contains empty values, THE System SHALL treat them as NULL values
6. WHEN type inference is complete, THE System SHALL display the inferred type for each column

### Requirement 3: SQL Query Execution

**User Story:** As a data analyst, I want to execute SQL queries against loaded data files, so that I can filter, aggregate, and analyze data using familiar SQL syntax.

#### Acceptance Criteria

1. WHEN a user enters a SQL query and executes it, THE System SHALL load the data into a Memory_Database
2. WHEN data is loaded into the Memory_Database, THE System SHALL create a table with inferred column types
3. WHEN a SQL query is executed, THE SQL_Engine SHALL execute the query against the Memory_Database
4. WHEN a query executes successfully, THE System SHALL display the Query_Result in a table view
5. WHEN a query executes successfully, THE System SHALL display the total row count of the result
6. IF a SQL query contains syntax errors, THEN THE System SHALL display the error message from SQLite
7. IF a SQL query references a non-existent table, THEN THE System SHALL display an error message
8. WHEN a query returns no rows, THE System SHALL display an empty result table with column headers

### Requirement 4: Query Result Display

**User Story:** As a user, I want to view query results in a clear table format, so that I can easily read and understand the data.

#### Acceptance Criteria

1. WHEN displaying query results, THE System SHALL show data in a table with columns and rows
2. WHEN displaying query results, THE System SHALL show column names as table headers
3. WHEN a result set is large, THE System SHALL support scrolling through the results
4. WHEN displaying numeric values, THE System SHALL align them appropriately
5. WHEN displaying NULL values, THE System SHALL show them as empty cells or a NULL indicator

### Requirement 5: Data Format Conversion

**User Story:** As a data engineer, I want to convert data between CSV and JSON formats, so that I can use data in different contexts and tools.

#### Acceptance Criteria

1. WHEN a user loads a CSV file and selects "Export to JSON", THE Data_Converter SHALL convert the data to JSON format
2. WHEN a user loads a JSON file and selects "Export to CSV", THE Data_Converter SHALL convert the data to CSV format
3. WHEN converting to JSON, THE System SHALL create an array of objects with column names as keys
4. WHEN converting to CSV, THE System SHALL create a header row with column names
5. WHEN converting to CSV, THE System SHALL properly escape values containing commas or quotes
6. WHEN conversion is complete, THE System SHALL prompt the user to save the converted file
7. WHEN the user saves the converted file, THE System SHALL write the data to the selected location

### Requirement 6: INSERT Statement Generation

**User Story:** As a database administrator, I want to generate SQL INSERT statements from data files, so that I can easily import data into databases.

#### Acceptance Criteria

1. WHEN a user selects "Generate INSERT Statements", THE System SHALL create INSERT INTO statements for all rows
2. WHEN generating INSERT statements, THE System SHALL use the file name (without extension) as the default table name
3. WHEN generating INSERT statements, THE System SHALL allow the user to specify a custom table name
4. WHEN generating INSERT statements, THE System SHALL properly quote TEXT values
5. WHEN generating INSERT statements, THE System SHALL represent NULL values as NULL (not quoted)
6. WHEN generating INSERT statements, THE System SHALL escape single quotes in TEXT values
7. WHEN INSERT statements are generated, THE System SHALL display them in a text view for copying
8. WHEN INSERT statements are generated, THE System SHALL allow the user to save them to a .sql file

### Requirement 7: File Management

**User Story:** As a user, I want to manage multiple loaded files, so that I can work with different datasets and switch between them.

#### Acceptance Criteria

1. WHEN a file is loaded, THE System SHALL add it to a list of loaded tables
2. WHEN multiple files are loaded, THE System SHALL display all loaded tables in the table list
3. WHEN a user clicks on a loaded table, THE System SHALL display its schema information
4. WHEN a user removes a loaded table, THE System SHALL remove it from the Memory_Database
5. WHEN a user removes a loaded table, THE System SHALL remove it from the table list
6. WHEN all tables are removed, THE System SHALL display the file drop zone

### Requirement 8: Error Handling

**User Story:** As a user, I want clear error messages when something goes wrong, so that I can understand and fix issues.

#### Acceptance Criteria

1. IF a file cannot be read, THEN THE System SHALL display an error message with the file name
2. IF a file format is not supported, THEN THE System SHALL display an error message listing supported formats
3. IF a file is empty, THEN THE System SHALL display an error message indicating the file has no data
4. IF a SQL query fails, THEN THE System SHALL display the SQLite error message
5. IF a file export fails, THEN THE System SHALL display an error message with the reason
6. WHEN an error occurs, THE System SHALL not crash or enter an invalid state

### Requirement 9: User Interface

**User Story:** As a user, I want a clean and intuitive interface, so that I can focus on data analysis without UI complexity.

#### Acceptance Criteria

1. WHEN the application starts, THE System SHALL display a file drop zone
2. WHEN no files are loaded, THE System SHALL show instructions for loading files
3. WHEN a file is loaded, THE System SHALL show the SQL query editor
4. WHEN a file is loaded, THE System SHALL show the loaded tables list
5. WHEN displaying the query editor, THE System SHALL provide a text area for SQL input
6. WHEN displaying the query editor, THE System SHALL provide an "Execute Query" button
7. WHEN displaying query results, THE System SHALL show export options (CSV, JSON, INSERT statements)
8. THE System SHALL follow macOS design guidelines for native appearance

### Requirement 10: Performance

**User Story:** As a user, I want the application to handle reasonably sized files efficiently, so that I can work without long wait times.

#### Acceptance Criteria

1. WHEN loading a CSV file under 10MB, THE System SHALL complete loading within 2 seconds
2. WHEN loading a JSON file under 10MB, THE System SHALL complete loading within 2 seconds
3. WHEN executing a simple SELECT query, THE System SHALL return results within 1 second
4. WHEN displaying query results, THE System SHALL render the table view smoothly
5. WHEN the application is idle, THE System SHALL use minimal CPU resources
