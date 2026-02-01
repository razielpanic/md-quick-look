import SwiftUI

@main
struct MDSpotlighterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("MD Spotlighter")
                .font(.title)
            Text("Quick Look extension for markdown files")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}
