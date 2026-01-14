//
//  TextTools.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import Foundation
import CryptoKit

/// 文本处理工具
struct TextTools {
    // MARK: - Base64
    
    /// Base64 编码
    static func base64Encode(_ text: String) throws -> String {
        guard let data = text.data(using: .utf8) else {
            throw TextToolsError.encodingFailed
        }
        return data.base64EncodedString()
    }
    
    /// Base64 解码
    static func base64Decode(_ base64: String) throws -> String {
        guard let data = Data(base64Encoded: base64),
              let text = String(data: data, encoding: .utf8) else {
            throw TextToolsError.decodingFailed
        }
        return text
    }
    
    // MARK: - URL 编码
    
    /// URL 编码
    static func urlEncode(_ text: String) throws -> String {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw TextToolsError.encodingFailed
        }
        return encoded
    }
    
    /// URL 解码
    static func urlDecode(_ encoded: String) throws -> String {
        guard let decoded = encoded.removingPercentEncoding else {
            throw TextToolsError.decodingFailed
        }
        return decoded
    }
    
    // MARK: - Hash
    
    /// 计算多种 Hash 值
    static func calculateHash(_ text: String) throws -> String {
        guard let data = text.data(using: .utf8) else {
            throw TextToolsError.encodingFailed
        }
        
        // MD5
        let md5 = Insecure.MD5.hash(data: data)
        let md5String = md5.map { String(format: "%02x", $0) }.joined()
        
        // SHA256
        let sha256 = SHA256.hash(data: data)
        let sha256String = sha256.map { String(format: "%02x", $0) }.joined()
        
        // SHA512
        let sha512 = SHA512.hash(data: data)
        let sha512String = sha512.map { String(format: "%02x", $0) }.joined()
        
        var result = "MD5:\n\(md5String)\n\n"
        result += "SHA256:\n\(sha256String)\n\n"
        result += "SHA512:\n\(sha512String)"
        
        return result
    }
    
    // MARK: - 文本对比
    
    /// 对比两段文本
    static func compareText(left: String, right: String) throws -> String {
        let leftLines = left.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let rightLines = right.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        
        let maxLines = max(leftLines.count, rightLines.count)
        var result: [String] = []
        var sameCount = 0
        var diffCount = 0
        var addedCount = 0
        var removedCount = 0
        
        for i in 0..<maxLines {
            let leftLine = i < leftLines.count ? leftLines[i] : nil
            let rightLine = i < rightLines.count ? rightLines[i] : nil
            
            if let left = leftLine, let right = rightLine {
                if left == right {
                    result.append("  \(i + 1) | \(left)")
                    sameCount += 1
                } else {
                    result.append("- \(i + 1) | \(left)")
                    result.append("+ \(i + 1) | \(right)")
                    diffCount += 1
                }
            } else if let left = leftLine {
                result.append("- \(i + 1) | \(left)")
                removedCount += 1
            } else if let right = rightLine {
                result.append("+ \(i + 1) | \(right)")
                addedCount += 1
            }
        }
        
        var summary = "对比结果：\n"
        summary += "相同行：\(sameCount)\n"
        summary += "不同行：\(diffCount)\n"
        summary += "新增行：\(addedCount)\n"
        summary += "删除行：\(removedCount)\n"
        summary += "\n图例：\n"
        summary += "  = 相同\n"
        summary += "- = 删除（仅在原始文本中）\n"
        summary += "+ = 新增（仅在对比文本中）\n"
        summary += "\n" + String(repeating: "-", count: 50) + "\n\n"
        
        return summary + result.joined(separator: "\n")
    }
}

enum TextToolsError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "编码失败"
        case .decodingFailed:
            return "解码失败"
        }
    }
}
