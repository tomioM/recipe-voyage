import SwiftUI

// Shows a single recipe with all details
struct RecipeDetailView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = CoreDataManager.shared
    @StateObject private var audioManager = AudioManager()
    
    let recipe: RecipeEntity
    
    @State private var showingEditor = false
    @State private var showingAudioRecorder = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            ParchmentBackground()
            
            // Main scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Fancy title with big first letter
                    OrnamentalTitle(
                        text: recipe.title ?? "Untitled",
                        color: recipe.displayColor
                    )
                    .padding(.top, 20)
                    
                    // Symbol icon
                    Image(systemName: recipe.symbol ?? "fork.knife")
                        .font(.system(size: 70))
                        .foregroundColor(recipe.displayColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    
                    // Description section - with safe unwrapping
                    if let description = recipe.recipeDescription,
                       !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        PaperSection(title: "Description") {
                            Text(description)
                                .font(.custom("Georgia", size: 18))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                                .lineSpacing(6)
                        }
                    }
                    
                    // Ingredients section - safer check
                    let ingredients = recipe.ingredientsArray
                    if !ingredients.isEmpty {
                        ingredientsSection(ingredients: ingredients)
                    }
                    
                    // Preparation steps section - safer check
                    let steps = recipe.stepsArray
                    if !steps.isEmpty {
                        stepsSection(steps: steps)
                    }
                    
                    // Audio recordings section - safer check
                    let audioNotes = recipe.audioNotesArray
                    if !audioNotes.isEmpty {
                        audioNotesSection(audioNotes: audioNotes)
                    }
                    
                    Spacer(minLength: 140)
                }
                .padding(40)
            }
            
            // Floating toolbar at bottom
            bottomToolbar
        }
        // Commented out until we build the editor
        // .sheet(isPresented: $showingEditor) {
        //     RecipeEditorView(recipe: recipe)
        // }
        .sheet(isPresented: $showingAudioRecorder) {
            AudioRecorderSheet(recipe: recipe)
        }
    }
    
    // MARK: - Ingredients Section
    
    private func ingredientsSection(ingredients: [IngredientEntity]) -> some View {
        PaperSection(title: "Ingredients") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(ingredients) { ingredient in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green.opacity(0.6))
                            .padding(.top, 4)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ingredient.name ?? "")
                                .font(.custom("Georgia", size: 16))
                                .fontWeight(.medium)
                            
                            if let quantity = ingredient.quantity, !quantity.isEmpty {
                                Text(quantity)
                                    .font(.custom("Georgia", size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Steps Section
    
    private func stepsSection(steps: [StepEntity]) -> some View {
        PaperSection(title: "Preparation") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.custom("Georgia-Bold", size: 20))
                            .foregroundColor(.brown)
                            .frame(width: 30, alignment: .trailing)
                        
                        Text(step.instruction ?? "")
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                            .lineSpacing(4)
                    }
                }
            }
        }
    }
    
    // MARK: - Audio Notes Section
    
    private func audioNotesSection(audioNotes: [AudioNoteEntity]) -> some View {
        PaperSection(title: "Voice Notes") {
            VStack(spacing: 12) {
                ForEach(audioNotes) { audioNote in
                    AudioNoteCell(
                        audioNote: audioNote,
                        audioManager: audioManager,
                        onDelete: {
                            dataManager.deleteAudioNote(audioNote)
                        }
                    )
                }
            }
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
                
                FloatingPaperButton(icon: "mic.fill") {
                    showingAudioRecorder = true
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Audio Recorder Sheet

struct AudioRecorderSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = CoreDataManager.shared
    @StateObject private var audioManager = AudioManager()
    
    let recipe: RecipeEntity
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Text("Record Voice Note")
                    .font(.custom("Georgia-Bold", size: 28))
                    .foregroundColor(.brown)
                
                Spacer()
                
                TapeRecorderButton(audioManager: audioManager) { fileName, duration in
                    dataManager.addAudioNote(to: recipe, fileName: fileName, duration: duration)
                    print("✅ Audio note saved to recipe")
                }
                
                Spacer()
                
                FloatingPaperButton(icon: "checkmark", label: "Done") {
                    dismiss()
                }
            }
            .padding(40)
        }
    }
}
