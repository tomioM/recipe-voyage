import SwiftUI

// MARK: - Recipe Ancestry Timeline
// Full-width horizontal timeline showing the journey of a recipe through generations

struct RecipeAncestryTimeline: View {
    let ancestrySteps: [AncestryStepEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
//            Text("Recipe Journey")
//                .font(.custom("Georgia-Bold", size: 24))
//                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            if ancestrySteps.isEmpty {
                // Empty state
                Text("No ancestry recorded")
                    .font(.custom("Georgia-Italic", size: 14))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .padding(.vertical, 20)
            } else {
                // Full-width horizontal scrolling timeline
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(ancestrySteps.enumerated()), id: \.element.id) { index, step in
                            HStack(spacing: 0) {
                                // Ancestry step card
                                AncestryStepCard(
                                    step: step,
                                    isFirst: index == 0,
                                    isLast: index == ancestrySteps.count - 1
                                )
                                
                                // Connector arrow (if not last)
                                if index < ancestrySteps.count - 1 {
                                    TimelineConnector()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
    }
}

// MARK: - Ancestry Step Card
// Individual card in the timeline - updated styling

struct AncestryStepCard: View {
    let step: AncestryStepEntity
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with flag/star
            HStack {
                // Country (required)
                Text(step.country ?? "Unknown")
                    .font(.custom("Georgia-Bold", size: 18))
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                
                Spacer()
                
                // Icon
                if isFirst {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.brown.opacity(0.6))
                } else if isLast {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.brown.opacity(0.6))
                }
            }
            
            // Region (optional)
            if let region = step.region, !region.isEmpty {
                Text(region)
                    .font(.custom("Georgia", size: 15))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
            }
            
            // Rough date (optional)
            if let date = step.roughDate, !date.isEmpty {
                Text(date)
                    .font(.custom("Georgia-Italic", size: 14))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
            }
            
            // Note (optional)
            if let note = step.note, !note.isEmpty {
                Text(note)
                    .font(.custom("Georgia", size: 13))
                    .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.25))
                    .lineLimit(3)
                    .frame(maxWidth: 220)
                    .padding(.top, 6)
            }
            
            // Generation indicator (optional)
            if step.generation > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 9))
                    Text("Gen \(step.generation)")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.brown.opacity(0.5))
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(width: 240, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.96, green: 0.95, blue: 0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.brown.opacity(isFirst || isLast ? 0.5 : 0.3), lineWidth: isFirst || isLast ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Timeline Connector
// Arrow connecting ancestry steps

struct TimelineConnector: View {
    var body: some View {
        HStack(spacing: 4) {
            // Dashed line
            Rectangle()
                .fill(Color.brown.opacity(0.3))
                .frame(width: 50, height: 2)
            
            // Arrow
            Image(systemName: "arrowtriangle.right.fill")
                .font(.system(size: 10))
                .foregroundColor(.brown.opacity(0.4))
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview

struct RecipeAncestryTimeline_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("With Ancestry")
                .font(.headline)
            
            RecipeAncestryTimeline(ancestrySteps: [])
                .padding()
            
            Spacer()
        }
    }
}
