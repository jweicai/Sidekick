//
//  FileLoaderManager.swift
//  Sidekick
//
//  Created on 2025-01-12.
//

import Foundation

/// 文件加载器管理器
/// 负责管理所有文件加载器插件
class FileLoaderManager {
    
    // MARK: - Singleton
    
    static let shared = FileLoaderManager()
    
    // MARK: - Properties
    
    private var loaders: [FileLoaderProtocol] = []
    
    // MARK: - Initialization
    
    private init() {
        // 注册内置加载器
        registerBuiltInLoaders()
    }
    
    // MARK: - Public Methods
    
    /// 注册文件加载器
    func register(loader: FileLoaderProtocol) {
        // 检查是否已注册
        if loaders.contains(where: { $0.name == loader.name }) {
            print("⚠️ Loader '\(loader.name)' already registered")
            return
        }
        
        loaders.append(loader)
        print("✅ Registered loader: \(loader.name) v\(loader.version)")
    }
    
    /// 注销文件加载器
    func unregister(loaderName: String) {
        loaders.removeAll { $0.name == loaderName }
        print("🗑️ Unregistered loader: \(loaderName)")
    }
    
    /// 获取所有加载器
    func allLoaders() -> [FileLoaderProtocol] {
        return loaders
    }
    
    /// 根据 URL 查找合适的加载器
    func findLoader(for url: URL) -> FileLoaderProtocol? {
        return loaders.first { $0.canLoad(url: url) }
    }
    
    /// 加载文件
    func loadFile(from url: URL) throws -> DataFrame {
        guard let loader = findLoader(for: url) else {
            throw FileLoaderError.unsupportedFileType(url.pathExtension)
        }
        
        print("📂 Loading file with: \(loader.name)")
        return try loader.load(from: url)
    }
    
    /// 获取支持的文件扩展名
    func supportedExtensions() -> [String] {
        return Array(Set(loaders.flatMap { $0.supportedExtensions }))
    }
    
    // MARK: - Private Methods
    
    /// 注册内置加载器
    private func registerBuiltInLoaders() {
        register(loader: CSVLoader())
        register(loader: JSONLoader())
        register(loader: XLSXLoader())
        register(loader: ParquetLoader())
    }
}

/// 文件加载器错误
enum FileLoaderError: Error, LocalizedError {
    case unsupportedFileType(String)
    case loaderNotFound
    case fileNotFound(fileName: String)
    case encodingError(fileName: String)
    case parseError(fileName: String, details: String)
    case emptyFile(fileName: String)
    case readError(fileName: String, underlyingError: Error)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let ext):
            return "不支持的文件类型: .\(ext)。支持的格式: csv, json, xlsx, parquet"
        case .loaderNotFound:
            return "未找到合适的文件加载器"
        case .fileNotFound(let fileName):
            return "找不到文件: \(fileName)"
        case .encodingError(let fileName):
            return "文件编码错误: \(fileName)。请确保文件使用 UTF-8 编码"
        case .parseError(let fileName, let details):
            return "解析文件失败: \(fileName)。\(details)"
        case .emptyFile(let fileName):
            return "文件为空: \(fileName)"
        case .readError(let fileName, let underlyingError):
            return "读取文件失败: \(fileName)。\(underlyingError.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unsupportedFileType:
            return "请使用以下格式之一: csv, json, xlsx, parquet"
        case .loaderNotFound:
            return "请检查文件格式是否正确"
        case .fileNotFound:
            return "请检查文件路径是否正确"
        case .encodingError:
            return "请将文件转换为 UTF-8 编码后重试"
        case .parseError:
            return "请检查文件格式是否正确"
        case .emptyFile:
            return "请确保文件包含数据"
        case .readError:
            return "请检查文件权限或重试"
        }
    }
}
