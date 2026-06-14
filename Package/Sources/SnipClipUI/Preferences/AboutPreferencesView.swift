import SwiftUI

struct AboutPreferencesView: View {
    var body: some View {
        VStack(spacing: 12) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 60, height: 60)
            }

            Text("SnipClipMac")
                .font(.title3.weight(.semibold))

            Text("0.1.0")
                .foregroundStyle(.secondary)

            Divider()
                .padding(.vertical, 8)

            Text("截图、标注、贴图和快速复制。")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }
}
