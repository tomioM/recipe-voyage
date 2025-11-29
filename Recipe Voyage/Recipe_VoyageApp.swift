import SwiftUI

// This is the entry point of the app
// It runs when the app launches

@main
struct RecipeBookApp: App {
    // Reference to our Core Data manager
    let persistenceController = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            // MosaicView is now our starting screen
            MosaicView()
                .preferredColorScheme(.light) // Always use light mode
        }
    }
}

// IMPORTANT: Make sure Info.plist has microphone permission!
// Key: "Privacy - Microphone Usage Description"
// Value: "This app needs microphone access to record voice notes for your recipes"
