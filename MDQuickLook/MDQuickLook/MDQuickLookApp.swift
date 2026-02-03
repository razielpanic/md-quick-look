import SwiftUI

@main
struct MDQuickLookApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) private var openURL

    var body: some Scene {
        // Settings scene - automatically creates Preferences menu item (Cmd+,)
        Settings {
            SettingsView()
        }

        // About window
        Window("About MD Quick Look", id: "about") {
            EmptyView()
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .windowMinimizeBehavior(.disabled)

        // First launch welcome window
        Window("Welcome", id: "firstLaunch") {
            EmptyView()
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)

        // Hidden window for first-launch detection
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
        .windowResizability(.contentSize)
        .commands {
            // Replace default About menu item with custom one
            CommandGroup(replacing: .appInfo) {
                Button("About MD Quick Look") {
                    openWindow(id: "about")
                }
            }

            // Replace Help menu with GitHub README link
            CommandGroup(replacing: .help) {
                Button("MD Quick Look Help") {
                    if let url = URL(string: "https://github.com/razielpanic/md-quick-look") {
                        openURL(url)
                    }
                }
            }
        }
        .task {
            // First-launch logic
            if !hasLaunchedBefore {
                openWindow(id: "firstLaunch")
                hasLaunchedBefore = true
            }
        }
    }
}

// Placeholder for Settings view (will be implemented in Plan 08-02)
struct SettingsView: View {
    var body: some View {
        EmptyView()
    }
}
