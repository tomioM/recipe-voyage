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
