import SwiftUI

struct FirstLaunchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            Text("Welcome to MD Quick Look")
                .font(.title2)
                .fontWeight(.semibold)

            // Extension status explanation
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Look Extension Status")
                    .font(.headline)

                Text("To preview Markdown files in Finder, the Quick Look extension must be enabled in System Settings.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Link to System Settings
                Button("Open Extensions Settings...") {
                    // Open System Settings to Extensions
                    if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)

                Text("Enable \"MD Quick Look\" under Quick Look.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            // Dismiss button
            Button("Get Started") {
                onDismiss?()
                // Don't call dismiss() - let the content router switch views
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 400, height: 360)
    }
}
