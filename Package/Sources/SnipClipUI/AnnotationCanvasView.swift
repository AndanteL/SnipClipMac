import AppKit
import ObjectiveC
import SnipClipCore

@MainActor
protocol AnnotationCanvasViewDelegate: AnyObject {
    func annotationCanvas(_ canvas: AnnotationCanvasView, didAdd item: AnnotationItem)
    func annotationCanvas(_ canvas: AnnotationCanvasView, didRemove item: AnnotationItem)
}

@MainActor
final class AnnotationCanvasView: NSView {
    weak var delegate: AnnotationCanvasViewDelegate?

    var screenshot: NSImage? {
        didSet { needsDisplay = true }
    }

    var annotations: [AnnotationItem] = [] {
        didSet { needsDisplay = true }
    }

    var canUndo: Bool { !annotations.isEmpty }
    var canRedo: Bool { !undoStack.isEmpty }

    var activeTool: AnnotationTool = .rectangle
    var activeStyle: AnnotationStyle = AnnotationStyle()
    var activeFontSize: CGFloat = 18

    private var currentAnnotation: AnnotationItem?
    private var startPoint: CGPoint?
    private var lastPoint: CGPoint?
    private var penPath = NSBezierPath()

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        window?.makeFirstResponder(self)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()

        screenshot?.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1)

        for annotation in annotations {
            drawAnnotation(annotation)
        }

        if let current = currentAnnotation {
            drawAnnotation(current)
        }
    }

    private func drawAnnotation(_ item: AnnotationItem) {
        let color = NSColor.fromHex(item.style.colorHex) ?? .controlAccentColor
        color.setStroke()

        let path: NSBezierPath

        switch item.tool {
        case .rectangle:
            path = NSBezierPath(rect: item.bounds)
            path.lineWidth = item.style.lineWidth
            path.stroke()

        case .ellipse:
            path = NSBezierPath(ovalIn: item.bounds)
            path.lineWidth = item.style.lineWidth
            path.stroke()

        case .pen:
            if let penData = item.text, let path = NSBezierPath.fromSVGString(penData) {
                path.lineWidth = item.style.lineWidth
                path.lineJoinStyle = .round
                path.lineCapStyle = .round
                path.stroke()
            }

        case .text:
            if let text = item.text {
                let attrs = textDrawingAttributes(for: item)
                let textSize = measuredTextSize(text, font: NSFont.systemFont(ofSize: item.style.fontSize))
                let vPad = Self.textVerticalPadding(fontSize: item.style.fontSize, textHeight: textSize.height)
                let drawPoint = CGPoint(
                    x: item.bounds.origin.x + Self.textHorizontalPadding,
                    y: item.bounds.origin.y + vPad
                )
                (text as NSString).draw(at: drawPoint, withAttributes: attrs)
            }

        case .mosaic:
            drawMosaic(in: item.bounds)
        }
    }

    // MARK: - Text measurement

    private static let textHorizontalPadding: CGFloat = 8

    private static func textVerticalPadding(fontSize: CGFloat, textHeight: CGFloat) -> CGFloat {
        let font = NSFont.systemFont(ofSize: fontSize)
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        return max(4, (lineHeight - textHeight) / 2)
    }

    private func textDrawingAttributes(for item: AnnotationItem) -> [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: item.style.fontSize),
            .foregroundColor: NSColor.fromHex(item.style.colorHex) ?? .controlAccentColor
        ]
    }

    private func measuredTextSize(_ text: String, font: NSFont) -> CGSize {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        return (text as NSString).boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs,
            context: nil
        ).size
    }

    private func normalizedTextRect(origin: CGPoint, text: String, fontSize: CGFloat) -> CGRect {
        let font = NSFont.systemFont(ofSize: fontSize)
        let textSize = measuredTextSize(text, font: font)
        let vPad = Self.textVerticalPadding(fontSize: fontSize, textHeight: textSize.height)
        return CGRect(
            x: origin.x,
            y: origin.y,
            width: ceil(textSize.width) + Self.textHorizontalPadding * 2,
            height: ceil(textSize.height) + vPad * 2
        )
    }

    private func drawMosaic(in rect: CGRect) {
        NSColor.windowBackgroundColor.withAlphaComponent(0.85).setFill()
        rect.fill()

        let mosaicSize: CGFloat = 16
        let anchorX = floor(rect.minX / mosaicSize)
        let anchorY = floor(rect.minY / mosaicSize)
        var x = floor(rect.minX / mosaicSize) * mosaicSize
        while x < rect.maxX {
            var y = floor(rect.minY / mosaicSize) * mosaicSize
            while y < rect.maxY {
                let xi = Int((x / mosaicSize - anchorX).rounded())
                let yi = Int((y / mosaicSize - anchorY).rounded())
                let hash = UInt64(bitPattern: Int64((xi &* 0x9E3779B9) ^ (yi &* 0x517CC1B7)))
                let brightness = 0.4 + CGFloat(hash % 50) / 100.0
                NSColor(white: brightness, alpha: 0.5).setFill()
                let cell = CGRect(x: x, y: y, width: mosaicSize, height: mosaicSize)
                cell.fill()
                y += mosaicSize
            }
            x += mosaicSize
        }

        NSColor.secondaryLabelColor.setStroke()
        let border = NSBezierPath(rect: rect)
        border.lineWidth = 1
        border.stroke()
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        startPoint = point
        lastPoint = point

        if activeTool == .pen {
            penPath = NSBezierPath()
            penPath.move(to: point)
            let item = AnnotationItem(tool: .pen, bounds: bounds, text: nil, style: activeStyle)
            currentAnnotation = item
        } else if activeTool == .text {
            addTextAnnotation(at: point)
            return
        } else {
            let item = AnnotationItem(tool: activeTool, bounds: CGRect(origin: point, size: .zero), style: activeStyle)
            currentAnnotation = item
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        lastPoint = point

        let rect = CGRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )

        if activeTool == .pen {
            penPath.line(to: point)
            currentAnnotation?.text = penPath.svgString
            currentAnnotation?.bounds = bounds.intersection(rect.insetBy(dx: -20, dy: -20))
        } else {
            currentAnnotation?.bounds = rect
        }

        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard var item = currentAnnotation else {
            startPoint = nil
            lastPoint = nil
            return
        }

        if item.bounds.width < 3 && item.bounds.height < 3 && activeTool != .pen {
            currentAnnotation = nil
            needsDisplay = true
            startPoint = nil
            lastPoint = nil
            return
        }

        item.bounds = item.bounds.integral
        annotations.append(item)
        undoStack.removeAll()
        delegate?.annotationCanvas(self, didAdd: item)

        currentAnnotation = nil
        startPoint = nil
        lastPoint = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            window?.close()
            return
        }

        if event.keyCode == 6, event.modifierFlags.contains(.command) {
            if event.modifierFlags.contains(.shift) {
                redo()
            } else {
                undo()
            }
            return
        }

        super.keyDown(with: event)
    }

    // MARK: - Undo/Redo

    private var undoStack: [AnnotationItem] = []

    func undo() {
        guard let last = annotations.popLast() else { return }
        undoStack.append(last)
        delegate?.annotationCanvas(self, didRemove: last)
        needsDisplay = true
    }

    func redo() {
        guard let item = undoStack.popLast() else { return }
        annotations.append(item)
        delegate?.annotationCanvas(self, didAdd: item)
        needsDisplay = true
    }

    // MARK: - Text

    private struct TextDraft {
        let fontSize: CGFloat
        let style: AnnotationStyle
        @MainActor static let key = malloc(1)!
    }

    private func addTextAnnotation(at point: CGPoint) {
        let font = NSFont.systemFont(ofSize: activeFontSize)
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let fieldHeight = lineHeight + 12
        let fieldWidth = max(200, activeFontSize * 12)

        let textField = NSTextField(frame: CGRect(origin: point, size: CGSize(width: fieldWidth, height: fieldHeight)))
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.font = font
        textField.textColor = NSColor.fromHex(activeStyle.colorHex) ?? .controlAccentColor
        textField.focusRingType = .none
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.stringValue = ""

        // Capture creation-time values so toolbar changes during editing don't affect this draft.
        // Rebuild style so fontSize inside the style is guaranteed to match.
        let draftStyle = AnnotationStyle(
            lineWidth: activeStyle.lineWidth,
            colorHex: activeStyle.colorHex,
            fontSize: activeFontSize
        )
        let draft = TextDraft(fontSize: activeFontSize, style: draftStyle)
        objc_setAssociatedObject(textField, TextDraft.key, draft, .OBJC_ASSOCIATION_RETAIN)

        addSubview(textField)
        window?.makeFirstResponder(textField)

        textField.target = self
        textField.action = #selector(textFieldDidEnd(_:))
    }

    @objc private func textFieldDidEnd(_ sender: NSTextField) {
        defer { window?.makeFirstResponder(self) }

        let text = sender.stringValue
        let draft = objc_getAssociatedObject(sender, TextDraft.key) as? TextDraft
        sender.removeFromSuperview()

        guard !text.isEmpty else { return }

        let fontSize = draft?.fontSize ?? activeFontSize
        let style = draft?.style ?? activeStyle
        let rect = normalizedTextRect(origin: sender.frame.origin, text: text, fontSize: fontSize)

        let item = AnnotationItem(
            tool: .text,
            bounds: rect,
            text: text,
            style: style
        )
        annotations.append(item)
        undoStack.removeAll()
        delegate?.annotationCanvas(self, didAdd: item)
        needsDisplay = true
    }
}

// MARK: - Helpers

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
}

private extension NSBezierPath {
    var svgString: String {
        var result = ""
        for i in 0..<elementCount {
            var points = [NSPoint](repeating: .zero, count: 3)
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                result += "M \(points[0].x) \(points[0].y) "
            case .lineTo:
                result += "L \(points[0].x) \(points[0].y) "
            case .curveTo:
                result += "C \(points[0].x) \(points[0].y) \(points[1].x) \(points[1].y) \(points[2].x) \(points[2].y) "
            case .closePath:
                result += "Z "
            case .cubicCurveTo, .quadraticCurveTo:
                break
            @unknown default:
                break
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    static func fromSVGString(_ svg: String) -> NSBezierPath? {
        let path = NSBezierPath()
        let tokens = svg
            .replacingOccurrences(of: ",", with: " ")
            .split(separator: " ")
        var i = 0
        while i < tokens.count {
            let cmd = String(tokens[i])
            switch cmd {
            case "M":
                guard i + 2 < tokens.count,
                      let x = Double(tokens[i + 1]), let y = Double(tokens[i + 2]) else { return nil }
                path.move(to: NSPoint(x: x, y: y))
                i += 3
            case "L":
                guard i + 2 < tokens.count,
                      let x = Double(tokens[i + 1]), let y = Double(tokens[i + 2]) else { return nil }
                path.line(to: NSPoint(x: x, y: y))
                i += 3
            case "C":
                guard i + 6 < tokens.count else { return nil }
                i += 7
            case "Z":
                path.close()
                i += 1
            default:
                i += 1
            }
        }
        return path
    }
}
