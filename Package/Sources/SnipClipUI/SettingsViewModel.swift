import Carbon
import Combine
import SnipClipCore
import SwiftUI

@MainActor
public final class SettingsViewModel: ObservableObject {
    private let store: AppSettingsStore

    @Published public var captureHotkey: HotkeyDefinition
    @Published public var cancelHotkey: HotkeyDefinition
    @Published public var saveDirectoryBookmark: Data?
    @Published public var saveDirectoryPath: String?
    @Published public var copyAfterCapture: Bool
    @Published public var openEditorAfterCapture: Bool
    @Published public var closeEditorAfterSave: Bool
    @Published public var defaultColorHex: String
    @Published public var defaultLineWidth: Double
    @Published public var defaultFontSize: Double
    @Published public var launchAtLogin: Bool
    @Published public var showDockIcon: Bool
    @Published public var showMenuBarIcon: Bool
    @Published public var hotkeyRegistrationError: String?
    @Published public var systemSettingsError: String?

    public var isRecordingCaptureHotkey = false
    public var isRecordingCancelHotkey = false

    private var cancellables: Set<AnyCancellable> = []

    public init(store: AppSettingsStore) {
        self.store = store
        let s = store.settings

        captureHotkey = s.captureHotkey
        cancelHotkey = s.cancelHotkey
        saveDirectoryBookmark = s.defaultSaveDirectoryBookmark
        saveDirectoryPath = s.defaultSaveDirectoryPath
        copyAfterCapture = s.copyAfterCapture
        openEditorAfterCapture = s.openEditorAfterCapture
        closeEditorAfterSave = s.closeEditorAfterSave
        defaultColorHex = s.defaultAnnotationStyle.colorHex
        defaultLineWidth = Double(s.defaultAnnotationStyle.lineWidth)
        defaultFontSize = Double(s.defaultAnnotationStyle.fontSize)
        launchAtLogin = s.launchAtLogin
        showDockIcon = s.showDockIcon
        showMenuBarIcon = s.showMenuBarIcon

        store.$hotkeyRegistrationError
            .sink { [weak self] error in self?.hotkeyRegistrationError = error }
            .store(in: &cancellables)

        store.$systemSettingsError
            .sink { [weak self] error in self?.systemSettingsError = error }
            .store(in: &cancellables)

        // Sync back when store is updated externally (e.g. launchAtLogin rollback)
        store.$settings
            .sink { [weak self] s in
                guard let self else { return }
                launchAtLogin = s.launchAtLogin
                showDockIcon = s.showDockIcon
                showMenuBarIcon = s.showMenuBarIcon
            }
            .store(in: &cancellables)
    }

    public func commitCaptureHotkey(_ hotkey: HotkeyDefinition) {
        captureHotkey = hotkey
        hotkeyRegistrationError = nil
        saveAll()
    }

    public func clearCaptureHotkey() {
        captureHotkey = HotkeyDefinition(keyCode: 0, modifiers: 0, displayText: "")
        saveAll()
    }

    public func commitColor(_ hex: String) {
        defaultColorHex = hex
        saveAll()
    }

    public func commitLineWidth(_ width: Double) {
        defaultLineWidth = width
        saveAll()
    }

    public func commitFontSize(_ size: Double) {
        defaultFontSize = Double(FontSizePolicy.clamped(CGFloat(size)))
        saveAll()
    }

    public func commitFontSizeInput(_ value: Double) {
        defaultFontSize = Double(FontSizePolicy.clamped(CGFloat(value)))
        saveAll()
    }

    public func setSaveDirectory(bookmark: Data?, path: String?) {
        saveDirectoryBookmark = bookmark
        saveDirectoryPath = path
        saveAll()
    }

    public func toggleCopyAfterCapture() {
        copyAfterCapture.toggle()
        saveAll()
    }

    public func toggleOpenEditor() {
        openEditorAfterCapture.toggle()
        saveAll()
    }

    public func toggleCloseEditorAfterSave() {
        closeEditorAfterSave.toggle()
        saveAll()
    }

    public func toggleLaunchAtLogin() {
        launchAtLogin.toggle()
        saveAll()
    }

    public func toggleShowDockIcon() {
        showDockIcon.toggle()
        saveAll()
    }

    public func toggleShowMenuBarIcon() {
        showMenuBarIcon.toggle()
        saveAll()
    }

    public func setRegistrationError(_ message: String) {
        hotkeyRegistrationError = message
    }

    public func clearRegistrationError() {
        hotkeyRegistrationError = nil
    }

    private func saveAll() {
        store.update { settings in
            settings.captureHotkey = captureHotkey
            settings.cancelHotkey = cancelHotkey
            settings.defaultSaveDirectoryBookmark = saveDirectoryBookmark
            settings.defaultSaveDirectoryPath = saveDirectoryPath
            settings.copyAfterCapture = copyAfterCapture
            settings.openEditorAfterCapture = openEditorAfterCapture
            settings.closeEditorAfterSave = closeEditorAfterSave
            settings.launchAtLogin = launchAtLogin
            settings.showDockIcon = showDockIcon
            settings.showMenuBarIcon = showMenuBarIcon
            settings.defaultFontSize = CGFloat(defaultFontSize)
            settings.defaultAnnotationStyle = AnnotationStyle(
                lineWidth: CGFloat(defaultLineWidth),
                colorHex: defaultColorHex,
                fontSize: CGFloat(defaultFontSize)
            )
        }
    }
}
