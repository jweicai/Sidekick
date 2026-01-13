//
//  FileLoaderManager.swift
//  TableQuery
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
        // 未来可以添加更多内置加载器
        // register(loader: ExcelLoader())
    }
}

/// 文件加载器错误
enum FileLoaderError: Error, LocalizedError {
    case unsupportedFileType(String)
    case loaderNotFound
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let ext):
            return "不支持的文件类型: .\(ext)"
        case .loaderNotFound:
            return "未找到合适的文件加载器"
        }
    }
}
