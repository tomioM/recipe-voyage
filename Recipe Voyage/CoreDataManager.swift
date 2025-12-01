import CoreData
import SwiftUI

// This class manages all database operations
class CoreDataManager: ObservableObject {
    
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    // Main mosaic recipes (not in inbox)
    @Published var recipes: [RecipeEntity] = []
    
    // Inbox recipes (received from others)
    @Published var inboxRecipes: [RecipeEntity] = []
    
    init() {
        container = NSPersistentContainer(name: "RecipeBook")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        fetchRecipes()
    }
    
    // MARK: - Fetch Recipes
    
    func fetchRecipes() {
        // Fetch main mosaic recipes
        let mainRequest = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        mainRequest.predicate = NSPredicate(format: "isInInbox == NO OR isInInbox == nil")
        mainRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \RecipeEntity.sortOrder, ascending: true)
        ]
        
        // Fetch inbox recipes
        let inboxRequest = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        inboxRequest.predicate = NSPredicate(format: "isInInbox == YES")
        inboxRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \RecipeEntity.createdDate, ascending: false)
        ]
        
        do {
            recipes = try container.viewContext.fetch(mainRequest)
            inboxRecipes = try container.viewContext.fetch(inboxRequest)
            print("📚 Loaded \(recipes.count) recipes, \(inboxRecipes.count) in inbox")
        } catch {
            print("❌ Failed to fetch recipes: \(error)")
        }
    }
    
    // MARK: - Move Recipe from Inbox to Mosaic
    
    func moveFromInboxToMosaic(_ recipe: RecipeEntity, atIndex: Int? = nil) {
        recipe.isInInbox = false
        
        if let index = atIndex, index < recipes.count {
            recipe.sortOrder = Int16(index)
            // Shift other recipes
            for i in index..<recipes.count {
                recipes[i].sortOrder = Int16(i + 1)
            }
        } else {
            recipe.sortOrder = Int16(recipes.count)
        }
        
        saveContext()
        fetchRecipes()
        print("📬 Moved recipe from inbox to mosaic: \(recipe.title ?? "Unknown")")
    }
    
    // MARK: - Reorder Recipes
    
    func moveRecipe(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < recipes.count,
              destinationIndex >= 0, destinationIndex < recipes.count else {
            return
        }
        
        var reordered = recipes
        let movedRecipe = reordered.remove(at: sourceIndex)
        reordered.insert(movedRecipe, at: destinationIndex)
        
        for (index, recipe) in reordered.enumerated() {
            recipe.sortOrder = Int16(index)
        }
        
        saveContext()
        fetchRecipes()
        print("🔀 Reordered recipes")
    }
    
    // MARK: - Create Recipe
    
    func createRecipe(title: String, symbol: String, color: String, description: String) -> RecipeEntity {
        let recipe = RecipeEntity(context: container.viewContext)
        
        recipe.id = UUID()
        recipe.title = title
        recipe.symbol = symbol
        recipe.colorHex = color
        recipe.recipeDescription = description
        recipe.createdDate = Date()
        recipe.sortOrder = Int16(recipes.count)
        recipe.isInInbox = false
        
        saveContext()
        fetchRecipes()
        
        print("✅ Created recipe: \(title)")
        return recipe
    }
    
    // Create a recipe that goes to inbox (simulating received recipe)
    func createInboxRecipe(title: String, symbol: String, color: String, description: String, senderName: String) -> RecipeEntity {
        let recipe = RecipeEntity(context: container.viewContext)
        
        recipe.id = UUID()
        recipe.title = title
        recipe.symbol = symbol
        recipe.colorHex = color
        recipe.recipeDescription = description
        recipe.createdDate = Date()
        recipe.isInInbox = true
        recipe.senderName = senderName
        
        saveContext()
        fetchRecipes()
        
        print("📬 Created inbox recipe: \(title) from \(senderName)")
        return recipe
    }
    
    // MARK: - Update Recipe
    
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
    
    func deleteRecipe(_ recipe: RecipeEntity) {
        if let audioNotes = recipe.audioNotes as? Set<AudioNoteEntity> {
            for note in audioNotes {
                deleteAudioFile(note.audioFileName ?? "")
            }
        }
        
        container.viewContext.delete(recipe)
        saveContext()
        fetchRecipes()
        
        print("🗑️ Deleted recipe: \(recipe.title ?? "Unknown")")
    }
    
    // MARK: - Ingredients
    
    func addIngredient(to recipe: RecipeEntity, name: String, quantity: String) {
        let ingredient = IngredientEntity(context: container.viewContext)
        ingredient.id = UUID()
        ingredient.name = name
        ingredient.quantity = quantity
        ingredient.sortOrder = Int16((recipe.ingredients?.count ?? 0))
        ingredient.recipe = recipe
        
        saveContext()
        print("✅ Added ingredient: \(name)")
    }
    
    func updateIngredient(_ ingredient: IngredientEntity, name: String, quantity: String) {
        ingredient.name = name
        ingredient.quantity = quantity
        saveContext()
    }
    
    func deleteIngredient(_ ingredient: IngredientEntity) {
        container.viewContext.delete(ingredient)
        saveContext()
    }
    
    func reorderIngredients(for recipe: RecipeEntity, from source: IndexSet, to destination: Int) {
        var items = recipe.ingredientsArray
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortOrder = Int16(index)
        }
        saveContext()
    }
    
    // MARK: - Steps
    
    func addStep(to recipe: RecipeEntity, instruction: String) {
        let step = StepEntity(context: container.viewContext)
        step.id = UUID()
        step.instruction = instruction
        step.sortOrder = Int16((recipe.steps?.count ?? 0))
        step.recipe = recipe
        
        saveContext()
        print("✅ Added step: \(instruction)")
    }
    
    func updateStep(_ step: StepEntity, instruction: String) {
        step.instruction = instruction
        saveContext()
    }
    
    func deleteStep(_ step: StepEntity) {
        container.viewContext.delete(step)
        saveContext()
    }
    
    func reorderSteps(for recipe: RecipeEntity, from source: IndexSet, to destination: Int) {
        var items = recipe.stepsArray
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortOrder = Int16(index)
        }
        saveContext()
    }
    
    // MARK: - Audio Notes
    
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
    
    // MARK: - Photos
    
    func addPhoto(to recipe: RecipeEntity, imageData: Data) {
        let photo = PhotoEntity(context: container.viewContext)
        photo.id = UUID()
        photo.imageData = imageData
        photo.createdDate = Date()
        photo.sortOrder = Int16((recipe.photos?.count ?? 0))
        photo.recipe = recipe
        
        saveContext()
        print("📷 Added photo to recipe")
    }
    
    func deletePhoto(_ photo: PhotoEntity) {
        container.viewContext.delete(photo)
        saveContext()
    }
    
    // MARK: - Location
    
    func setLocation(for recipe: RecipeEntity, latitude: Double, longitude: Double, name: String) {
        recipe.latitude = latitude
        recipe.longitude = longitude
        recipe.locationName = name
        saveContext()
        print("📍 Set location: \(name)")
    }
    
    func removeLocation(from recipe: RecipeEntity) {
        recipe.latitude = 0
        recipe.longitude = 0
        recipe.locationName = nil
        saveContext()
    }
    
    // MARK: - Ancestry Steps
    
    func addAncestryStep(to recipe: RecipeEntity, country: String, region: String?, roughDate: String?, note: String?, generation: Int16?) {
        let ancestryStep = AncestryStepEntity(context: container.viewContext)
        ancestryStep.id = UUID()
        ancestryStep.country = country
        ancestryStep.region = region
        ancestryStep.roughDate = roughDate
        ancestryStep.note = note
        ancestryStep.generation = generation ?? 0
        ancestryStep.sortOrder = Int16((recipe.ancestrySteps?.count ?? 0))
        ancestryStep.recipe = recipe
        
        saveContext()
        print("🌍 Added ancestry step: \(country)")
    }
    
    func updateAncestryStep(_ step: AncestryStepEntity, country: String, region: String?, roughDate: String?, note: String?, generation: Int16?) {
        step.country = country
        step.region = region
        step.roughDate = roughDate
        step.note = note
        step.generation = generation ?? 0
        saveContext()
    }
    
    func deleteAncestryStep(_ step: AncestryStepEntity) {
        container.viewContext.delete(step)
        saveContext()
    }
    
    func reorderAncestrySteps(for recipe: RecipeEntity, from source: IndexSet, to destination: Int) {
        var items = recipe.ancestryStepsArray
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortOrder = Int16(index)
        }
        saveContext()
    }
    
    // MARK: - Private Helpers
    
    func saveContext() {
        do {
            try container.viewContext.save()
            print("💾 Saved to database")
        } catch {
            print("❌ Failed to save: \(error)")
        }
    }
    
    private func deleteAudioFile(_ fileName: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: filePath)
        print("🗑️ Deleted audio file: \(fileName)")
    }
    
    func refreshRecipe(_ recipe: RecipeEntity) {
        container.viewContext.refresh(recipe, mergeChanges: true)
    }
}

// MARK: - Helper Extensions

extension RecipeEntity {
    var ingredientsArray: [IngredientEntity] {
        let set = ingredients as? Set<IngredientEntity> ?? []
        return set.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var stepsArray: [StepEntity] {
        let set = steps as? Set<StepEntity> ?? []
        return set.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var audioNotesArray: [AudioNoteEntity] {
        let set = audioNotes as? Set<AudioNoteEntity> ?? []
        return set.sorted {
            ($0.createdDate ?? Date()) > ($1.createdDate ?? Date())
        }
    }
    
    var ancestryStepsArray: [AncestryStepEntity] {
        let set = ancestrySteps as? Set<AncestryStepEntity> ?? []
        return set.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var photosArray: [PhotoEntity] {
        let set = photos as? Set<PhotoEntity> ?? []
        return set.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var displayColor: Color {
        Color(hex: colorHex ?? "#8B4513") ?? .brown
    }
    
    // Get the first/primary audio note for auto-play
    var primaryAudioNote: AudioNoteEntity? {
        audioNotesArray.first
    }
}

// MARK: - Color Extension

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
    
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
