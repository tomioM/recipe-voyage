import SwiftUI

// MARK: - Create Recipe View
// WYSIWYG editor that mirrors the recipe detail view layout
// Users edit the interface directly, not through a form

struct CreateRecipeView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @ObservedObject var dataManager = CoreDataManager.shared
    @StateObject private var audioManager = AudioManager()
    
    // Recipe data being edited
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var ingredients: [EditableIngredient] = []
    @State private var steps: [EditableStep] = []
    @State private var ancestrySteps: [EditableAncestry] = []
    @State private var draggedAncestry: EditableAncestry?
    
    // Audio recording
    @State private var recordedFileName: String?
    @State private var recordedDuration: TimeInterval = 0
    @State private var isRecording = false
    
    // UI state
    @State private var showingDiscardAlert = false
    
    var isLandscape: Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }
    
    var isLandscapeiPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    var hasContent: Bool {
        !title.isEmpty || !description.isEmpty || !ingredients.isEmpty || !steps.isEmpty || recordedFileName != nil
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(red: 0.98, green: 0.97, blue: 0.94)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Editable ancestry timeline at top
                    editableAncestryTimeline
                        .padding(.top, geometry.safeAreaInsets.top + 50)
                    
                    // Main content area
                    if isLandscape {
                        HStack(alignment: .top, spacing: 0) {
                            // Recipe content editor
                            ScrollView {
                                recipeEditorContent
                                    .padding(.bottom, 120)
                            }
                            .frame(width: geometry.size.width * (isLandscapeiPad ? 0.7 : 0.65))
                            
                            Divider()
                            
                            // Audio recording sidebar
                            audioRecordingSidebar(geometry: geometry)
                        }
                    } else {
                        // Portrait layout
                        ScrollView {
                            VStack(spacing: 24) {
                                recipeEditorContent
                                
                                // Audio recording section
                                audioRecordingSection
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
                
                // Header with Cancel/Save
                headerBar
                
                // Save button floating at bottom
                saveButton(geometry: geometry)
            }
            .ignoresSafeArea()
        }
        .alert("Discard Recipe?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard this recipe?")
        }
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        VStack {
            HStack {
                Button(action: {
                    if hasContent {
                        showingDiscardAlert = true
                    } else {
                        dismiss()
                    }
                }) {
                    Text("Cancel")
                        .foregroundColor(.brown)
                }
                .padding(.leading, 20)
                
                Spacer()
                
                Text("New Recipe")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                
                Spacer()
                
                // Invisible spacer for balance
                Text("Cancel")
                    .opacity(0)
                    .padding(.trailing, 20)
            }
            .padding(.top, 50)
            .padding(.bottom, 10)
            .background(Color(red: 0.98, green: 0.97, blue: 0.94).opacity(0.95))
            
            Spacer()
        }
    }
    
    // MARK: - Editable Ancestry Timeline
    
    private var editableAncestryTimeline: some View {
        VStack(spacing: 0) {
            ancestryTimelineContent
        }
//        .background {
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    Color.brown.opacity(0.15),
//                    Color.brown.opacity(0.08)
//                ]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        }
    }
    
    private var ancestryTimelineContent: some View {
        HStack(spacing: 0) {
            playPauseButton
            ancestryCardsScrollView
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var playPauseButton: some View {
        if let fileName = recordedFileName {
            Button(action: { audioManager.togglePlayback(fileName: fileName) }) {
                Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.brown)
                    .padding(.leading, 16)
            }
        }
    }

    private var ancestryCardsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(ancestrySteps.enumerated()), id: \.element.id) { index, step in
                    ancestryCardRow(for: step, at: index)
                }
                addOriginButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func ancestryCardRow(for step: EditableAncestry, at index: Int) -> some View {
        HStack(spacing: 8) {
            EditableAncestryCard(
                ancestry: $ancestrySteps[index],
                onDelete: {
                    withAnimation {
                        ancestrySteps.removeAll { $0.id == step.id }
                    }
                }
            )
            .opacity(draggedAncestry?.id == step.id ? 0.5 : 1.0)
            .onDrag {
                self.draggedAncestry = step
                return NSItemProvider(object: step.id.uuidString as NSString)
            }
            .onDrop(of: [.text], delegate: AncestryDropDelegate(
                item: step,
                items: $ancestrySteps,
                draggedItem: $draggedAncestry
            ))
            
            if index < ancestrySteps.count - 1 {
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brown.opacity(0.6))
            }
        }
    }

    private var addOriginButton: some View {
        Button(action: { withAnimation { ancestrySteps.append(EditableAncestry()) } }) {
            VStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                Text("Add Origin")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.brown)
            .frame(minWidth: 100)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                    .foregroundColor(.brown.opacity(0.5))
            )
        }
    }
    
    // MARK: - Recipe Editor Content
    
    private var recipeEditorContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title field (inline editable)
            TextField("Recipe Title", text: $title)
                .font(.system(size: isLandscapeiPad ? 32 : 26, weight: .bold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                .padding(.top, 16)
            
            // Description field
            ZStack(alignment: .topLeading) {
                if description.isEmpty {
                    Text("Add a description...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.6))
                        .italic()
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                
                TextEditor(text: $description)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                    .frame(minHeight: 60)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            
            // Ingredients section
            ingredientsEditor
            
            // Steps section
            stepsEditor
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Ingredients Editor
    
    private var ingredientsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, _ in
                EditableIngredientRow(
                    ingredient: $ingredients[index],
                    onDelete: {
                        ingredients.remove(at: index)
                    }
                )
            }
            
            // Add ingredient button
            Button(action: {
                ingredients.append(EditableIngredient())
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18))
                    Text("Add Ingredient")
                        .font(.system(size: 16))
                }
                .foregroundColor(.brown)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Steps Editor
    
    private var stepsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, _ in
                EditableStepRow(
                    step: $steps[index],
                    stepNumber: index + 1,
                    onDelete: {
                        steps.remove(at: index)
                    }
                )
            }
            
            // Add step button
            Button(action: {
                steps.append(EditableStep())
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18))
                    Text("Add Step")
                        .font(.system(size: 16))
                }
                .foregroundColor(.brown)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Audio Recording Sidebar (Landscape)
    
    private func audioRecordingSidebar(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            Text("Voice Recording")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                .padding(.top, 16)
            
            Spacer()
            
            audioRecorderWidget
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Audio Recording Section (Portrait)
    
    private var audioRecordingSection: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal, 20)
            
            Text("Voice Recording")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            audioRecorderWidget
        }
    }
    
    // MARK: - Audio Recorder Widget
    
    private var audioRecorderWidget: some View {
        VStack(spacing: 16) {
            // Recording visualization
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red.opacity(0.2) : Color.brown.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.brown)
                            .frame(width: 80, height: 80)
                        
                        if isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Recording status
            if isRecording {
                Text(audioManager.formatDuration(audioManager.recordingDuration))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
            } else if let fileName = recordedFileName {
                // Show recorded audio
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Button(action: {
                            audioManager.togglePlayback(fileName: fileName)
                        }) {
                            Image(systemName: audioManager.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.brown)
                        }
                        
                        Text(audioManager.formatDuration(recordedDuration))
                            .font(.system(size: 18, design: .monospaced))
                            .foregroundColor(.brown)
                        
                        Button(action: {
                            // Delete recording
                            recordedFileName = nil
                            recordedDuration = 0
                        }) {
                            Image(systemName: "trash.circle")
                                .font(.system(size: 30))
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                    
                    Text("Recording saved")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } else {
                Text("Tap to record")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private func toggleRecording() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if isRecording {
            let duration = audioManager.stopRecording()
            isRecording = false
            recordedDuration = duration
        } else {
            // Delete previous recording if any
            recordedFileName = audioManager.startRecording()
            isRecording = true
        }
    }
    
    // MARK: - Save Button
    
    private func saveButton(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            Button(action: saveRecipe) {
                Text("Save Recipe")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(title.isEmpty ? Color.gray : Color.brown)
                    )
            }
            .disabled(title.isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
        }
    }
    
    // MARK: - Save Recipe
    
    private func saveRecipe() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Create the recipe
        let recipe = dataManager.createRecipe(
            title: title,
            symbol: "fork.knife",
            color: "#8B4513",
            description: description
        )
        
        // Add ingredients
        for ingredient in ingredients where !ingredient.name.isEmpty {
            dataManager.addIngredient(to: recipe, name: ingredient.name, quantity: ingredient.quantity)
        }
        
        // Add steps
        for step in steps where !step.instruction.isEmpty {
            dataManager.addStep(to: recipe, instruction: step.instruction)
        }
        
        // Add ancestry
        for ancestry in ancestrySteps where !ancestry.country.isEmpty {
            dataManager.addAncestryStep(
                to: recipe,
                country: ancestry.country,
                region: ancestry.region.isEmpty ? nil : ancestry.region,
                roughDate: ancestry.date.isEmpty ? nil : ancestry.date,
                note: ancestry.note.isEmpty ? nil : ancestry.note,
                generation: nil
            )
        }
        
        // Add audio recording
        if let fileName = recordedFileName {
            dataManager.addAudioNote(to: recipe, fileName: fileName, duration: recordedDuration)
        }
        
        dismiss()
    }
}

// MARK: - Editable Data Models

struct EditableIngredient: Identifiable {
    let id = UUID()
    var name: String = ""
    var quantity: String = ""
}

struct EditableStep: Identifiable {
    let id = UUID()
    var instruction: String = ""
}

struct EditableAncestry: Identifiable {
    let id = UUID()
    var country: String = ""
    var region: String = ""
    var date: String = ""
    var note: String = ""
}

// MARK: - Editable Ingredient Row

struct EditableIngredientRow: View {
    @Binding var ingredient: EditableIngredient
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Circle()
                .fill(Color.brown.opacity(0.5))
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Ingredient name", text: $ingredient.name)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                
                TextField("Quantity (e.g., 2 cups)", text: $ingredient.quantity)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Editable Step Row

struct EditableStepRow: View {
    @Binding var step: EditableStep
    let stepNumber: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(stepNumber)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.brown))
            
            TextField("Instruction...", text: $step.instruction, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                .lineLimit(1...5)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Editable Ancestry Card

struct EditableAncestryCard: View {
    @Binding var ancestry: EditableAncestry
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Delete button in top right corner
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red.opacity(0.6))
                }
            }
            
            // Country and Region on same line (Country LEFT, Region RIGHT)
            HStack(spacing: 10) {
                // Country field (required) - LEFT
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 3) {
                        Text("Country")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray.opacity(0.8))
                        Text("*")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    
                    TextField("Italy", text: $ancestry.country)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(ancestry.country.isEmpty ? Color.red.opacity(0.3) : Color.brown.opacity(0.2), lineWidth: 1.5)
                                )
                        )
                }
                .frame(maxWidth: .infinity)
                
                // Region field (optional) - RIGHT
                VStack(alignment: .leading, spacing: 4) {
                    Text("Region (opt)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                    
                    TextField("Tuscany", text: $ancestry.region)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.brown.opacity(0.8))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.brown.opacity(0.15), lineWidth: 1)
                                )
                        )
                }
                .frame(maxWidth: .infinity)
            }
            
            // Date field (optional)
            VStack(alignment: .leading, spacing: 4) {
                Text("Date (opt)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                
                TextField("1920s", text: $ancestry.date)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.brown.opacity(0.15), lineWidth: 1)
                            )
                    )
            }
            
            // Note field (optional) - SINGLE LINE
            VStack(alignment: .leading, spacing: 4) {
                Text("Note (opt)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                
                TextField("Add context...", text: $ancestry.note)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.brown.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .submitLabel(.done)
            }
            
            // Drag handle at bottom
            HStack {
                Spacer()
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.4))
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(minWidth: 280, maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.brown.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Ancestry Drop Delegate

struct AncestryDropDelegate: DropDelegate {
    let item: EditableAncestry
    @Binding var items: [EditableAncestry]
    @Binding var draggedItem: EditableAncestry?
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let fromIndex = items.firstIndex(where: { $0.id == draggedItem?.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }),
              fromIndex != toIndex else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct CreateRecipeView_Previews: PreviewProvider {
    static var previews: some View {
        CreateRecipeView()
    }
}
