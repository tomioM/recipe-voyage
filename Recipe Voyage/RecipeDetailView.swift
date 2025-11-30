import SwiftUI

// Shows a single recipe with all details
struct RecipeDetailView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = CoreDataManager.shared
    @StateObject private var audioManager = AudioManager()
    
    let recipe: RecipeEntity
    
    @State private var showingEditor = false
    @State private var refreshTrigger = false
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                ParchmentBackground()
                
                // Main two-column layout
                HStack(alignment: .top, spacing: 0) {
                    // LEFT SIDE: Main recipe content (clean, unstyled)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            
                            // Decorative title
                            DecorativeTitle(text: recipe.title ?? "Untitled")
                                .padding(.top, 40)
                                .padding(.bottom, 24)
                            
                            // Description (no label, just content)
                            if let description = recipe.recipeDescription, !description.isEmpty {
                                Text(description)
                                    .font(.custom("Georgia-Italic", size: 18))
                                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.2))
                                    .lineSpacing(6)
                                    .padding(.bottom, 32)
                            }
                            
                            // Ingredients section
                            if !recipe.ingredientsArray.isEmpty {
                                ingredientsSection
                                    .padding(.bottom, 32)
                            }
                            
                            // Steps section
                            if !recipe.stepsArray.isEmpty {
                                stepsSection
                                    .padding(.bottom, 32)
                            }
                            
                            Spacer(minLength: 120)
                        }
                        .padding(.horizontal, 40)
                    }
                    .frame(width: geometry.size.width * 0.60)
                    
                    // RIGHT SIDE: Tape recorder and photos
                    ScrollView {
                        VStack(alignment: .center, spacing: 40) {
                            // Tape Recorder (no label)
                            TapeRecorderView(
                                recipe: recipe,
                                audioManager: audioManager,
                                dataManager: dataManager
                            )
                            .padding(.top, 60)
                            
                            // Photo placeholders (no caption)
                            photoSection
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(width: geometry.size.width * 0.40)
                }
                .id(refreshTrigger)
                
                // Floating toolbar at bottom
                bottomToolbar
            }
        }
        .ignoresSafeArea()
        .onAppear {
            dataManager.container.viewContext.refresh(recipe, mergeChanges: true)
        }
        .sheet(isPresented: $showingEditor) {
            Text("Editor coming soon!")
                .font(.largeTitle)
        }
    }
    
    // MARK: - Decorative Title
    
    struct DecorativeTitle: View {
        let text: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 4) {
                // Big decorative first letter
                Text(String(text.prefix(1)))
                    .font(.custom("Georgia-Bold", size: 72))
                    .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.2))
                    .frame(alignment: .top)
                    .offset(y: -8)
                
                // Rest of the title
                Text(String(text.dropFirst()))
                    .font(.custom("Georgia", size: 32))
                    .foregroundColor(Color(red: 0.25, green: 0.18, blue: 0.12))
                    .padding(.top, 12)
            }
        }
    }
    
    // MARK: - Ingredients Section
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Simple divider line
            Rectangle()
                .fill(Color.brown.opacity(0.3))
                .frame(height: 1)
                .padding(.bottom, 8)
            
            // Section title
            Text("Ingredients")
                .font(.custom("Georgia-Bold", size: 20))
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                .padding(.bottom, 4)
            
            // Ingredient list
            ForEach(recipe.ingredientsArray) { ingredient in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    // Bullet
                    Text("•")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.brown.opacity(0.5))
                    
                    // Ingredient with quantity
                    if let quantity = ingredient.quantity, !quantity.isEmpty {
                        Text("\(quantity) ")
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                        +
                        Text(ingredient.name ?? "")
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(Color(red: 0.25, green: 0.18, blue: 0.12))
                    } else {
                        Text(ingredient.name ?? "")
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(Color(red: 0.25, green: 0.18, blue: 0.12))
                    }
                }
            }
        }
    }
    
    // MARK: - Steps Section
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Simple divider line
            Rectangle()
                .fill(Color.brown.opacity(0.3))
                .frame(height: 1)
                .padding(.bottom, 8)
            
            // Section title
            Text("Preparation")
                .font(.custom("Georgia-Bold", size: 20))
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                .padding(.bottom, 4)
            
            // Steps
            ForEach(Array(recipe.stepsArray.enumerated()), id: \.element) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    // Step number
                    Text("\(index + 1).")
                        .font(.custom("Georgia-Bold", size: 16))
                        .foregroundColor(Color.brown.opacity(0.6))
                        .frame(width: 24, alignment: .trailing)
                    
                    // Instruction
                    Text(step.instruction ?? "")
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(Color(red: 0.25, green: 0.18, blue: 0.12))
                        .lineSpacing(4)
                }
                .padding(.bottom, 4)
            }
        }
    }
    
    // MARK: - Photo Section (no caption)
    
    private var photoSection: some View {
        VStack(spacing: 20) {
            PhotoPlaceholder(size: CGSize(width: 180, height: 160), rotation: 2)
            PhotoPlaceholder(size: CGSize(width: 160, height: 140), rotation: -2.5)
            PhotoPlaceholder(size: CGSize(width: 170, height: 150), rotation: 1.5)
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                FloatingPaperButton(icon: "arrow.left") {
                    dismiss()
                }
                
                FloatingPaperButton(icon: "pencil") {
                    showingEditor = true
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Tape Recorder View
// Vintage-style tape recorder with record, play/pause, stop

struct TapeRecorderView: View {
    let recipe: RecipeEntity
    @ObservedObject var audioManager: AudioManager
    let dataManager: CoreDataManager
    
    @State private var currentRecordingFileName: String?
    @State private var isRecording = false
    @State private var reelRotation: Double = 0
    @State private var leftReelRotation: Double = 0
    @State private var rightReelRotation: Double = 0
    
    // Get the single audio note for this recipe (if any)
    private var audioNote: AudioNoteEntity? {
        recipe.audioNotesArray.first
    }
    
    private var isPlaying: Bool {
        guard let note = audioNote else { return false }
        return audioManager.isPlaying && audioManager.currentPlayingFileName == note.audioFileName
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tape recorder body
            ZStack {
                // Main body
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.75, green: 0.68, blue: 0.58),
                                Color(red: 0.65, green: 0.58, blue: 0.48)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 220, height: 180)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Inner bezel
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.25, green: 0.22, blue: 0.2))
                    .frame(width: 200, height: 160)
                
                VStack(spacing: 12) {
                    // Tape window (shows reels)
                    ZStack {
                        // Window background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.15, green: 0.12, blue: 0.1))
                            .frame(width: 180, height: 70)
                        
                        // Left reel
                        TapeReel(rotation: leftReelRotation)
                            .offset(x: -50)
                        
                        // Right reel
                        TapeReel(rotation: rightReelRotation)
                            .offset(x: 50)
                        
                        // Tape connecting reels
                        Rectangle()
                            .fill(Color(red: 0.3, green: 0.25, blue: 0.2))
                            .frame(width: 60, height: 3)
                            .offset(y: 8)
                        
                        // Duration display
                        if let note = audioNote {
                            Text(audioManager.formatDuration(isRecording ? audioManager.recordingDuration : note.duration))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.green.opacity(0.8))
                                .offset(y: -25)
                        } else if isRecording {
                            Text(audioManager.formatDuration(audioManager.recordingDuration))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.red.opacity(0.9))
                                .offset(y: -25)
                        } else {
                            Text("0:00")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.6))
                                .offset(y: -25)
                        }
                    }
                    
                    // Control buttons
                    HStack(spacing: 16) {
                        // Record button
                        Button(action: toggleRecording) {
                            Circle()
                                .fill(isRecording ? Color.red : Color(red: 0.7, green: 0.2, blue: 0.2))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                                .shadow(color: isRecording ? .red.opacity(0.5) : .clear, radius: 6)
                        }
                        
                        // Play/Pause button
                        Button(action: togglePlayback) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                                    .frame(width: 36, height: 36)
                                
                                if isPlaying {
                                    // Pause icon
                                    HStack(spacing: 4) {
                                        Rectangle()
                                            .fill(Color.white)
                                            .frame(width: 4, height: 14)
                                        Rectangle()
                                            .fill(Color.white)
                                            .frame(width: 4, height: 14)
                                    }
                                } else {
                                    // Play icon
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .offset(x: 2)
                                }
                            }
                        }
                        .disabled(audioNote == nil && !isRecording)
                        .opacity(audioNote == nil && !isRecording ? 0.5 : 1.0)
                        
                        // Stop button
                        Button(action: stopAll) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
                                    .frame(width: 36, height: 36)
                                
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .disabled(!isPlaying && !isRecording)
                        .opacity(!isPlaying && !isRecording ? 0.5 : 1.0)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .onAppear {
            // Start reel animation if playing
            updateReelAnimation()
        }
        .onChange(of: isPlaying) { _ in
            updateReelAnimation()
        }
        .onChange(of: isRecording) { _ in
            updateReelAnimation()
        }
    }
    
    // MARK: - Actions
    
    private func toggleRecording() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if isRecording {
            // Stop recording
            let duration = audioManager.stopRecording()
            if let fileName = currentRecordingFileName, duration > 0 {
                // Delete existing recording first
                if let existingNote = audioNote {
                    dataManager.deleteAudioNote(existingNote)
                }
                // Save new recording
                dataManager.addAudioNote(to: recipe, fileName: fileName, duration: duration)
                dataManager.container.viewContext.refresh(recipe, mergeChanges: true)
            }
            currentRecordingFileName = nil
            isRecording = false
        } else {
            // Stop any playback first
            audioManager.stopPlayback()
            // Start recording
            currentRecordingFileName = audioManager.startRecording()
            isRecording = audioManager.isRecording
        }
    }
    
    private func togglePlayback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if let note = audioNote, let fileName = note.audioFileName {
            audioManager.togglePlayback(fileName: fileName)
        }
    }
    
    private func stopAll() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if isRecording {
            // Cancel recording without saving
            _ = audioManager.stopRecording()
            currentRecordingFileName = nil
            isRecording = false
        }
        audioManager.stopPlayback()
    }
    
    private func updateReelAnimation() {
        if isPlaying || isRecording {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                leftReelRotation = 360
                rightReelRotation = 360
            }
        } else {
            withAnimation(.easeOut(duration: 0.5)) {
                // Keep current rotation (don't reset)
            }
        }
    }
}

// MARK: - Tape Reel

struct TapeReel: View {
    let rotation: Double
    
    var body: some View {
        ZStack {
            // Reel base
            Circle()
                .fill(Color(red: 0.2, green: 0.18, blue: 0.15))
                .frame(width: 50, height: 50)
            
            // Tape on reel
            Circle()
                .fill(Color(red: 0.35, green: 0.3, blue: 0.25))
                .frame(width: 40, height: 40)
            
            // Center hub
            Circle()
                .fill(Color(red: 0.5, green: 0.45, blue: 0.4))
                .frame(width: 16, height: 16)
            
            // Spokes
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(Color(red: 0.2, green: 0.18, blue: 0.15))
                    .frame(width: 2, height: 40)
                    .rotationEffect(.degrees(Double(i) * 60 + rotation))
            }
            
            // Center hole
            Circle()
                .fill(Color(red: 0.15, green: 0.12, blue: 0.1))
                .frame(width: 6, height: 6)
        }
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Photo Placeholder (simplified, no caption)

struct PhotoPlaceholder: View {
    let size: CGSize
    let rotation: Double
    
    var body: some View {
        ZStack {
            // Photo frame
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 1, y: 2)
            
            // Dashed border
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .foregroundColor(.brown.opacity(0.25))
            
            // Placeholder icon
            VStack(spacing: 6) {
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(.brown.opacity(0.25))
                Text("Tap to add")
                    .font(.system(size: 10))
                    .foregroundColor(.brown.opacity(0.35))
            }
            
            // Tape at top
            TapeStrip()
                .offset(y: -size.height / 2 + 10)
        }
        .frame(width: size.width, height: size.height)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Preview

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataManager.shared.container.viewContext
        let recipe = RecipeEntity(context: context)
        recipe.title = "Sample Recipe"
        recipe.symbol = "fork.knife"
        recipe.colorHex = "#8B4513"
        
        return RecipeDetailView(recipe: recipe)
    }
}
