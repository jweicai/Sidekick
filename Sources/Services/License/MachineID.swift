//
//  MachineID.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import Foundation
import IOKit
import CommonCrypto

/// 机器唯一标识符管理
class MachineID {
    
    /// 获取机器唯一标识符
    static func get() -> String {
        // 优先使用硬件 UUID
        if let uuid = getHardwareUUID() {
            return uuid
        }
        
        // 备用方案：使用系统 UUID
        if let uuid = getSystemUUID() {
            return uuid
        }
        
        // 最后方案：生成组合 ID
        return generateFallbackID()
    }
    
    // MARK: - Private Methods
    
    /// 获取硬件 UUID（最稳定）
    private static func getHardwareUUID() -> String? {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        
        guard platformExpert > 0 else { return nil }
        
        defer { IOObjectRelease(platformExpert) }
        
        guard let uuid = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        ).takeUnretainedValue() as? String else {
            return nil
        }
        
        return uuid
    }
    
    /// 获取系统 UUID
    private static func getSystemUUID() -> String? {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        
        guard platformExpert > 0 else { return nil }
        
        defer { IOObjectRelease(platformExpert) }
        
        guard let serialNumber = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformSerialNumberKey as CFString,
            kCFAllocatorDefault,
            0
        ).takeUnretainedValue() as? String else {
            return nil
        }
        
        return serialNumber
    }
    
    /// 生成备用 ID
    private static func generateFallbackID() -> String {
        let hostname = Host.current().name ?? "unknown"
        let username = NSUserName()
        let combined = "\(hostname)|\(username)"
        return combined.sha256()
    }
}

// MARK: - String Extension

extension String {
    /// SHA256 哈希
    func sha256() -> String {
        guard let data = self.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
