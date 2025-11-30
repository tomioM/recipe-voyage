import SwiftUI

// The main screen showing all recipe cards in a mosaic grid with stitching
struct MosaicView: View {
    
    // MARK: - Properties
    
    @ObservedObject var dataManager = CoreDataManager.shared
    @State private var selectedRecipe: RecipeEntity?
    @State private var showingRecipeDetail = false
    @State private var showingEditor = false
    
    // MARK: - Grid Configuration
    
    // No spacing - cards will be edge-to-edge for mosaic effect
    let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 220), spacing: 0)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                
                // Background
                WoodBackground()
                
                // Main content
                ScrollView {
                    if dataManager.recipes.isEmpty {
                        emptyStateView
                    } else {
                        recipeGridView
                    }
                }
                
                // Floating button at bottom
                floatingToolbar
            }
            .navigationTitle("My Recipe Book")
            .navigationBarTitleDisplayMode(.inline)
            
            .fullScreenCover(isPresented: $showingRecipeDetail) {
                if let recipe = selectedRecipe {
                    RecipeDetailView(recipe: recipe)
                        .onDisappear {
                            selectedRecipe = nil
                        }
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
    
    // Recipe grid with zero spacing for mosaic effect
    private var recipeGridView: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(dataManager.recipes) { recipe in
                MosaicRecipeCard(recipe: recipe)
                    .onTapGesture {
                        print("📱 Tapped recipe: \(recipe.title ?? "Unknown")")
                        dataManager.container.viewContext.refresh(recipe, mergeChanges: true)
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
        .padding(0) // No padding for edge-to-edge mosaic
        .padding(.bottom, 120) // Space for floating button
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

// MARK: - Mosaic Recipe Card with Stitching
// Card designed for edge-to-edge mosaic display with visual stitching

struct MosaicRecipeCard: View {
    let recipe: RecipeEntity
    
    var body: some View {
        ZStack {
            // Base paper card
            Rectangle()
                .fill(Color(red: 0.96, green: 0.95, blue: 0.92))
            
            // Paper texture
            PaperTexture(type: "aged")
            
            // Card content
            VStack(spacing: 16) {
                // Icon at top
                Image(systemName: recipe.symbol ?? "fork.knife")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(recipe.displayColor)
                    .padding(.top, 24)
                
                // Ornamental title - highlights first letter, truncates rest
                OrnamentalCardTitle(
                    text: recipe.title ?? "Untitled",
                    color: recipe.displayColor
                )
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Audio indicator if present
                if let audioNotes = recipe.audioNotes, audioNotes.count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.system(size: 12))
                        Text("\(audioNotes.count)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.brown.opacity(0.6))
                    .padding(.bottom, 16)
                }
            }
            
            // Stitching borders - overlaid on top
            StitchedBorder()
        }
        .frame(width: 220, height: 280)
    }
}

// MARK: - Ornamental Card Title
// Highlights the first letter ornamentally, shows rest in smaller text with truncation

struct OrnamentalCardTitle: View {
    let text: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // First letter - large and ornamental
            if let firstChar = text.first {
                ZStack {
                    // Decorative seal behind first letter
                    Image(systemName: "seal.fill")
                        .font(.system(size: 40))
                        .foregroundColor(color.opacity(0.15))
                    
                    // The ornamental first letter
                    Text(String(firstChar))
                        .font(.custom("Georgia-Bold", size: 48))
                        .foregroundColor(color)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // Rest of title - smaller, with truncation
            if text.count > 1 {
                Text(String(text.dropFirst()))
                    .font(.custom("Georgia", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                    .multilineTextAlignment(.center)
                    .lineLimit(2) // Maximum 2 lines
                    .truncationMode(.tail) // Add ... at end if too long
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Stitched Border
// Creates irregular, natural-looking stitching effect between cards

struct StitchedBorder: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Right edge stitching (vertical line)
                Path { path in
                    let x = width - 1 // Right edge
                    
                    // Add slight irregularity to make it look hand-stitched
                    path.move(to: CGPoint(x: x, y: 0))
                    
                    // Draw with slight variations
                    var currentY: CGFloat = 0
                    let stitchLength: CGFloat = 12
                    let gapLength: CGFloat = 8
                    
                    while currentY < height {
                        path.addLine(to: CGPoint(x: x + CGFloat.random(in: -0.5...0.5), y: currentY + stitchLength))
                        currentY += stitchLength
                        
                        if currentY < height {
                            path.move(to: CGPoint(x: x + CGFloat.random(in: -0.5...0.5), y: currentY + gapLength))
                            currentY += gapLength
                        }
                    }
                }
                .stroke(Color.brown.opacity(0.4), lineWidth: 2)
                
                // Bottom edge stitching (horizontal line)
                Path { path in
                    let y = height - 1 // Bottom edge
                    
                    path.move(to: CGPoint(x: 0, y: y))
                    
                    var currentX: CGFloat = 0
                    let stitchLength: CGFloat = 12
                    let gapLength: CGFloat = 8
                    
                    while currentX < width {
                        path.addLine(to: CGPoint(x: currentX + stitchLength, y: y + CGFloat.random(in: -0.5...0.5)))
                        currentX += stitchLength
                        
                        if currentX < width {
                            path.move(to: CGPoint(x: currentX + gapLength, y: y + CGFloat.random(in: -0.5...0.5)))
                            currentX += gapLength
                        }
                    }
                }
                .stroke(Color.brown.opacity(0.4), lineWidth: 2)
            }
        }
    }
}

// MARK: - Preview

struct MosaicView_Previews: PreviewProvider {
    static var previews: some View {
        MosaicView()
    }
}
