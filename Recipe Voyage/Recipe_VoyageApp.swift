//
//  Recipe_VoyageApp.swift
//  Recipe Voyage
//
//  Created by Tomio Walkley-Miyagawa on 2025-11-29.
//

import SwiftUI

@main
struct Recipe_VoyageApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
