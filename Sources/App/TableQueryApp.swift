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
/// 这是解决 SwiftUI macOS 应用键盘输入问题的关键
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 确保应用成为活动应用并接受键盘输入
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // 当应用变为活动状态时，确保窗口可以接收键盘输入
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
