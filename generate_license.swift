#!/usr/bin/env swift

//
//  generate_license.swift
//  Sidekick License Generator
//
//  用法：swift generate_license.swift <email> <machineID>
//  示例：swift generate_license.swift test@example.com ABC123DEF456
//

import Foundation
import CommonCrypto

// MARK: - License Generator

func generateLicenseKey(email: String, machineID: String) -> String {
    let combined = "\(email)|\(machineID)|SIDEKICK_SECRET"
    let hash = sha256(combined)
    let key = String(hash.prefix(16)).uppercased()
    
    // 格式化为 XXXX-XXXX-XXXX-XXXX
    var formatted = ""
    for (index, char) in key.enumerated() {
        if index > 0 && index % 4 == 0 {
            formatted += "-"
        }
        formatted.append(char)
    }
    
    return formatted
}

func sha256(_ string: String) -> String {
    guard let data = string.data(using: .utf8) else { return "" }
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
    }
    return hash.map { String(format: "%02x", $0) }.joined()
}

// MARK: - Main

print("🔑 Sidekick License Generator")
print(String(repeating: "=", count: 50))

// 获取参数
let arguments = CommandLine.arguments

if arguments.count < 3 {
    print("❌ 用法: swift generate_license.swift <email> <machineID>")
    print("")
    print("示例:")
    print("  swift generate_license.swift test@example.com ABC123DEF456")
    print("")
    exit(1)
}

let email = arguments[1].lowercased()
let machineID = arguments[2]

// 验证邮箱格式
let emailPattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailPattern)
guard emailPredicate.evaluate(with: email) else {
    print("❌ 邮箱格式不正确: \(email)")
    exit(1)
}

// 生成激活码
let licenseKey = generateLicenseKey(email: email, machineID: machineID)

// 输出结果
print("")
print("✅ 激活码生成成功！")
print("")
print("邮箱地址: \(email)")
print("机器码:   \(machineID)")
print("激活码:   \(licenseKey)")
print("")
print(String(repeating: "=", count: 50))
print("💡 请将激活码发送给用户")
print("")
