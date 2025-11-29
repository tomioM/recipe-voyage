//
//  Test_AppApp.swift
//  Test App
//
//  Created by Tomio Walkley-Miyagawa on 2025-11-29.
//

import SwiftUI

@main
struct RecipeBookApp: App {
    // Use our CoreDataManager instead
    let dataManager = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Always use light mode
        }
    }
}
