import SwiftUI

// DEPRECATED: This is a test view that is no longer used
// The main app entry point is MosaicView

struct ContentView: View {
    var body: some View {
        ZStack {
            // Background color
            Color(red: 0.96, green: 0.95, blue: 0.92)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Title
                Text("Recipe Voyage")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.brown)
                    .padding(.top, 60)
                
                Text("This is a test view")
                    .font(.system(size: 18))
                    .foregroundColor(.brown.opacity(0.6))
                
                Text("The main app starts at MosaicView")
                    .font(.system(size: 14))
                    .foregroundColor(.brown.opacity(0.5))
                
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

/*
 
 CONTENTVIEW HISTORY
 ===================
 
 This file was originally used for testing the audio recording system.
 It has been replaced by MosaicView as the main entry point.
 
 The app now launches with:
 Recipe_VoyageApp.swift → MosaicView
 
 This file is kept for historical reference but is not used in the app.
 
 */
