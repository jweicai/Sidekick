//
//  OtherTools.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import Foundation

/// 其他工具集合
struct OtherTools {
    // MARK: - UUID 生成
    
    /// 生成 UUID
    static func generateUUID(count: Int = 1, uppercase: Bool = false, withHyphens: Bool = true) -> String {
        var results: [String] = []
        
        for _ in 0..<count {
            let uuid = UUID().uuidString
            var formatted = uuid
            
            if !withHyphens {
                formatted = formatted.replacingOccurrences(of: "-", with: "")
            }
            
            if !uppercase {
                formatted = formatted.lowercased()
            }
            
            results.append(formatted)
        }
        
        return results.joined(separator: "\n")
    }
    
    // MARK: - 颜色转换
    
    /// 转换颜色格式（自动识别）
    static func convertColor(_ input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检测格式
        if trimmed.hasPrefix("#") {
            // HEX 格式
            return try convertFromHex(trimmed)
        } else if trimmed.lowercased().hasPrefix("rgb") {
            // RGB 格式
            return try convertFromRGB(trimmed)
        } else if trimmed.lowercased().hasPrefix("hsl") {
            // HSL 格式
            return try convertFromHSL(trimmed)
        } else {
            throw ColorError.invalidFormat
        }
    }
    
    /// 从 HEX 转换
    private static func convertFromHex(_ hex: String) throws -> String {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")
        
        // 支持 3 位和 6 位 HEX
        if cleaned.count == 3 {
            cleaned = cleaned.map { "\($0)\($0)" }.joined()
        }
        
        guard cleaned.count == 6,
              let hexValue = Int(cleaned, radix: 16) else {
            throw ColorError.invalidHex
        }
        
        let r = (hexValue >> 16) & 0xFF
        let g = (hexValue >> 8) & 0xFF
        let b = hexValue & 0xFF
        
        let (h, s, l) = rgbToHSL(r: r, g: g, b: b)
        
        var result = "HEX：#\(cleaned.uppercased())\n"
        result += "RGB：rgb(\(r), \(g), \(b))\n"
        result += "HSL：hsl(\(h)°, \(s)%, \(l)%)\n"
        result += "\n预览：\n"
        result += "R: \(r) (0x\(String(format: "%02X", r)))\n"
        result += "G: \(g) (0x\(String(format: "%02X", g)))\n"
        result += "B: \(b) (0x\(String(format: "%02X", b)))"
        
        return result
    }
    
    /// 从 RGB 转换
    private static func convertFromRGB(_ rgb: String) throws -> String {
        // 解析 rgb(r, g, b) 或 rgba(r, g, b, a)
        let pattern = #"rgba?\((\d+),\s*(\d+),\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: rgb, range: NSRange(rgb.startIndex..., in: rgb)) else {
            throw ColorError.invalidRGB
        }
        
        guard let rRange = Range(match.range(at: 1), in: rgb),
              let gRange = Range(match.range(at: 2), in: rgb),
              let bRange = Range(match.range(at: 3), in: rgb),
              let r = Int(rgb[rRange]),
              let g = Int(rgb[gRange]),
              let b = Int(rgb[bRange]),
              r >= 0 && r <= 255,
              g >= 0 && g <= 255,
              b >= 0 && b <= 255 else {
            throw ColorError.invalidRGB
        }
        
        let hexValue = (r << 16) | (g << 8) | b
        let hexString = String(format: "%06X", hexValue)
        
        let (h, s, l) = rgbToHSL(r: r, g: g, b: b)
        
        var result = "RGB：rgb(\(r), \(g), \(b))\n"
        result += "HEX：#\(hexString)\n"
        result += "HSL：hsl(\(h)°, \(s)%, \(l)%)\n"
        result += "\n预览：\n"
        result += "R: \(r) (0x\(String(format: "%02X", r)))\n"
        result += "G: \(g) (0x\(String(format: "%02X", g)))\n"
        result += "B: \(b) (0x\(String(format: "%02X", b)))"
        
        return result
    }
    
    /// 从 HSL 转换
    private static func convertFromHSL(_ hsl: String) throws -> String {
        // 解析 hsl(h, s%, l%)
        let pattern = #"hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: hsl, range: NSRange(hsl.startIndex..., in: hsl)) else {
            throw ColorError.invalidHSL
        }
        
        guard let hRange = Range(match.range(at: 1), in: hsl),
              let sRange = Range(match.range(at: 2), in: hsl),
              let lRange = Range(match.range(at: 3), in: hsl),
              let h = Int(hsl[hRange]),
              let s = Int(hsl[sRange]),
              let l = Int(hsl[lRange]),
              h >= 0 && h <= 360,
              s >= 0 && s <= 100,
              l >= 0 && l <= 100 else {
            throw ColorError.invalidHSL
        }
        
        let (r, g, b) = hslToRGB(h: h, s: s, l: l)
        
        let hexValue = (r << 16) | (g << 8) | b
        let hexString = String(format: "%06X", hexValue)
        
        var result = "HSL：hsl(\(h)°, \(s)%, \(l)%)\n"
        result += "RGB：rgb(\(r), \(g), \(b))\n"
        result += "HEX：#\(hexString)\n"
        result += "\n预览：\n"
        result += "R: \(r) (0x\(String(format: "%02X", r)))\n"
        result += "G: \(g) (0x\(String(format: "%02X", g)))\n"
        result += "B: \(b) (0x\(String(format: "%02X", b)))"
        
        return result
    }
    
    // MARK: - 正则表达式测试
    
    /// 测试正则表达式
    static func testRegex(pattern: String, text: String, options: RegexOptions = RegexOptions()) throws -> String {
        var regexOptions: NSRegularExpression.Options = []
        if options.caseInsensitive {
            regexOptions.insert(.caseInsensitive)
        }
        if options.multiline {
            regexOptions.insert(.anchorsMatchLines)
        }
        if options.dotMatchesLineSeparators {
            regexOptions.insert(.dotMatchesLineSeparators)
        }
        
        let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        var result = "正则表达式：\(pattern)\n"
        result += "匹配数量：\(matches.count)\n"
        result += "\n"
        
        if matches.isEmpty {
            result += "❌ 没有找到匹配项"
        } else {
            result += "✅ 找到 \(matches.count) 个匹配项：\n\n"
            
            for (index, match) in matches.enumerated() {
                if let range = Range(match.range, in: text) {
                    let matchedText = String(text[range])
                    result += "[\(index + 1)] \(matchedText)\n"
                    
                    // 显示捕获组
                    if match.numberOfRanges > 1 {
                        result += "  捕获组：\n"
                        for i in 1..<match.numberOfRanges {
                            if let groupRange = Range(match.range(at: i), in: text) {
                                let groupText = String(text[groupRange])
                                result += "    (\(i)) \(groupText)\n"
                            }
                        }
                    }
                    result += "\n"
                }
            }
        }
        
        return result
    }
    
    // MARK: - 辅助方法
    
    /// RGB 转 HSL
    private static func rgbToHSL(r: Int, g: Int, b: Int) -> (h: Int, s: Int, l: Int) {
        let rNorm = Double(r) / 255.0
        let gNorm = Double(g) / 255.0
        let bNorm = Double(b) / 255.0
        
        let maxVal = max(rNorm, gNorm, bNorm)
        let minVal = min(rNorm, gNorm, bNorm)
        let delta = maxVal - minVal
        
        var h: Double = 0
        var s: Double = 0
        let l = (maxVal + minVal) / 2.0
        
        if delta != 0 {
            s = l > 0.5 ? delta / (2.0 - maxVal - minVal) : delta / (maxVal + minVal)
            
            if maxVal == rNorm {
                h = ((gNorm - bNorm) / delta) + (gNorm < bNorm ? 6 : 0)
            } else if maxVal == gNorm {
                h = ((bNorm - rNorm) / delta) + 2
            } else {
                h = ((rNorm - gNorm) / delta) + 4
            }
            
            h /= 6.0
        }
        
        return (Int(h * 360), Int(s * 100), Int(l * 100))
    }
    
    /// HSL 转 RGB
    private static func hslToRGB(h: Int, s: Int, l: Int) -> (r: Int, g: Int, b: Int) {
        let hNorm = Double(h) / 360.0
        let sNorm = Double(s) / 100.0
        let lNorm = Double(l) / 100.0
        
        if sNorm == 0 {
            let gray = Int(lNorm * 255)
            return (gray, gray, gray)
        }
        
        let q = lNorm < 0.5 ? lNorm * (1 + sNorm) : lNorm + sNorm - lNorm * sNorm
        let p = 2 * lNorm - q
        
        func hueToRGB(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1/6 { return p + (q - p) * 6 * t }
            if t < 1/2 { return q }
            if t < 2/3 { return p + (q - p) * (2/3 - t) * 6 }
            return p
        }
        
        let r = Int(hueToRGB(p, q, hNorm + 1/3) * 255)
        let g = Int(hueToRGB(p, q, hNorm) * 255)
        let b = Int(hueToRGB(p, q, hNorm - 1/3) * 255)
        
        return (r, g, b)
    }
}

// MARK: - 正则表达式选项

struct RegexOptions {
    var caseInsensitive: Bool = false
    var multiline: Bool = false
    var dotMatchesLineSeparators: Bool = false
}

// MARK: - 错误类型

enum ColorError: Error, LocalizedError {
    case invalidFormat
    case invalidHex
    case invalidRGB
    case invalidHSL
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "无法识别的颜色格式，支持 HEX (#RRGGBB)、RGB (rgb(r,g,b))、HSL (hsl(h,s%,l%))"
        case .invalidHex:
            return "无效的 HEX 格式，应为 #RRGGBB 或 #RGB"
        case .invalidRGB:
            return "无效的 RGB 格式，应为 rgb(r, g, b)，值范围 0-255"
        case .invalidHSL:
            return "无效的 HSL 格式，应为 hsl(h, s%, l%)，H: 0-360, S/L: 0-100"
        }
    }
}
