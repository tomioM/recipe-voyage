
import SwiftUI

struct ContentView: View {
    // Create an audio manager - @StateObject means it stays alive
    @StateObject private var audioManager = AudioManager()
    
    // Track recordings we've made
    @State private var recordings: [(String, TimeInterval)] = []
    
    var body: some View {
        ZStack {
            // Background color
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Title
                Text("Audio Recorder Test")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.brown)
                    .padding(.top, 60)
                
                // The tape recorder button
                TapeRecorderButton(audioManager: audioManager) { fileName, duration in
                    // This runs when recording stops
                    recordings.append((fileName, duration))
                    print("✅ Recording saved: \(fileName)")
                    print("📝 Duration: \(duration) seconds")
                    print("📊 Total recordings: \(recordings.count)")
                }
                
                // Show list of recordings
                if !recordings.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Recordings:")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.brown)
                        
                        ForEach(Array(recordings.enumerated()), id: \.offset) { index, recording in
                            HStack(spacing: 16) {
                                // Play button
                                Button {
                                    print("🎵 Playing recording \(index + 1)")
                                    audioManager.togglePlayback(fileName: recording.0)
                                } label: {
                                    Image(systemName: audioManager.isPlaying && audioManager.currentPlayingFileName == recording.0 ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.brown)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Recording \(index + 1)")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(audioManager.formatDuration(recording.1))
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
    }
}

// Preview for Xcode canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
