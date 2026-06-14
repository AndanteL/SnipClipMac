import AppKit
import CoreGraphics

public enum CaptureSessionState: Equatable {
    case idle
    case selecting(displayID: CGDirectDisplayID?)
    case captured(rect: CGRect, displayID: CGDirectDisplayID, image: NSImage)
    case cancelled

    public static func == (lhs: CaptureSessionState, rhs: CaptureSessionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): true
        case (.selecting(let a), .selecting(let b)): a == b
        case (.captured(let ar, let ad, _), .captured(let br, let bd, _)): ar == br && ad == bd
        case (.cancelled, .cancelled): true
        default: false
        }
    }
}

@MainActor
public final class CaptureSession {
    public private(set) var state: CaptureSessionState = .idle

    public init() {}

    public func beginSelection(on displayID: CGDirectDisplayID? = nil) {
        state = .selecting(displayID: displayID)
    }

    public func finishSelection(rect: CGRect, displayID: CGDirectDisplayID, image: NSImage) {
        state = .captured(rect: rect.integral, displayID: displayID, image: image)
    }

    public func cancel() {
        state = .cancelled
    }

    public func reset() {
        state = .idle
    }
}
