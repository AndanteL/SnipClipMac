import SnipClipCore
import XCTest

final class AnnotationStyleTests: XCTestCase {
    func testDecodeOldJSONWithoutFontSize() throws {
        let json = """
        {"lineWidth":3,"colorHex":"#00FF00"}
        """.data(using: .utf8)!

        let style = try JSONDecoder().decode(AnnotationStyle.self, from: json)
        XCTAssertEqual(style.lineWidth, 3)
        XCTAssertEqual(style.colorHex, "#00FF00")
        XCTAssertEqual(style.fontSize, 18, "missing fontSize should default to 18")
    }

    func testDecodeNewJSONWithFontSize() throws {
        let json = """
        {"lineWidth":2,"colorHex":"#FF0000","fontSize":36}
        """.data(using: .utf8)!

        let style = try JSONDecoder().decode(AnnotationStyle.self, from: json)
        XCTAssertEqual(style.fontSize, 36)
    }
}
