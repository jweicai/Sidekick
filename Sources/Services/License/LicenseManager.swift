//
//  LicenseManager.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import Foundation

/// 许可证类型
enum LicenseType: String, Codable {
    case free = "免费版"
    case pro = "专业版"
    case enterprise = "企业版"
}

/// 许可证信息
struct License: Codable {
    let type: LicenseType
    let expiryDate: Date?
    let features: [String: Bool]
    
    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return Date() > expiry
    }
}

/// 功能限制配置
struct FeatureLimits {
    let maxRowsPerTable: Int
    let maxTables: Int
    let maxExportSize: Int
    let allowedFormats: [String]
    let allowedTools: [String]
}

/// 许可证管理器
class LicenseManager {
    static let shared = LicenseManager()
    
    private let licenseKey = "TableQuery.License"
    private var currentLicense: License?
    
    private init() {
        loadLicense()
    }
    
    // MARK: - License Management
    
    /// 获取当前许可证类型
    var licenseType: LicenseType {
        if let license = currentLicense, !license.isExpired {
            return license.type
        }
        return .free
    }
    
    /// 加载许可证
    private func loadLicense() {
        guard let data = UserDefaults.standard.data(forKey: licenseKey),
              let license = try? JSONDecoder().decode(License.self, from: data) else {
            // 默认免费版
            currentLicense = createFreeLicense()
            return
        }
        currentLicense = license
    }
    
    /// 保存许可证
    private func saveLicense(_ license: License) {
        if let data = try? JSONEncoder().encode(license) {
            UserDefaults.standard.set(data, forKey: licenseKey)
            currentLicense = license
        }
    }
    
    /// 创建免费版许可证
    private func createFreeLicense() -> License {
        License(
            type: .free,
            expiryDate: nil,
            features: [
                "unlimited_tables": false,
                "unlimited_rows": false,
                "export_all_formats": false,
                "all_tools": false,
                "advanced_query": false,
                "batch_operations": false
            ]
        )
    }
    
    /// 激活许可证
    /// - Parameter key: 许可证密钥
    /// - Returns: 是否激活成功
    func activateLicense(key: String) -> (success: Bool, message: String) {
        guard let license = LicenseKeyValidator.validateLicenseKey(key) else {
            return (false, "无效的许可证密钥")
        }
        
        if license.isExpired {
            return (false, "许可证已过期")
        }
        
        saveLicense(license)
        return (true, "许可证激活成功！")
    }
    
    /// 停用许可证（恢复到免费版）
    func deactivateLicense() {
        let freeLicense = createFreeLicense()
        saveLicense(freeLicense)
    }
    
    /// 激活专业版（用于测试）
    func activateProLicense(expiryDate: Date? = nil) {
        let license = License(
            type: .pro,
            expiryDate: expiryDate,
            features: [
                "unlimited_tables": true,
                "unlimited_rows": true,
                "export_all_formats": true,
                "all_tools": true,
                "advanced_query": true,
                "batch_operations": false
            ]
        )
        saveLicense(license)
    }
    
    /// 激活企业版（用于测试）
    func activateEnterpriseLicense(expiryDate: Date? = nil) {
        let license = License(
            type: .enterprise,
            expiryDate: expiryDate,
            features: [
                "unlimited_tables": true,
                "unlimited_rows": true,
                "export_all_formats": true,
                "all_tools": true,
                "advanced_query": true,
                "batch_operations": true
            ]
        )
        saveLicense(license)
    }
    
    // MARK: - Feature Limits
    
    /// 获取当前版本的功能限制
    var limits: FeatureLimits {
        switch licenseType {
        case .free:
            return FeatureLimits(
                maxRowsPerTable: 1000,
                maxTables: 3,
                maxExportSize: 1000,
                allowedFormats: ["csv", "json"],
                allowedTools: ["json.flatten", "json.format"]
            )
        case .pro:
            return FeatureLimits(
                maxRowsPerTable: 100000,
                maxTables: 20,
                maxExportSize: 100000,
                allowedFormats: ["csv", "json", "xlsx", "sql"],
                allowedTools: [
                    "json.flatten", "json.format", "json.compress", "json.validate",
                    "ip.convert", "ip.subnet",
                    "timestamp.toDate", "timestamp.toTimestamp",
                    "text.base64", "text.url"
                ]
            )
        case .enterprise:
            return FeatureLimits(
                maxRowsPerTable: Int.max,
                maxTables: Int.max,
                maxExportSize: Int.max,
                allowedFormats: ["csv", "json", "xlsx", "sql", "parquet"],
                allowedTools: [] // 空数组表示所有工具都可用
            )
        }
    }
    
    // MARK: - Permission Checks
    
    /// 检查是否可以添加更多表
    func canAddMoreTables(currentCount: Int) -> Bool {
        return currentCount < limits.maxTables
    }
    
    /// 检查是否可以导入指定行数
    func canImportRows(count: Int) -> Bool {
        return count <= limits.maxRowsPerTable
    }
    
    /// 获取允许导入的最大行数
    func getMaxImportRows(requestedRows: Int) -> Int {
        return min(requestedRows, limits.maxRowsPerTable)
    }
    
    /// 检查是否支持指定格式
    func supportsFormat(_ format: String) -> Bool {
        return limits.allowedFormats.contains(format.lowercased())
    }
    
    /// 检查是否可以使用指定工具
    func canUseTool(_ toolId: String) -> Bool {
        // 企业版所有工具都可用
        if licenseType == .enterprise {
            return true
        }
        return limits.allowedTools.contains(toolId)
    }
    
    /// 检查功能是否可用
    func hasFeature(_ feature: String) -> Bool {
        guard let license = currentLicense else { return false }
        return license.features[feature] ?? false
    }
    
    // MARK: - Upgrade Prompts
    
    /// 获取升级提示信息
    func getUpgradeMessage(for feature: String) -> String {
        switch licenseType {
        case .free:
            return "此功能需要升级到专业版或企业版"
        case .pro:
            return "此功能仅在企业版中可用"
        case .enterprise:
            return ""
        }
    }
    
    /// 获取限制提示信息
    func getLimitMessage(for limitType: String) -> String {
        switch limitType {
        case "rows":
            return "免费版最多支持 \(limits.maxRowsPerTable) 行数据，升级到专业版可支持 100,000 行"
        case "tables":
            return "免费版最多支持 \(limits.maxTables) 个数据表，升级到专业版可支持 20 个"
        case "export":
            return "免费版导出限制为 \(limits.maxExportSize) 行，升级解除限制"
        default:
            return "升级到专业版或企业版以解锁更多功能"
        }
    }
}
