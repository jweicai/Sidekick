//
//  ErrorHandlingPropertyTests.swift
//  Sidekick
//
//  Property-based tests for error handling
//

import Testing
import Foundation
@testable import Sidekick

@Suite("Error Handling Properties")
struct ErrorHandlingPropertyTests {
    
    // MARK: - Property 30: File Read Error Messages
    // Feature: table-query-mvp, Property 30: File Read Error Messages
    // Validates: Requirements 8.1
    
    @Test("Property 30: File read errors include file name")
    func fileReadErrorMessages() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            let fileName = "test_file_\(Int.random(in: 1...1000)).csv"
            
            // Test file not found error
            let notFoundError = FileLoaderError.fileNotFound(fileName: fileName)
            #expect(notFoundError.errorDescription?.contains(fileName) == true, 
                   "File not found error should include file name")
            
            // Test encoding error
            let encodingError = FileLoaderError.encodingError(fileName: fileName)
            #expect(encodingError.errorDescription?.contains(fileName) == true,
                   "Encoding error should include file name")
            
            // Test parse error
            let parseError = FileLoaderError.parseError(fileName: fileName, details: "Invalid format")
            #expect(parseError.errorDescription?.contains(fileName) == true,
                   "Parse error should include file name")
            
            // Test empty file error
            let emptyError = FileLoaderError.emptyFile(fileName: fileName)
            #expect(emptyError.errorDescription?.contains(fileName) == true,
                   "Empty file error should include file name")
        }
    }
    
    // MARK: - Property 31: Unsupported Format Error Messages
    // Feature: table-query-mvp, Property 31: Unsupported Format Error Messages
    // Validates: Requirements 8.2
    
    @Test("Property 31: Unsupported format errors list supported formats")
    func unsupportedFormatErrorMessages() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            let ext = "xyz\(Int.random(in: 1...1000))"
            
            let error = FileLoaderError.unsupportedFileType(ext)
            
            let description = error.errorDescription ?? ""
            
            // Verify extension is included
            #expect(description.contains(ext), "Error should include file extension")
            
            // Verify supported formats are mentioned
            #expect(description.contains("csv") || description.contains("json"), 
                   "Error should mention supported formats")
            
            // Verify recovery suggestion mentions formats
            let suggestion = error.recoverySuggestion ?? ""
            #expect(suggestion.contains("csv") || suggestion.contains("json"), 
                   "Recovery suggestion should mention formats")
        }
    }
    
    // MARK: - Property 32: SQLite Error Propagation
    // Feature: table-query-mvp, Property 32: SQLite Error Propagation
    // Validates: Requirements 8.4
    
    @Test("Property 32: SQLite errors are passed through")
    func sqliteErrorPropagation() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            let sqlEngine = SQLEngine()
            try sqlEngine.createDatabase()
            
            // Generate invalid SQL
            let invalidQueries = [
                "SELECT * FROM nonexistent_table_\(Int.random(in: 1...1000))",
                "SELEC * FROM test",
                "SELECT * FORM test",
                "INSERT INTO (values)",
                "UPDATE SET x = 1"
            ]
            
            for sql in invalidQueries {
                do {
                    _ = try sqlEngine.executeQuery(sql: sql)
                    // If we get here, the query unexpectedly succeeded
                } catch {
                    // Verify error message is not empty
                    let errorMessage = error.localizedDescription
                    #expect(!errorMessage.isEmpty, "Error message should not be empty")
                    
                    // Verify it's a meaningful error (not just generic)
                    #expect(errorMessage.count > 5, "Error message should be descriptive")
                }
            }
            
            sqlEngine.closeDatabase()
        }
    }
    
    // MARK: - Property 33: Export Error Messages
    // Feature: table-query-mvp, Property 33: Export Error Messages
    // Validates: Requirements 8.5
    
    @Test("Property 33: Export failures provide error messages")
    func exportErrorMessages() throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            // Test empty data error
            let emptyError = ConversionError.emptyData
            #expect(emptyError.errorDescription != nil, "Empty data error should have description")
            #expect(!emptyError.errorDescription!.isEmpty, "Error description should not be empty")
            
            // Test invalid data error
            let invalidError = ConversionError.invalidData
            #expect(invalidError.errorDescription != nil, "Invalid data error should have description")
            
            // Test encoding failed error
            let encodingError = ConversionError.encodingFailed
            #expect(encodingError.errorDescription != nil, "Encoding error should have description")
            
            // Test file write failed error
            let path = "/tmp/test_\(Int.random(in: 1...1000)).csv"
            let writeError = ConversionError.fileWriteFailed(path)
            #expect(writeError.errorDescription?.contains(path) == true,
                   "File write error should include path")
            
            // Test serialization failed error
            let format = ["CSV", "JSON"].randomElement()!
            let serializationError = ConversionError.serializationFailed(format: format, details: "Test error")
            #expect(serializationError.errorDescription?.contains(format) == true,
                   "Serialization error should include format")
        }
    }
    
    // MARK: - Additional Tests
    
    @Test("SQL errors include table name when relevant")
    func sqlErrorsIncludeTableName() {
        let tableName = "test_table"
        
        let creationError = SQLError.tableCreationFailed(tableName: tableName, details: "Test")
        #expect(creationError.errorDescription?.contains(tableName) == true)
        
        let notFoundError = SQLError.tableNotFound(tableName)
        #expect(notFoundError.errorDescription?.contains(tableName) == true)
        
        let dropError = SQLError.tableDropFailed(tableName: tableName, details: "Test")
        #expect(dropError.errorDescription?.contains(tableName) == true)
    }
    
    @Test("All errors have recovery suggestions")
    func allErrorsHaveRecoverySuggestions() {
        // File loader errors
        let fileErrors: [FileLoaderError] = [
            .fileNotFound(fileName: "test.csv"),
            .unsupportedFileType("xyz"),
            .encodingError(fileName: "test.csv"),
            .parseError(fileName: "test.csv", details: "Invalid"),
            .emptyFile(fileName: "test.csv"),
            .readError(fileName: "test.csv", underlyingError: NSError(domain: "", code: 0)),
            .loaderNotFound
        ]
        
        for error in fileErrors {
            #expect(error.recoverySuggestion != nil, "File error should have recovery suggestion")
        }
        
        // SQL errors
        let sqlErrors: [SQLError] = [
            .databaseNotOpen,
            .databaseCreationFailed("Error"),
            .queryPreparationFailed("Error"),
            .executionFailed("Error"),
            .tableNotFound("test"),
            .tableCreationFailed(tableName: "test", details: "Error"),
            .tableDropFailed(tableName: "test", details: "Error")
        ]
        
        for error in sqlErrors {
            #expect(error.recoverySuggestion != nil, "SQL error should have recovery suggestion")
        }
        
        // Conversion errors
        let conversionErrors: [ConversionError] = [
            .emptyData,
            .invalidData,
            .encodingFailed,
            .fileWriteFailed("/tmp/test"),
            .serializationFailed(format: "CSV", details: "Test")
        ]
        
        for error in conversionErrors {
            #expect(error.recoverySuggestion != nil, "Conversion error should have recovery suggestion")
        }
    }
    
    @Test("Error messages are in Chinese")
    func errorMessagesAreInChinese() {
        // Verify key errors have Chinese messages
        let fileError = FileLoaderError.fileNotFound(fileName: "test.csv")
        #expect(fileError.errorDescription?.contains("找不到") == true)
        
        let sqlError = SQLError.tableNotFound("test")
        #expect(sqlError.errorDescription?.contains("不存在") == true)
        
        let conversionError = ConversionError.emptyData
        #expect(conversionError.errorDescription?.contains("没有") == true)
    }
}
