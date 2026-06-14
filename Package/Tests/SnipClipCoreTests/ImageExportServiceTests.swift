import AppKit
import SnipClipCore
import XCTest

final class ImageExportServiceTests: XCTestCase {
    func testDefaultFileNameFormat() {
        let service = ImageExportService()
        let date = Date(timeIntervalSince1970: 1718432000) // 2024-06-15 06:13:20 UTC
        let name = service.defaultFileName(now: date)

        XCTAssertTrue(name.hasPrefix("SnipClip_"))
        XCTAssertTrue(name.hasSuffix(".png"))
    }

    func testPNGDataProducesValidData() throws {
        let service = ImageExportService()
        let image = NSImage(size: NSSize(width: 64, height: 64))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 64, height: 64).fill()
        image.unlockFocus()

        let data = try service.pngData(from: image)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testSavePNGWritesFile() throws {
        let service = ImageExportService()
        let image = NSImage(size: NSSize(width: 32, height: 32))
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(x: 0, y: 0, width: 32, height: 32).fill()
        image.unlockFocus()

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_save_\(UUID().uuidString).png")
        try service.savePNG(image, to: tempURL)

        let written = try Data(contentsOf: tempURL)
        XCTAssertGreaterThan(written.count, 0)
        try? FileManager.default.removeItem(at: tempURL)
    }
}
