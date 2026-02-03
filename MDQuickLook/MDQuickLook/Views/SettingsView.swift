import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Quick Look Extension", systemImage: "eye.fill")
                        .font(.headline)

                    Text("The Quick Look extension lets you preview Markdown files by pressing Space in Finder.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Status:")
                            .foregroundColor(.secondary)
                        Text("Check in System Settings")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .font(.callout)

                    Button("Open Extension Settings...") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                            openURL(url)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Extension")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Version \(Bundle.main.releaseVersionNumber ?? "Unknown")")
                        .font(.callout)

                    Link("View on GitHub",
                         destination: URL(string: "https://github.com/razielpanic/md-quick-look")!)
                        .font(.callout)
                }
                .padding(.vertical, 4)
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 320)
    }
}
