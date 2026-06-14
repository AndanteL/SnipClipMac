import AppKit
import CoreGraphics

public enum ScreenRecordingPermissionState: Equatable {
    case granted
    case deniedOrNotDetermined
}

public final class ScreenshotPermissionController {
    public init() {}

    public func currentState() -> ScreenRecordingPermissionState {
        CGPreflightScreenCaptureAccess() ? .granted : .deniedOrNotDetermined
    }

    @discardableResult
    public func requestIfNeeded() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }

        return CGRequestScreenCaptureAccess()
    }

    public func openPrivacyPane() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
