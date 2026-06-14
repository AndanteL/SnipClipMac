import Carbon
import Foundation

public struct AppSettings: Codable, Equatable {
    public var captureHotkey: HotkeyDefinition
    public var cancelHotkey: HotkeyDefinition
    public var defaultSaveDirectoryBookmark: Data?
    public var defaultSaveDirectoryPath: String?
    public var copyAfterCapture: Bool
    public var openEditorAfterCapture: Bool
    public var closeEditorAfterSave: Bool
    public var defaultAnnotationStyle: AnnotationStyle
    public var launchAtLogin: Bool
    public var showDockIcon: Bool
    public var showMenuBarIcon: Bool
    public var defaultFontSize: CGFloat

    private enum CodingKeys: String, CodingKey {
        case captureHotkey, cancelHotkey, defaultSaveDirectoryBookmark, defaultSaveDirectoryPath
        case copyAfterCapture, openEditorAfterCapture, closeEditorAfterSave
        case defaultAnnotationStyle
        case launchAtLogin, showDockIcon, showMenuBarIcon, defaultFontSize
    }

    public init(
        captureHotkey: HotkeyDefinition = AppSettings.defaultCaptureHotkey,
        cancelHotkey: HotkeyDefinition = AppSettings.defaultCancelHotkey,
        defaultSaveDirectoryBookmark: Data? = nil,
        defaultSaveDirectoryPath: String? = nil,
        copyAfterCapture: Bool = false,
        openEditorAfterCapture: Bool = true,
        closeEditorAfterSave: Bool = false,
        defaultAnnotationStyle: AnnotationStyle = AnnotationStyle(),
        launchAtLogin: Bool = false,
        showDockIcon: Bool = true,
        showMenuBarIcon: Bool = true,
        defaultFontSize: CGFloat = 18
    ) {
        self.captureHotkey = captureHotkey
        self.cancelHotkey = cancelHotkey
        self.defaultSaveDirectoryBookmark = defaultSaveDirectoryBookmark
        self.defaultSaveDirectoryPath = defaultSaveDirectoryPath
        self.copyAfterCapture = copyAfterCapture
        self.openEditorAfterCapture = openEditorAfterCapture
        self.closeEditorAfterSave = closeEditorAfterSave
        self.defaultAnnotationStyle = defaultAnnotationStyle
        self.launchAtLogin = launchAtLogin
        self.showDockIcon = showDockIcon
        self.showMenuBarIcon = showMenuBarIcon
        self.defaultFontSize = defaultFontSize
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        captureHotkey = try container.decode(HotkeyDefinition.self, forKey: .captureHotkey)
        cancelHotkey = try container.decode(HotkeyDefinition.self, forKey: .cancelHotkey)
        defaultSaveDirectoryBookmark = try container.decodeIfPresent(Data.self, forKey: .defaultSaveDirectoryBookmark)
        defaultSaveDirectoryPath = try container.decodeIfPresent(String.self, forKey: .defaultSaveDirectoryPath)
        copyAfterCapture = try container.decodeIfPresent(Bool.self, forKey: .copyAfterCapture) ?? false
        openEditorAfterCapture = try container.decodeIfPresent(Bool.self, forKey: .openEditorAfterCapture) ?? true
        closeEditorAfterSave = try container.decodeIfPresent(Bool.self, forKey: .closeEditorAfterSave) ?? false
        defaultAnnotationStyle = try container.decode(AnnotationStyle.self, forKey: .defaultAnnotationStyle)
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        showDockIcon = try container.decodeIfPresent(Bool.self, forKey: .showDockIcon) ?? true
        showMenuBarIcon = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? true
        defaultFontSize = try container.decodeIfPresent(CGFloat.self, forKey: .defaultFontSize) ?? 18
    }

    public static var defaultCaptureHotkey: HotkeyDefinition {
        HotkeyDefinition(
            keyCode: 18,
            modifiers: UInt32(cmdKey | shiftKey),
            displayText: "⇧⌘1"
        )
    }

    public static var defaultCancelHotkey: HotkeyDefinition {
        HotkeyDefinition(
            keyCode: 53,
            modifiers: 0,
            displayText: "⎋"
        )
    }
}
