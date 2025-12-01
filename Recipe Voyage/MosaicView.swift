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
    @State private var isInboxExpanded = true
    
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
                            .frame(width: isInboxExpanded ? min(280, geometry.size.width * 0.25) : 60)
                        
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
                            .frame(height: isInboxExpanded ? 140 : 50)
                        
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
            // Header
            HStack {
                if isInboxExpanded {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.white)
                    Text("Inbox")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if !dataManager.inboxRecipes.isEmpty {
                        Text("(\(dataManager.inboxRecipes.count))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                Button(action: { withAnimation { isInboxExpanded.toggle() } }) {
                    Image(systemName: isInboxExpanded ? "chevron.left" : "chevron.right")
                        .foregroundColor(.white)
                        .padding(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.2))
            
            if isInboxExpanded {
                if dataManager.inboxRecipes.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No recipes")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
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
                
                // Test button to add inbox recipe
                Button(action: createTestInboxRecipe) {
                    Label("Add Test Inbox", systemImage: "plus.circle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 10)
            }
        }
        .background(Color.black.opacity(0.15))
    }
    
    // MARK: - Inbox Strip (Portrait)
    
    private func inboxStrip(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.white)
                Text("Inbox")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if !dataManager.inboxRecipes.isEmpty {
                    Text("(\(dataManager.inboxRecipes.count))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: { withAnimation { isInboxExpanded.toggle() } }) {
                    Image(systemName: isInboxExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                }
                
                // Test button
                Button(action: createTestInboxRecipe) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            if isInboxExpanded {
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
        }
        .background(Color.black.opacity(0.15))
    }
    
    // MARK: - Main Mosaic Area
    
    private func mosaicArea(geometry: GeometryProxy) -> some View {
        let availableWidth = isLandscape ? 
            geometry.size.width - (isInboxExpanded ? min(280, geometry.size.width * 0.25) : 60) :
            geometry.size.width
        let availableHeight = isLandscape ?
            geometry.size.height :
            geometry.size.height - (isInboxExpanded ? 140 : 50)
        
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
            dataManager: dataManager
        ))
    }
    
    // MARK: - Responsive Mosaic Grid
    
    private func responsiveMosaicGrid(availableWidth: CGFloat, availableHeight: CGFloat) -> some View {
        // Calculate optimal card size and grid based on available space
        let minCardWidth: CGFloat = isLandscapeiPad ? 200 : 160
        let minCardHeight: CGFloat = isLandscapeiPad ? 140 : 120
        let spacing: CGFloat = 8
        
        // Calculate how many columns/rows fit
        let columns = max(1, Int((availableWidth - spacing) / (minCardWidth + spacing)))
        let rows = max(1, Int((availableHeight - spacing) / (minCardHeight + spacing)))
        
        let cardWidth = (availableWidth - CGFloat(columns + 1) * spacing) / CGFloat(columns)
        let cardHeight = (availableHeight - CGFloat(rows + 1) * spacing) / CGFloat(rows)
        
        let gridItems = Array(repeating: GridItem(.fixed(cardWidth), spacing: spacing), count: columns)
        
        return ScrollView {
            LazyVGrid(columns: gridItems, spacing: spacing) {
                ForEach(Array(dataManager.recipes.enumerated()), id: \.element.id) { index, recipe in
                    MosaicRecipeCard(
                        recipe: recipe,
                        width: cardWidth,
                        height: cardHeight,
                        isBeingDragged: draggedRecipe?.id == recipe.id
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
            .padding(spacing)
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
                
                Button(action: { showingCreateRecipe = true }) {
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

// MARK: - Mosaic Recipe Card

struct MosaicRecipeCard: View {
    let recipe: RecipeEntity
    let width: CGFloat
    let height: CGFloat
    let isBeingDragged: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.96, green: 0.95, blue: 0.92))
            
            VStack(spacing: 8) {
                Image(systemName: recipe.symbol ?? "fork.knife")
                    .font(.system(size: min(width, height) * 0.25))
                    .foregroundColor(recipe.displayColor)
                
                Text(recipe.title ?? "Untitled")
                    .font(.system(size: min(14, min(width, height) * 0.1), weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                    .padding(.horizontal, 8)
                
                // Show audio indicator
                if !recipe.audioNotesArray.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.system(size: 10))
                        Text("\(recipe.audioNotesArray.count)")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.brown.opacity(0.6))
                }
            }
            .padding(8)
        }
        .frame(width: width, height: height)
        .opacity(isBeingDragged ? 0.5 : 1.0)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Inbox Recipe Card

struct InboxRecipeCard: View {
    let recipe: RecipeEntity
    var compact: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "envelope.open")
                    .font(.system(size: compact ? 12 : 14))
                    .foregroundColor(.brown)
                
                if !compact {
                    Text(recipe.senderName ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.brown.opacity(0.8))
                }
                
                Spacer()
            }
            
            Text(recipe.title ?? "Untitled")
                .font(.system(size: compact ? 13 : 15, weight: .medium))
                .lineLimit(compact ? 1 : 2)
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            if !compact, let sender = recipe.senderName {
                Text("From: \(sender)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(compact ? 10 : 12)
        .frame(width: compact ? 140 : nil)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.brown.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Drop Delegates

struct MosaicDropDelegate: DropDelegate {
    @Binding var draggedInboxRecipe: RecipeEntity?
    let dataManager: CoreDataManager
    
    func performDrop(info: DropInfo) -> Bool {
        if let inboxRecipe = draggedInboxRecipe {
            dataManager.moveFromInboxToMosaic(inboxRecipe)
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
    
    func performDrop(info: DropInfo) -> Bool {
        // Handle inbox recipe drop
        if let inboxRecipe = draggedInboxRecipe {
            if let targetIndex = recipes.firstIndex(where: { $0.id == recipe.id }) {
                dataManager.moveFromInboxToMosaic(inboxRecipe, atIndex: targetIndex)
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

// MARK: - Preview

struct MosaicView_Previews: PreviewProvider {
    static var previews: some View {
        MosaicView()
    }
}
