import SwiftUI

@main
struct MDQuickLookApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false

    var body: some Scene {
        // Main window that auto-opens and routes to first-launch or settings
        WindowGroup {
            if !hasLaunchedBefore {
                FirstLaunchView()
                    .onAppear {
                        hasLaunchedBefore = true
                    }
                    .frame(width: 400, height: 360)
            } else {
                SettingsView()
                    .frame(width: 450, height: 320)
            }
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
