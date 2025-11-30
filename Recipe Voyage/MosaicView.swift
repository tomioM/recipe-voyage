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

struct StitchingOverlay: View {
    let hasTopNeighbor: Bool
    let hasBottomNeighbor: Bool
    let hasLeftNeighbor: Bool
    let hasRightNeighbor: Bool
    
    let stitchColor: Color = .red // Bright red for testing
    let stitchLength: CGFloat = 12
    let stitchSpacing: CGFloat = 20
    let stitchThickness: CGFloat = 2.5
    let stitchOffset: CGFloat = 6 // How far stitches poke out
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            Canvas { context, size in
                // Draw stitching on each edge that has a neighbor
                // Stitches are drawn pointing OUTWARD from the card
                
                if hasTopNeighbor {
                    drawEdgeStitches(
                        context: &context,
                        along: .top,
                        length: width,
                        size: size
                    )
                }
                
                if hasBottomNeighbor {
                    drawEdgeStitches(
                        context: &context,
                        along: .bottom,
                        length: width,
                        size: size
                    )
                }
                
                if hasLeftNeighbor {
                    drawEdgeStitches(
                        context: &context,
                        along: .left,
                        length: height,
                        size: size
                    )
                }
                
                if hasRightNeighbor {
                    drawEdgeStitches(
                        context: &context,
                        along: .right,
                        length: height,
                        size: size
                    )
                }
            }
        }
    }
    
    enum Edge {
        case top, bottom, left, right
    }
    
    private func drawEdgeStitches(context: inout GraphicsContext, along edge: Edge, length: CGFloat, size: CGSize) {
        let numberOfStitches = Int(length / stitchSpacing)
        let actualSpacing = length / CGFloat(numberOfStitches + 1)
        
        for i in 1...numberOfStitches {
            let position = actualSpacing * CGFloat(i)
            drawSingleStitch(context: &context, at: position, edge: edge, size: size)
        }
    }
    
    private func drawSingleStitch(context: inout GraphicsContext, at position: CGFloat, edge: Edge, size: CGSize) {
        // Each stitch is an X pattern that crosses over the edge
        // The stitch "pokes out" beyond the card boundary
        
        var path = Path()
        
        switch edge {
        case .top:
            // Stitch crosses the top edge, pointing upward (out of card)
            // First diagonal of X
            path.move(to: CGPoint(x: position - stitchLength/2, y: stitchOffset))
            path.addLine(to: CGPoint(x: position + stitchLength/2, y: -stitchOffset))
            // Second diagonal of X
            path.move(to: CGPoint(x: position + stitchLength/2, y: stitchOffset))
            path.addLine(to: CGPoint(x: position - stitchLength/2, y: -stitchOffset))
            
        case .bottom:
            // Stitch crosses the bottom edge, pointing downward
            let y = size.height
            path.move(to: CGPoint(x: position - stitchLength/2, y: y - stitchOffset))
            path.addLine(to: CGPoint(x: position + stitchLength/2, y: y + stitchOffset))
            path.move(to: CGPoint(x: position + stitchLength/2, y: y - stitchOffset))
            path.addLine(to: CGPoint(x: position - stitchLength/2, y: y + stitchOffset))
            
        case .left:
            // Stitch crosses the left edge, pointing leftward
            path.move(to: CGPoint(x: stitchOffset, y: position - stitchLength/2))
            path.addLine(to: CGPoint(x: -stitchOffset, y: position + stitchLength/2))
            path.move(to: CGPoint(x: stitchOffset, y: position + stitchLength/2))
            path.addLine(to: CGPoint(x: -stitchOffset, y: position - stitchLength/2))
            
        case .right:
            // Stitch crosses the right edge, pointing rightward
            let x = size.width
            path.move(to: CGPoint(x: x - stitchOffset, y: position - stitchLength/2))
            path.addLine(to: CGPoint(x: x + stitchOffset, y: position + stitchLength/2))
            path.move(to: CGPoint(x: x - stitchOffset, y: position + stitchLength/2))
            path.addLine(to: CGPoint(x: x + stitchOffset, y: position - stitchLength/2))
        }
        
        context.stroke(
            path,
            with: .color(stitchColor),
            style: StrokeStyle(
                lineWidth: stitchThickness,
                lineCap: .round
            )
        )
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
                hasRightNeighbor: hasRightNeighbor
            )
        }
        // Note: Not clipping - stitches extend into neighboring card space
        // which creates the illusion of shared stitching
    }
}

struct MosaicView_Previews: PreviewProvider {
    static var previews: some View {
        MosaicView()
    }
}
