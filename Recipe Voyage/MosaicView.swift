import SwiftUI

// The main screen showing all recipe cards in a horizontal scrolling grid
struct MosaicView: View {
    
    // MARK: - Properties
    
    @ObservedObject var dataManager = CoreDataManager.shared
    @State private var selectedRecipe: RecipeEntity?
    @State private var showingEditor = false
    
    // MARK: - Grid Configuration
    
    // 3 fixed rows, horizontal scrolling
    let rows = [
        GridItem(.fixed(180), spacing: 0),
        GridItem(.fixed(180), spacing: 0),
        GridItem(.fixed(180), spacing: 0)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                
                // Background
                WoodBackground()
                
                // Main content - horizontal scrolling grid
                ScrollView(.horizontal, showsIndicators: false) {
                    if dataManager.recipes.isEmpty {
                        emptyStateView
                    } else {
                        recipeGridView
                            .padding(.leading, 40)
                            .padding(.trailing, 20)
                    }
                }
                
                // Floating button at bottom
                floatingToolbar
            }
            .navigationTitle("My Recipe Book")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
                    .onAppear {
                        print("✅ RecipeDetailView fullScreenCover appeared")
                        print("📝 Recipe: \(recipe.title ?? "Unknown")")
                    }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Subviews
    
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
    
    // Recipe grid - 3 rows, scrolling horizontally
    private var recipeGridView: some View {
        LazyHGrid(rows: rows, spacing: 0) {
            ForEach(dataManager.recipes) { recipe in
                SimpleTileCard(recipe: recipe)
                    .onTapGesture {
                        print("📱 Tapped recipe: \(recipe.title ?? "Unknown")")
                        dataManager.container.viewContext.refresh(recipe, mergeChanges: true)
                        selectedRecipe = recipe
                    }
                    .contextMenu {
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
        .frame(height: 540) // 3 rows × 180px each
    }
    
    private var floatingToolbar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 20) {
                FloatingPaperButton(icon: "hammer.fill", label: "Test Data") {
                    createTestRecipe()
                }
                
                FloatingPaperButton(icon: "plus", label: "New Recipe") {
                    print("⚠️ Editor not built yet - coming in Day 3!")
                }
                .opacity(0.5)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Test Data
    
    private func createTestRecipe() {
        print("🔨 Creating test recipe...")
        
        let recipe = dataManager.createRecipe(
            title: "Grandmother's Cookies",
            symbol: "birthday.cake.fill",
            color: "#D2691E",
            description: "A family favorite passed down through generations."
        )
        
        dataManager.addIngredient(to: recipe, name: "All-purpose flour", quantity: "2 cups")
        dataManager.addIngredient(to: recipe, name: "Sugar", quantity: "1 cup")
        dataManager.addIngredient(to: recipe, name: "Butter", quantity: "1 stick")
        
        dataManager.addStep(to: recipe, instruction: "Preheat oven to 350°F")
        dataManager.addStep(to: recipe, instruction: "Mix ingredients")
        dataManager.addStep(to: recipe, instruction: "Bake for 12 minutes")
        
        print("✅ Test recipe created!")
    }
}

// MARK: - Simple Tile Card
// Minimal white card with just the recipe title

struct SimpleTileCard: View {
    let recipe: RecipeEntity
    
    var body: some View {
        ZStack {
            // Simple background
            Rectangle()
                .fill(Color.white)
            
            // Just text
            Text(recipe.title ?? "Untitled")
                .font(.system(size: 18))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(20)
        }
        .frame(width: 320, height: 180)
        .border(Color.gray, width: 1)
    }
}

// MARK: - Preview

struct MosaicView_Previews: PreviewProvider {
    static var previews: some View {
        MosaicView()
    }
}
