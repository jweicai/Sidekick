//
//  LicenseManager.swift
//  Sidekick
//
//  Created on 2025-01-14.
//

import Foundation
import Combine

/// 许可证管理器
class LicenseManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isActivated: Bool = false
    @Published var trialDaysRemaining: Int = 90
    @Published var licenseEmail: String = ""
    
    // MARK: - Constants
    
    private let trialDays = 90
    private let licenseKey = "Sidekick.License"
    private let trialStartKey = "Sidekick.TrialStart"
    
    // MARK: - Singleton
    
    static let shared = LicenseManager()
    
    private init() {
        checkLicenseStatus()
    }
    
    // MARK: - Public Methods
    
    /// 检查许可证状态
    func checkLicenseStatus() {
        // 1. 检查是否已激活
        if let license = loadLicense(), validateLicense(license) {
            isActivated = true
            licenseEmail = license.email
            return
        }
        
        // 2. 检查试用期
        let trialStart = getTrialStartDate()
        let daysPassed = Calendar.current.dateComponents([.day], from: trialStart, to: Date()).day ?? 0
        trialDaysRemaining = max(0, trialDays - daysPassed)
        isActivated = false
    }
    
    /// 是否在试用期
    var isInTrial: Bool {
        return !isActivated && trialDaysRemaining > 0
    }
    
    /// 试用期是否已过期
    var isExpired: Bool {
        return !isActivated && trialDaysRemaining <= 0
    }
    
    /// 激活许可证
    func activate(licenseKey: String, email: String) -> Result<Void, LicenseError> {
        // 1. 验证格式
        let cleanKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard isValidLicenseFormat(cleanKey) else {
            return .failure(.invalidFormat)
        }
        
        guard isValidEmail(cleanEmail) else {
            return .failure(.invalidEmail)
        }
        
        // 2. 获取机器码
        let machineID = MachineID.get()
        
        // 3. 验证激活码
        guard validateActivationCode(cleanKey, email: cleanEmail, machineID: machineID) else {
            return .failure(.invalidLicense)
        }
        
        // 4. 保存许可证
        let license = License(
            key: cleanKey,
            email: cleanEmail,
            machineID: machineID,
            activatedAt: Date()
        )
        
        saveLicense(license)
        
        // 5. 更新状态
        isActivated = true
        licenseEmail = cleanEmail
        
        return .success(())
    }
    
    /// 获取机器码（用于购买时提供）
    func getMachineID() -> String {
        return MachineID.get()
    }
    
    // MARK: - Private Methods
    
    /// 获取试用开始日期
    private func getTrialStartDate() -> Date {
        if let trialStart = UserDefaults.standard.object(forKey: trialStartKey) as? Date {
            return trialStart
        }
        
        // 首次启动，记录试用开始时间
        let now = Date()
        UserDefaults.standard.set(now, forKey: trialStartKey)
        return now
    }
    
    /// 验证激活码格式
    private func isValidLicenseFormat(_ key: String) -> Bool {
        // 格式：XXXX-XXXX-XXXX-XXXX
        let pattern = "^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"
        return key.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// 验证邮箱格式
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    
    /// 验证激活码（本地验证）
    private func validateActivationCode(_ key: String, email: String, machineID: String) -> Bool {
        // 简单的本地验证逻辑
        // 实际使用时，你可以：
        // 1. 使用服务器验证
        // 2. 使用加密算法验证
        // 3. 使用签名验证
        
        // 这里使用简单的哈希验证作为示例
        let combined = "\(email)|\(machineID)|SIDEKICK_SECRET"
        let hash = combined.sha256()
        let expectedPrefix = String(hash.prefix(16)).uppercased()
        let keyWithoutDashes = key.replacingOccurrences(of: "-", with: "")
        
        return keyWithoutDashes == expectedPrefix
    }
    
    /// 验证许可证
    private func validateLicense(_ license: License) -> Bool {
        // 1. 检查机器码是否匹配
        let currentMachineID = MachineID.get()
        guard license.machineID == currentMachineID else {
            return false
        }
        
        // 2. 验证激活码
        return validateActivationCode(license.key, email: license.email, machineID: license.machineID)
    }
    
    /// 保存许可证
    private func saveLicense(_ license: License) {
        if let encoded = try? JSONEncoder().encode(license) {
            UserDefaults.standard.set(encoded, forKey: licenseKey)
        }
    }
    
    /// 加载许可证
    private func loadLicense() -> License? {
        guard let data = UserDefaults.standard.data(forKey: licenseKey),
              let license = try? JSONDecoder().decode(License.self, from: data) else {
            return nil
        }
        return license
    }
}

// MARK: - Data Models

/// 许可证
struct License: Codable {
    let key: String
    let email: String
    let machineID: String
    let activatedAt: Date
}

/// 许可证错误
enum LicenseError: LocalizedError {
    case invalidFormat
    case invalidEmail
    case invalidLicense
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "激活码格式不正确，应为 XXXX-XXXX-XXXX-XXXX"
        case .invalidEmail:
            return "邮箱地址格式不正确"
        case .invalidLicense:
            return "激活码无效或已被使用"
        case .networkError:
            return "网络连接失败，请稍后重试"
        }
    }
}
