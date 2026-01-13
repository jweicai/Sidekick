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
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
