import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

// MARK: - Configuration Models

struct DecorativeFontOption: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    
    static let options: [DecorativeFontOption] = [
        DecorativeFontOption(name: "Didot", displayName: "Didot"),
        DecorativeFontOption(name: "Baskerville", displayName: "Baskerville"),
        DecorativeFontOption(name: "Bodoni 72", displayName: "Bodoni"),
        DecorativeFontOption(name: "Copperplate", displayName: "Copperplate"),
        DecorativeFontOption(name: "Snell Roundhand", displayName: "Snell Roundhand"),
        DecorativeFontOption(name: "Cochin", displayName: "Cochin"),
        DecorativeFontOption(name: "Palatino", displayName: "Palatino")
    ]
}

struct AccentColorOption: Identifiable {
    let id = UUID()
    let name: String
    let hexColor: String
    let color: Color
    
    static let options: [AccentColorOption] = [
        AccentColorOption(name: "Classic Brown", hexColor: "#8B4513", color: Color(red: 0.545, green: 0.271, blue: 0.075)),
        AccentColorOption(name: "Burgundy", hexColor: "#800020", color: Color(red: 0.502, green: 0.0, blue: 0.125)),
        AccentColorOption(name: "Navy Blue", hexColor: "#000080", color: Color(red: 0.0, green: 0.0, blue: 0.502)),
        AccentColorOption(name: "Royal Purple", hexColor: "#6B3FA0", color: Color(red: 0.420, green: 0.247, blue: 0.627)),
        AccentColorOption(name: "Burnt Orange", hexColor: "#CC5500", color: Color(red: 0.8, green: 0.333, blue: 0.0)),
        AccentColorOption(name: "Olive Green", hexColor: "#556B2F", color: Color(red: 0.333, green: 0.420, blue: 0.184)),
        AccentColorOption(name: "Charcoal", hexColor: "#36454F", color: Color(red: 0.212, green: 0.271, blue: 0.310))
    ]
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

// MARK: - Create Recipe View

struct CreateRecipeView: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // MARK: - Managers
    @ObservedObject var dataManager = CoreDataManager.shared
    @StateObject private var audioManager = AudioManager()
    
    // MARK: - Recipe State
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var owner: String = ""
    @State private var ingredients: [EditableIngredient] = []
    @State private var steps: [EditableStep] = []
    @State private var ancestrySteps: [EditableAncestry] = []
    
    // MARK: - Customization State
    @State private var selectedDecorativeFont: String = DecorativeFontOption.options[0].name
    @State private var selectedAccentColor: String = AccentColorOption.options[0].hexColor
    
    // MARK: - Audio State
    @State private var recordedFileName: String?
    @State private var recordedDuration: TimeInterval = 0
    @State private var isRecording = false
    @State private var showingAudioPicker = false
    
    // MARK: - UI State
    @State private var keyboardHeight: CGFloat = 0
    @State private var showingDiscardAlert = false
    @State private var draggedAncestry: EditableAncestry?
    
    // MARK: - Computed Properties
    private var isLandscape: Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }
    
    private var isLandscapeiPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    private var hasContent: Bool {
        !title.isEmpty || !description.isEmpty || !owner.isEmpty ||
        !ingredients.isEmpty || !steps.isEmpty || recordedFileName != nil
    }
    
    private var currentAccentColor: Color {
        Color(hex: selectedAccentColor) ?? Color.brown
    }
    
    private var isSaveButtonVisible: Bool {
        keyboardHeight == 0
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                
                VStack(spacing: 0) {
                    if isLandscape {
                        landscapeLayout(geometry: geometry)
                    } else {
                        portraitLayout
                    }
                    
                    if isSaveButtonVisible {
                        saveButton(geometry: geometry)
                    }
                }
                .ignoresSafeArea()
            }
        }
        .alert("Discard Recipe?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard this recipe?")
        }
        .fileImporter(
            isPresented: $showingAudioPicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            handleAudioFilePicked(result: result)
        }
        .onAppear(perform: setupKeyboardObservers)
    }
    
    // MARK: - Layout Views
    
    private var backgroundView: some View {
        Color(red: 0.98, green: 0.97, blue: 0.94)
            .ignoresSafeArea()
    }
    
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    sectionBlock(title: "HISTORY") {
                        editableAncestryTimelineCompact
                    }
                    
                    sectionBlock(title: "RECIPE") {
                        recipeEditorContent
                    }
                }
                .padding(20)
                .padding(.bottom, max(120, keyboardHeight + 20))
            }
            .frame(width: geometry.size.width * (isLandscapeiPad ? 0.7 : 0.65))
            
            Divider()
            
            audioRecordingSidebar
        }
    }
    
    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                sectionBlock(title: "RECIPE") {
                    recipeEditorContent
                }
                
                sectionBlock(title: "HISTORY") {
                    editableAncestryTimelineCompact
                }
                
                sectionBlock(title: "RECORDING") {
                    audioRecorderWidget
                }
                
                sectionBlock(title: "CUSTOMIZATION") {
                    combinedCustomizationPicker
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, max(100, keyboardHeight + 20))
        }
    }
    
    // MARK: - Section Block
    
    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.brown.opacity(0.6))
                .tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            content()
        }
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
    }
    
    // MARK: - Recipe Editor Content
    
    private var recipeEditorContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            TextField("Recipe Title", text: $title)
                .font(.system(size: isLandscapeiPad ? 32 : 26, weight: .bold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            TextField("Owner (optional)", text: $owner)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.5))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.brown.opacity(0.2), lineWidth: 1))
                )
            
            descriptionEditor
            ingredientsEditor
            stepsEditor
        }
        .padding(.horizontal, 20)
    }
    
    private var descriptionEditor: some View {
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
    }
    
    private var ingredientsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, _ in
                EditableIngredientRow(
                    ingredient: $ingredients[index],
                    onDelete: { ingredients.remove(at: index) }
                )
            }
            
            Button(action: { ingredients.append(EditableIngredient()) }) {
                Label("Add Ingredient", systemImage: "plus.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.brown)
                    .padding(.vertical, 8)
            }
        }
    }
    
    private var stepsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, _ in
                EditableStepRow(
                    step: $steps[index],
                    stepNumber: index + 1,
                    onDelete: { steps.remove(at: index) }
                )
            }
            
            Button(action: { steps.append(EditableStep()) }) {
                Label("Add Step", systemImage: "plus.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.brown)
                    .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Ancestry Timeline
    
    private var editableAncestryTimelineCompact: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(ancestrySteps.enumerated()), id: \.element.id) { index, step in
                    ancestryCardRow(for: step, at: index)
                }
                addAncestryButton
            }
            .padding(.horizontal, 20)
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
    
    private var addAncestryButton: some View {
        Button(action: {
            withAnimation {
                ancestrySteps.append(EditableAncestry())
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                Text("Add History")
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
    
    // MARK: - Audio Recording Sidebar
    
    private var audioRecordingSidebar: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text("RECORDING")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.brown.opacity(0.6))
                        .tracking(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    audioRecorderWidget
                }
                .padding(20)
                .background(Color.white.opacity(0.5))
                .cornerRadius(16)
                
                VStack(spacing: 16) {
                    Text("CUSTOMIZATION")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.brown.opacity(0.6))
                        .tracking(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    combinedCustomizationPicker
                }
                .padding(20)
                .background(Color.white.opacity(0.5))
                .cornerRadius(16)
            }
            .padding(20)
        }
    }
    
    // MARK: - Audio Recorder Widget
    
    private var audioRecorderWidget: some View {
        VStack(spacing: 16) {
            // Choice buttons - Record or Pick File
            if recordedFileName == nil && !isRecording {
                audioChoiceButtons
            }
            
            // Recording visualization (when recording or when file is selected)
            if isRecording || recordedFileName != nil {
                recordingVisualization
                recordingStatus
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
    
    private var audioChoiceButtons: some View {
        VStack(spacing: 12) {
            Text("Add Audio")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
            
            HStack(spacing: 16) {
                // Record button
                Button(action: toggleRecording) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.brown.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.brown)
                        }
                        
                        Text("Record")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.brown)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brown.opacity(0.3), lineWidth: 2)
                            )
                    )
                }
                
                // Pick file button
                Button(action: { showingAudioPicker = true }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.brown.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "folder.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.brown)
                        }
                        
                        Text("Choose File")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.brown)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.brown.opacity(0.3), lineWidth: 2)
                            )
                    )
                }
            }
        }
    }
    
    private var recordingVisualization: some View {
        ZStack {
            Circle()
                .fill(isRecording ? Color.red.opacity(0.2) : Color.brown.opacity(0.1))
                .frame(width: 120, height: 120)
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
            
            if isRecording {
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 80, height: 80)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            } else if recordedFileName != nil {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.brown)
            }
        }
    }
    
    @ViewBuilder
    private var recordingStatus: some View {
        if isRecording {
            Text(audioManager.formatDuration(audioManager.recordingDuration))
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
        } else if let fileName = recordedFileName {
            recordedAudioControls(fileName: fileName)
        }
    }
    
    private func recordedAudioControls(fileName: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { audioManager.togglePlayback(fileName: fileName) }) {
                    Image(systemName: audioManager.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.brown)
                }
                
                Text(audioManager.formatDuration(recordedDuration))
                    .font(.system(size: 18, design: .monospaced))
                    .foregroundColor(.brown)
                
                Button(action: deleteRecording) {
                    Image(systemName: "trash.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            
            Text("Audio saved")
                .font(.caption)
                .foregroundColor(.green)
            
            // Add option to replace with new audio
            Button(action: { 
                deleteRecording()
            }) {
                Text("Replace Audio")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.brown)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.brown.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Customization Picker
    
    private var combinedCustomizationPicker: some View {
        VStack(spacing: 20) {
            if let firstLetter = title.first {
                previewLetterBlock(firstLetter)
            }
            
            fontStylePicker
            accentColorPicker
        }
    }
    
    private func previewLetterBlock(_ letter: Character) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            
            Text(String(letter).uppercased())
                .font(.custom(selectedDecorativeFont, size: 72))
                .foregroundColor(currentAccentColor)
        }
        .frame(width: 120, height: 120)
    }
    
    private var fontStylePicker: some View {
        customizationSection(title: "Font Style") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(DecorativeFontOption.options) { option in
                        fontOptionCard(option)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func fontOptionCard(_ option: DecorativeFontOption) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedDecorativeFont == option.name ? currentAccentColor.opacity(0.1) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                selectedDecorativeFont == option.name ? currentAccentColor : Color.gray.opacity(0.3),
                                lineWidth: selectedDecorativeFont == option.name ? 3 : 1
                            )
                    )
                
                Text(String(title.first ?? "A").uppercased())
                    .font(.custom(option.name, size: 48))
                    .foregroundColor(currentAccentColor)
            }
            .frame(width: 80, height: 80)
            
            Text(option.displayName)
                .font(.system(size: 12, weight: selectedDecorativeFont == option.name ? .semibold : .regular))
                .foregroundColor(selectedDecorativeFont == option.name ? currentAccentColor : .gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                selectedDecorativeFont = option.name
            }
        }
    }
    
    private var accentColorPicker: some View {
        customizationSection(title: "Accent Color") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AccentColorOption.options) { option in
                        colorOptionCard(option)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func colorOptionCard(_ option: AccentColorOption) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(option.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                selectedAccentColor == option.hexColor ? Color.black : Color.clear,
                                lineWidth: 3
                            )
                    )
                
                if selectedAccentColor == option.hexColor {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            .frame(width: 60, height: 60)
            
            Text(option.name)
                .font(.system(size: 11, weight: selectedAccentColor == option.hexColor ? .semibold : .regular))
                .foregroundColor(selectedAccentColor == option.hexColor ? Color(red: 0.3, green: 0.2, blue: 0.1) : .gray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
                .minimumScaleFactor(0.8)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                selectedAccentColor = option.hexColor
            }
        }
    }
    
    private func customizationSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            content()
        }
    }
    
    // MARK: - Save Button
    
    private func saveButton(geometry: GeometryProxy) -> some View {
        Button(action: saveRecipe) {
            Text("Save Recipe")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(title.isEmpty ? Color.gray : Color.brown)
                )
        }
        .disabled(title.isEmpty)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 16) + 16)
        .background(
            Color(red: 0.98, green: 0.97, blue: 0.94)
                .ignoresSafeArea(edges: .bottom)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.25), value: keyboardHeight)
    }
    
    // MARK: - Actions
    
    private func toggleRecording() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if isRecording {
            recordedDuration = audioManager.stopRecording()
            isRecording = false
        } else {
            recordedFileName = audioManager.startRecording()
            isRecording = true
        }
    }
    
    private func deleteRecording() {
        recordedFileName = nil
        recordedDuration = 0
    }
    
    private func handleAudioFilePicked(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let sourceURL = urls.first else { return }
            
            // Copy the audio file to the app's documents directory
            let fileName = "imported_\(UUID().uuidString).\(sourceURL.pathExtension)"
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(fileName)
            
            do {
                // Start accessing security-scoped resource
                guard sourceURL.startAccessingSecurityScopedResource() else {
                    print("❌ Failed to access security-scoped resource")
                    return
                }
                defer { sourceURL.stopAccessingSecurityScopedResource() }
                
                // Copy the file
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                
                // Get the duration of the audio file
                let asset = AVURLAsset(url: destinationURL)
                let duration = CMTimeGetSeconds(asset.duration)
                
                // Update state
                recordedFileName = fileName
                recordedDuration = duration
                
                print("✅ Audio file imported: \(fileName), duration: \(duration)")
                
            } catch {
                print("❌ Failed to import audio file: \(error)")
            }
            
        case .failure(let error):
            print("❌ File picker error: \(error)")
        }
    }
    
    private func saveRecipe() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let recipe = dataManager.createRecipe(
            title: title,
            symbol: "fork.knife",
            color: selectedAccentColor,
            description: description
        )
        
        recipe.decorativeCapFont = selectedDecorativeFont
        
        if !owner.isEmpty {
            recipe.ownerName = owner
        }
        
        ingredients.filter { !$0.name.isEmpty }.forEach {
            dataManager.addIngredient(to: recipe, name: $0.name, quantity: $0.quantity)
        }
        
        steps.filter { !$0.instruction.isEmpty }.forEach {
            dataManager.addStep(to: recipe, instruction: $0.instruction)
        }
        
        ancestrySteps.filter { !$0.country.isEmpty }.forEach {
            dataManager.addAncestryStep(
                to: recipe,
                country: $0.country,
                region: $0.region.isEmpty ? nil : $0.region,
                roughDate: $0.date.isEmpty ? nil : $0.date,
                note: $0.note.isEmpty ? nil : $0.note,
                generation: nil
            )
        }
        
        if let fileName = recordedFileName {
            dataManager.addAudioNote(to: recipe, fileName: fileName, duration: recordedDuration)
        }
        
        dataManager.saveContext()
        dismiss()
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
}

// MARK: - Editable Component Views

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

struct EditableAncestryCard: View {
    @Binding var ancestry: EditableAncestry
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red.opacity(0.6))
                }
            }
            
            HStack(spacing: 10) {
                inputField(
                    label: "Country",
                    placeholder: "Italy",
                    text: $ancestry.country,
                    isRequired: true,
                    fontSize: 16,
                    fontWeight: .bold
                )
                
                inputField(
                    label: "Region (opt)",
                    placeholder: "Tuscany",
                    text: $ancestry.region,
                    isRequired: false,
                    fontSize: 14,
                    fontWeight: .semibold
                )
            }
            
            inputField(
                label: "Date (opt)",
                placeholder: "1920s",
                text: $ancestry.date,
                isRequired: false,
                fontSize: 13,
                fontWeight: .regular
            )
            
            inputField(
                label: "Note (opt)",
                placeholder: "Add context...",
                text: $ancestry.note,
                isRequired: false,
                fontSize: 13,
                fontWeight: .regular
            )
            
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
    
    private func inputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isRequired: Bool,
        fontSize: CGFloat,
        fontWeight: Font.Weight
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                
                if isRequired {
                    Text("*")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            
            TextField(placeholder, text: text)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(isRequired ? Color(red: 0.3, green: 0.2, blue: 0.1) : Color.brown.opacity(0.8))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isRequired && text.wrappedValue.isEmpty ? Color.red.opacity(0.3) : Color.brown.opacity(0.15),
                                    lineWidth: isRequired ? 1.5 : 1
                                )
                        )
                )
                .submitLabel(.done)
        }
    }
}

// MARK: - Supporting Types

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
              fromIndex != toIndex else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            items.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

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
