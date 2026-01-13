//
//  TableQueryApp.swift
//  TableQuery
//
//  Created on 2025-01-12.
//

import SwiftUI

@main
struct TableQueryApp: App {
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
