import SwiftUI
import UniformTypeIdentifiers

// The main screen showing all recipe cards in a horizontal scrolling grid
struct MosaicView: View {
    
    // MARK: - Properties
    
    @ObservedObject var dataManager = CoreDataManager.shared
    @State private var selectedRecipe: RecipeEntity?
    @State private var showingEditor = false
    
    // Drag and drop state
    @State private var draggedRecipe: RecipeEntity?
    
    // Track newly added recipes for animation
    @State private var newlyAddedRecipeIDs: Set<UUID> = []
    
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
                let isBeingDragged = draggedRecipe?.id == recipe.id
                let isNewlyAdded = newlyAddedRecipeIDs.contains(recipe.id ?? UUID())
                
                StitchedTileCard(
                    recipe: recipe,
                    index: index,
                    totalCount: dataManager.recipes.count,
                    isBeingDragged: isBeingDragged,
                    isNewlyAdded: isNewlyAdded,
                    draggedRecipe: draggedRecipe
                )
                .opacity(isBeingDragged ? 0.5 : 1.0)
                .onTapGesture {
                    print("📱 Tapped recipe: \(recipe.title ?? "Unknown")")
                    dataManager.container.viewContext.refresh(recipe, mergeChanges: true)
                    selectedRecipe = recipe
                }
                .onDrag {
                    self.draggedRecipe = recipe
                    return NSItemProvider(object: (recipe.id?.uuidString ?? "") as NSString)
                }
                .onDrop(of: [.text], delegate: RecipeDropDelegate(
                    recipe: recipe,
                    recipes: dataManager.recipes,
                    draggedRecipe: $draggedRecipe,
                    dataManager: dataManager
                ))
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
        
        let recipeNumber = dataManager.recipes.count + 1
        
        let recipe = dataManager.createRecipe(
            title: "Grandmother's Cookies #\(recipeNumber)",
            symbol: "birthday.cake.fill",
            color: "#D2691E",
            description: "A family favorite passed down through generations."
        )
        
        // Add ancestry timeline
        dataManager.addAncestryStep(
            to: recipe,
            country: "Italy",
            region: "Sicily",
            roughDate: "1890s",
            note: "Original family recipe from great-great-grandmother Maria",
            generation: 1
        )

        dataManager.addAncestryStep(
            to: recipe,
            country: "Canada",
            region: "Montreal, QC",
            roughDate: "1920s",
            note: "Adapted when family immigrated, using Canadian butter",
            generation: 2
        )

        dataManager.addAncestryStep(
            to: recipe,
            country: "Canada",
            region: "Ottawa, ON",
            roughDate: "1950s",
            note: "Grandmother added maple syrup",
            generation: 3
        )

        dataManager.addAncestryStep(
            to: recipe,
            country: "Canada",
            region: "Toronto, ON",
            roughDate: "1980s",
            note: "Mom's version with chocolate chips",
            generation: 4
        )

        dataManager.addAncestryStep(
            to: recipe,
            country: "Canada",
            region: "Ottawa, ON",
            roughDate: "2024",
            note: "My recipe today",
            generation: 5
        )
        
        dataManager.addIngredient(to: recipe, name: "All-purpose flour", quantity: "2 cups")
        dataManager.addIngredient(to: recipe, name: "Sugar", quantity: "1 cup")
        dataManager.addIngredient(to: recipe, name: "Butter", quantity: "1 stick")
        
        dataManager.addStep(to: recipe, instruction: "Preheat oven to 350°F")
        dataManager.addStep(to: recipe, instruction: "Mix ingredients")
        dataManager.addStep(to: recipe, instruction: "Bake for 12 minutes")
        
        // Track as newly added for stitch animation
        if let recipeID = recipe.id {
            newlyAddedRecipeIDs.insert(recipeID)
            
            // Remove from newly added set after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                newlyAddedRecipeIDs.remove(recipeID)
            }
        }
        
        print("✅ Test recipe #\(recipeNumber) created!")
    }
}

// MARK: - Recipe Drop Delegate
// Handles drag and drop reordering of recipe cards

struct RecipeDropDelegate: DropDelegate {
    let recipe: RecipeEntity
    let recipes: [RecipeEntity]
    @Binding var draggedRecipe: RecipeEntity?
    let dataManager: CoreDataManager
    
    func performDrop(info: DropInfo) -> Bool {
        draggedRecipe = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedRecipe = draggedRecipe,
              draggedRecipe.id != recipe.id,
              let fromIndex = recipes.firstIndex(where: { $0.id == draggedRecipe.id }),
              let toIndex = recipes.firstIndex(where: { $0.id == recipe.id }) else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            dataManager.moveRecipe(from: fromIndex, to: toIndex)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
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
    
    // Animation state
    let isBeingDragged: Bool
    let isNewlyAdded: Bool
    
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
                    AnimatedEdgeStitches(
                        edge: .top,
                        length: geo.size.width,
                        size: geo.size,
                        seed: edgeSeed(forHorizontalEdgeAboveRow: row, col: col),
                        baseSpacing: baseSpacing,
                        spacingVariation: spacingVariation,
                        rotationVariation: rotationVariation,
                        stitchSize: stitchSize,
                        isBeingDragged: isBeingDragged,
                        isNewlyAdded: isNewlyAdded
                    )
                }
                
                // LEFT edge stitches - this card is responsible for drawing the seam to its left
                if hasLeftNeighbor {
                    AnimatedEdgeStitches(
                        edge: .left,
                        length: geo.size.height,
                        size: geo.size,
                        seed: edgeSeed(forVerticalEdgeLeftOfCol: col, row: row),
                        baseSpacing: baseSpacing,
                        spacingVariation: spacingVariation,
                        rotationVariation: rotationVariation,
                        stitchSize: stitchSize,
                        isBeingDragged: isBeingDragged,
                        isNewlyAdded: isNewlyAdded
                    )
                }
                
                // NOTE: We do NOT draw bottom or right edges
                // Those will be drawn by the neighboring card's top/left edges
            }
        }
    }
    
    // Generate a consistent seed for a horizontal edge (between two rows)
    private func edgeSeed(forHorizontalEdgeAboveRow row: Int, col: Int) -> Int {
        return row * 1000 + col * 100
    }
    
    // Generate a consistent seed for a vertical edge (between two columns)
    private func edgeSeed(forVerticalEdgeLeftOfCol col: Int, row: Int) -> Int {
        return row * 1000 + col * 100 + 50000
    }
}

// MARK: - Animated Edge Stitches
// Draws stitches along a single edge with animation support

struct AnimatedEdgeStitches: View {
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
    let isBeingDragged: Bool
    let isNewlyAdded: Bool
    
    // Generate stitch positions with irregular spacing
    private var stitchData: [(position: CGFloat, rotation: Double)] {
        var result: [(CGFloat, Double)] = []
        var currentPosition: CGFloat = baseSpacing
        var index = 0
        
        while currentPosition < length - baseSpacing / 2 {
            let positionSeed = seed + index * 17
            let rotationSeed = seed + index * 31
            
            let spacingOffset = seededRandom(positionSeed) * spacingVariation * 2 - spacingVariation
            let rotation = seededRandom(rotationSeed) * rotationVariation * 2 - rotationVariation
            
            result.append((currentPosition, rotation))
            
            currentPosition += baseSpacing + spacingOffset
            index += 1
        }
        
        return result
    }
    
    private func seededRandom(_ seed: Int) -> Double {
        let x = sin(Double(seed) * 12.9898) * 43758.5453
        return x - floor(x)
    }
    
    var body: some View {
        ForEach(Array(stitchData.enumerated()), id: \.offset) { index, data in
            AnimatedSingleStitch(
                edge: edge,
                position: data.position,
                rotation: data.rotation,
                size: size,
                stitchSize: stitchSize,
                isBeingDragged: isBeingDragged,
                isNewlyAdded: isNewlyAdded,
                stitchIndex: index,
                totalStitches: stitchData.count
            )
        }
    }
}

// MARK: - Animated Single Stitch
// A single X-pattern stitch with animation support

struct AnimatedSingleStitch: View {
    let edge: AnimatedEdgeStitches.Edge
    let position: CGFloat
    let rotation: Double
    let size: CGSize
    let stitchSize: CGFloat
    let isBeingDragged: Bool
    let isNewlyAdded: Bool
    let stitchIndex: Int
    let totalStitches: Int
    
    @State private var isVisible: Bool = false
    @State private var scale: CGFloat = 0.0
    
    // Stagger delay based on stitch position
    private var animationDelay: Double {
        Double(stitchIndex) * 0.08
    }
    
    // Reverse delay for drag-out animation
    private var reverseAnimationDelay: Double {
        Double(totalStitches - stitchIndex - 1) * 0.05
    }
    
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
        .scaleEffect(scale)
        .opacity(scale)
        .position(stitchPosition)
        .onAppear {
            // Initial appearance animation
            if isNewlyAdded {
                // Staggered wipe-in animation for new cards
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(animationDelay)) {
                    scale = 1.0
                }
            } else {
                // Instant for existing cards
                scale = 1.0
            }
        }
        .modifier(DragChangeModifier(isBeingDragged: isBeingDragged, scale: $scale, animationDelay: animationDelay, reverseAnimationDelay: reverseAnimationDelay))
        .modifier(NewlyAddedChangeModifier(isNewlyAdded: isNewlyAdded, scale: $scale, animationDelay: animationDelay))
    }
    
    private var baseRotation: Double {
        switch edge {
        case .top, .bottom:
            return 0
        case .left, .right:
            return 90
        }
    }
    
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

// Helper modifier for drag changes (works on all iOS versions)
struct DragChangeModifier: ViewModifier {
    let isBeingDragged: Bool
    @Binding var scale: CGFloat
    let animationDelay: Double
    let reverseAnimationDelay: Double
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isBeingDragged) { newValue in
                if newValue {
                    withAnimation(.easeIn(duration: 0.15).delay(reverseAnimationDelay)) {
                        scale = 0.0
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(animationDelay)) {
                        scale = 1.0
                    }
                }
            }
    }
}

// Helper modifier for newly added changes (works on all iOS versions)
struct NewlyAddedChangeModifier: ViewModifier {
    let isNewlyAdded: Bool
    @Binding var scale: CGFloat
    let animationDelay: Double
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isNewlyAdded) { newValue in
                if newValue {
                    scale = 0.0
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(animationDelay)) {
                        scale = 1.0
                    }
                }
            }
    }
}

// MARK: - Stitched Tile Card
// Wraps SimpleTileCard with stitching overlay based on grid position

struct StitchedTileCard: View {
    let recipe: RecipeEntity
    let index: Int
    let totalCount: Int
    let isBeingDragged: Bool
    let isNewlyAdded: Bool
    let draggedRecipe: RecipeEntity?
    
    // Grid is 3 rows, fills column by column
    private var row: Int { index % 3 }
    private var col: Int { index / 3 }
    private var totalCols: Int { (totalCount + 2) / 3 }
    
    // Determine which edges have neighbors
    private var hasTopNeighbor: Bool {
        row > 0
    }
    
    private var hasBottomNeighbor: Bool {
        guard row < 2 else { return false }
        let belowIndex = col * 3 + (row + 1)
        return belowIndex < totalCount
    }
    
    private var hasLeftNeighbor: Bool {
        col > 0
    }
    
    private var hasRightNeighbor: Bool {
        let rightIndex = (col + 1) * 3 + row
        return rightIndex < totalCount
    }
    
    // Check if any adjacent card is being dragged (to hide shared stitches)
    private var isAdjacentToDraggedCard: Bool {
        guard let draggedRecipe = draggedRecipe else { return false }
        
        // Get dragged card's position
        // This is a simplification - in real app you'd track this properly
        return false
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
                col: col,
                isBeingDragged: isBeingDragged,
                isNewlyAdded: isNewlyAdded
            )
        }
    }
}

// MARK: - Preview

struct MosaicView_Previews: PreviewProvider {
    static var previews: some View {
        MosaicView()
    }
}
