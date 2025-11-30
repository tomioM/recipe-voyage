import CoreData
import SwiftUI

// This class manages all database operations
// Think of it as the librarian who organizes all your recipes
class CoreDataManager: ObservableObject {
    
    // "shared" means there's only one CoreDataManager for the whole app
    static let shared = CoreDataManager()
    
    // The container holds our database
    let container: NSPersistentContainer
    
    // @Published means: when this changes, update any views watching it
    // This is an array (list) of all recipes
    @Published var recipes: [RecipeEntity] = []
    
    // init() runs when we create the CoreDataManager
    init() {
        // Create/open the database file
        // "RecipeBook" must match your .xcdatamodeld file name
        container = NSPersistentContainer(name: "RecipeBook")
        
        // Load the database from disk
        container.loadPersistentStores { description, error in
            if let error = error {
                // If something went wrong, print it
                print("❌ Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        // Load all recipes into memory
        fetchRecipes()
    }
    
    // MARK: - Fetch Recipes
    // Get all recipes from the database
    func fetchRecipes() {
        // NSFetchRequest is like a search query
        let request = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        
        // Sort by sortOrder for manual arrangement
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \RecipeEntity.sortOrder, ascending: true)
        ]
        
        do {
            // Try to get the recipes
            recipes = try container.viewContext.fetch(request)
            print("📚 Loaded \(recipes.count) recipes")
        } catch {
            print("❌ Failed to fetch recipes: \(error)")
        }
    }
    
    // MARK: - Reorder Recipes
    // Move a recipe from one position to another
    func moveRecipe(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < recipes.count,
              destinationIndex >= 0, destinationIndex < recipes.count else {
            return
        }
        
        // Reorder the array
        var reordered = recipes
        let movedRecipe = reordered.remove(at: sourceIndex)
        reordered.insert(movedRecipe, at: destinationIndex)
        
        // Update sortOrder for all recipes
        for (index, recipe) in reordered.enumerated() {
            recipe.sortOrder = Int16(index)
        }
        
        saveContext()
        fetchRecipes()
        
        print("🔀 Reordered recipes")
    }
    
    // MARK: - Create Recipe
    // Make a new recipe and save it
    func createRecipe(title: String, symbol: String, color: String, description: String) -> RecipeEntity {
        // Create a new recipe object
        let recipe = RecipeEntity(context: container.viewContext)
        
        // Fill in the details
        recipe.id = UUID() // Unique identifier
        recipe.title = title
        recipe.symbol = symbol
        recipe.colorHex = color
        recipe.recipeDescription = description
        recipe.createdDate = Date() // Right now
        recipe.sortOrder = Int16(recipes.count) // Add to end
        
        // Save to database
        saveContext()
        
        // Reload the recipes list
        fetchRecipes()
        
        print("✅ Created recipe: \(title)")
        return recipe
    }
    
    // MARK: - Update Recipe
    // Change an existing recipe
    func updateRecipe(_ recipe: RecipeEntity, title: String, symbol: String, color: String, description: String) {
        recipe.title = title
        recipe.symbol = symbol
        recipe.colorHex = color
        recipe.recipeDescription = description
        
        saveContext()
        fetchRecipes()
        
        print("✅ Updated recipe: \(title)")
    }
    
    // MARK: - Delete Recipe
    // Remove a recipe (and its audio files)
    func deleteRecipe(_ recipe: RecipeEntity) {
        // First, delete any audio files on disk
        if let audioNotes = recipe.audioNotes as? Set<AudioNoteEntity> {
            for note in audioNotes {
                deleteAudioFile(note.audioFileName ?? "")
            }
        }
        
        // Delete from database
        container.viewContext.delete(recipe)
        saveContext()
        fetchRecipes()
        
        print("🗑️ Deleted recipe: \(recipe.title ?? "Unknown")")
    }
    
    // MARK: - Ingredients
    // Add an ingredient to a recipe
    func addIngredient(to recipe: RecipeEntity, name: String, quantity: String) {
        let ingredient = IngredientEntity(context: container.viewContext)
        ingredient.id = UUID()
        ingredient.name = name
        ingredient.quantity = quantity
        ingredient.sortOrder = Int16((recipe.ingredients?.count ?? 0))
        ingredient.recipe = recipe // Connect to recipe
        
        saveContext()
        print("✅ Added ingredient: \(name)")
    }
    
    func deleteIngredient(_ ingredient: IngredientEntity) {
        container.viewContext.delete(ingredient)
        saveContext()
    }
    
    // MARK: - Steps
    // Add a preparation step to a recipe
    func addStep(to recipe: RecipeEntity, instruction: String) {
        let step = StepEntity(context: container.viewContext)
        step.id = UUID()
        step.instruction = instruction
        step.sortOrder = Int16((recipe.steps?.count ?? 0))
        step.recipe = recipe
        
        saveContext()
        print("✅ Added step: \(instruction)")
    }
    
    func deleteStep(_ step: StepEntity) {
        container.viewContext.delete(step)
        saveContext()
    }
    
    // MARK: - Audio Notes
    // Add an audio recording to a recipe
    func addAudioNote(to recipe: RecipeEntity, fileName: String, duration: Double) {
        let audioNote = AudioNoteEntity(context: container.viewContext)
        audioNote.id = UUID()
        audioNote.audioFileName = fileName
        audioNote.duration = duration
        audioNote.createdDate = Date()
        audioNote.recipe = recipe
        
        saveContext()
        print("🎤 Added audio note: \(fileName)")
    }
    
    func deleteAudioNote(_ note: AudioNoteEntity) {
        if let fileName = note.audioFileName {
            deleteAudioFile(fileName)
        }
        container.viewContext.delete(note)
        saveContext()
    }
    
    // MARK: - Private Helpers
    // Save changes to database
    private func saveContext() {
        do {
            try container.viewContext.save()
            print("💾 Saved to database")
        } catch {
            print("❌ Failed to save: \(error)")
        }
    }
    
    // Delete an audio file from disk
    private func deleteAudioFile(_ fileName: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: filePath)
        print("🗑️ Deleted audio file: \(fileName)")
    }
}

// MARK: - Helper Extensions
// These make it easier to work with Core Data relationships

extension RecipeEntity {
    // Get ingredients as a sorted array (instead of a Set)
    var ingredientsArray: [IngredientEntity] {
        let set = ingredients as? Set<IngredientEntity> ?? []
        return set.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // Get steps as a sorted array
    var stepsArray: [StepEntity] {
        let set = steps as? Set<StepEntity> ?? []
        return set.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // Get audio notes, newest first
    var audioNotesArray: [AudioNoteEntity] {
        let set = audioNotes as? Set<AudioNoteEntity> ?? []
        return set.sorted {
            ($0.createdDate ?? Date()) > ($1.createdDate ?? Date())
        }
    }
    
    // Convert hex color string to SwiftUI Color
    var displayColor: Color {
        Color(hex: colorHex ?? "#8B4513") ?? .brown
    }
}

// MARK: - Color Extension
// Allows us to create colors from hex strings like "#FF0000"

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    // Convert Color to hex string
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
