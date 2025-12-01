import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Mosaic View
// Responsive home screen with recipe grid and inbox

struct MosaicView: View {
    
    @ObservedObject var dataManager = CoreDataManager.shared
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @State private var selectedRecipe: RecipeEntity?
    @State private var showingCreateRecipe = false
    @State private var draggedRecipe: RecipeEntity?
    @State private var draggedInboxRecipe: RecipeEntity?
    @State private var showingShareSheet = false
    @State private var recipeToShare: RecipeEntity?
    
    // Track newly added recipes for animation
    @State private var newlyAddedRecipeIDs: Set<UUID> = []
    
    // Detect if we're in landscape iPad
    var isLandscapeiPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    var isLandscape: Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(red: 0.45, green: 0.35, blue: 0.25)
                    .ignoresSafeArea()
                
                if isLandscape {
                    // Landscape layout: Inbox on left, Mosaic on right
                    HStack(spacing: 0) {
                        // Inbox sidebar
                        inboxSidebar(geometry: geometry)
                            .frame(width: min(280, geometry.size.width * 0.25))
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Main mosaic area
                        mosaicArea(geometry: geometry)
                    }
                } else {
                    // Portrait layout: Inbox at top, Mosaic below
                    VStack(spacing: 0) {
                        // Inbox strip at top
                        inboxStrip(geometry: geometry)
                            .frame(height: 140)
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Main mosaic area
                        mosaicArea(geometry: geometry)
                    }
                }
                
                // Floating create button
                createButton
            }
        }
        .fullScreenCover(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
        }
        .fullScreenCover(isPresented: $showingCreateRecipe) {
            CreateRecipeView()
        }
    }
    
    // MARK: - Inbox Sidebar (Landscape)
    
    private func inboxSidebar(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Inbox area with rounded corners and padding from borders
            VStack(spacing: 0) {
                // Mail icon and new mail indicator
                HStack {
                    Spacer()
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // New mail indicator line
                if !dataManager.inboxRecipes.isEmpty {
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(height: 2)
                        .frame(width: 60)
                        .padding(.bottom, 12)
                }
                
                // Inbox recipes
                if dataManager.inboxRecipes.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(dataManager.inboxRecipes) { recipe in
                                InboxRecipeCard(recipe: recipe)
                                    .onDrag {
                                        self.draggedInboxRecipe = recipe
                                        return NSItemProvider(object: (recipe.id?.uuidString ?? "") as NSString)
                                    }
                                    .onTapGesture {
                                        selectedRecipe = recipe
                                    }
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .background(Color.black.opacity(0.2))
            .cornerRadius(16)
            .padding(12)
            
            Spacer()
            
            // Share/Export area at bottom
            ShareDropZone(
                draggedRecipe: $draggedRecipe,
                showingShareSheet: $showingShareSheet,
                recipeToShare: $recipeToShare
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
            
            // Test button to add inbox recipe
            Button(action: createTestInboxRecipe) {
                Label("Add Test Inbox", systemImage: "plus.circle")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 10)
        }
        .background(Color.black.opacity(0.15))
    }
    
    // MARK: - Inbox Strip (Portrait)
    
    private func inboxStrip(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Mail icon and indicator
            HStack {
                Spacer()
                
                VStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                    
                    // New mail indicator line
                    if !dataManager.inboxRecipes.isEmpty {
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 2)
                    }
                }
                .padding(.leading, 16)
                
                // Test button
                Button(action: createTestInboxRecipe) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.trailing, 16)
            }
            .padding(.vertical, 8)
            
            // Inbox recipes in horizontal scroll
            if dataManager.inboxRecipes.isEmpty {
                HStack {
                    Spacer()
                    Text("No recipes in inbox")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                }
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(dataManager.inboxRecipes) { recipe in
                            InboxRecipeCard(recipe: recipe, compact: true)
                                .onDrag {
                                    self.draggedInboxRecipe = recipe
                                    return NSItemProvider(object: (recipe.id?.uuidString ?? "") as NSString)
                                }
                                .onTapGesture {
                                    selectedRecipe = recipe
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .padding(.horizontal, 12)
                .padding(.top, 8)
        )
    }
    
    // MARK: - Main Mosaic Area
    
    private func mosaicArea(geometry: GeometryProxy) -> some View {
        let availableWidth = isLandscape ? 
            geometry.size.width - min(280, geometry.size.width * 0.25) :
            geometry.size.width
        let availableHeight = isLandscape ?
            geometry.size.height :
            geometry.size.height - 140
        
        return ZStack {
            if dataManager.recipes.isEmpty {
                emptyStateView
            } else {
                responsiveMosaicGrid(
                    availableWidth: availableWidth,
                    availableHeight: availableHeight
                )
            }
        }
        .onDrop(of: [.text], delegate: MosaicDropDelegate(
            draggedInboxRecipe: $draggedInboxRecipe,
            dataManager: dataManager,
            newlyAddedRecipeIDs: $newlyAddedRecipeIDs
        ))
    }
    
    // MARK: - Responsive Mosaic Grid
    
    private func responsiveMosaicGrid(availableWidth: CGFloat, availableHeight: CGFloat) -> some View {
        // Calculate optimal card size and grid based on available space
        let minCardWidth: CGFloat = isLandscapeiPad ? 200 : 160
        let minCardHeight: CGFloat = isLandscapeiPad ? 140 : 120
        let spacing: CGFloat = 0 // No spacing - stitches between cards
        let padding: CGFloat = 20 // Padding around the grid
        
        // Calculate how many columns/rows fit (accounting for padding)
        let availableGridWidth = availableWidth - (padding * 2)
        let availableGridHeight = availableHeight - (padding * 2)
        
        let columns = max(1, Int((availableGridWidth - spacing) / (minCardWidth + spacing)))
        let rows = max(1, Int((availableGridHeight - spacing) / (minCardHeight + spacing)))
        
        let cardWidth = (availableGridWidth - CGFloat(columns + 1) * spacing) / CGFloat(columns)
        let cardHeight = (availableGridHeight - CGFloat(rows + 1) * spacing) / CGFloat(rows)
        
        let gridItems = Array(repeating: GridItem(.fixed(cardWidth), spacing: spacing), count: columns)
        
        return ScrollView {
            LazyVGrid(columns: gridItems, spacing: spacing) {
                ForEach(Array(dataManager.recipes.enumerated()), id: \.element.id) { index, recipe in
                    StitchedMosaicCard(
                        recipe: recipe,
                        width: cardWidth,
                        height: cardHeight,
                        index: index,
                        totalCount: dataManager.recipes.count,
                        columns: columns,
                        isBeingDragged: draggedRecipe?.id == recipe.id,
                        isNewlyAdded: newlyAddedRecipeIDs.contains(recipe.id ?? UUID()),
                        draggedRecipe: draggedRecipe
                    )
                    .onTapGesture {
                        dataManager.refreshRecipe(recipe)
                        selectedRecipe = recipe
                    }
                    .onDrag {
                        self.draggedRecipe = recipe
                        return NSItemProvider(object: (recipe.id?.uuidString ?? "") as NSString)
                    }
                    .onDrop(of: [.text], delegate: RecipeReorderDropDelegate(
                        recipe: recipe,
                        recipes: dataManager.recipes,
                        draggedRecipe: $draggedRecipe,
                        draggedInboxRecipe: $draggedInboxRecipe,
                        dataManager: dataManager,
                        newlyAddedRecipeIDs: $newlyAddedRecipeIDs
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
            .padding(padding)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Recipes Yet")
                .font(.title2)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Tap + to create your first recipe")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: { 
                    showingCreateRecipe = true 
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.brown))
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(24)
            }
        }
    }
    
    // MARK: - Test Data
    
    private func createTestInboxRecipe() {
        let senders = ["Grandma Rose", "Aunt Maria", "Uncle Joe", "Mom", "Cousin Sarah"]
        let titles = ["Secret Pie Recipe", "Family Pasta", "Holiday Cookies", "Sunday Roast", "Birthday Cake"]
        
        let recipe = dataManager.createInboxRecipe(
            title: titles.randomElement() ?? "Recipe",
            symbol: "fork.knife",
            color: "#8B4513",
            description: "A wonderful family recipe shared with love.",
            senderName: senders.randomElement() ?? "Family"
        )
        
        dataManager.addIngredient(to: recipe, name: "Love", quantity: "Lots")
        dataManager.addIngredient(to: recipe, name: "Patience", quantity: "Some")
        dataManager.addStep(to: recipe, instruction: "Mix with care")
        dataManager.addStep(to: recipe, instruction: "Bake until golden")
    }
}

// MARK: - Stitched Mosaic Card
// Wraps MosaicRecipeCard with stitching overlay based on grid position

struct StitchedMosaicCard: View {
    let recipe: RecipeEntity
    let width: CGFloat
    let height: CGFloat
    let index: Int
    let totalCount: Int
    let columns: Int
    let isBeingDragged: Bool
    let isNewlyAdded: Bool
    let draggedRecipe: RecipeEntity?
    
    // Calculate grid position
    private var row: Int { index / columns }
    private var col: Int { index % columns }
    private var totalRows: Int { (totalCount + columns - 1) / columns }
    
    // Determine which edges have neighbors
    private var hasTopNeighbor: Bool {
        row > 0
    }
    
    private var hasBottomNeighbor: Bool {
        let belowIndex = (row + 1) * columns + col
        return belowIndex < totalCount
    }
    
    private var hasLeftNeighbor: Bool {
        col > 0
    }
    
    private var hasRightNeighbor: Bool {
        col < columns - 1 && index + 1 < totalCount
    }
    
    // Determine which corners should be rounded (outer corners only)
    private var roundedCorners: UIRectCorner {
        var corners: UIRectCorner = []
        
        // Top-left corner: round if no top AND no left neighbor
        if !hasTopNeighbor && !hasLeftNeighbor {
            corners.insert(.topLeft)
        }
        
        // Top-right corner: round if no top AND no right neighbor
        if !hasTopNeighbor && !hasRightNeighbor {
            corners.insert(.topRight)
        }
        
        // Bottom-left corner: round if no bottom AND no left neighbor
        if !hasBottomNeighbor && !hasLeftNeighbor {
            corners.insert(.bottomLeft)
        }
        
        // Bottom-right corner: round if no bottom AND no right neighbor
        if !hasBottomNeighbor && !hasRightNeighbor {
            corners.insert(.bottomRight)
        }
        
        return corners
    }
    
    var body: some View {
        ZStack {
            MosaicRecipeCard(
                recipe: recipe,
                width: width,
                height: height,
                isBeingDragged: false, // Don't apply opacity here, we do it at parent level
                roundedCorners: roundedCorners
            )
            
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
        .opacity(isBeingDragged ? 0.5 : 1.0)
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
    let baseSpacing: CGFloat = 30
    let spacingVariation: CGFloat = 4 // +/- variation in spacing
    let rotationVariation: Double = 15 // +/- degrees of rotation
    let stitchSize: CGFloat = 20
    
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
        .onChange(of: isNewlyAdded) { newValue in
            if newValue {
                scale = 0.0
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(animationDelay)) {
                    scale = 1.0
                }
            }
        }
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

// MARK: - Mosaic Recipe Card
// New design: Two-column layout with decorative capital and owner info

struct MosaicRecipeCard: View {
    let recipe: RecipeEntity
    let width: CGFloat
    let height: CGFloat
    let isBeingDragged: Bool
    let roundedCorners: UIRectCorner
    
    // Calculate column widths (1:4 ratio)
    private var leftColumnWidth: CGFloat { width * 0.2 }
    private var rightColumnWidth: CGFloat { width * 0.8 }
    
    // Extract first letter for decorative capital
    private var firstLetter: String {
        String((recipe.title ?? "R").prefix(1)).uppercased()
    }
    
    var body: some View {
        ZStack {
            // Background with color tint
            // TODO: Replace with background texture image + color tint
            // Background should be a subtle paper/parchment texture
            // that gets tinted with the recipe's color (NOT owner color)
            RoundedCornerShape(corners: roundedCorners, radius: 12)
                .fill(backgroundColor)
            
            // TODO: Add decorative border image overlay
            // Border should be a separate image that frames the card
            // with vintage/ornate styling
            RoundedCornerShape(corners: roundedCorners, radius: 12)
                .stroke(Color.brown.opacity(0.3), lineWidth: 2)
            
            // Card content
            VStack(spacing: 0) {
                // Main content area (two columns)
                HStack(alignment: .top, spacing: 0) {
                    // LEFT COLUMN: Decorative capital letter (1/5 width)
                    decorativeCapitalColumn
                        .frame(width: leftColumnWidth)
                    
                    // RIGHT COLUMN: Recipe title (4/5 width)
                    titleColumn
                        .frame(width: rightColumnWidth)
                }
                .frame(maxHeight: .infinity)
                
                Spacer()
                
                // BOTTOM: Owner info line
                ownerInfoLine
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
            .padding(.top, 12)
        }
        .frame(width: width, height: height)
    }
    
    // MARK: - Decorative Capital Column
    
    private var decorativeCapitalColumn: some View {
        VStack {
            Spacer()
            
            // TODO: Replace with decorative capital image
            // Should be an ornate, vintage-style capital letter
            // For now, using text as placeholder
            Text(firstLetter)
                .font(.custom("Georgia-Bold", size: min(width, height) * 0.25))
                .foregroundColor(decorativeCapitalColor)
            
            Spacer()
        }
    }
    
    // MARK: - Title Column
    
    private var titleColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            
            Text(recipe.title ?? "Untitled")
                .font(.custom("Georgia", size: fontSize))
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .foregroundColor(textColor)
                .padding(.trailing, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Owner Info Line
    
    private var ownerInfoLine: some View {
        HStack(spacing: 6) {
            // Owner profile photo (circular) - loaded from Assets
            if let owner = recipe.owner,
               let photoName = owner.profilePhotoName {
                Image(photoName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.brown.opacity(0.3), lineWidth: 1)
                    )
            } else {
                // Placeholder profile photo
                Circle()
                    .fill(Color.brown.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.brown.opacity(0.5))
                    )
            }
            
            // Owner name - display "Personal Recipe" if owner name is exactly "self"
            Text(displayOwnerName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
            
            Spacer()
            
            // Audio indicator (if present)
            if !recipe.audioNotesArray.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "waveform")
                        .font(.system(size: 9))
                    Text("\(recipe.audioNotesArray.count)")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(.brown.opacity(0.5))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var displayOwnerName: String {
        let ownerName = recipe.owner?.name ?? "Unknown"
        return ownerName == "self" ? "Personal Recipe" : ownerName
    }
    
    private var backgroundColor: Color {
        // Use bgColorHex for background tinting
        if let bgColorHex = recipe.bgColorHex {
            return (Color(hex: bgColorHex) ?? Color(red: 0.96, green: 0.95, blue: 0.92)).opacity(0.15)
        } else {
            return Color(red: 0.96, green: 0.95, blue: 0.92)
        }
    }
    
    private var textColor: Color {
        // Use colorHex for text color
        if let colorHex = recipe.colorHex {
            return Color(hex: colorHex) ?? Color(red: 0.3, green: 0.2, blue: 0.1)
        } else {
            return Color(red: 0.3, green: 0.2, blue: 0.1)
        }
    }
    
    private var decorativeCapitalColor: Color {
        // Use colorHex for decorative capital
        if let colorHex = recipe.colorHex {
            return Color(hex: colorHex) ?? .brown
        } else {
            return .brown
        }
    }
    
    private var fontSize: CGFloat {
        min(16, min(width, height) * 0.12)
    }
}

// MARK: - Inbox Recipe Card

struct InboxRecipeCard: View {
    let recipe: RecipeEntity
    var compact: Bool = false
    
    // Calculate card dimensions
    private var cardWidth: CGFloat { compact ? 140 : 220 }
    private var cardHeight: CGFloat { compact ? 100 : 140 }
    
    // Calculate column widths (1:4 ratio, same as mosaic card)
    private var leftColumnWidth: CGFloat { cardWidth * 0.2 }
    private var rightColumnWidth: CGFloat { cardWidth * 0.8 }
    
    // Extract first letter for decorative capital
    private var firstLetter: String {
        String((recipe.title ?? "R").prefix(1)).uppercased()
    }
    
    var body: some View {
        ZStack {
            // Background with color tint (using bgColorHex)
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
            
            // Border
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.brown.opacity(0.3), lineWidth: 1.5)
            
            // Card content
            VStack(spacing: 0) {
                // Main content area (two columns)
                HStack(alignment: .top, spacing: 0) {
                    // LEFT COLUMN: Decorative capital letter (1/5 width)
                    VStack {
                        Spacer()
                        Text(firstLetter)
                            .font(.custom("Georgia-Bold", size: compact ? 28 : 35))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    .frame(width: leftColumnWidth)
                    
                    // RIGHT COLUMN: Recipe title (4/5 width)
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer()
                        
                        Text(recipe.title ?? "Untitled")
                            .font(.custom("Georgia", size: compact ? 11 : 13))
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                            .lineLimit(compact ? 2 : 3)
                            .foregroundColor(textColor)
                            .padding(.trailing, 8)
                        
                        Spacer()
                    }
                    .frame(width: rightColumnWidth)
                }
                .frame(maxHeight: .infinity)
                
                Spacer()
                
                // BOTTOM: Sender info line
                HStack(spacing: 6) {
                    Image(systemName: "envelope.open")
                        .font(.system(size: compact ? 8 : 10))
                        .foregroundColor(.brown.opacity(0.5))
                    
                    Text(recipe.senderName ?? "Unknown")
                        .font(.system(size: compact ? 8 : 10, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
            .padding(.top, 8)
        }
        .frame(width: cardWidth, height: cardHeight)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        // Use bgColorHex for background tinting
        if let bgColorHex = recipe.bgColorHex {
            return (Color(hex: bgColorHex) ?? Color(red: 0.96, green: 0.95, blue: 0.92)).opacity(0.15)
        } else {
            return Color(red: 0.96, green: 0.95, blue: 0.92)
        }
    }
    
    private var textColor: Color {
        // Use colorHex for text color
        if let colorHex = recipe.colorHex {
            return Color(hex: colorHex) ?? Color(red: 0.3, green: 0.2, blue: 0.1)
        } else {
            return Color(red: 0.3, green: 0.2, blue: 0.1)
        }
    }
}

// MARK: - Share Drop Zone

struct ShareDropZone: View {
    @Binding var draggedRecipe: RecipeEntity?
    @Binding var showingShareSheet: Bool
    @Binding var recipeToShare: RecipeEntity?
    
    @State private var isHovering = false
    @State private var animateSuccess = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .foregroundColor(isHovering ? Color.white.opacity(0.7) : Color.white.opacity(0.4))
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isHovering ? Color.white.opacity(0.1) : Color.clear)
                )
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 28))
                            .foregroundColor(isHovering ? .white.opacity(0.8) : .white.opacity(0.3))
                        
                        Text("Share")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                )
            
            // Success animation overlay
            if animateSuccess {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.3))
                    .frame(height: 80)
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onDrop(of: [.text], isTargeted: $isHovering) { providers in
            if let recipe = draggedRecipe {
                // Trigger success animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animateSuccess = true
                }
                
                // Show share sheet after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    recipeToShare = recipe
                    showingShareSheet = true
                    
                    // Reset animation
                    withAnimation {
                        animateSuccess = false
                    }
                }
                
                draggedRecipe = nil
                return true
            }
            return false
        }
        .sheet(isPresented: $showingShareSheet) {
            if let recipe = recipeToShare {
                ShareSheet(recipe: recipe)
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: View {
    let recipe: RecipeEntity
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.brown)
                    .padding()
                
                Text("Share Recipe")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(recipe.title ?? "Untitled Recipe")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        // Export as PDF
                        dismiss()
                    }) {
                        Label("Export as PDF", systemImage: "doc.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Send via email
                        dismiss()
                    }) {
                        Label("Send via Email", systemImage: "envelope.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Share with others
                        dismiss()
                    }) {
                        Label("Share with Others", systemImage: "person.2.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

// MARK: - Drop Delegates

struct MosaicDropDelegate: DropDelegate {
    @Binding var draggedInboxRecipe: RecipeEntity?
    let dataManager: CoreDataManager
    @Binding var newlyAddedRecipeIDs: Set<UUID>
    
    func performDrop(info: DropInfo) -> Bool {
        if let inboxRecipe = draggedInboxRecipe {
            dataManager.moveFromInboxToMosaic(inboxRecipe)
            
            // Track as newly added for animation
            if let recipeID = inboxRecipe.id {
                newlyAddedRecipeIDs.insert(recipeID)
                
                // Remove from newly added set after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    newlyAddedRecipeIDs.remove(recipeID)
                }
            }
            
            draggedInboxRecipe = nil
            return true
        }
        return false
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

struct RecipeReorderDropDelegate: DropDelegate {
    let recipe: RecipeEntity
    let recipes: [RecipeEntity]
    @Binding var draggedRecipe: RecipeEntity?
    @Binding var draggedInboxRecipe: RecipeEntity?
    let dataManager: CoreDataManager
    @Binding var newlyAddedRecipeIDs: Set<UUID>
    
    func performDrop(info: DropInfo) -> Bool {
        // Handle inbox recipe drop
        if let inboxRecipe = draggedInboxRecipe {
            if let targetIndex = recipes.firstIndex(where: { $0.id == recipe.id }) {
                dataManager.moveFromInboxToMosaic(inboxRecipe, atIndex: targetIndex)
                
                // Track as newly added for animation
                if let recipeID = inboxRecipe.id {
                    newlyAddedRecipeIDs.insert(recipeID)
                    
                    // Remove from newly added set after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        newlyAddedRecipeIDs.remove(recipeID)
                    }
                }
            }
            draggedInboxRecipe = nil
            return true
        }
        
        draggedRecipe = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Only handle mosaic recipe reordering
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

// MARK: - Rounded Corner Shape
// Custom shape that allows rounding specific corners

struct RoundedCornerShape: Shape {
    let corners: UIRectCorner
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

struct MosaicView_Previews: PreviewProvider {
    static var previews: some View {
        MosaicView()
    }
}
