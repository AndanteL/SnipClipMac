import SnipClipCore
import XCTest

final class AppSettingsStoreTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnipClipMacTests_\(UUID().uuidString)")
        try? FileManager.default.removeItem(at: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func makeStore() -> AppSettingsStore {
        AppSettingsStore(directoryURL: tempDir)
    }

    func testDefaultSettingsOnFirstLaunch() {
        let store = makeStore()
        let settings = store.settings

        XCTAssertEqual(settings.captureHotkey.keyCode, 18)
        XCTAssertEqual(settings.cancelHotkey.keyCode, 53)
        XCTAssertFalse(settings.copyAfterCapture)
        XCTAssertTrue(settings.openEditorAfterCapture)
        XCTAssertFalse(settings.closeEditorAfterSave)
        XCTAssertNil(settings.defaultSaveDirectoryBookmark)
        XCTAssertNil(settings.defaultSaveDirectoryPath)
        XCTAssertEqual(settings.defaultAnnotationStyle.lineWidth, 2)
        XCTAssertEqual(settings.defaultAnnotationStyle.colorHex, "#FF3B30")
    }

    func testUpdatePersistsChanges() {
        let store = makeStore()

        store.update { settings in
            settings.copyAfterCapture = true
            settings.closeEditorAfterSave = true
        }

        XCTAssertTrue(store.settings.copyAfterCapture)
        XCTAssertTrue(store.settings.closeEditorAfterSave)
    }

    func testReloadReadsFromDisk() {
        let store1 = makeStore()
        store1.update { settings in
            settings.copyAfterCapture = true
        }

        let store2 = makeStore()
        XCTAssertTrue(store2.settings.copyAfterCapture)
    }
}
