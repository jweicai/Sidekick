//
//  TableQueryApp.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import SwiftUI
import AppKit

@main
struct TableQueryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    // 确保窗口获得焦点
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.windows.first?.makeKeyAndOrderFront(nil)
                    }
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
        }
    }
}

/// AppDelegate 用于处理应用级别的事件
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用激活策略为常规应用（而不是辅助应用）
        NSApp.setActivationPolicy(.regular)
        
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
