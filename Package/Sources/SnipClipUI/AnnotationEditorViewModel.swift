import AppKit
import SnipClipCore

@MainActor
public final class AnnotationEditorViewModel: ObservableObject {
    @Published public var activeTool: AnnotationTool = .rectangle
    @Published public var activeStyle: AnnotationStyle
    @Published public var annotations: [AnnotationItem] = []
    @Published public var canUndo: Bool = false
    @Published public var canRedo: Bool = false
    @Published public var lastErrorMessage: String?

    public let originalImage: NSImage
    public let exportService = ImageExportService()
    public let pasteboardService: PasteboardService

    private var undoStack: [AnnotationCommand] = []
    private var redoStack: [AnnotationCommand] = []
    private var previousState: [AnnotationItem] = []

    public init(image: NSImage, style: AnnotationStyle = AnnotationStyle()) {
        originalImage = image
        activeStyle = style
        pasteboardService = PasteboardService(exportService: exportService)
    }

    public func setTool(_ tool: AnnotationTool) {
        activeTool = tool
    }

    public func addAnnotation(_ item: AnnotationItem) {
        let command = AnnotationCommand.add(item)
        undoStack.append(command)
        redoStack.removeAll()
        annotations.append(item)
        updateUndoState()
    }

    public func undo() {
        guard let command = undoStack.popLast() else { return }
        switch command {
        case .add(let item):
            annotations.removeAll { $0.id == item.id }
            redoStack.append(command)
        case .remove(let id):
            if let item = previousState.first(where: { $0.id == id }) {
                annotations.append(item)
                redoStack.append(.add(item))
            }
        case .update(let item):
            if let index = annotations.firstIndex(where: { $0.id == item.id }) {
                let old = annotations[index]
                annotations[index] = item
                redoStack.append(.update(old))
            }
        }
        updateUndoState()
    }

    public func redo() {
        guard let command = redoStack.popLast() else { return }
        switch command {
        case .add(let item):
            annotations.append(item)
            undoStack.append(command)
        case .remove(let id):
            if let index = annotations.firstIndex(where: { $0.id == id }) {
                let removed = annotations.remove(at: index)
                undoStack.append(.remove(removed.id))
            }
        case .update:
            break
        }
        updateUndoState()
    }

    public func snapshotForUndo() {
        previousState = annotations
    }

    public func copyToPasteboard(renderedImage: NSImage) {
        do {
            try pasteboardService.copyPNG(renderedImage)
        } catch {
            lastErrorMessage = "复制失败：\(error.localizedDescription)"
        }
    }

    public func saveToFile(
        renderedImage: NSImage,
        directoryBookmark: Data?,
        directoryPath: String? = nil,
        closeEditorAfterSave: Bool = false,
        closeAction: @escaping () -> Void = {}
    ) {
        if let directoryURL = resolveSaveDirectory(bookmark: directoryBookmark, path: directoryPath) {
            let didAccess = directoryURL.startAccessingSecurityScopedResource()
            defer { if didAccess { directoryURL.stopAccessingSecurityScopedResource() } }

            let fileName = exportService.defaultFileName()
            let fileURL = directoryURL.appendingPathComponent(fileName)
            do {
                try exportService.savePNG(renderedImage, to: fileURL)
                if closeEditorAfterSave {
                    closeAction()
                }
                return
            } catch {
                lastErrorMessage = "保存失败：\(error.localizedDescription)"
                promptSavePanel(
                    renderedImage: renderedImage,
                    initialDirectory: directoryURL,
                    closeEditorAfterSave: closeEditorAfterSave,
                    closeAction: closeAction
                )
                return
            }
        }

        promptSavePanel(
            renderedImage: renderedImage,
            initialDirectory: defaultDownloadsDirectory(),
            closeEditorAfterSave: closeEditorAfterSave,
            closeAction: closeAction
        )
    }

    private func promptSavePanel(
        renderedImage: NSImage,
        initialDirectory: URL?,
        closeEditorAfterSave: Bool,
        closeAction: @escaping () -> Void
    ) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.directoryURL = initialDirectory
        panel.nameFieldStringValue = exportService.defaultFileName()
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try self?.exportService.savePNG(renderedImage, to: url)
                if closeEditorAfterSave {
                    closeAction()
                }
            } catch {
                self?.lastErrorMessage = "保存失败：\(error.localizedDescription)"
            }
        }
    }

    private func resolveSaveDirectory(bookmark: Data?, path: String?) -> URL? {
        if let bookmark, let url = resolveBookmark(bookmark) {
            return url
        }

        if let path, !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }

        return nil
    }

    private func resolveBookmark(_ bookmark: Data) -> URL? {
        var isStale = false
        let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return url
    }

    private func defaultDownloadsDirectory() -> URL? {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    }

    private func updateUndoState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}
