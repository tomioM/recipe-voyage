//
//  AudioManager.swift
//  Recipe Voyage
//
//  Created by Tomio Walkley-Miyagawa on 2025-11-29.
//

import AVFoundation
import SwiftUI

// This class handles all audio recording and playback
class AudioManager: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    // MARK: - Published Properties
    // These cause views to update when they change
    
    @Published var isRecording = false // Are we currently recording?
    @Published var isPlaying = false // Are we currently playing audio?
    @Published var currentPlayingFileName: String? // Which file is playing?
    @Published var recordingDuration: TimeInterval = 0 // How long have we been recording?
    
    // MARK: - Private Properties
    // These are internal - views don't need to see them
    
    private var audioRecorder: AVAudioRecorder? // The recorder object
    private var audioPlayer: AVAudioPlayer? // The player object
    private var recordingTimer: Timer? // Updates duration every 0.1 seconds
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // Configure iOS audio system
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // Set category to playAndRecord (we do both)
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            print("🔊 Audio session configured")
        } catch {
            print("❌ Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Recording Functions
    
    // Start recording audio
    // Returns the filename if successful, nil if it fails
    func startRecording() -> String? {
        // Generate unique filename using UUID
        let fileName = "recording_\(UUID().uuidString).m4a"
        
        // Get path to Documents folder
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent(fileName)
        
        // Configure audio quality settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC), // AAC format (compressed)
            AVSampleRateKey: 44100.0, // CD quality
            AVNumberOfChannelsKey: 1, // Mono (not stereo)
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue // High quality
        ]
        
        do {
            // Create the recorder
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self // Tell it we want to know when things happen
            audioRecorder?.record() // Start recording!
            
            isRecording = true
            recordingDuration = 0
            
            // Start a timer to update duration
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingDuration = self?.audioRecorder?.currentTime ?? 0
            }
            
            print("🎤 Started recording: \(fileName)")
            return fileName
            
        } catch {
            print("❌ Failed to start recording: \(error)")
            return nil
        }
    }
    
    // Stop recording
    // Returns the duration of the recording
    func stopRecording() -> TimeInterval {
        audioRecorder?.stop() // Stop the recorder
        recordingTimer?.invalidate() // Stop the timer
        recordingTimer = nil
        isRecording = false
        
        let duration = recordingDuration
        recordingDuration = 0
        
        print("⏹️ Stopped recording. Duration: \(duration) seconds")
        return duration
    }
    
    // MARK: - Playback Functions
    
    // Play an audio file
    func playAudio(fileName: String) {
        stopPlayback() // Stop any current playback first
        
        // Get the full file path
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            // Create the player
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.play() // Start playing!
            
            isPlaying = true
            currentPlayingFileName = fileName
            
            print("▶️ Playing: \(fileName)")
            
        } catch {
            print("❌ Failed to play audio: \(error)")
        }
    }
    
    // Stop playback
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        currentPlayingFileName = nil
    }
    
    // Toggle playback (play if stopped, stop if playing)
    func togglePlayback(fileName: String) {
        if isPlaying && currentPlayingFileName == fileName {
            stopPlayback()
        } else {
            playAudio(fileName: fileName)
        }
    }
    
    // MARK: - Delegates
    // These functions are called automatically by iOS
    
    // Called when audio finishes playing
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentPlayingFileName = nil
        print("⏹️ Finished playing audio")
    }
    
    // MARK: - Helper Functions
    
    // Format duration as MM:SS
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Recording Button View
// The visual tape recorder button

struct TapeRecorderButton: View {
    @ObservedObject var audioManager: AudioManager
    let onRecordingComplete: (String, TimeInterval) -> Void // Callback when done
    
    @State private var currentFileName: String? // Track the current recording
    @State private var pulseAnimation = false // For the pulsing red dot
    
    var body: some View {
        VStack(spacing: 12) {
            // The button itself
            Button(action: toggleRecording) {
                ZStack {
                    // Base (looks like a tape recorder)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.25, green: 0.2, blue: 0.18))
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Record button (red circle)
                    Circle()
                        .fill(audioManager.isRecording ? Color.red : Color(red: 0.8, green: 0.2, blue: 0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .scaleEffect(audioManager.isRecording ? 1.1 : 1.0)
                        .opacity(audioManager.isRecording ? (pulseAnimation ? 0.6 : 1.0) : 1.0)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Show timer when recording, instruction when not
            if audioManager.isRecording {
                Text(audioManager.formatDuration(audioManager.recordingDuration))
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .monospacedDigit() // Makes numbers line up nicely
            } else {
                Text("Tap to Record")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(.brown)
            }
        }
        .onChange(of: audioManager.isRecording) { recording in
            if recording {
                // Start pulsing animation
                withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                    pulseAnimation = true
                }
            } else {
                pulseAnimation = false
            }
        }
    }
    
    // Handle button press
    private func toggleRecording() {
        // Haptic feedback (vibration)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if audioManager.isRecording {
            // Stop recording
            let duration = audioManager.stopRecording()
            if let fileName = currentFileName {
                // Call the completion handler
                onRecordingComplete(fileName, duration)
            }
            currentFileName = nil
        } else {
            // Start recording
            currentFileName = audioManager.startRecording()
        }
    }
}

// MARK: - Audio Note Cell
// Shows a single audio recording in a list

struct AudioNoteCell: View {
    let audioNote: AudioNoteEntity
    @ObservedObject var audioManager: AudioManager
    let onDelete: () -> Void // Called when trash button tapped
    
    // Is this audio note currently playing?
    var isPlaying: Bool {
        audioManager.isPlaying && audioManager.currentPlayingFileName == audioNote.audioFileName
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Play/stop button
            Button(action: {
                if let fileName = audioNote.audioFileName {
                    audioManager.togglePlayback(fileName: fileName)
                }
            }) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.brown)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                    Text("Recording")
                        .font(.custom("Georgia", size: 14))
                        .fontWeight(.medium)
                }
                
                // Duration
                Text(audioManager.formatDuration(audioNote.duration))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.brown.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
