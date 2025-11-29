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
