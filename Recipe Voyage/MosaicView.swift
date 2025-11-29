import SwiftUI

// The main screen showing all recipe cards in a grid
struct MosaicView: View {
    
    // MARK: - Properties
    
    @ObservedObject var dataManager = CoreDataManager.shared
    
    @State private var selectedRecipe: RecipeEntity?
    @State private var showingRecipeDetail = false
    @State private var showingEditor = false
    
    // MARK: - Grid Configuration
    
    let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 220), spacing: 24)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                WoodBackground()
                
                ScrollView {
                    if dataManager.recipes.isEmpty {
                        emptyStateView
                    } else {
                        recipeGridView
                    }
                }
                
                floatingToolbar
            }
            .navigationTitle("My Recipe Book")
            .navigationBarTitleDisplayMode(.inline)
            
            // EDITOR DISABLED - will add on Day 3
            // .fullScreenCover(isPresented: $showingEditor) {
            //     RecipeEditorView(recipe: nil)
            // }
            
            .sheet(isPresented: $showingRecipeDetail) {
                if let recipe = selectedRecipe {
                    RecipeDetailView(recipe: recipe)
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
            
            Text("Tap the hammer to add test recipes")
                .font(.custom("Georgia", size: 18))
                .foregroundColor(.brown.opacity(0.6))
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }
    
    private var recipeGridView: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(dataManager.recipes) { recipe in
                RecipeCardView(recipe: recipe)
                    .onTapGesture {
                        print("🔵 Tapped recipe: \(recipe.title ?? "nil")")
                        selectedRecipe = recipe
                        showingRecipeDetail = true
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
        .padding(32)
        .padding(.bottom, 120)
    }
    
    private var floatingToolbar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 20) {
                // Test data button
                FloatingPaperButton(icon: "hammer.fill", label: "Test Data") {
                    createTestRecipe()
                }
                
                // New recipe button - DISABLED until Day 3
                // FloatingPaperButton(icon: "plus", label: "New Recipe") {
                //     showingEditor = true
                // }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Test Recipe Creation
    
    private func createTestRecipe() {
        print("🔨 Creating test recipe...")
        
        let recipe = dataManager.createRecipe(
            title: "Grandmother's Cookies",
            symbol: "birthday.cake.fill",
            color: "#D2691E",
            description: "A family favorite passed down through generations. These cookies are perfect with a glass of milk!"
        )
        
        print("✅ Recipe created: \(recipe.title ?? "nil")")
        
        dataManager.addIngredient(to: recipe, name: "All-purpose flour", quantity: "2 cups")
        dataManager.addIngredient(to: recipe, name: "Granulated sugar", quantity: "1 cup")
        dataManager.addIngredient(to: recipe, name: "Butter (softened)", quantity: "1 stick")
        dataManager.addIngredient(to: recipe, name: "Eggs", quantity: "2 large")
        dataManager.addIngredient(to: recipe, name: "Vanilla extract", quantity: "1 tsp")
        
        print("✅ Added \(recipe.ingredientsArray.count) ingredients")
        
        dataManager.addStep(to: recipe, instruction: "Preheat oven to 350°F (175°C) and line baking sheets with parchment paper.")
        dataManager.addStep(to: recipe, instruction: "In a large bowl, cream together butter and sugar until light and fluffy, about 3 minutes.")
        dataManager.addStep(to: recipe, instruction: "Beat in eggs one at a time, then stir in vanilla extract.")
        dataManager.addStep(to: recipe, instruction: "Gradually mix in flour until just combined. Do not overmix.")
        dataManager.addStep(to: recipe, instruction: "Drop rounded tablespoons of dough onto prepared baking sheets, spacing 2 inches apart.")
        dataManager.addStep(to: recipe, instruction: "Bake for 10-12 minutes or until edges are lightly golden. Let cool on pan for 2 minutes before transferring to wire rack.")
        
        print("✅ Added \(recipe.stepsArray.count) steps")
        print("📚 Total recipes: \(dataManager.recipes.count)")
    }
}

struct MosaicView_Previews: PreviewProvider {
    static var previews: some View {
        MosaicView()
    }
}
