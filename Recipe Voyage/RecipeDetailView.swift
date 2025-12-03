import SwiftUI
import PhotosUI

// MARK: - Recipe Detail View
// Shows recipe with compact timeline, two-column content layout, and auto-play audio

struct RecipeDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @ObservedObject var dataManager = CoreDataManager.shared
    @StateObject private var audioManager = AudioManager()
    
    let recipe: RecipeEntity
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    
    var isLandscape: Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }
    
    var isLandscapeiPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(red: 0.98, green: 0.97, blue: 0.94)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with close button
                    headerSection
                    
                    // Main content area - two column layout
                    HStack(alignment: .top, spacing: 0) {
                        // Left column - scrollable (everything except ingredients)
                        leftColumnContent(geometry: geometry)
                        
                        // Vertical divider
                        Rectangle()
                            .fill(Color.brown.opacity(0.2))
                            .frame(width: 2)
                        
                        // Right column - independently scrollable ingredients
                        rightColumnContent(geometry: geometry)
                    }
                }
                
                // Floating audio player at bottom
                if recipe.primaryAudioNote != nil {
                    floatingAudioPlayer(geometry: geometry)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            // Auto-play audio when view appears
            if let audioNote = recipe.primaryAudioNote,
               let fileName = audioNote.audioFileName {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    audioManager.playAudio(fileName: fileName)
                }
            }
        }
        .onDisappear {
            audioManager.stopPlayback()
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    dataManager.addPhoto(to: recipe, imageData: data)
                    dataManager.refreshRecipe(recipe)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.brown.opacity(0.8))
                    .background(Circle().fill(Color.white))
            }
            .padding(.trailing, 20)
        }
        .padding(.top, 50)
        .padding(.bottom, 12)
        .background(Color(red: 0.98, green: 0.97, blue: 0.94))
    }
    
    // MARK: - Left Column Content
    
    private func leftColumnContent(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 32) {
                // Recipe title with decorative capital
                titleSection
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                
                // History/Ancestry Section
                if !recipe.ancestryStepsArray.isEmpty {
                    ancestrySection
                        .padding(.horizontal, 32)
                }
                
                // Description
                if let description = recipe.recipeDescription, !description.isEmpty {
                    descriptionSection(description)
                        .padding(.horizontal, 32)
                }
                
                // Instructions
                if !recipe.stepsArray.isEmpty {
                    instructionsSection
                        .padding(.horizontal, 32)
                }
                
                // Photos Section
                photosSection
                    .padding(.horizontal, 32)
                
                // Bottom padding for audio player
                Spacer()
                    .frame(height: 100)
            }
        }
        .frame(width: geometry.size.width * 0.58)
    }
    
    // MARK: - Right Column Content (Ingredients)
    
    private func rightColumnContent(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Ingredients header
                Text("INGREDIENTS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.brown.opacity(0.6))
                    .tracking(2)
                    .padding(.top, 24)
                
                if !recipe.ingredientsArray.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(recipe.ingredientsArray) { ingredient in
                            ingredientRow(ingredient)
                        }
                    }
                } else {
                    Text("No ingredients listed")
                        .font(.system(size: 15))
                        .foregroundColor(.gray.opacity(0.7))
                        .italic()
                        .padding(.vertical, 20)
                }
                
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: geometry.size.width * 0.42)
        .background(
            Color.white.opacity(0.3)
        )
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        let title = recipe.title ?? "Untitled Recipe"
        let fontName = recipe.decorativeCapFont ?? "Didot"
        let accentColor = Color(hex: recipe.colorHex ?? "#8B4513") ?? Color.brown
        
        return VStack(alignment: .leading, spacing: 16) {
            if let firstChar = title.first {
                HStack(alignment: .top, spacing: 0) {
                    // Decorative capital letter with ornamental frame
                    decorativeCapitalView(letter: String(firstChar).uppercased(), fontName: fontName, accentColor: accentColor)
                    
                    // Rest of the title
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(title.dropFirst()))
                            .font(.system(size: 38, weight: .bold, design: .serif))
                            .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.08))
                            .lineSpacing(4)
                    }
                    .padding(.top, 12)
                }
            } else {
                Text(title)
                    .font(.system(size: 38, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.08))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Decorative Capital View
    
    private func decorativeCapitalView(letter: String, fontName: String, accentColor: Color) -> some View {
        let letterSize: CGFloat = 72
        
        return ZStack {
            // Ornamental background circle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            accentColor.opacity(0.15),
                            accentColor.opacity(0.05)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: letterSize * 0.6
                    )
                )
                .frame(width: letterSize * 1.2, height: letterSize * 1.2)
            
            // Decorative ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor.opacity(0.4),
                            accentColor.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: letterSize * 1.1, height: letterSize * 1.1)
            
            // The decorative letter itself
            Text(letter)
                .font(.custom(fontName, size: letterSize))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor,
                            accentColor.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: accentColor.opacity(0.3), radius: 3, x: 0, y: 2)
        }
        .frame(width: letterSize * 1.3, height: letterSize * 1.3)
    }
    
    // MARK: - Ancestry Section
    
    private var ancestrySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HISTORY")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.brown.opacity(0.6))
                .tracking(2)
            
            compactAncestryTimelineContent
        }
    }
    
    private var compactAncestryTimelineContent: some View {
        HStack(spacing: 0) {
            // Play/Pause button on the left (if audio exists)
            if let audioNote = recipe.primaryAudioNote,
               let fileName = audioNote.audioFileName {
                Button(action: {
                    audioManager.togglePlayback(fileName: fileName)
                }) {
                    Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.brown)
                }
                .padding(.trailing, 16)
            }
            
            // Ancestry timeline
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(recipe.ancestryStepsArray.enumerated()), id: \.element.id) { index, step in
                        HStack(spacing: 12) {
                            // Ancestry step card
                            VStack(alignment: .leading, spacing: 10) {
                                // Header label
                                Text("ORIGIN \(index + 1)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.brown.opacity(0.5))
                                    .tracking(1)
                                
                                // Country
                                Text(step.country ?? "Unknown")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.08))
                                
                                // Region (if not empty)
                                if let region = step.region, !region.isEmpty {
                                    Text(region)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.brown.opacity(0.8))
                                }
                                
                                // Date (if not empty)
                                if let date = step.roughDate, !date.isEmpty {
                                    Text(date)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray.opacity(0.9))
                                        .italic()
                                        .padding(.top, 4)
                                }
                                
                                // Note (if not empty)
                                if let note = step.note, !note.isEmpty {
                                    Text(note)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                                        .lineLimit(4)
                                        .padding(.top, 4)
                                }
                            }
                            .padding(20)
                            .frame(minWidth: 220)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.9))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.brown.opacity(0.3), lineWidth: 2)
                                    )
                                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                            )
                            
                            // Arrow connector
                            if index < recipe.ancestryStepsArray.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.brown.opacity(0.5))
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.brown.opacity(0.08),
                            Color.brown.opacity(0.04)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
    
    // MARK: - Description Section
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ABOUT")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.brown.opacity(0.6))
                .tracking(2)
            
            Text(description)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.15))
                .lineSpacing(6)
                .italic()
        }
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("INSTRUCTIONS")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.brown.opacity(0.6))
                .tracking(2)
            
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Array(recipe.stepsArray.enumerated()), id: \.element.id) { index, step in
                    stepRow(index: index, step: step)
                }
            }
        }
    }
    
    private func stepRow(index: Int, step: StepEntity) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.brown.opacity(0.9),
                                Color.brown.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Text("\(index + 1)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
            
            // Step instruction
            Text(step.instruction ?? "")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
        }
    }
    
    // MARK: - Ingredient Row
    
    private func ingredientRow(_ ingredient: IngredientEntity) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                // Decorative bullet
                Circle()
                    .fill(Color.brown.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                
                // Ingredient details
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name ?? "")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.08))
                    
                    if let qty = ingredient.quantity, !qty.isEmpty {
                        Text(qty)
                            .font(.system(size: 15))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
            }
            
            // Separator line
            Rectangle()
                .fill(Color.brown.opacity(0.15))
                .frame(height: 1)
                .padding(.leading, 18)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Photos Section
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("MY PHOTOS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.brown.opacity(0.6))
                    .tracking(2)
                
                Spacer()
                
                Button(action: { showingPhotoPicker = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.brown)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                }
            }
            
            if !recipe.photosArray.isEmpty {
                // Photo grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(recipe.photosArray) { photo in
                        if let imageData = photo.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipped()
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        dataManager.deletePhoto(photo)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            } else {
                Text("No photos yet. Tap 'Add' to include photos of your dish!")
                    .font(.system(size: 15))
                    .foregroundColor(.gray.opacity(0.7))
                    .italic()
                    .padding(.vertical, 20)
            }
        }
    }
    
    // MARK: - Floating Audio Player
    
    private func floatingAudioPlayer(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            if let audioNote = recipe.primaryAudioNote {
                HStack(spacing: 20) {
                    // Play/Pause button
                    Button(action: {
                        if let fileName = audioNote.audioFileName {
                            audioManager.togglePlayback(fileName: fileName)
                        }
                    }) {
                        Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.brown)
                    }
                    
                    // Progress and time
                    VStack(alignment: .leading, spacing: 10) {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.25))
                                    .frame(height: 10)
                                
                                // Progress fill
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.brown,
                                                Color.brown.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geo.size.width * CGFloat(audioManager.currentTime / max(audioNote.duration, 0.1)),
                                        height: 10
                                    )
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let progress = max(0, min(1, value.location.x / geo.size.width))
                                        let seekTime = Double(progress) * audioNote.duration
                                        audioManager.seek(to: seekTime)
                                    }
                            )
                        }
                        .frame(height: 10)
                        
                        // Time labels
                        HStack {
                            Text(audioManager.formatDuration(audioManager.currentTime))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text(audioManager.formatDuration(audioNote.duration))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Stop button
                    Button(action: {
                        audioManager.stopPlayback()
                    }) {
                        Image(systemName: "stop.circle")
                            .font(.system(size: 36))
                            .foregroundColor(.brown.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: -4)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 12)
            }
        }
    }
}

// MARK: - Preview

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataManager.shared.container.viewContext
        let recipe = RecipeEntity(context: context)
        recipe.title = "Test Recipe"
        recipe.recipeDescription = "A delicious test recipe"
        
        return RecipeDetailView(recipe: recipe)
    }
}
