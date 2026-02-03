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
            AboutView()
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
            FirstLaunchView()
        }
        .windowResizability(.contentSize)
    }
}

// App delegate for window management
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check if this is first launch
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

        if !hasLaunchedBefore {
            // First launch - open welcome window
            openWindow(id: "firstLaunch")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        } else {
            // Subsequent launch - open settings window
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    private func openWindow(id: String) {
        // Find and open window by ID
        for window in NSApp.windows {
            if window.identifier?.rawValue == id {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }

        // If window doesn't exist yet, wait a bit and try again
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.openWindow(id: id)
        }
    }

    @objc func showAboutWindow() {
        openWindow(id: "about")
    }
}


