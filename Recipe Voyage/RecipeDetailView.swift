//
//  RecipeDetailView.swift
//  Recipe Voyage
//
//  Created by Tomio Walkley-Miyagawa on 2025-11-29.
//

import SwiftUI

// Shows a single recipe with all details
struct RecipeDetailView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) var dismiss
    // Allows us to close this view
    
    @ObservedObject var dataManager = CoreDataManager.shared
    // Access to database
    
    @StateObject private var audioManager = AudioManager()
    // Manages audio playback/recording
    
    let recipe: RecipeEntity
    // The recipe we're showing
    
    @State private var showingEditor = false
    // Should we show the edit screen?
    
    @State private var showingAudioRecorder = false
    // Should we show the audio recording sheet?
    
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
                    
                    // Description section
                    if let description = recipe.recipeDescription, !description.isEmpty {
                        PaperSection(title: "Description") {
                            Text(description)
                                .font(.custom("Georgia", size: 18))
                                .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                                .lineSpacing(6)
                        }
                    }
                    
                    // Ingredients section
                    if !recipe.ingredientsArray.isEmpty {
                        ingredientsSection
                    }
                    
                    // Preparation steps section
                    if !recipe.stepsArray.isEmpty {
                        stepsSection
                    }
                    
                    // Audio recordings section
                    if !recipe.audioNotesArray.isEmpty {
                        audioNotesSection
                    }
                    
                    Spacer(minLength: 140) // Space for bottom toolbar
                }
                .padding(40)
            }
            
            // Floating toolbar at bottom
            bottomToolbar
        }
//        .sheet(isPresented: $showingEditor) {
//            // Show editor when true
//            RecipeEditorView(recipe: recipe)
//        }
        .sheet(isPresented: $showingAudioRecorder) {
            // Show audio recorder when true
            AudioRecorderSheet(recipe: recipe)
        }
    }
    
    // MARK: - Ingredients Section
    
    private var ingredientsSection: some View {
        PaperSection(title: "Ingredients") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(recipe.ingredientsArray) { ingredient in
                    HStack(alignment: .top, spacing: 8) {
                        // Little leaf bullet point
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green.opacity(0.6))
                            .padding(.top, 4)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            // Ingredient name
                            Text(ingredient.name ?? "")
                                .font(.custom("Georgia", size: 16))
                                .fontWeight(.medium)
                            
                            // Quantity (if provided)
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
    
    private var stepsSection: some View {
        PaperSection(title: "Preparation") {
            VStack(alignment: .leading, spacing: 16) {
                // Loop through steps with index numbers
                ForEach(Array(recipe.stepsArray.enumerated()), id: \.element) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        // Step number
                        Text("\(index + 1).")
                            .font(.custom("Georgia-Bold", size: 20))
                            .foregroundColor(.brown)
                            .frame(width: 30, alignment: .trailing)
                        
                        // Step instruction
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
    
    private var audioNotesSection: some View {
        PaperSection(title: "Voice Notes") {
            VStack(spacing: 12) {
                ForEach(recipe.audioNotesArray) { audioNote in
                    AudioNoteCell(
                        audioNote: audioNote,
                        audioManager: audioManager,
                        onDelete: {
                            // Delete this audio note
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
            Spacer() // Push to bottom
            
            HStack(spacing: 16) {
                // Back button
                FloatingPaperButton(icon: "arrow.left") {
                    dismiss()
                }
                
                // Edit button
                FloatingPaperButton(icon: "pencil") {
                    showingEditor = true
                }
                
                // Record audio button
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
// This is the screen that slides up when you tap the microphone button

struct AudioRecorderSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = CoreDataManager.shared
    @StateObject private var audioManager = AudioManager()
    
    let recipe: RecipeEntity
    @State private var currentFileName: String?
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Title
                Text("Record Voice Note")
                    .font(.custom("Georgia-Bold", size: 28))
                    .foregroundColor(.brown)
                
                Spacer()
                
                // The tape recorder button
                TapeRecorderButton(audioManager: audioManager) { fileName, duration in
                    // When recording finishes, save to database
                    dataManager.addAudioNote(to: recipe, fileName: fileName, duration: duration)
                    print("✅ Audio note saved to recipe")
                }
                
                Spacer()
                
                // Done button
                FloatingPaperButton(icon: "checkmark", label: "Done") {
                    dismiss()
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Preview

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample recipe for preview
        let context = CoreDataManager.shared.container.viewContext
        let recipe = RecipeEntity(context: context)
        recipe.title = "Sample Recipe"
        recipe.symbol = "fork.knife"
        recipe.colorHex = "#8B4513"
        
        return RecipeDetailView(recipe: recipe)
    }
}
