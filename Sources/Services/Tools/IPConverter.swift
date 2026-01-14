//
//  IPConverter.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import Foundation

/// IP 地址转换工具
struct IPConverter {
    /// 转换 IP 地址（自动识别格式）
    static func convert(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试识别输入格式
        if trimmed.contains(".") {
            // 可能是 IP 地址
            return try convertFromIP(trimmed)
        } else if trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
            // 十六进制
            return try convertFromHex(trimmed)
        } else if let _ = Int(trimmed) {
            // 整数
            return try convertFromInt(trimmed)
        } else {
            throw IPError.invalidFormat
        }
    }
    
    /// 从 IP 地址转换
    private static func convertFromIP(_ ip: String) throws -> String {
        let components = ip.split(separator: ".").map(String.init)
        guard components.count == 4 else {
            throw IPError.invalidIPAddress
        }
        
        var intValue: UInt32 = 0
        for (index, component) in components.enumerated() {
            guard let octet = UInt8(component) else {
                throw IPError.invalidIPAddress
            }
            intValue += UInt32(octet) << (24 - index * 8)
        }
        
        let hexValue = String(format: "0x%08X", intValue)
        
        var result = "IP 地址：\(ip)\n"
        result += "整数：\(intValue)\n"
        result += "十六进制：\(hexValue)\n"
        result += "二进制：\(String(intValue, radix: 2).padLeft(toLength: 32, withPad: "0"))"
        
        return result
    }
    
    /// 从整数转换
    private static func convertFromInt(_ intStr: String) throws -> String {
        guard let intValue = UInt32(intStr) else {
            throw IPError.invalidInteger
        }
        
        let octet1 = UInt8((intValue >> 24) & 0xFF)
        let octet2 = UInt8((intValue >> 16) & 0xFF)
        let octet3 = UInt8((intValue >> 8) & 0xFF)
        let octet4 = UInt8(intValue & 0xFF)
        
        let ip = "\(octet1).\(octet2).\(octet3).\(octet4)"
        let hexValue = String(format: "0x%08X", intValue)
        
        var result = "整数：\(intValue)\n"
        result += "IP 地址：\(ip)\n"
        result += "十六进制：\(hexValue)\n"
        result += "二进制：\(String(intValue, radix: 2).padLeft(toLength: 32, withPad: "0"))"
        
        return result
    }
    
    /// 从十六进制转换
    private static func convertFromHex(_ hexStr: String) throws -> String {
        let cleaned = hexStr.replacingOccurrences(of: "0x", with: "").replacingOccurrences(of: "0X", with: "")
        guard let intValue = UInt32(cleaned, radix: 16) else {
            throw IPError.invalidHex
        }
        
        let octet1 = UInt8((intValue >> 24) & 0xFF)
        let octet2 = UInt8((intValue >> 16) & 0xFF)
        let octet3 = UInt8((intValue >> 8) & 0xFF)
        let octet4 = UInt8(intValue & 0xFF)
        
        let ip = "\(octet1).\(octet2).\(octet3).\(octet4)"
        
        var result = "十六进制：0x\(cleaned.uppercased())\n"
        result += "整数：\(intValue)\n"
        result += "IP 地址：\(ip)\n"
        result += "二进制：\(String(intValue, radix: 2).padLeft(toLength: 32, withPad: "0"))"
        
        return result
    }
    
    /// 计算子网信息
    static func calculateSubnet(_ cidr: String) throws -> String {
        let parts = cidr.split(separator: "/")
        guard parts.count == 2,
              let prefixLength = Int(parts[1]),
              prefixLength >= 0 && prefixLength <= 32 else {
            throw IPError.invalidCIDR
        }
        
        let ip = String(parts[0])
        let components = ip.split(separator: ".").map(String.init)
        guard components.count == 4 else {
            throw IPError.invalidIPAddress
        }
        
        var ipInt: UInt32 = 0
        for (index, component) in components.enumerated() {
            guard let octet = UInt8(component) else {
                throw IPError.invalidIPAddress
            }
            ipInt += UInt32(octet) << (24 - index * 8)
        }
        
        // 计算子网掩码
        let mask: UInt32 = prefixLength == 0 ? 0 : ~((1 << (32 - prefixLength)) - 1)
        let networkInt = ipInt & mask
        let broadcastInt = networkInt | ~mask
        let firstHostInt = networkInt + 1
        let lastHostInt = broadcastInt - 1
        let totalHosts = UInt32(1 << (32 - prefixLength))
        let usableHosts = totalHosts > 2 ? totalHosts - 2 : 0
        
        // 转换为 IP 字符串
        func intToIP(_ value: UInt32) -> String {
            let o1 = UInt8((value >> 24) & 0xFF)
            let o2 = UInt8((value >> 16) & 0xFF)
            let o3 = UInt8((value >> 8) & 0xFF)
            let o4 = UInt8(value & 0xFF)
            return "\(o1).\(o2).\(o3).\(o4)"
        }
        
        var result = "CIDR：\(cidr)\n\n"
        result += "网络地址：\(intToIP(networkInt))\n"
        result += "子网掩码：\(intToIP(mask))\n"
        result += "广播地址：\(intToIP(broadcastInt))\n"
        result += "第一个可用主机：\(intToIP(firstHostInt))\n"
        result += "最后一个可用主机：\(intToIP(lastHostInt))\n"
        result += "总主机数：\(totalHosts)\n"
        result += "可用主机数：\(usableHosts)"
        
        return result
    }
    
    /// 验证 IP 地址
    static func validate(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查 IPv4
        if isValidIPv4(trimmed) {
            return "✅ 有效的 IPv4 地址\n\n地址：\(trimmed)\n类型：IPv4"
        }
        
        // 检查 IPv6
        if isValidIPv6(trimmed) {
            return "✅ 有效的 IPv6 地址\n\n地址：\(trimmed)\n类型：IPv6"
        }
        
        throw IPError.invalidIPAddress
    }
    
    /// 批量转换 IP 地址
    static func batchConvert(_ input: String) throws -> String {
        let lines = input.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        var results: [String] = []
        
        for (index, line) in lines.enumerated() {
            if line.isEmpty { continue }
            
            do {
                let result = try convert(line)
                results.append("[\(index + 1)] \(line)\n\(result)\n")
            } catch {
                results.append("[\(index + 1)] \(line)\n❌ 错误：\(error.localizedDescription)\n")
            }
        }
        
        return results.joined(separator: "\n")
    }
    
    // MARK: - 辅助方法
    
    private static func isValidIPv4(_ ip: String) -> Bool {
        let components = ip.split(separator: ".").map(String.init)
        guard components.count == 4 else { return false }
        
        for component in components {
            guard let octet = UInt8(component), octet <= 255 else {
                return false
            }
        }
        
        return true
    }
    
    private static func isValidIPv6(_ ip: String) -> Bool {
        // 简单的 IPv6 验证
        let components = ip.split(separator: ":").map(String.init)
        guard components.count >= 3 && components.count <= 8 else { return false }
        
        for component in components {
            if component.isEmpty { continue }
            guard component.count <= 4 else { return false }
            guard Int(component, radix: 16) != nil else { return false }
        }
        
        return true
    }
}

enum IPError: Error, LocalizedError {
    case invalidFormat
    case invalidIPAddress
    case invalidInteger
    case invalidHex
    case invalidCIDR
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "无法识别的格式，请输入 IP 地址、整数或十六进制"
        case .invalidIPAddress:
            return "无效的 IP 地址格式"
        case .invalidInteger:
            return "无效的整数格式"
        case .invalidHex:
            return "无效的十六进制格式"
        case .invalidCIDR:
            return "无效的 CIDR 格式，应为：192.168.1.0/24"
        }
    }
}

// MARK: - String Extension

extension String {
    func padLeft(toLength: Int, withPad: String) -> String {
        let padCount = toLength - self.count
        guard padCount > 0 else { return self }
        return String(repeating: withPad, count: padCount) + self
    }
}
