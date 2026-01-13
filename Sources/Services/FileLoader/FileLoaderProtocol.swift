//
//  FileLoaderProtocol.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import Foundation
import UniformTypeIdentifiers

/// 文件加载器协议
/// 所有文件格式的加载器都需要实现这个协议
protocol FileLoaderProtocol {
    /// 加载器名称
    var name: String { get }
    
    /// 加载器版本
    var version: String { get }
    
    /// 支持的文件类型
    var supportedTypes: [UTType] { get }
    
    /// 支持的文件扩展名
    var supportedExtensions: [String] { get }
    
    /// 检查是否支持该文件
    func canLoad(url: URL) -> Bool
    
    /// 从 URL 加载文件
    func load(from url: URL) throws -> DataFrame
}

/// 默认实现
extension FileLoaderProtocol {
    func canLoad(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedExtensions.contains(ext)
    }
}
