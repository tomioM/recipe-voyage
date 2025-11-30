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
            ForEach(Array(dataManager.recipes.enumerated()), id: \.element.id) { index, recipe in
                StitchedTileCard(
                    recipe: recipe,
                    index: index,
                    totalCount: dataManager.recipes.count
                )
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

// MARK: - Stitching Overlay
// Creates a hand-sewn stitching effect on shared edges between tiles
// IMPORTANT: Only draws on TOP and LEFT edges to avoid duplication with neighbors

struct StitchingOverlay: View {
    let hasTopNeighbor: Bool
    let hasBottomNeighbor: Bool
    let hasLeftNeighbor: Bool
    let hasRightNeighbor: Bool
    
    // Use a seed based on grid position for consistent randomness
    let row: Int
    let col: Int
    
    // Stitch configuration
    let baseSpacing: CGFloat = 40
    let spacingVariation: CGFloat = 4 // +/- variation in spacing
    let rotationVariation: Double = 15 // +/- degrees of rotation
    let stitchSize: CGFloat = 35
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // TOP edge stitches - this card is responsible for drawing the seam above it
                if hasTopNeighbor {
                    EdgeStitches(
                        edge: .top,
                        length: geo.size.width,
                        size: geo.size,
                        seed: edgeSeed(forHorizontalEdgeAboveRow: row, col: col),
                        baseSpacing: baseSpacing,
                        spacingVariation: spacingVariation,
                        rotationVariation: rotationVariation,
                        stitchSize: stitchSize
                    )
                }
                
                // LEFT edge stitches - this card is responsible for drawing the seam to its left
                if hasLeftNeighbor {
                    EdgeStitches(
                        edge: .left,
                        length: geo.size.height,
                        size: geo.size,
                        seed: edgeSeed(forVerticalEdgeLeftOfCol: col, row: row),
                        baseSpacing: baseSpacing,
                        spacingVariation: spacingVariation,
                        rotationVariation: rotationVariation,
                        stitchSize: stitchSize
                    )
                }
                
                // NOTE: We do NOT draw bottom or right edges
                // Those will be drawn by the neighboring card's top/left edges
            }
        }
    }
    
    // Generate a consistent seed for a horizontal edge (between two rows)
    // This ensures the same seed is used regardless of which card draws it
    private func edgeSeed(forHorizontalEdgeAboveRow row: Int, col: Int) -> Int {
        // Edge above row R is identified by (row: R, col: C)
        return row * 1000 + col * 100
    }
    
    // Generate a consistent seed for a vertical edge (between two columns)
    private func edgeSeed(forVerticalEdgeLeftOfCol col: Int, row: Int) -> Int {
        // Edge left of col C is identified by (row: R, col: C) + offset to differentiate from horizontal
        return row * 1000 + col * 100 + 50000
    }
}

// MARK: - Edge Stitches
// Draws stitches along a single edge

struct EdgeStitches: View {
    enum Edge {
        case top, bottom, left, right
    }
    
    let edge: Edge
    let length: CGFloat
    let size: CGSize
    let seed: Int
    let baseSpacing: CGFloat
    let spacingVariation: CGFloat
    let rotationVariation: Double
    let stitchSize: CGFloat
    
    // Generate stitch positions with irregular spacing
    private var stitchData: [(position: CGFloat, rotation: Double)] {
        var result: [(CGFloat, Double)] = []
        var currentPosition: CGFloat = baseSpacing
        var index = 0
        
        while currentPosition < length - baseSpacing / 2 {
            // Seeded pseudo-random for consistent results
            let positionSeed = seed + index * 17
            let rotationSeed = seed + index * 31
            
            // Irregular spacing: base spacing +/- variation
            let spacingOffset = seededRandom(positionSeed) * spacingVariation * 2 - spacingVariation
            
            // Irregular rotation: +/- degrees
            let rotation = seededRandom(rotationSeed) * rotationVariation * 2 - rotationVariation
            
            result.append((currentPosition, rotation))
            
            currentPosition += baseSpacing + spacingOffset
            index += 1
        }
        
        return result
    }
    
    // Simple seeded random number generator (0.0 to 1.0)
    private func seededRandom(_ seed: Int) -> Double {
        let x = sin(Double(seed) * 12.9898) * 43758.5453
        return x - floor(x)
    }
    
    var body: some View {
        ForEach(Array(stitchData.enumerated()), id: \.offset) { _, data in
            SingleStitch(
                edge: edge,
                position: data.position,
                rotation: data.rotation,
                size: size,
                stitchSize: stitchSize
            )
        }
    }
}

// MARK: - Single Stitch
// A single X-pattern stitch made of two crossed stitch images

struct SingleStitch: View {
    let edge: EdgeStitches.Edge
    let position: CGFloat
    let rotation: Double // Additional random rotation for irregularity
    let size: CGSize
    let stitchSize: CGFloat
    
    var body: some View {
        ZStack {
            // First diagonal of X
            Image("stitch-1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: stitchSize)
                .rotationEffect(.degrees(baseRotation + 45 + rotation))
            
            // Second diagonal of X
            Image("stitch-1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: stitchSize)
                .rotationEffect(.degrees(baseRotation - 45 + rotation))
        }
        .position(stitchPosition)
    }
    
    // Base rotation depends on edge orientation
    private var baseRotation: Double {
        switch edge {
        case .top, .bottom:
            return 0 // X pattern for horizontal edges
        case .left, .right:
            return 90 // Rotate 90° for vertical edges
        }
    }
    
    // Position the stitch centered on the edge
    private var stitchPosition: CGPoint {
        switch edge {
        case .top:
            return CGPoint(x: position, y: 0)
        case .bottom:
            return CGPoint(x: position, y: size.height)
        case .left:
            return CGPoint(x: 0, y: position)
        case .right:
            return CGPoint(x: size.width, y: position)
        }
    }
}

// MARK: - Stitched Tile Card
// Wraps SimpleTileCard with stitching overlay based on grid position

struct StitchedTileCard: View {
    let recipe: RecipeEntity
    let index: Int
    let totalCount: Int
    
    // Grid is 3 rows, fills column by column
    private var row: Int { index % 3 }
    private var col: Int { index / 3 }
    private var totalCols: Int { (totalCount + 2) / 3 }
    
    // Determine which edges have neighbors
    private var hasTopNeighbor: Bool {
        row > 0
    }
    
    private var hasBottomNeighbor: Bool {
        // Has bottom neighbor if not bottom row AND there's actually a card below
        guard row < 2 else { return false }
        let belowIndex = col * 3 + (row + 1)
        return belowIndex < totalCount
    }
    
    private var hasLeftNeighbor: Bool {
        col > 0
    }
    
    private var hasRightNeighbor: Bool {
        // Has right neighbor if there's a card in the same row of next column
        let rightIndex = (col + 1) * 3 + row
        return rightIndex < totalCount
    }
    
    var body: some View {
        ZStack {
            SimpleTileCard(recipe: recipe)
            
            StitchingOverlay(
                hasTopNeighbor: hasTopNeighbor,
                hasBottomNeighbor: hasBottomNeighbor,
                hasLeftNeighbor: hasLeftNeighbor,
                hasRightNeighbor: hasRightNeighbor,
                row: row,
                col: col
            )
        }
    }
}

struct MosaicView_Previews: PreviewProvider {
    static var previews: some View {
        MosaicView()
    }
}
