import SwiftUI

@main
struct RecipeBookApp: App {
    let persistenceController = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            MosaicView()
                .preferredColorScheme(.light)
        }
    }
}
