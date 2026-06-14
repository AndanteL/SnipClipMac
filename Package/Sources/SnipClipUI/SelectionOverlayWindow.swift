import AppKit
import SnipClipCore

@MainActor
final class SelectionOverlayWindow: NSWindow {
    var onCommit: ((CGRect, CGDirectDisplayID) -> Void)?
    var onCancel: (() -> Void)?

    private let display: DisplayInfo

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    init(display: DisplayInfo) {
        self.display = display
        let contentView = SelectionOverlayView(frame: CGRect(origin: .zero, size: display.frame.size))
        super.init(
            contentRect: display.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.contentView = contentView
        contentView.onCommit = { [weak self] rect in
            guard let self else { return }
            let windowRect = contentView.convert(rect, to: nil)
            let screenRect = self.convertToScreen(windowRect)
            self.onCommit?(screenRect, self.display.id)
        }
        contentView.onCancel = { [weak self] in
            self?.onCancel?()
        }

        backgroundColor = .clear
        isOpaque = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        level = .modalPanel
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }
}
