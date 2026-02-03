import SwiftUI

@main
struct MDQuickLookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
        .commands {
            // Replace default About menu item with custom one
            CommandGroup(replacing: .appInfo) {
                Button("About MD Quick Look") {
                    NSApp.sendAction(#selector(AppDelegate.showAboutWindow), to: nil, from: nil)
                }
            }

            // Replace Help menu with GitHub README link
            CommandGroup(replacing: .help) {
                Button("MD Quick Look Help") {
                    if let url = URL(string: "https://github.com/razielpanic/md-quick-look") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }

        // First launch welcome window
        Window("Welcome", id: "firstLaunch") {
            FirstLaunchHandler()
        }
        .windowResizability(.contentSize)
    }
}

// App delegate for window management
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // First-launch logic handled by FirstLaunchHandler view
    }

    @objc func showAboutWindow() {
        // Find and activate the about window
        for window in NSApp.windows {
            if window.identifier?.rawValue == "about" {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
    }
}

// View that handles first-launch detection
struct FirstLaunchHandler: View {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        EmptyView()
            .onAppear {
                if hasLaunchedBefore {
                    // Already launched before, close this window
                    dismiss()
                } else {
                    // First launch, mark as launched
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
