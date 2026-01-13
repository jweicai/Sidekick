//
//  DesignSystem.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import SwiftUI

/// 设计系统 - 遵循 macOS Human Interface Guidelines 的设计语言
enum DesignSystem {
    
    // MARK: - Colors
    
    enum Colors {
        // Accent Colors (macOS standard)
        static let accent = Color.accentColor  // System blue #007AFF
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // System Colors (auto-adapting to light/dark mode)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let background = Color(NSColor.windowBackgroundColor)
        static let secondaryBackground = Color(NSColor.controlBackgroundColor)
        static let separator = Color(NSColor.separatorColor)
        
        // Data Type Colors
        static let typeInteger = Color.blue
        static let typeReal = Color.green
        static let typeText = Color.orange
        static let typeBoolean = Color.purple
        static let typeDate = Color.cyan
        static let typeNull = Color.gray
    }
    
    // MARK: - Typography
    
    enum Typography {
        static let title1 = Font.system(size: 24, weight: .bold, design: .default)
        static let title2 = Font.system(size: 18, weight: .semibold, design: .default)
        static let title3 = Font.system(size: 15, weight: .medium, design: .default)
        static let body = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let code = Font.system(size: 12, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 6
        static let large: CGFloat = 8
    }
    
    // MARK: - Animation Durations
    
    enum Animation {
        static let fast: Double = 0.15
        static let medium: Double = 0.2
        static let slow: Double = 0.3
    }
}

// MARK: - View Extensions for Common Patterns

extension View {
    /// 主按钮样式 (macOS 标准蓝色按钮)
    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.body)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.accent)
            .cornerRadius(DesignSystem.CornerRadius.medium)
    }
    
    /// 次要按钮样式 (macOS 边框按钮)
    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.accent)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.accent.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.small)
    }
    
    /// Source List 风格 (类似 Finder/Xcode 侧边栏)
    func sourceListStyle() -> some View {
        self
            .listStyle(.sidebar)
    }
}

