import SwiftUI

// The main screen showing all recipe cards in a grid
struct MosaicView: View {
    
    // MARK: - Properties
    
    @ObservedObject var dataManager = CoreDataManager.shared
    // Watch for changes in recipes
    
    @State private var selectedRecipe: RecipeEntity?
    // Which recipe was tapped?
    
    @State private var showingRecipeDetail = false
    // Should we show the recipe detail screen?
    
    @State private var showingEditor = false
    // Should we show the recipe editor screen?
    
    // MARK: - Grid Configuration
    
    // Define grid layout
    // "adaptive" means: fit as many 200-220 wide columns as possible
    let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 220), spacing: 24)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack { // Layer things on top of each other
                
                // Background
                WoodBackground()
                
                // Main content
                ScrollView {
                    if dataManager.recipes.isEmpty {
                        // Show this when there are no recipes
                        emptyStateView
                    } else {
                        // Show recipe grid
                        recipeGridView
                    }
                }
                
                // Floating button at bottom
                floatingToolbar
            }
            .navigationTitle("My Recipe Book")
            .navigationBarTitleDisplayMode(.inline)
            
            // These show when state variables are true
            // Comment out editor for now - we'll build it tomorrow
            // .fullScreenCover(isPresented: $showingEditor) {
            //     RecipeEditorView(recipe: nil)
            // }
            .fullScreenCover(isPresented: $showingRecipeDetail) {
                if let recipe = selectedRecipe {
                    RecipeDetailView(recipe: recipe)
                        .onDisappear {
                            selectedRecipe = nil
                        }
                } else {
                    // Fallback if recipe is somehow nil
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Error: Recipe not found")
                            .font(.custom("Georgia", size: 24))
                            .foregroundColor(.red)
                        
                        Text("Selected recipe: \(selectedRecipe?.title ?? "nil")")
                            .font(.caption)
                        
                        FloatingPaperButton(icon: "xmark", label: "Close") {
                            showingRecipeDetail = false
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.96, green: 0.95, blue: 0.92))
                }
            }
        }
        .navigationViewStyle(.stack) // Important for iPad
    }
    
    // MARK: - Subviews
    
    // Empty state (no recipes yet)
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(.brown.opacity(0.3))
            
            Text("No Recipes Yet")
                .font(.custom("Georgia", size: 28))
                .foregroundColor(.brown)
            
            Text("Tap + to create your first recipe")
                .font(.custom("Georgia", size: 18))
                .foregroundColor(.brown.opacity(0.6))
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }
    
    // Recipe grid
    private var recipeGridView: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(dataManager.recipes) { recipe in
                RecipeCardView(recipe: recipe)
                    .onTapGesture {
                        // When tapped, show detail view
                        print("📱 Tapped recipe: \(recipe.title ?? "Unknown")")
                        print("   Recipe ID: \(recipe.id?.uuidString ?? "nil")")
                        
                        // Make sure recipe is in the current context
                        dataManager.container.viewContext.refresh(recipe, mergeChanges: true)
                        
                        selectedRecipe = recipe
                        showingRecipeDetail = true
                    }
                    .contextMenu {
                        // Long-press menu
                        Button(role: .destructive) {
                            withAnimation {
                                dataManager.deleteRecipe(recipe)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(32)
        .padding(.bottom, 120) // Space for floating button
    }
    
    // Floating toolbar at bottom
    private var floatingToolbar: some View {
        VStack {
            Spacer() // Push to bottom
            
            HStack(spacing: 20) {
                // Temporary test button
                FloatingPaperButton(icon: "hammer.fill", label: "Test Data") {
                    createTestRecipe()
                }
                
                // New recipe button (disabled until we build editor)
                FloatingPaperButton(icon: "plus", label: "New Recipe") {
                    print("⚠️ Editor not built yet - coming in Day 3!")
                    // showingEditor = true
                }
                .opacity(0.5) // Grayed out
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Test Data
    // Creates a sample recipe for testing
    
    private func createTestRecipe() {
        print("🔨 Creating test recipe...")
        
        let recipe = dataManager.createRecipe(
            title: "Grandmother's Cookies",
            symbol: "birthday.cake.fill",
            color: "#D2691E",
            description: "A family favorite passed down through generations. These cookies are perfect with milk!"
        )
        
        dataManager.addIngredient(to: recipe, name: "All-purpose flour", quantity: "2 cups")
        dataManager.addIngredient(to: recipe, name: "Granulated sugar", quantity: "1 cup")
        dataManager.addIngredient(to: recipe, name: "Butter (softened)", quantity: "1 stick")
        dataManager.addIngredient(to: recipe, name: "Eggs", quantity: "2 large")
        dataManager.addIngredient(to: recipe, name: "Vanilla extract", quantity: "1 tsp")
        
        dataManager.addStep(to: recipe, instruction: "Preheat oven to 350°F (175°C) and line baking sheets with parchment paper.")
        dataManager.addStep(to: recipe, instruction: "In a large bowl, cream together butter and sugar until light and fluffy.")
        dataManager.addStep(to: recipe, instruction: "Beat in eggs one at a time, then stir in vanilla extract.")
        dataManager.addStep(to: recipe, instruction: "Gradually mix in flour until just combined. Do not overmix.")
        dataManager.addStep(to: recipe, instruction: "Drop rounded tablespoons of dough onto prepared baking sheets, spacing 2 inches apart.")
        dataManager.addStep(to: recipe, instruction: "Bake for 10-12 minutes or until edges are lightly golden. Let cool on pan for 2 minutes before transferring to wire rack.")
        
        print("✅ Test recipe created successfully!")
    }
}

// MARK: - Preview
// This lets you see the view in Xcode's preview panel

struct MosaicView_Previews: PreviewProvider {
    static var previews: some View {
        MosaicView()
    }
}
