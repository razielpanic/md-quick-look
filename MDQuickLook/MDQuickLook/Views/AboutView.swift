import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            // App icon from asset catalog
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)

            // App name
            Text("MD Quick Look")
                .font(.title)
                .fontWeight(.semibold)

            // Version
            Text("Version \(Bundle.main.releaseVersionNumber ?? "Unknown")")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .frame(width: 200)

            // GitHub link (displayed as URL per CONTEXT.md)
            Link("github.com/razielpanic/md-quick-look",
                 destination: URL(string: "https://github.com/razielpanic/md-quick-look")!)
                .font(.body)

            Spacer()
                .frame(height: 8)

            // Copyright and brief description
            Text("Quick Look extension for Markdown files")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("© 2026 Rocketpop")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 320, height: 340)
    }
}
