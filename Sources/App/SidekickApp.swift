//
//  SidekickApp.swift
//  Sidekick
//
//  Created on 2025-01-12.
//

import SwiftUI
import AppKit

@main
struct SidekickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var showActivationSheet = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .disabled(licenseManager.isExpired)
                    .blur(radius: licenseManager.isExpired ? 3 : 0)
                
                // 试用期过期遮罩
                if licenseManager.isExpired {
                    TrialExpiredOverlay(showActivationSheet: $showActivationSheet)
                }
            }
            .onAppear {
                // 确保窗口获得焦点
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }
                
                // 检查许可证状态
                licenseManager.checkLicenseStatus()
                
                // 如果试用期过期，显示激活界面
                if licenseManager.isExpired {
                    showActivationSheet = true
                }
            }
            .sheet(isPresented: $showActivationSheet) {
                ActivationView()
            }
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("添加文件...") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenFile"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // 添加许可证菜单
            CommandGroup(after: .appInfo) {
                Button("激活许可证...") {
                    showActivationSheet = true
                }
                
                Divider()
                
                if licenseManager.isInTrial {
                    Button("试用期剩余 \(licenseManager.trialDaysRemaining) 天") {
                        showActivationSheet = true
                    }
                }
            }
        }
    }
}

/// 试用期过期遮罩
struct TrialExpiredOverlay: View {
    @Binding var showActivationSheet: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
            }
            
            // 文本
            VStack(spacing: 12) {
                Text("试用期已结束")
                    .font(.system(size: 28, weight: .bold))
                
                Text("感谢您试用 Sidekick 90 天")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text("请购买激活码以继续使用")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // 按钮
            VStack(spacing: 12) {
                Button(action: { showActivationSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "key.fill")
                        Text("激活许可证")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    if let url = URL(string: "https://your-store.com/sidekick") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("购买激活码")
                    }
                    .foregroundColor(.blue)
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.98))
    }
}

/// AppDelegate 用于处理应用级别的事件
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用激活策略为常规应用（而不是辅助应用）
        NSApp.setActivationPolicy(.regular)
        
        // 强制使用浅色模式（禁用深色模式）
        NSApp.appearance = NSAppearance(named: .aqua)
        
        // 确保应用成为活动应用
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // 当应用变为活动状态时，确保窗口可以接收键盘输入
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
