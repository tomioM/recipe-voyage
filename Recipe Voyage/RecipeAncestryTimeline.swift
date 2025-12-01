import SwiftUI

// MARK: - Recipe Ancestry Timeline
// Horizontal timeline showing the journey of a recipe through generations

struct RecipeAncestryTimeline: View {
    let ancestrySteps: [AncestryStepEntity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("Recipe Journey")
                .font(.custom("Georgia-Bold", size: 20))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            if ancestrySteps.isEmpty {
                // Empty state
                Text("No ancestry recorded")
                    .font(.custom("Georgia-Italic", size: 14))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .padding(.vertical, 20)
            } else {
                // Horizontal scrolling timeline
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
                                
                                // Connector line (if not last)
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
        .padding(.vertical, 8)
    }
}

// MARK: - Ancestry Step Card
// Individual card in the timeline

struct AncestryStepCard: View {
    let step: AncestryStepEntity
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Country (required)
            Text(step.country ?? "Unknown")
                .font(.custom("Georgia-Bold", size: 16))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            // Region (optional)
            if let region = step.region, !region.isEmpty {
                Text(region)
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
            }
            
            // Rough date (optional)
            if let date = step.roughDate, !date.isEmpty {
                Text(date)
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
            }
            
            // Note (optional)
            if let note = step.note, !note.isEmpty {
                Text(note)
                    .font(.custom("Georgia", size: 12))
                    .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.25))
                    .lineLimit(3)
                    .frame(maxWidth: 180)
                    .padding(.top, 4)
            }
            
            // Generation indicator (optional)
            if step.generation > 0 {
                Text("Generation \(step.generation)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.brown.opacity(0.6))
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .frame(width: 200, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.96, green: 0.95, blue: 0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.brown.opacity(0.3), lineWidth: 1)
        )
        // Highlight first and last differently
        .overlay(
            Group {
                if isFirst {
                    VStack {
                        HStack {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.brown.opacity(0.6))
                                .padding(4)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                if isLast {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.brown.opacity(0.6))
                                .padding(4)
                        }
                        Spacer()
                    }
                }
            }
        )
    }
}

// MARK: - Timeline Connector
// Arrow connecting ancestry steps

struct TimelineConnector: View {
    var body: some View {
        HStack(spacing: 0) {
            // Line
            Rectangle()
                .fill(Color.brown.opacity(0.4))
                .frame(width: 40, height: 2)
            
            // Arrow
            Image(systemName: "arrowtriangle.right.fill")
                .font(.system(size: 8))
                .foregroundColor(.brown.opacity(0.4))
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Preview

struct RecipeAncestryTimeline_Previews: PreviewProvider {
    static var previews: some View {
        // Mock data for preview
        VStack {
            Text("With Ancestry")
                .font(.headline)
            
            RecipeAncestryTimeline(ancestrySteps: [])
            
            Text("Empty State")
                .font(.headline)
                .padding(.top)
            
            RecipeAncestryTimeline(ancestrySteps: [])
                .padding()
        }
    }
}
