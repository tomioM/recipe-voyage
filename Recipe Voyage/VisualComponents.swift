import SwiftUI

// MARK: - Paper Texture System
// This overlays a paper texture image on top of views

struct PaperTexture: View {
    let type: String // "aged", "parchment", or "cardstock"
    
    var body: some View {
        Image(type) // Load image from Assets
            .resizable() // Allow it to stretch
            .aspectRatio(contentMode: .fill) // Fill the space
            .blendMode(.multiply) // Blend with background color
            .opacity(0.35) // Make it semi-transparent
    }
}

// MARK: - Paper Card
// Creates a card that looks like a piece of paper

struct PaperCard: View {
    // Random slight rotation makes it look more natural
    var rotation: Double = Double.random(in: -1.5...1.5)
    
    var body: some View {
        ZStack { // ZStack layers things on top of each other
            // Base color (cream/beige)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.96, green: 0.95, blue: 0.92))
            
            // Paper texture on top
            PaperTexture(type: "aged")
            
            // Subtle border
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5) // Drop shadow
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 0, z: 1)) // Slight tilt
    }
}

// MARK: - Recipe Card
// The card you see in the mosaic view

struct RecipeCardView: View {
    let recipe: RecipeEntity // The recipe data
    
    var body: some View {
        PaperCard()
            .frame(width: 200, height: 280) // Set size
            .overlay( // Put content on top of the card
                VStack(spacing: 20) { // VStack = vertical stack
                    // Icon at top
                    Image(systemName: recipe.symbol ?? "fork.knife")
                        .font(.system(size: 55, weight: .light))
                        .foregroundColor(recipe.displayColor)
                        .padding(.top, 30)
                    
                    // Recipe title
                    Text(recipe.title ?? "Untitled")
                        .font(.custom("Georgia", size: 20))
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                        .padding(.horizontal, 16)
                        .lineLimit(3) // Max 3 lines
                    
                    Spacer()
                    
                    // Show audio indicator if there are recordings
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
            )
    }
}

// MARK: - Floating Button
// The buttons that float at the bottom of the screen

struct FloatingPaperButton: View {
    let icon: String // SF Symbol name (like "plus")
    let label: String? // Optional text label
    let action: () -> Void // What happens when you tap
    
    // Custom initializer to make label optional
    init(icon: String, label: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback (vibration)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action() // Run the action
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                
                // Show label if provided
                if let label = label {
                    Text(label)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
            .frame(height: 60)
            .padding(.horizontal, label != nil ? 24 : 20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.95, green: 0.93, blue: 0.89))
                    
                    PaperTexture(type: "cardstock")
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle()) // Apply press animation
    }
}

// Button style that scales down when pressed
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Section Container
// A styled container for recipe sections (ingredients, steps, etc.)

struct PaperSection<Content: View>: View {
    let title: String
    let content: () -> Content // Content is provided by whoever uses this
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text(title)
                .font(.custom("Georgia-Bold", size: 22))
                .foregroundColor(.brown)
            
            // Section content box
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.97, green: 0.95, blue: 0.91))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.brown.opacity(0.2), lineWidth: 2)
                    )
                
                PaperTexture(type: "parchment")
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                content() // The actual content goes here
                    .padding(20)
            }
        }
    }
}

// MARK: - Ornamental Title
// Big fancy title with decorative first letter

struct OrnamentalTitle: View {
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Big decorative first letter
            ZStack {
                Text(String(text.prefix(1))) // First character
                    .font(.custom("Georgia-Bold", size: 85))
                    .foregroundColor(color)
                
                // Seal background decoration
                Image(systemName: "seal.fill")
                    .font(.system(size: 75))
                    .foregroundColor(color.opacity(0.15))
            }
            .frame(width: 90)
            
            // Rest of the title
            VStack(alignment: .leading, spacing: 4) {
                Text(String(text.dropFirst())) // Everything after first character
                    .font(.custom("Georgia", size: 38))
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.25, green: 0.15, blue: 0.1))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Backgrounds

struct WoodBackground: View {
    var body: some View {
        ZStack {
            // Brown background color
            Color(red: 0.45, green: 0.35, blue: 0.25)
                .ignoresSafeArea()
            
            // If you have a wood texture image, uncomment these lines:
            // Image("wood_texture")
            //     .resizable()
            //     .ignoresSafeArea()
            //     .opacity(0.3)
        }
    }
}

struct ParchmentBackground: View {
    var body: some View {
        ZStack {
            // Light cream background
            Color(red: 0.98, green: 0.97, blue: 0.94)
                .ignoresSafeArea()
            
            // Parchment texture overlay
            PaperTexture(type: "parchment")
                .ignoresSafeArea()
                .allowsHitTesting(false) // Don't block touches
        }
    }
}

// MARK: - Scrapbook Audio Section
// Audio recordings displayed in scrapbook style on the aside

struct ScrapbookAudioSection: View {
    let audioNotes: [AudioNoteEntity]
    @ObservedObject var audioManager: AudioManager
    let onDelete: (AudioNoteEntity) -> Void
    let onAddRecording: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with add button
            HStack {
                Image(systemName: "waveform")
                    .font(.system(size: 18))
                    .foregroundColor(.brown)
                Text("Voice Notes")
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundColor(.brown)
                Spacer()
                Button(action: onAddRecording) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.brown)
                }
            }
            .padding(.horizontal, 8)
            
            // Audio note cards
            ForEach(audioNotes) { audioNote in
                ScrapbookAudioCard(
                    audioNote: audioNote,
                    audioManager: audioManager,
                    onDelete: { onDelete(audioNote) }
                )
            }
        }
    }
}

// MARK: - Scrapbook Audio Card
// Individual audio recording card with scrapbook styling

struct ScrapbookAudioCard: View {
    let audioNote: AudioNoteEntity
    @ObservedObject var audioManager: AudioManager
    let onDelete: () -> Void
    
    var isPlaying: Bool {
        audioManager.isPlaying && audioManager.currentPlayingFileName == audioNote.audioFileName
    }
    
    // Fixed rotation based on audio note ID for consistency
    private var rotation: Double {
        let hash = abs(audioNote.id?.hashValue ?? 0)
        return Double((hash % 40)) / 10.0 - 2.0 // Range: -2.0 to +2.0
    }
    
    var body: some View {
        ZStack {
            // Paper card background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.97, green: 0.96, blue: 0.93))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 3)
            
            PaperTexture(type: "aged")
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Content
            VStack(spacing: 12) {
                // Play/Stop button
                Button(action: {
                    if let fileName = audioNote.audioFileName {
                        audioManager.togglePlayback(fileName: fileName)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.brown.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.brown)
                    }
                }
                
                // Duration
                Text(audioManager.formatDuration(audioNote.duration))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.brown.opacity(0.7))
                
                // Delete button
                Button(action: onDelete) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                        Text("Remove")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.red.opacity(0.6))
                }
            }
            .padding(16)
        }
        .frame(width: 150, height: 160)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Scrapbook Photo Section
// Photo attachment spaces in scrapbook style

struct ScrapbookPhotoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 18))
                    .foregroundColor(.brown)
                Text("Photos")
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundColor(.brown)
            }
            .padding(.horizontal, 8)
            
            // Photo placeholders
            VStack(spacing: 20) {
                ScrapbookPhotoPlaceholder(size: CGSize(width: 200, height: 180), rotation: 2)
                ScrapbookPhotoPlaceholder(size: CGSize(width: 160, height: 160), rotation: -3)
                ScrapbookPhotoPlaceholder(size: CGSize(width: 180, height: 150), rotation: 1.5)
            }
        }
    }
}

// MARK: - Scrapbook Photo Placeholder
// Empty photo slot with tape effect

struct ScrapbookPhotoPlaceholder: View {
    let size: CGSize
    let rotation: Double
    
    var body: some View {
        ZStack {
            // Photo frame/slot
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 1, y: 2)
            
            // Dashed border
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .foregroundColor(.brown.opacity(0.3))
            
            // Placeholder icon
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundColor(.brown.opacity(0.3))
                Text("Tap to add")
                    .font(.system(size: 12))
                    .foregroundColor(.brown.opacity(0.4))
            }
            
            // Tape pieces at top corners
            TapeStrip()
                .offset(x: -size.width/3, y: -size.height/2 + 10)
            
            TapeStrip()
                .rotationEffect(.degrees(90))
                .offset(x: size.width/3, y: -size.height/2 + 10)
        }
        .frame(width: size.width, height: size.height)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Tape Strip
// Decorative tape piece for scrapbook effect

struct TapeStrip: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.93, blue: 0.85),
                        Color(red: 0.98, green: 0.96, blue: 0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 50, height: 20)
            .opacity(0.8)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
