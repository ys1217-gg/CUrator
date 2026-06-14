//
//  CUratorApp.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import SwiftData
import SwiftUI

@main
struct CUratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ContentItem.self, CategoryItem.self])
    }
}
