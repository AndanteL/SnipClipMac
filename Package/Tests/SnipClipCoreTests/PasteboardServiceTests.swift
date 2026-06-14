import AppKit
import SnipClipCore
import XCTest

final class PasteboardServiceTests: XCTestCase {
    func testCopyPNGSetsPasteboardData() throws {
        let service = PasteboardService()
        let image = NSImage(size: NSSize(width: 32, height: 32))
        image.lockFocus()
        NSColor.green.setFill()
        NSRect(x: 0, y: 0, width: 32, height: 32).fill()
        image.unlockFocus()

        try service.copyPNG(image)

        let pasteboard = NSPasteboard.general
        XCTAssertNotNil(pasteboard.data(forType: .png))
    }
}
