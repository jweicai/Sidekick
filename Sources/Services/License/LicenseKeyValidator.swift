//
//  LicenseKeyValidator.swift
//  Sidekick
//
//  Created on 2025-01-13.
//

import Foundation
import CryptoKit

/// 许可证密钥验证器
struct LicenseKeyValidator {
    
    // 密钥（实际使用时应该混淆或加密）
    private static let secretKey = "Sidekick-Secret-Key-2025"
    
    /// 生成许可证密钥
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - licenseType: 许可证类型
    ///   - expiryDate: 过期日期（可选）
    /// - Returns: 许可证密钥
    static func generateLicenseKey(email: String, licenseType: LicenseType, expiryDate: Date? = nil) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let expiryTimestamp = expiryDate.map { Int($0.timeIntervalSince1970) } ?? 0
        
        // 构造数据：邮箱|类型|时间戳|过期时间
        let data = "\(email)|\(licenseType.rawValue)|\(timestamp)|\(expiryTimestamp)"
        
        // 生成签名
        let signature = generateSignature(data: data)
        
        // 组合：数据 + 签名
        let combined = "\(data)|\(signature)"
        
        // Base64 编码
        let encoded = combined.data(using: .utf8)?.base64EncodedString() ?? ""
        
        // 格式化为 XXXX-XXXX-XXXX-XXXX
        return formatLicenseKey(encoded)
    }
    
    /// 验证许可证密钥
    /// - Parameter key: 许可证密钥
    /// - Returns: 许可证信息（如果有效）
    static func validateLicenseKey(_ key: String) -> License? {
        // 移除格式化字符
        let cleanKey = key.replacingOccurrences(of: "-", with: "")
        
        // Base64 解码
        guard let data = Data(base64Encoded: cleanKey),
              let decoded = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // 分割数据
        let components = decoded.components(separatedBy: "|")
        guard components.count == 5 else { return nil }
        
        let email = components[0]
        let typeString = components[1]
        let timestampString = components[2]
        let expiryString = components[3]
        let signature = components[4]
        
        // 验证签名
        let dataToVerify = "\(email)|\(typeString)|\(timestampString)|\(expiryString)"
        let expectedSignature = generateSignature(data: dataToVerify)
        
        guard signature == expectedSignature else {
            return nil
        }
        
        // 解析许可证类型
        guard let licenseType = LicenseType(rawValue: typeString) else {
            return nil
        }
        
        // 解析过期时间
        var expiryDate: Date? = nil
        if let expiryTimestamp = Int(expiryString), expiryTimestamp > 0 {
            expiryDate = Date(timeIntervalSince1970: TimeInterval(expiryTimestamp))
        }
        
        // 构造许可证
        let license = createLicense(type: licenseType, expiryDate: expiryDate)
        
        // 检查是否过期
        if license.isExpired {
            return nil
        }
        
        return license
    }
    
    /// 生成签名
    private static func generateSignature(data: String) -> String {
        let key = SymmetricKey(data: secretKey.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(for: data.data(using: .utf8)!, using: key)
        return Data(signature).base64EncodedString()
    }
    
    /// 格式化许可证密钥为 XXXX-XXXX-XXXX-XXXX
    private static func formatLicenseKey(_ key: String) -> String {
        var formatted = ""
        var count = 0
        
        for char in key {
            if count > 0 && count % 4 == 0 {
                formatted.append("-")
            }
            formatted.append(char)
            count += 1
        }
        
        return formatted
    }
    
    /// 创建许可证对象
    private static func createLicense(type: LicenseType, expiryDate: Date?) -> License {
        let features: [String: Bool]
        
        switch type {
        case .free:
            features = [
                "unlimited_tables": false,
                "unlimited_rows": false,
                "export_all_formats": false,
                "all_tools": false,
                "advanced_query": false,
                "batch_operations": false
            ]
        case .pro:
            features = [
                "unlimited_tables": true,
                "unlimited_rows": true,
                "export_all_formats": true,
                "all_tools": true,
                "advanced_query": true,
                "batch_operations": false
            ]
        case .enterprise:
            features = [
                "unlimited_tables": true,
                "unlimited_rows": true,
                "export_all_formats": true,
                "all_tools": true,
                "advanced_query": true,
                "batch_operations": true
            ]
        }
        
        return License(type: type, expiryDate: expiryDate, features: features)
    }
}
