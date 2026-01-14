//
//  TimestampToolsView.swift
//  TableQuery
//
//  Created on 2025-01-13.
//

import SwiftUI

// MARK: - 统一的时间戳转换视图

struct TimestampConverterView: View {
    @State private var currentTimestamp: Int = Int(Date().timeIntervalSince1970)
    @State private var currentUnit: TimestampUnit = .seconds
    @State private var timer: Timer?
    @State private var isTimerRunning: Bool = true
    
    // 选项卡
    @State private var selectedTab: ConversionTab = .single
    
    // 时间戳转日期
    @State private var timestampInput: String = ""
    @State private var timestampOutput: String = ""
    @State private var timestampError: String?
    @State private var timestampUnit: TimestampUnit = .milliseconds
    @State private var timestampTimezone: String = "Asia/Shanghai"
    
    // 日期转时间戳
    @State private var dateInput: String = ""
    @State private var dateOutput: String = ""
    @State private var dateError: String?
    @State private var outputUnit: TimestampUnit = .seconds
    @State private var dateTimezone: String = "Asia/Shanghai"
    
    enum TimestampUnit: String, CaseIterable {
        case seconds = "秒(s)"
        case milliseconds = "毫秒(ms)"
        case microseconds = "微秒(μs)"
        
        var shortName: String {
            switch self {
            case .seconds: return "秒"
            case .milliseconds: return "毫秒"
            case .microseconds: return "微秒"
            }
        }
    }
    
    enum ConversionTab: String, CaseIterable {
        case single = "单个转换"
        case batch = "批量转换"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("时间戳转换")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background)
            
            Divider()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // 当前时间戳 - 大号显示
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("当前时间戳")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            // 大号时间戳显示
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(displayCurrentTimestamp())
                                    .font(.system(size: 36, weight: .regular, design: .default))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text(currentUnit.shortName)
                                    .font(.system(size: 16))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            // 操作按钮
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Button(action: toggleUnit) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 11))
                                        Text("切换单位")
                                            .font(DesignSystem.Typography.caption)
                                    }
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { copyToClipboard(displayCurrentTimestamp()) }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 11))
                                        Text("复制")
                                            .font(DesignSystem.Typography.caption)
                                    }
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: toggleTimer) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isTimerRunning ? "stop.fill" : "play.fill")
                                            .font(.system(size: 11))
                                        Text(isTimerRunning ? "停止" : "开始")
                                            .font(DesignSystem.Typography.caption)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isTimerRunning ? Color.red : DesignSystem.Colors.accent)
                                    .cornerRadius(DesignSystem.CornerRadius.small)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }
                    
                    // 选项卡
                    HStack(spacing: 0) {
                        ForEach(ConversionTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                Text(tab.rawValue)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(selectedTab == tab ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.sm)
                                    .background(selectedTab == tab ? Color.white : Color.clear)
                                    .overlay(
                                        Rectangle()
                                            .fill(selectedTab == tab ? DesignSystem.Colors.accent : Color.clear)
                                            .frame(height: 2),
                                        alignment: .bottom
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(DesignSystem.Colors.background)
                    .overlay(
                        Rectangle()
                            .fill(DesignSystem.Colors.border)
                            .frame(height: 1),
                        alignment: .bottom
                    )
                    
                    // 转换内容
                    if selectedTab == .single {
                        VStack(spacing: DesignSystem.Spacing.xl) {
                            // 时间戳转日期时间
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 13))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    Text("时间戳转日期时间")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                                
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    TextField("1768318890176", text: $timestampInput)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13, design: .monospaced))
                                        .padding(DesignSystem.Spacing.sm)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                        )
                                    
                                    Picker("", selection: $timestampUnit) {
                                        ForEach(TimestampUnit.allCases, id: \.self) { unit in
                                            Text(unit.rawValue).tag(unit)
                                        }
                                    }
                                    .frame(width: 100)
                                    .pickerStyle(.menu)
                                    
                                    Button(action: convertTimestamp) {
                                        Text("转换")
                                            .font(DesignSystem.Typography.body)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                                            .cornerRadius(DesignSystem.CornerRadius.small)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(timestampInput.isEmpty)
                                }
                                
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    TextField("转换结果", text: $timestampOutput)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13, design: .monospaced))
                                        .padding(DesignSystem.Spacing.sm)
                                        .background(DesignSystem.Colors.background)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                        )
                                        .disabled(true)
                                    
                                    Picker("", selection: $timestampTimezone) {
                                        Text("Asia/Shanghai").tag("Asia/Shanghai")
                                        Text("UTC").tag("UTC")
                                        Text("America/New_York").tag("America/New_York")
                                    }
                                    .frame(width: 140)
                                    .pickerStyle(.menu)
                                }
                                
                                if let error = timestampError {
                                    ErrorCard(message: error)
                                }
                            }
                            
                            // 日期时间转时间戳
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 13))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    Text("日期时间转时间戳")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                                
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    TextField("2026-01-13 23:41:30", text: $dateInput)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13, design: .monospaced))
                                        .padding(DesignSystem.Spacing.sm)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                        )
                                    
                                    Picker("", selection: $dateTimezone) {
                                        Text("Asia/Shanghai").tag("Asia/Shanghai")
                                        Text("UTC").tag("UTC")
                                        Text("America/New_York").tag("America/New_York")
                                    }
                                    .frame(width: 140)
                                    .pickerStyle(.menu)
                                    
                                    Button(action: convertDate) {
                                        Text("转换")
                                            .font(DesignSystem.Typography.body)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                                            .cornerRadius(DesignSystem.CornerRadius.small)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(dateInput.isEmpty)
                                }
                                
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    TextField("转换结果", text: $dateOutput)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13, design: .monospaced))
                                        .padding(DesignSystem.Spacing.sm)
                                        .background(DesignSystem.Colors.background)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                        )
                                        .disabled(true)
                                    
                                    Picker("", selection: $outputUnit) {
                                        ForEach(TimestampUnit.allCases, id: \.self) { unit in
                                            Text(unit.rawValue).tag(unit)
                                        }
                                    }
                                    .frame(width: 100)
                                    .pickerStyle(.menu)
                                }
                                
                                if let error = dateError {
                                    ErrorCard(message: error)
                                }
                            }
                        }
                    } else {
                        // 批量转换
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("批量转换功能即将推出")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(DesignSystem.Spacing.xl)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func displayCurrentTimestamp() -> String {
        switch currentUnit {
        case .seconds:
            return "\(currentTimestamp)"
        case .milliseconds:
            return "\(currentTimestamp * 1000)"
        case .microseconds:
            return "\(currentTimestamp * 1000000)"
        }
    }
    
    private func toggleUnit() {
        switch currentUnit {
        case .seconds:
            currentUnit = .milliseconds
        case .milliseconds:
            currentUnit = .microseconds
        case .microseconds:
            currentUnit = .seconds
        }
    }
    
    private func toggleTimer() {
        isTimerRunning.toggle()
        if isTimerRunning {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTimestamp = Int(Date().timeIntervalSince1970)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func convertTimestamp() {
        timestampError = nil
        timestampOutput = ""
        
        do {
            timestampOutput = try TimestampConverter.timestampToDate(
                timestampInput,
                unit: timestampUnit,
                timezone: timestampTimezone
            )
        } catch {
            timestampError = error.localizedDescription
        }
    }
    
    private func convertDate() {
        dateError = nil
        dateOutput = ""
        
        do {
            dateOutput = try TimestampConverter.dateToTimestamp(
                dateInput,
                unit: outputUnit,
                timezone: dateTimezone
            )
        } catch {
            dateError = error.localizedDescription
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - 错误卡片

struct ErrorCard: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundColor(DesignSystem.Colors.error)
            
            Text(message)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.error)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.error.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
}

// MARK: - 时间戳转换工具

struct TimestampConverter {
    /// 时间戳转日期
    static func timestampToDate(
        _ timestampString: String,
        unit: TimestampConverterView.TimestampUnit,
        timezone: String
    ) throws -> String {
        guard let timestamp = Double(timestampString) else {
            throw TimestampError.invalidTimestamp
        }
        
        // 根据单位转换为秒
        let timeInterval: TimeInterval
        switch unit {
        case .seconds:
            timeInterval = timestamp
        case .milliseconds:
            timeInterval = timestamp / 1000
        case .microseconds:
            timeInterval = timestamp / 1000000
        }
        
        let date = Date(timeIntervalSince1970: timeInterval)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: timezone)
        
        return formatter.string(from: date)
    }
    
    /// 日期转时间戳
    static func dateToTimestamp(
        _ dateString: String,
        unit: TimestampConverterView.TimestampUnit,
        timezone: String
    ) throws -> String {
        let formatters = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd"
        ]
        
        var date: Date?
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = TimeZone(identifier: timezone)
            if let parsedDate = formatter.date(from: dateString) {
                date = parsedDate
                break
            }
        }
        
        guard let date = date else {
            throw TimestampError.invalidDateFormat
        }
        
        let timestamp = date.timeIntervalSince1970
        
        // 根据单位返回结果
        let result: String
        switch unit {
        case .seconds:
            result = "\(Int(timestamp))"
        case .milliseconds:
            result = "\(Int(timestamp * 1000))"
        case .microseconds:
            result = "\(Int(timestamp * 1000000))"
        }
        
        return result
    }
}

enum TimestampError: Error, LocalizedError {
    case invalidTimestamp
    case invalidDateFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidTimestamp:
            return "无效的时间戳格式"
        case .invalidDateFormat:
            return "无效的日期格式，支持格式：YYYY-MM-DD HH:mm:ss"
        }
    }
}
