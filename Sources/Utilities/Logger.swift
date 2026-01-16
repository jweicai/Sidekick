//
//  Logger.swift
//  Sidekick
//
//  Created on 2025-01-16.
//

import Foundation
import os.log

/// 日志级别
enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var prefix: String {
        switch self {
        case .debug: return "🔍 DEBUG"
        case .info: return "ℹ️ INFO"
        case .warning: return "⚠️ WARN"
        case .error: return "❌ ERROR"
        }
    }
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// 日志模块
enum LogModule: String {
    case app = "App"
    case database = "Database"
    case fileLoader = "FileLoader"
    case query = "Query"
    case ui = "UI"
    case persistence = "Persistence"
}

/// 统一日志管理器
final class Logger {
    
    static let shared = Logger()
    
    /// 最小日志级别（低于此级别的不输出）
    var minLevel: LogLevel = .debug
    
    /// 是否写入文件
    var writeToFile: Bool = true
    
    /// 日志文件路径
    private var logFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let logsDir = appSupport.appendingPathComponent("Sidekick/Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        return logsDir.appendingPathComponent("sidekick-\(dateString).log")
    }
    
    private let queue = DispatchQueue(label: "com.sidekick.logger", qos: .utility)
    private let dateFormatter: DateFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        // 启动时记录
        info(.app, "Sidekick started")
        info(.app, "Log file: \(logFileURL.path)")
    }
    
    // MARK: - Public Methods
    
    func debug(_ module: LogModule, _ message: String, file: String = #file, line: Int = #line) {
        log(level: .debug, module: module, message: message, file: file, line: line)
    }
    
    func info(_ module: LogModule, _ message: String, file: String = #file, line: Int = #line) {
        log(level: .info, module: module, message: message, file: file, line: line)
    }
    
    func warning(_ module: LogModule, _ message: String, file: String = #file, line: Int = #line) {
        log(level: .warning, module: module, message: message, file: file, line: line)
    }
    
    func error(_ module: LogModule, _ message: String, file: String = #file, line: Int = #line) {
        log(level: .error, module: module, message: message, file: file, line: line)
    }
    
    func error(_ module: LogModule, _ message: String, error: Error, file: String = #file, line: Int = #line) {
        log(level: .error, module: module, message: "\(message): \(error.localizedDescription)", file: file, line: line)
    }
    
    // MARK: - Private Methods
    
    private func log(level: LogLevel, module: LogModule, message: String, file: String, line: Int) {
        guard level >= minLevel else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(timestamp) \(level.prefix) [\(module.rawValue)] \(message) (\(fileName):\(line))"
        
        // 控制台输出
        print(logMessage)
        
        // 文件输出
        if writeToFile {
            queue.async { [weak self] in
                self?.writeToLogFile(logMessage)
            }
        }
    }
    
    private func writeToLogFile(_ message: String) {
        let line = message + "\n"
        
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
    
    /// 获取最近的日志内容
    func getRecentLogs(lines: Int = 100) -> String {
        guard let content = try? String(contentsOf: logFileURL, encoding: .utf8) else {
            return "No logs available"
        }
        
        let allLines = content.components(separatedBy: "\n")
        let recentLines = allLines.suffix(lines)
        return recentLines.joined(separator: "\n")
    }
    
    /// 清理旧日志（保留最近 7 天）
    func cleanOldLogs() {
        let logsDir = logFileURL.deletingLastPathComponent()
        guard let files = try? FileManager.default.contentsOfDirectory(at: logsDir, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        for file in files {
            if let attrs = try? file.resourceValues(forKeys: [.creationDateKey]),
               let creationDate = attrs.creationDate,
               creationDate < cutoffDate {
                try? FileManager.default.removeItem(at: file)
                info(.app, "Cleaned old log: \(file.lastPathComponent)")
            }
        }
    }
}

// MARK: - 便捷全局函数

func logDebug(_ module: LogModule, _ message: String, file: String = #file, line: Int = #line) {
    Logger.shared.debug(module, message, file: file, line: line)
}

func logInfo(_ module: LogModule, _ message: String, file: String = #file, line: Int = #line) {
    Logger.shared.info(module, message, file: file, line: line)
}

func logWarning(_ module: LogModule, _ message: String, file: String = #file, line: Int = #line) {
    Logger.shared.warning(module, message, file: file, line: line)
}

func logError(_ module: LogModule, _ message: String, file: String = #file, line: Int = #line) {
    Logger.shared.error(module, message, file: file, line: line)
}

func logError(_ module: LogModule, _ message: String, error: Error, file: String = #file, line: Int = #line) {
    Logger.shared.error(module, message, error: error, file: file, line: line)
}
