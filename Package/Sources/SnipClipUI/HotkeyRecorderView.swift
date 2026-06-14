import AppKit
import SnipClipCore
import SwiftUI

public struct HotkeyRecorderView: NSViewRepresentable {
    @Binding public var hotkey: HotkeyDefinition
    public var onCommit: (() -> Void)?

    public init(hotkey: Binding<HotkeyDefinition>, onCommit: (() -> Void)? = nil) {
        _hotkey = hotkey
        self.onCommit = onCommit
    }

    public func makeNSView(context: Context) -> HotkeyRecorderField {
        let field = HotkeyRecorderField()
        field.onHotkeyCaptured = { definition in
            hotkey = definition
            onCommit?()
        }
        field.onClear = {
            hotkey = HotkeyDefinition(keyCode: 0, modifiers: 0, displayText: "")
            onCommit?()
        }
        return field
    }

    public func updateNSView(_ nsView: HotkeyRecorderField, context: Context) {
        nsView.displayText = hotkey.displayText.isEmpty ? "点按录制快捷键" : hotkey.displayText
    }
}

@MainActor
public final class HotkeyRecorderField: NSView {
    public var onHotkeyCaptured: ((HotkeyDefinition) -> Void)?
    public var onClear: (() -> Void)?

    public var displayText: String = "点按录制快捷键" {
        didSet { needsDisplay = true }
    }

    private var isRecording = false

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 4
        layer?.borderWidth = 1
        updateBorder()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }

    public override var acceptsFirstResponder: Bool { true }

    public override func becomeFirstResponder() -> Bool {
        isRecording = true
        updateBorder()
        return true
    }

    public override func resignFirstResponder() -> Bool {
        isRecording = false
        updateBorder()
        return true
    }

    public override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    public override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 {
            isRecording = false
            updateBorder()
            window?.makeFirstResponder(nil)
            return
        }

        if event.keyCode == 51 || event.keyCode == 117 {
            onClear?()
            isRecording = false
            updateBorder()
            window?.makeFirstResponder(nil)
            return
        }

        let carbonModifiers = HotkeyFormatter.carbonModifiers(from: event.modifierFlags)
        let text = HotkeyFormatter.string(from: UInt32(event.keyCode), carbonModifiers: carbonModifiers)
        let definition = HotkeyDefinition(
            keyCode: UInt32(event.keyCode),
            modifiers: carbonModifiers,
            displayText: text
        )

        displayText = text
        isRecording = false
        updateBorder()
        onHotkeyCaptured?(definition)
        window?.makeFirstResponder(nil)
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: isRecording ? NSColor.controlAccentColor : NSColor.labelColor
        ]

        let text = isRecording ? "输入快捷键..." : displayText
        let size = (text as NSString).size(withAttributes: attrs)
        let point = NSPoint(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2
        )
        (text as NSString).draw(at: point, withAttributes: attrs)
    }

    private func updateBorder() {
        layer?.borderColor = isRecording ? NSColor.controlAccentColor.cgColor : NSColor.separatorColor.cgColor
    }
}
