import AppKit
import CoreGraphics

public enum ScreenCaptureError: Error {
    case displayNotFound
    case captureFailed
    case cropFailed
}

@MainActor
public final class ScreenCaptureService {
    public init() {}

    public func capture(rect globalRect: CGRect, displayID: CGDirectDisplayID) async throws -> NSImage {
        guard let screenshot = CGDisplayCreateImage(displayID) else {
            throw ScreenCaptureError.captureFailed
        }

        guard let screen = NSScreen.screens.first(where: { screen in
            (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == displayID
        }) else {
            throw ScreenCaptureError.displayNotFound
        }

        let screenFrame = screen.frame
        let displayRect = globalRect.intersection(screenFrame)
        guard !displayRect.isNull, !displayRect.isEmpty else {
            throw ScreenCaptureError.cropFailed
        }

        let scaleX = CGFloat(screenshot.width) / screenFrame.width
        let scaleY = CGFloat(screenshot.height) / screenFrame.height

        let originX = (displayRect.minX - screenFrame.minX) * scaleX
        let originY = (screenFrame.maxY - displayRect.maxY) * scaleY
        let width = displayRect.width * scaleX
        let height = displayRect.height * scaleY

        let imageBounds = CGRect(x: 0, y: 0, width: screenshot.width, height: screenshot.height)
        let pixelRect = CGRect(x: originX, y: originY, width: width, height: height)
            .integral
            .intersection(imageBounds)

        guard !pixelRect.isNull, !pixelRect.isEmpty, let cropped = screenshot.cropping(to: pixelRect) else {
            throw ScreenCaptureError.cropFailed
        }

        return NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
    }
}
