//
//  DesignSystem.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import SwiftUI

/// 设计系统 - 参考 Apifox 风格
enum DesignSystem {
    
    // MARK: - Colors
    
    enum Colors {
        // 主题色 - 紫色调
        static let accent = Color(hex: "7C3AED")
        static let accentLight = Color(hex: "A78BFA")
        static let accentDark = Color(hex: "5B21B6")
        
        // 状态色
        static let success = Color(hex: "10B981")
        static let warning = Color(hex: "F59E0B")
        static let error = Color(hex: "EF4444")
        static let info = Color(hex: "3B82F6")
        
        // 最左侧功能栏（浅灰色）
        static let navBackground = Color(hex: "F3F4F6")
        static let navHover = Color(hex: "E5E7EB")
        static let navSelected = Color(hex: "E0E2E7")
        static let navText = Color(hex: "6B7280")
        static let navTextActive = Color(hex: "374151")
        
        // 第二栏侧边栏（浅色）
        static let sidebarBackground = Color(hex: "F8F9FB")
        static let sidebarHover = Color(hex: "EEF0F4")
        static let sidebarSelected = Color(hex: "E8EAEF")
        static let sidebarText = Color(hex: "6B7280")
        static let sidebarTextActive = Color(hex: "1F2937")
        
        // 主内容区背景
        static let background = Color.white
        static let secondaryBackground = Color(hex: "F9FAFB")
        static let tertiaryBackground = Color(hex: "F3F4F6")
        
        // 文字颜色
        static let textPrimary = Color(hex: "1F2937")
        static let textSecondary = Color(hex: "6B7280")
        static let textMuted = Color(hex: "9CA3AF")
        
        // 边框和分隔线
        static let separator = Color(hex: "E5E7EB")
        static let border = Color(hex: "E5E7EB")
        static let borderLight = Color(hex: "F3F4F6")
        
        // 数据类型颜色
        static let typeInteger = Color(hex: "3B82F6")
        static let typeReal = Color(hex: "10B981")
        static let typeText = Color(hex: "F59E0B")
        static let typeBoolean = Color(hex: "8B5CF6")
        static let typeDate = Color(hex: "06B6D4")
        static let typeNull = Color(hex: "9CA3AF")
        
        // 表格颜色
        static let tableHeader = Color(hex: "F9FAFB")
        static let tableRowEven = Color.white
        static let tableRowOdd = Color(hex: "F9FAFB")
        static let tableRowHover = Color(hex: "F3F4F6")
    }
    
    // MARK: - Typography
    
    enum Typography {
        static let title1 = Font.system(size: 24, weight: .bold, design: .default)
        static let title2 = Font.system(size: 18, weight: .semibold, design: .default)
        static let title3 = Font.system(size: 15, weight: .medium, design: .default)
        static let body = Font.system(size: 13, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 13, weight: .medium, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let captionMedium = Font.system(size: 11, weight: .medium, design: .default)
        static let code = Font.system(size: 12, weight: .regular, design: .monospaced)
        static let codeLarge = Font.system(size: 13, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 6
        static let large: CGFloat = 8
        static let xlarge: CGFloat = 12
    }
    
    // MARK: - Shadows
    
    enum Shadows {
        static let small = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let large = Color.black.opacity(0.15)
    }
    
    // MARK: - Animation Durations
    
    enum Animation {
        static let fast: Double = 0.15
        static let medium: Double = 0.2
        static let slow: Double = 0.3
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.accent)
            .cornerRadius(DesignSystem.CornerRadius.medium)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.accent)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.accent.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}
