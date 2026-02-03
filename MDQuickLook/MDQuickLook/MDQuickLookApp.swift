import SwiftUI

@main
struct MDQuickLookApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Main window that auto-opens
        WindowGroup {
            ContentRouter(appState: appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Replace default About menu item with custom one
            CommandGroup(replacing: .appInfo) {
                Button("About MD Quick Look") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationName: "MD Quick Look",
                        .applicationVersion: Bundle.main.releaseVersionNumber ?? "Unknown",
                        .applicationIcon: NSApp.applicationIconImage
                    ])
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
    }
}

// Separate router view to handle first-launch logic
struct ContentRouter: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Group {
            if appState.isFirstLaunch {
                FirstLaunchView(onDismiss: {
                    appState.markLaunchedBefore()
                })
                .frame(width: 400, height: 360)
            } else {
                SettingsView()
                    .frame(width: 450, height: 320)
            }
        }
    }
}

// App state manager
class AppState: ObservableObject {
    @Published var isFirstLaunch: Bool

    private let hasLaunchedKey = "hasLaunchedBefore"

    init() {
        // Check if app has launched before
        self.isFirstLaunch = !UserDefaults.standard.bool(forKey: hasLaunchedKey)
    }

    func markLaunchedBefore() {
        UserDefaults.standard.set(true, forKey: hasLaunchedKey)
        isFirstLaunch = false
    }
}
