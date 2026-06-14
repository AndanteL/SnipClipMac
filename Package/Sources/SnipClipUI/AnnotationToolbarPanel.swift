import AppKit
import Combine
import SnipClipCore

@MainActor
public protocol AnnotationToolbarPanelDelegate: AnyObject {
    func toolbarPanel(_ panel: AnnotationToolbarPanel, didSelectTool tool: AnnotationTool)
    func toolbarPanel(_ panel: AnnotationToolbarPanel, didChangeColor hex: String)
    func toolbarPanel(_ panel: AnnotationToolbarPanel, didChangeLineWidth width: CGFloat)
    func toolbarPanel(_ panel: AnnotationToolbarPanel, didChangeFontSize size: CGFloat)
    func toolbarPanelDidRequestUndo(_ panel: AnnotationToolbarPanel)
    func toolbarPanelDidRequestRedo(_ panel: AnnotationToolbarPanel)
    func toolbarPanelDidRequestCopy(_ panel: AnnotationToolbarPanel)
    func toolbarPanelDidRequestSave(_ panel: AnnotationToolbarPanel)
    func toolbarPanelDidRequestPin(_ panel: AnnotationToolbarPanel)
}

@MainActor
public final class AnnotationToolbarPanel: NSPanel {
    public weak var toolbarDelegate: AnnotationToolbarPanelDelegate?

    public var activeTool: AnnotationTool = .rectangle {
        didSet { toolControl.selectedSegment = toolIndex(for: activeTool) }
    }

    public var activeColorHex: String = "#FF3B30" {
        didSet { colorWell.color = NSColor.fromHex(activeColorHex) ?? .systemRed }
    }

    public var activeLineWidth: CGFloat = 2 {
        didSet {
            lineWidthSlider.doubleValue = Double(activeLineWidth)
            lineWidthLabel.stringValue = String(format: "%.0f", activeLineWidth)
        }
    }

    public var activeFontSize: CGFloat = 18 {
        didSet {
            fontSizeStepper.doubleValue = Double(activeFontSize)
            fontSizeField.stringValue = FontSizePolicy.displayText(activeFontSize)
        }
    }

    public var canUndo: Bool = false { didSet { undoBtn.isEnabled = canUndo } }
    public var canRedo: Bool = false { didSet { redoBtn.isEnabled = canRedo } }

    private let toolControl: NSSegmentedControl
    private let colorWell: NSColorWell
    private let lineWidthSlider: NSSlider
    private let lineWidthLabel: NSTextField
    private let fontSizeStepper: NSStepper
    private let fontSizeField: NSTextField
    private let undoBtn: NSButton
    private let redoBtn: NSButton
    private let copyBtn: NSButton
    private let saveBtn: NSButton
    private let pinBtn: NSButton
    private var targetWindow: NSWindow?
    private var frameObserver: NSKeyValueObservation?

    private static let tools: [(AnnotationTool, String)] = [
        (.rectangle, "rectangle"),
        (.ellipse, "oval"),
        (.pen, "pencil.tip"),
        (.text, "character.textbox"),
        (.mosaic, "square.grid.3x3"),
    ]

    public init() {
        toolControl = NSSegmentedControl()
        colorWell = NSColorWell()

        lineWidthSlider = NSSlider(value: 2, minValue: 1, maxValue: 8, target: nil, action: nil)
        lineWidthSlider.isContinuous = true
        lineWidthSlider.controlSize = .small

        lineWidthLabel = NSTextField(labelWithString: "2")
        lineWidthLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        lineWidthLabel.alignment = .center

        fontSizeStepper = NSStepper()
        fontSizeStepper.minValue = 10
        fontSizeStepper.maxValue = 72
        fontSizeStepper.doubleValue = 18
        fontSizeStepper.increment = 2
        fontSizeStepper.valueWraps = false

        fontSizeField = FontSizeTextField()
        fontSizeField.stringValue = "18"
        fontSizeField.isEditable = true
        fontSizeField.isSelectable = true
        fontSizeField.alignment = .center
        fontSizeField.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        fontSizeField.lineBreakMode = .byClipping
        fontSizeField.maximumNumberOfLines = 1
        fontSizeField.formatter = {
            let fmt = NumberFormatter()
            fmt.minimum = 10
            fmt.maximum = 72
            fmt.allowsFloats = false
            return fmt
        }()

        undoBtn = NSButton()
        redoBtn = NSButton()
        copyBtn = NSButton()
        saveBtn = NSButton()
        pinBtn = NSButton()

        super.init(
            contentRect: CGRect(x: 0, y: 0, width: 700, height: 38),
            styleMask: [.titled, .fullSizeContentView, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )

        title = ""
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        level = .floating
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        setupContent()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }

    // MARK: - Setup

    private func setupContent() {
        guard let contentView else { return }

        let effectView = NSVisualEffectView(frame: contentView.bounds)
        effectView.autoresizingMask = [.width, .height]
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        contentView.addSubview(effectView)

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12
        stack.distribution = .fill
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        effectView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: effectView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: effectView.bottomAnchor),
        ])

        // Tool selector
        toolControl.segmentStyle = .separated
        toolControl.trackingMode = .selectOne
        toolControl.segmentCount = Self.tools.count
        for (i, (_, symbol)) in Self.tools.enumerated() {
            toolControl.setLabel("", forSegment: i)
            toolControl.setImage(NSImage(systemSymbolName: symbol, accessibilityDescription: nil), forSegment: i)
            toolControl.setWidth(32, forSegment: i)
        }
        toolControl.selectedSegment = 0
        toolControl.target = self
        toolControl.action = #selector(toolChanged(_:))
        stack.addArrangedSubview(toolControl)

        // Separator
        stack.addArrangedSubview(makeSeparator())

        // Color well
        colorWell.color = NSColor.fromHex(activeColorHex) ?? .systemRed
        colorWell.target = self
        colorWell.action = #selector(colorChanged(_:))
        colorWell.isBordered = false
        colorWell.controlSize = .small
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            colorWell.widthAnchor.constraint(equalToConstant: 28),
            colorWell.heightAnchor.constraint(equalToConstant: 24),
        ])
        stack.addArrangedSubview(colorWell)

        // Line width icon
        let lineIcon = NSTextField(labelWithString: "—")
        lineIcon.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        lineIcon.alignment = .center
        lineIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineIcon.widthAnchor.constraint(equalToConstant: 14),
        ])
        stack.addArrangedSubview(lineIcon)

        // Line width
        lineWidthSlider.target = self
        lineWidthSlider.action = #selector(lineWidthChanged(_:))
        lineWidthSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineWidthSlider.widthAnchor.constraint(equalToConstant: 64),
        ])
        stack.addArrangedSubview(lineWidthSlider)

        lineWidthLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineWidthLabel.widthAnchor.constraint(equalToConstant: 24),
        ])
        stack.addArrangedSubview(lineWidthLabel)

        // Font size icon
        let fontIcon = NSTextField(labelWithString: "A")
        fontIcon.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        fontIcon.alignment = .center
        fontIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fontIcon.widthAnchor.constraint(equalToConstant: 14),
        ])
        stack.addArrangedSubview(fontIcon)

        // Font size stepper + label
        fontSizeField.delegate = self
        fontSizeStepper.target = self
        fontSizeStepper.action = #selector(fontSizeChanged(_:))
        fontSizeStepper.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(fontSizeStepper)

        fontSizeField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fontSizeField.widthAnchor.constraint(equalToConstant: 38),
        ])
        stack.addArrangedSubview(fontSizeField)

        // Separator
        stack.addArrangedSubview(makeSeparator())

        // Actions
        undoBtn.image = NSImage(systemSymbolName: "arrow.uturn.backward", accessibilityDescription: "撤销")
        undoBtn.bezelStyle = .texturedRounded
        undoBtn.target = self
        undoBtn.action = #selector(undoAction)
        stack.addArrangedSubview(undoBtn)

        redoBtn.image = NSImage(systemSymbolName: "arrow.uturn.forward", accessibilityDescription: "重做")
        redoBtn.bezelStyle = .texturedRounded
        redoBtn.target = self
        redoBtn.action = #selector(redoAction)
        stack.addArrangedSubview(redoBtn)

        NSLayoutConstraint.activate([
            undoBtn.widthAnchor.constraint(equalToConstant: 28),
            redoBtn.widthAnchor.constraint(equalToConstant: 28),
        ])

        // Separator
        stack.addArrangedSubview(makeSeparator())

        copyBtn.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "复制")
        copyBtn.bezelStyle = .texturedRounded
        copyBtn.target = self
        copyBtn.action = #selector(copyAction)
        stack.addArrangedSubview(copyBtn)

        saveBtn.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "保存")
        saveBtn.bezelStyle = .texturedRounded
        saveBtn.target = self
        saveBtn.action = #selector(saveAction)
        stack.addArrangedSubview(saveBtn)

        pinBtn.image = NSImage(systemSymbolName: "pin", accessibilityDescription: "贴图")
        pinBtn.bezelStyle = .texturedRounded
        pinBtn.target = self
        pinBtn.action = #selector(pinAction)
        stack.addArrangedSubview(pinBtn)

        NSLayoutConstraint.activate([
            copyBtn.widthAnchor.constraint(equalToConstant: 28),
            saveBtn.widthAnchor.constraint(equalToConstant: 28),
            pinBtn.widthAnchor.constraint(equalToConstant: 28),
        ])

        undoBtn.isEnabled = false
        redoBtn.isEnabled = false
    }

    private func makeSeparator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(equalToConstant: 1),
            box.heightAnchor.constraint(equalToConstant: 20),
        ])
        return box
    }

    // MARK: - Child window attach

    public func attach(to window: NSWindow) {
        targetWindow = window
        window.addChildWindow(self, ordered: .above)

        positionBelowTitleBar(of: window)

        frameObserver = window.observe(\.frame, options: []) { [weak self] _, _ in
            DispatchQueue.main.async { [weak self] in
                self?.positionBelowTitleBar(of: window)
            }
        }

        window.makeKeyAndOrderFront(nil)
        orderFront(nil)
    }

    public func detach() {
        frameObserver?.invalidate()
        frameObserver = nil
        targetWindow?.removeChildWindow(self)
        targetWindow = nil
        orderOut(nil)
    }

    private func positionBelowTitleBar(of window: NSWindow) {
        let windowFrame = window.frame
        let titleBarHeight: CGFloat = 28
        let panelWidth = min(frame.width, windowFrame.width - 20)
        setFrame(
            CGRect(
                x: windowFrame.midX - panelWidth / 2,
                y: windowFrame.maxY - titleBarHeight - frame.height,
                width: panelWidth,
                height: frame.height
            ),
            display: true,
            animate: false
        )
    }

    // MARK: - Actions

    @objc private func toolChanged(_ sender: NSSegmentedControl) {
        guard let tool = Self.tools[safe: sender.selectedSegment]?.0 else { return }
        activeTool = tool
        toolbarDelegate?.toolbarPanel(self, didSelectTool: tool)
    }

    @objc private func colorChanged(_ sender: NSColorWell) {
        activeColorHex = sender.color.hexString
        toolbarDelegate?.toolbarPanel(self, didChangeColor: activeColorHex)
    }

    @objc private func lineWidthChanged(_ sender: NSSlider) {
        activeLineWidth = CGFloat(sender.doubleValue)
        lineWidthLabel.stringValue = String(format: "%.0f", activeLineWidth)
        toolbarDelegate?.toolbarPanel(self, didChangeLineWidth: activeLineWidth)
    }

    @objc private func fontSizeChanged(_ sender: NSStepper) {
        setFontSize(CGFloat(sender.doubleValue), notify: true)
    }

    private func commitFontSizeFromField() {
        let raw = CGFloat(fontSizeField.doubleValue)
        setFontSize(raw, notify: true)
    }

    private func setFontSize(_ value: CGFloat, notify: Bool) {
        let next = FontSizePolicy.clamped(value)
        activeFontSize = next
        fontSizeStepper.doubleValue = Double(next)
        fontSizeField.stringValue = FontSizePolicy.displayText(next)

        if notify {
            toolbarDelegate?.toolbarPanel(self, didChangeFontSize: next)
        }
    }

    @objc private func undoAction() { toolbarDelegate?.toolbarPanelDidRequestUndo(self) }
    @objc private func redoAction() { toolbarDelegate?.toolbarPanelDidRequestRedo(self) }
    @objc private func copyAction() { toolbarDelegate?.toolbarPanelDidRequestCopy(self) }
    @objc private func saveAction() { toolbarDelegate?.toolbarPanelDidRequestSave(self) }
    @objc private func pinAction() { toolbarDelegate?.toolbarPanelDidRequestPin(self) }

    private func toolIndex(for tool: AnnotationTool) -> Int {
        Self.tools.firstIndex { $0.0 == tool } ?? 0
    }
}

// MARK: - FontSizeTextField

@MainActor
private final class FontSizeTextField: NSTextField {
    override var needsPanelToBecomeKey: Bool { true }
}

// MARK: - NSTextFieldDelegate

extension AnnotationToolbarPanel: NSTextFieldDelegate {
    public func controlTextDidBeginEditing(_ obj: Notification) {
        // Ensure panel responds to keyboard while editing
        makeKey()
    }

    public func controlTextDidEndEditing(_ obj: Notification) {
        commitFontSizeFromField()
        // Return key focus to the editor window's canvas
        if let editor = targetWindow, editor.isVisible {
            editor.makeKeyAndOrderFront(nil)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension NSColor {
    static func fromHex(_ hex: String) -> NSColor? {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        return NSColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "#FF3B30" }
        let r = UInt8(rgb.redComponent * 255)
        let g = UInt8(rgb.greenComponent * 255)
        let b = UInt8(rgb.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
