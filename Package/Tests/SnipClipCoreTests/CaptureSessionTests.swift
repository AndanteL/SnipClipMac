import AppKit
import SnipClipCore
import XCTest

@MainActor
final class CaptureSessionTests: XCTestCase {
    func testSelectionLifecycle() {
        let session = CaptureSession()
        let testImage = NSImage(size: NSSize(width: 100, height: 100))

        session.beginSelection(on: 1)
        XCTAssertEqual(session.state, .selecting(displayID: 1))

        session.finishSelection(rect: CGRect(x: 10.2, y: 20.4, width: 99.6, height: 80.2), displayID: 1, image: testImage)

        switch session.state {
        case .captured(let rect, let displayID, _):
            XCTAssertEqual(rect, CGRect(x: 10, y: 20, width: 100, height: 81))
            XCTAssertEqual(displayID, 1)
        default:
            XCTFail("Expected .captured state")
        }

        session.cancel()
        XCTAssertEqual(session.state, .cancelled)

        session.reset()
        XCTAssertEqual(session.state, .idle)
    }
}
