import SwiftUI

// MARK: - Paper Texture System

struct PaperTexture: View {
    let type: String // "aged", "parchment", or "cardstock"
    
    var body: some View {
        Image(type)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .blendMode(.multiply)
            .opacity(0.35)
    }
}

// MARK: - Backgrounds

struct WoodBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.45, green: 0.35, blue: 0.25)
                .ignoresSafeArea()
        }
    }
}

struct ParchmentBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.94)
                .ignoresSafeArea()
            
            PaperTexture(type: "parchment")
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Decorative Title

struct DecorativeTitle: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.custom("Georgia-Bold", size: 36))
            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Paper Card

struct PaperCard: View {
    var rotation: Double = Double.random(in: -1.5...1.5)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.96, green: 0.95, blue: 0.92))
            
            PaperTexture(type: "aged")
            
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 0, z: 1))
    }
}

// MARK: - Floating Button

struct FloatingPaperButton: View {
    let icon: String
    let label: String?
    let action: () -> Void
    
    init(icon: String, label: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                
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
    }
}

// MARK: - Photo Placeholder

struct PhotoPlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundColor(.brown.opacity(0.3))
            
            Text("Tap to add photo")
                .font(.system(size: 12))
                .foregroundColor(.brown.opacity(0.5))
        }
        .frame(width: 180, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundColor(.brown.opacity(0.3))
        )
    }
}
