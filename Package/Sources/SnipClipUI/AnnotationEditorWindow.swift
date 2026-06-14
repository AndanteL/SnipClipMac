import AppKit
import Combine
import SnipClipCore

@MainActor
final class AnnotationEditorWindow: NSWindow, AnnotationToolbarPanelDelegate, AnnotationCanvasViewDelegate {
    let canvasView: AnnotationCanvasView
    let viewModel: AnnotationEditorViewModel
    private let toolbarPanel: AnnotationToolbarPanel
    private let saveDirectoryBookmark: Data?
    private let saveDirectoryPath: String?
    private let closeEditorAfterSave: Bool
    private let errorLabel: NSTextField
    private var cancellables: Set<AnyCancellable> = []
    private var currentErrorMessage: String?
    var onPin: ((PinnedImageWindowController) -> Void)?
    var onClose: (() -> Void)?

    init(image: NSImage,
         style: AnnotationStyle = AnnotationStyle(),
         saveDirectoryBookmark: Data? = nil,
         saveDirectoryPath: String? = nil,
         closeEditorAfterSave: Bool = false) {
        self.saveDirectoryBookmark = saveDirectoryBookmark
        self.saveDirectoryPath = saveDirectoryPath
        self.closeEditorAfterSave = closeEditorAfterSave

        viewModel = AnnotationEditorViewModel(image: image, style: style)
        canvasView = AnnotationCanvasView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        canvasView.screenshot = image
        canvasView.activeStyle = style
        canvasView.activeTool = viewModel.activeTool

        toolbarPanel = AnnotationToolbarPanel()

        errorLabel = NSTextField(labelWithString: "")
        errorLabel.isHidden = true
        errorLabel.font = NSFont.systemFont(ofSize: 11)
        errorLabel.textColor = .systemRed
        errorLabel.alignment = .center
        errorLabel.lineBreakMode = .byTruncatingTail
        errorLabel.maximumNumberOfLines = 1

        let padding: CGFloat = 30
        let contentRect = CGRect(x: 0, y: 0, width: image.size.width + padding * 2, height: image.size.height + padding * 2)
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        title = "SnipClip — 标注"
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        animationBehavior = .none

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: self
        )

        toolbarPanel.toolbarDelegate = self
        toolbarPanel.activeTool = viewModel.activeTool
        toolbarPanel.activeColorHex = style.colorHex
        toolbarPanel.activeLineWidth = style.lineWidth
        toolbarPanel.activeFontSize = style.fontSize
        canvasView.activeFontSize = style.fontSize

        errorLabel.frame = CGRect(x: 12, y: contentRect.height - 18, width: contentRect.width - 24, height: 16)

        let container = NSView(frame: contentRect)
        container.addSubview(errorLabel)

        let scrollView = NSScrollView(frame: CGRect(x: padding, y: padding, width: image.size.width, height: image.size.height))
        scrollView.documentView = canvasView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .bezelBorder
        container.addSubview(scrollView)

        contentView = container
        makeKeyAndOrderFront(nil)
        center()

        canvasView.delegate = self
        toolbarPanel.attach(to: self)

        observeErrors()
    }

    private func observeErrors() {
        viewModel.$lastErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self, let message, !message.isEmpty else {
                    self?.currentErrorMessage = nil
                    self?.errorLabel.isHidden = true
                    return
                }
                self.currentErrorMessage = message
                self.errorLabel.stringValue = message
                self.errorLabel.isHidden = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                    guard let self, self.currentErrorMessage == message else { return }
                    self.errorLabel.isHidden = true
                    self.currentErrorMessage = nil
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - AnnotationToolbarPanelDelegate

    func toolbarPanel(_ panel: AnnotationToolbarPanel, didSelectTool tool: AnnotationTool) {
        viewModel.setTool(tool)
        canvasView.activeTool = tool
    }

    func toolbarPanel(_ panel: AnnotationToolbarPanel, didChangeColor hex: String) {
        canvasView.activeStyle = AnnotationStyle(
            lineWidth: canvasView.activeStyle.lineWidth,
            colorHex: hex,
            fontSize: canvasView.activeFontSize
        )
    }

    func toolbarPanel(_ panel: AnnotationToolbarPanel, didChangeLineWidth width: CGFloat) {
        canvasView.activeStyle = AnnotationStyle(
            lineWidth: width,
            colorHex: canvasView.activeStyle.colorHex,
            fontSize: canvasView.activeFontSize
        )
    }

    func toolbarPanel(_ panel: AnnotationToolbarPanel, didChangeFontSize size: CGFloat) {
        canvasView.activeFontSize = size
        canvasView.activeStyle = AnnotationStyle(
            lineWidth: canvasView.activeStyle.lineWidth,
            colorHex: canvasView.activeStyle.colorHex,
            fontSize: size
        )
    }

    func toolbarPanelDidRequestUndo(_ panel: AnnotationToolbarPanel) {
        canvasView.undo()
        syncUndoState()
    }

    func toolbarPanelDidRequestRedo(_ panel: AnnotationToolbarPanel) {
        canvasView.redo()
        syncUndoState()
    }

    func toolbarPanelDidRequestCopy(_ panel: AnnotationToolbarPanel) {
        guard let rendered = renderAnnotatedImage() else { return }
        viewModel.copyToPasteboard(renderedImage: rendered)
    }

    func toolbarPanelDidRequestSave(_ panel: AnnotationToolbarPanel) {
        guard let rendered = renderAnnotatedImage() else { return }
        viewModel.saveToFile(
            renderedImage: rendered,
            directoryBookmark: saveDirectoryBookmark,
            directoryPath: saveDirectoryPath,
            closeEditorAfterSave: closeEditorAfterSave,
            closeAction: { [weak self] in self?.close() }
        )
    }

    func toolbarPanelDidRequestPin(_ panel: AnnotationToolbarPanel) {
        guard let rendered = renderAnnotatedImage() else { return }
        let controller = PinnedImageWindowController(image: rendered)
        controller.showWindow(nil)
        onPin?(controller)
    }

    // MARK: - AnnotationCanvasViewDelegate

    func annotationCanvas(_ canvas: AnnotationCanvasView, didAdd item: AnnotationItem) {
        syncUndoState()
    }

    func annotationCanvas(_ canvas: AnnotationCanvasView, didRemove item: AnnotationItem) {
        syncUndoState()
    }

    private func syncUndoState() {
        toolbarPanel.canUndo = canvasView.canUndo
        toolbarPanel.canRedo = canvasView.canRedo
    }

    @objc private func windowWillClose(_ notification: Notification) {
        toolbarPanel.detach()
        onClose?()
    }

    // MARK: - Rendering

    private func renderAnnotatedImage() -> NSImage? {
        let rect = canvasView.bounds
        guard rect.width > 0, rect.height > 0 else { return nil }

        let rep = canvasView.bitmapImageRepForCachingDisplay(in: rect)
        guard let rep else { return nil }
        canvasView.cacheDisplay(in: rect, to: rep)
        let image = NSImage(size: rect.size)
        image.addRepresentation(rep)
        return image
    }
}
