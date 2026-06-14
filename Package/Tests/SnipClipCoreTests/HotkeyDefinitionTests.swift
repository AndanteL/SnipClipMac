import Carbon
import SnipClipCore
import XCTest

final class HotkeyDefinitionTests: XCTestCase {
    func testFormatterCommandShift1() {
        let text = HotkeyFormatter.string(from: 18, carbonModifiers: UInt32(cmdKey | shiftKey))
        XCTAssertEqual(text, "⇧⌘1")
    }

    func testFormatterEscape() {
        let text = HotkeyFormatter.string(from: 53, carbonModifiers: 0)
        XCTAssertEqual(text, "⎋")
    }

    func testFormatterLetter() {
        let text = HotkeyFormatter.string(from: 12, carbonModifiers: UInt32(cmdKey))
        XCTAssertEqual(text, "⌘Q")
    }

    func testCarbonModifiersFromNSEvent() {
        let flags: NSEvent.ModifierFlags = [.command, .shift]
        let carbon = HotkeyFormatter.carbonModifiers(from: flags)
        XCTAssertEqual(carbon, UInt32(cmdKey | shiftKey))
    }
}
