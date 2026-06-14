import AppKit
import SwiftUI

public struct SaveLocationPickerView: View {
    @Binding public var bookmark: Data?
    @Binding public var path: String?
    @State private var displayPath: String = ""

    public init(bookmark: Binding<Data?>, path: Binding<String?>) {
        _bookmark = bookmark
        _path = path
        _displayPath = State(initialValue: path.wrappedValue ?? Self.pathFromBookmark(bookmark.wrappedValue))
    }

    public var body: some View {
        HStack {
            Text(displayPath.isEmpty ? "未选择" : displayPath)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(displayPath.isEmpty ? .secondary : .primary)

            Spacer()

            Button("选择...") {
                selectDirectory()
            }
        }
        .onChange(of: bookmark) { _, newValue in
            displayPath = path ?? Self.pathFromBookmark(newValue)
        }
        .onChange(of: path) { _, newValue in
            displayPath = newValue ?? Self.pathFromBookmark(bookmark)
        }
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "选择保存目录"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let data = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        bookmark = data
        path = url.path
        displayPath = url.path
    }

    private static func pathFromBookmark(_ bookmark: Data?) -> String {
        guard let bookmark else { return "" }
        var isStale = false
        let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return url?.path ?? ""
    }
}
