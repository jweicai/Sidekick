#!/usr/bin/env swift

import Foundation
import CryptoKit

// 复制 LicenseKeyValidator 的逻辑用于生成测试密钥

let secretKey = "TableQuery-Secret-Key-2025"

func generateSignature(data: String) -> String {
    let key = SymmetricKey(data: secretKey.data(using: .utf8)!)
    let signature = HMAC<SHA256>.authenticationCode(for: data.data(using: .utf8)!, using: key)
    return Data(signature).base64EncodedString()
}

func formatLicenseKey(_ key: String) -> String {
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

func generateLicenseKey(email: String, licenseType: String, expiryDate: Date? = nil) -> String {
    let timestamp = Int(Date().timeIntervalSince1970)
    let expiryTimestamp = expiryDate.map { Int($0.timeIntervalSince1970) } ?? 0
    
    // 构造数据：邮箱|类型|时间戳|过期时间
    let data = "\(email)|\(licenseType)|\(timestamp)|\(expiryTimestamp)"
    
    // 生成签名
    let signature = generateSignature(data: data)
    
    // 组合：数据 + 签名
    let combined = "\(data)|\(signature)"
    
    // Base64 编码
    let encoded = combined.data(using: .utf8)?.base64EncodedString() ?? ""
    
    // 格式化为 XXXX-XXXX-XXXX-XXXX
    return formatLicenseKey(encoded)
}

// 生成测试许可证
print("=== TableQuery 许可证生成器 ===\n")

// 免费版（不需要密钥）
print("免费版：无需许可证密钥\n")

// 专业版
let proKey = generateLicenseKey(email: "test@example.com", licenseType: "专业版")
print("专业版测试密钥：")
print(proKey)
print()

// 企业版
let enterpriseKey = generateLicenseKey(email: "test@example.com", licenseType: "企业版")
print("企业版测试密钥：")
print(enterpriseKey)
print()

// 带过期时间的专业版（30天后过期）
let expiryDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
let proKeyWithExpiry = generateLicenseKey(email: "test@example.com", licenseType: "专业版", expiryDate: expiryDate)
print("专业版测试密钥（30天后过期）：")
print(proKeyWithExpiry)
print()

print("提示：将这些密钥复制到应用的激活界面进行测试")
