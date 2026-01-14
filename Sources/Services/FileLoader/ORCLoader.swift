//
//  ORCLoader.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import Foundation
import UniformTypeIdentifiers

/// ORC 文件加载器
/// 使用 Python pyarrow 库读取 ORC 文件
class ORCLoader: FileLoaderProtocol {
    
    // MARK: - FileLoaderProtocol
    
    var name: String { "ORC Loader" }
    var version: String { "1.0.0" }
    var supportedTypes: [UTType] { [] } // ORC 没有标准的 UTType
    var supportedExtensions: [String] { ["orc"] }
    
    // MARK: - Public Methods
    
    func load(from url: URL) throws -> DataFrame {
        // 检查 Python 和 pyarrow 是否可用
        guard isPythonAvailable() else {
            throw ORCLoaderError.pythonNotFound
        }
        
        guard isPyArrowAvailable() else {
            throw ORCLoaderError.pyarrowNotInstalled
        }
        
        // 使用 Python 脚本读取 ORC 文件并转换为 CSV
        let csvContent = try readORCToCSV(url: url)
        
        // 使用 CSVLoader 解析 CSV 数据
        let csvLoader = CSVLoader()
        
        // 创建临时文件来保存 CSV 数据
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("temp_\(UUID().uuidString).csv")
        
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        return try csvLoader.load(from: tempURL)
    }
    
    // MARK: - Private Methods
    
    /// 检查 Python 是否可用
    private func isPythonAvailable() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["python3"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// 检查 pyarrow 是否已安装
    private func isPyArrowAvailable() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/python3"
        task.arguments = ["-c", "import pyarrow"]
        
        let pipe = Pipe()
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// 使用 Python pyarrow 读取 ORC 文件并转换为 CSV
    private func readORCToCSV(url: URL) throws -> String {
        let pythonScript = """
        import sys
        import pyarrow.orc as orc
        import pyarrow.csv as csv
        import io
        
        try:
            # 读取 ORC 文件
            table = orc.read_table('\(url.path)')
            
            # 转换为 CSV
            output = io.BytesIO()
            csv.write_csv(table, output)
            
            # 输出 CSV 数据
            sys.stdout.buffer.write(output.getvalue())
            sys.exit(0)
        except Exception as e:
            sys.stderr.write(f"Error: {str(e)}\\n")
            sys.exit(1)
        """
        
        // 创建临时 Python 脚本文件
        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("read_orc_\(UUID().uuidString).py")
        
        try pythonScript.write(to: scriptURL, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: scriptURL)
        }
        
        // 执行 Python 脚本
        let task = Process()
        task.launchPath = "/usr/bin/python3"
        task.arguments = [scriptURL.path]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                throw ORCLoaderError.readFailed(errorMessage)
            }
            
            let csvData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            
            guard !csvData.isEmpty else {
                throw ORCLoaderError.emptyFile
            }
            
            guard let csvString = String(data: csvData, encoding: .utf8) else {
                throw ORCLoaderError.readFailed("无法解码 CSV 数据")
            }
            
            return csvString
        } catch let error as ORCLoaderError {
            throw error
        } catch {
            throw ORCLoaderError.readFailed(error.localizedDescription)
        }
    }
}

// MARK: - ORC Loader Errors

enum ORCLoaderError: Error, LocalizedError {
    case pythonNotFound
    case pyarrowNotInstalled
    case readFailed(String)
    case emptyFile
    
    var errorDescription: String? {
        switch self {
        case .pythonNotFound:
            return """
            未找到 Python 3
            
            ORC 文件需要 Python 3 支持。请安装 Python 3：
            
            方法 1 - 使用 Homebrew：
            brew install python3
            
            方法 2 - 从官网下载：
            https://www.python.org/downloads/
            """
            
        case .pyarrowNotInstalled:
            return """
            未安装 PyArrow 库
            
            ORC 文件需要 PyArrow 库支持。请安装：
            
            pip3 install pyarrow
            
            或者：
            python3 -m pip install pyarrow
            """
            
        case .readFailed(let message):
            return "读取 ORC 文件失败：\(message)"
            
        case .emptyFile:
            return "ORC 文件为空或无法读取数据"
        }
    }
}
