import AppKit

@MainActor
public final class PinnedImageWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    private let pinWindow: NSWindow
    private var imageView: NSImageView
    private var opacitySlider: NSSlider?
    private var isPinned: Bool = false

    public init(image: NSImage) {
        imageView = NSImageView(image: image)
        imageView.imageScaling = .scaleProportionallyUpOrDown

        let containerFrame = Self.containerFrame(for: image)
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: containerFrame.size),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        pinWindow = window

        super.init(window: window)

        window.delegate = self
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none

        let container = buildContainer(with: image)
        window.contentView = container
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    // MARK: - Container Setup

    private static func containerFrame(for image: NSImage) -> CGRect {
        let padding: CGFloat = 28
        return CGRect(
            x: 0, y: 0,
            width: image.size.width + padding * 2,
            height: image.size.height + padding * 2 + 30
        )
    }

    private func buildContainer(with image: NSImage) -> NSView {
        let padding: CGFloat = 28
        let containerFrame = Self.containerFrame(for: image)
        let container = NSView(frame: containerFrame)

        imageView.frame = CGRect(x: padding, y: padding + 30, width: image.size.width, height: image.size.height)

        let header = buildHeader(frame: CGRect(x: 0, y: 0, width: containerFrame.width, height: 30))

        container.addSubview(header)
        container.addSubview(imageView)

        return container
    }

    private func buildHeader(frame: CGRect) -> NSView {
        let header = NSView(frame: frame)
        header.wantsLayer = true
        header.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.45).cgColor

        let closeBtn = NSButton(
            frame: CGRect(x: frame.width - 26, y: 5, width: 20, height: 20)
        )
        closeBtn.title = "×"
        closeBtn.bezelStyle = .inline
        closeBtn.isBordered = false
        closeBtn.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        closeBtn.contentTintColor = .white
        closeBtn.target = self
        closeBtn.action = #selector(closeAction)
        header.addSubview(closeBtn)

        let pinBtn = NSButton(frame: CGRect(x: frame.width - 52, y: 5, width: 24, height: 20))
        pinBtn.title = "📌"
        pinBtn.bezelStyle = .inline
        pinBtn.isBordered = false
        pinBtn.font = NSFont.systemFont(ofSize: 12)
        pinBtn.target = self
        pinBtn.action = #selector(togglePin)
        header.addSubview(pinBtn)

        let slider = NSSlider(frame: CGRect(x: 10, y: 4, width: 120, height: 22))
        slider.minValue = 0.2
        slider.maxValue = 1.0
        slider.doubleValue = 1.0
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(opacityChanged(_:))
        header.addSubview(slider)
        opacitySlider = slider

        return header
    }

    // MARK: - Actions

    @objc private func closeAction() {
        pinWindow.close()
    }

    @objc private func opacityChanged(_ sender: NSSlider) {
        pinWindow.alphaValue = CGFloat(sender.doubleValue)
    }

    @objc private func togglePin() {
        isPinned.toggle()
        if isPinned {
            pinWindow.level = .screenSaver
        } else {
            pinWindow.level = .floating
        }
    }

    public func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
