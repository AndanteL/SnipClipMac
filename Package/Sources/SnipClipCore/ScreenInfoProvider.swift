import AppKit
import CoreGraphics

public struct DisplayInfo: Equatable, Identifiable {
    public let id: CGDirectDisplayID
    public let frame: CGRect
    public let visibleFrame: CGRect
    public let backingScaleFactor: CGFloat

    public init(id: CGDirectDisplayID, frame: CGRect, visibleFrame: CGRect, backingScaleFactor: CGFloat) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.backingScaleFactor = backingScaleFactor
    }
}

public final class ScreenInfoProvider {
    public init() {}

    public func allDisplays() -> [DisplayInfo] {
        NSScreen.screens.compactMap { screen in
            guard let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value else {
                return nil
            }

            return DisplayInfo(
                id: displayID,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                backingScaleFactor: screen.backingScaleFactor
            )
        }
    }
}
