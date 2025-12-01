import SwiftUI
import PhotosUI

// MARK: - Recipe Detail View
// Shows recipe with compact timeline, content, photos sidebar, and auto-play audio

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
                    // Main content area
                    if isLandscape {
                        // Landscape: Recipe on left, Photos on right
                        HStack(alignment: .top, spacing: 0) {
                            // Recipe content (scrollable)
                            ScrollView {
                                VStack(spacing: 20) {
                                    // History Block
                                    if !recipe.ancestryStepsArray.isEmpty {
                                        VStack(spacing: 16) {
                                            Text("HISTORY")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.brown.opacity(0.6))
                                                .tracking(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            compactAncestryTimelineContent
                                        }
                                        .padding(20)
                                        .background(Color.white.opacity(0.5))
                                        .cornerRadius(16)
                                    }
                                    
                                    // Recipe Block
                                    VStack(spacing: 16) {
                                        Text("RECIPE")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.brown.opacity(0.6))
                                            .tracking(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        recipeContentBody
                                    }
                                    .padding(20)
                                    .background(Color.white.opacity(0.5))
                                    .cornerRadius(16)
                                }
                                .padding(20)
                                .padding(.bottom, 100)
                            }
                            .frame(width: geometry.size.width * (isLandscapeiPad ? 0.7 : 0.65))
                            
                            Divider()
                            
                            // Photos sidebar
                            photosSidebar(geometry: geometry)
                        }
                    } else {
                        // Portrait: Recipe content with photos below or overlaid
                        ScrollView {
                            VStack(spacing: 20) {
                                Spacer()
                                    .frame(height: 70)
                                // History Block
                                if !recipe.ancestryStepsArray.isEmpty {
                                    VStack(spacing: 16) {
                                        Text("HISTORY")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.brown.opacity(0.6))
                                            .tracking(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 20)
                                        
                                        compactAncestryTimelineContent
                                    }
                                    .padding(.vertical, 20)
                                    .background(Color.white.opacity(0.5))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                                }
                                
                                // Recipe Block
                                VStack(spacing: 16) {
                                    Text("RECIPE")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.brown.opacity(0.6))
                                        .tracking(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                    
                                    recipeContentBody
                                }
                                .padding(.vertical, 20)
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(16)
                                .padding(.horizontal, 16)
                                
                                // Photos section in portrait
                                photosSection
                            }
                            .padding(.bottom, 100) // Space for audio player
                        }
                    }
                }
                
                // Close button
                closeButton
                
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
    
    // MARK: - Compact Ancestry Timeline
    
    private var compactAncestryTimelineContent: some View {
        HStack(spacing: 0) {
            // Play/Pause button on the left (if audio exists)
            if let audioNote = recipe.primaryAudioNote,
               let fileName = audioNote.audioFileName {
                Button(action: {
                    audioManager.togglePlayback(fileName: fileName)
                }) {
                    Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.brown)
                        .padding(.leading, 16)
                }
            }
            
            // Ancestry timeline
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(recipe.ancestryStepsArray.enumerated()), id: \.element.id) { index, step in
                        HStack(spacing: 8) {
                            // Ancestry step card (larger and more prominent)
                            VStack(alignment: .leading, spacing: 8) {
                                // Header label
                                Text("ORIGIN \(index + 1)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.brown.opacity(0.5))
                                    .tracking(0.5)
                                
                                // Country and Region row
                                HStack(spacing: 10) {
                                    // Country (always shown)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(step.country ?? "Unknown")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                                    }
                                    
                                    // Region (if not empty)
                                    if let region = step.region, !region.isEmpty {
                                        Divider()
                                            .frame(height: 30)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(region)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.brown.opacity(0.8))
                                        }
                                    }
                                }
                                
                                // Date (if not empty)
                                if let date = step.roughDate, !date.isEmpty {
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(date)
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                            .italic()
                                    }
                                }
                                
                                // Note (if not empty)
                                if let note = step.note, !note.isEmpty {
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(note)
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                                            .lineLimit(3)
                                    }
                                }
                            }
                            .padding(16)
                            .frame(minWidth: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.brown.opacity(0.25), lineWidth: 2)
                                    )
                                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                            )
                            
                            // Arrow connector
                            if index < recipe.ancestryStepsArray.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.brown.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.brown.opacity(0.15),
                    Color.brown.opacity(0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    

    
    private var recipeContentBody: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title with decorative capital letter
            titleWithDecorativeCap
            
            // Description
            if let description = recipe.recipeDescription, !description.isEmpty {
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                    .italic()
            }
            
            // Ingredients
            if !recipe.ingredientsArray.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingredients")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                    
                    ForEach(recipe.ingredientsArray) { ingredient in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.brown.opacity(0.5))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ingredient.name ?? "")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                                
                                if let qty = ingredient.quantity, !qty.isEmpty {
                                    Text(qty)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            
            // Steps
            if !recipe.stepsArray.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Instructions")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                    
                    ForEach(Array(recipe.stepsArray.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.brown))
                            
                            Text(step.instruction ?? "")
                                .font(.system(size: 16))
                                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Title with Decorative Capital
    
    private var titleWithDecorativeCap: some View {
        let title = recipe.title ?? "Untitled Recipe"
        let fontName = recipe.decorativeCapFont ?? "Didot"
        let accentColor = Color(hex: recipe.colorHex ?? "#8B4513") ?? Color.brown
        
        return HStack(alignment: .top, spacing: 8) {
            if let firstChar = title.first {
                // Decorative capital letter
                Text(String(firstChar).uppercased())
                    .font(.custom(fontName, size: isLandscapeiPad ? 72 : 64))
                    .foregroundColor(accentColor)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                // Rest of the title
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(title.dropFirst()))
                        .font(.system(size: isLandscapeiPad ? 32 : 26, weight: .bold))
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                }
                .padding(.top, isLandscapeiPad ? 12 : 8)
            } else {
                Text(title)
                    .font(.system(size: isLandscapeiPad ? 32 : 26, weight: .bold))
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            }
        }
        .padding(.top, recipe.ancestryStepsArray.isEmpty ? 60 : 16)
    }
    
    // MARK: - Photos Sidebar (Landscape)
    
    private func photosSidebar(geometry: GeometryProxy) -> some View {
        let sidebarWidth = geometry.size.width * (isLandscapeiPad ? 0.3 : 0.35)
        
        return VStack(spacing: 16) {
            HStack {
                Text("My Photos")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                
                Spacer()
                
                Button(action: { showingPhotoPicker = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.brown)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, recipe.ancestryStepsArray.isEmpty ? 60 : 16)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recipe.photosArray) { photo in
                        if let imageData = photo.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: sidebarWidth - 32, height: 200)
                                .clipped()
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                .padding(.horizontal, 16)
            }
        }
        .frame(width: sidebarWidth)
        .background(Color.white.opacity(0.5))
    }
    
    // MARK: - Photos Section (Portrait)
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Photos")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                
                Spacer()
                
                Button(action: { showingPhotoPicker = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.brown)
                }
            }
            .padding(.horizontal, 20)
            
            if !recipe.photosArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recipe.photosArray) { photo in
                            if let imageData = photo.imageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 150)
                                    .clipped()
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Floating Audio Player
    
    private func floatingAudioPlayer(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            if let audioNote = recipe.primaryAudioNote {
                HStack(spacing: 16) {
                    // Play/Pause button
                    Button(action: {
                        if let fileName = audioNote.audioFileName {
                            audioManager.togglePlayback(fileName: fileName)
                        }
                    }) {
                        Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.brown)
                    }
                    
                    // Progress and time
                    VStack(alignment: .leading, spacing: 8) {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)
                                
                                // Progress fill
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.brown)
                                    .frame(
                                        width: geo.size.width * CGFloat(audioManager.currentTime / max(audioNote.duration, 0.1)),
                                        height: 8
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
                        .frame(height: 8)
                        
                        // Time labels
                        HStack {
                            Text(audioManager.formatDuration(audioManager.currentTime))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text(audioManager.formatDuration(audioNote.duration))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Stop button
                    Button(action: {
                        audioManager.stopPlayback()
                    }) {
                        Image(systemName: "stop.circle")
                            .font(.system(size: 32))
                            .foregroundColor(.brown.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: -2)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
            }
        }
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.brown.opacity(0.8))
                        .background(Circle().fill(Color.white))
                }
                .padding(.top, 50)
                .padding(.trailing, 20)
            }
            Spacer()
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
