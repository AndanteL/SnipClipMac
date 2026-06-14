import AppKit
import Combine
import ServiceManagement
import SnipClipCore
import SnipClipUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore = AppSettingsStore()
    let settingsViewModel: SettingsViewModel

    private lazy var captureCoordinator = CaptureCoordinator(
        permissionController: ScreenshotPermissionController(),
        screenInfoProvider: ScreenInfoProvider(),
        settingsStore: settingsStore
    )
    private lazy var hotkeyService = HotkeyService { [weak self] in
        DispatchQueue.main.async {
            self?.startCapture()
        }
    }
    private lazy var settingsWindowController = SettingsWindowController(
        viewModel: settingsViewModel
    )
    private var cancellables: Set<AnyCancellable> = []
    private var isRollingBackSystemSetting = false

    override init() {
        settingsViewModel = SettingsViewModel(store: settingsStore)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        registerCurrentHotkey()
        observeSettings()
        syncSystemSettings()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showSettingsWindow()
        return false
    }

    func showSettingsWindow() {
        settingsWindowController.show()
    }

    private func registerCurrentHotkey() {
        let hotkey = settingsStore.settings.captureHotkey

        hotkeyService.unregister()
        settingsStore.hotkeyRegistrationError = nil

        guard !hotkey.displayText.isEmpty, hotkey.keyCode != 0 || hotkey.modifiers != 0 else {
            return
        }

        let ok = hotkeyService.register(
            keyCode: hotkey.keyCode,
            modifiers: hotkey.modifiers
        )

        if !ok {
            settingsStore.hotkeyRegistrationError = "快捷键 \(hotkey.displayText) 注册失败，可能与其他快捷键冲突"
        }
    }

    private func syncSystemSettings() {
        let s = settingsStore.settings

        // Launch at login — only act when status doesn't match desired state
        let status = SMAppService.mainApp.status
        do {
            if s.launchAtLogin, status != .enabled {
                try SMAppService.mainApp.register()
            } else if !s.launchAtLogin, status == .enabled {
                try SMAppService.mainApp.unregister()
            }
            if !isRollingBackSystemSetting {
                settingsStore.systemSettingsError = nil
            }
            isRollingBackSystemSetting = false
        } catch {
            settingsStore.systemSettingsError = "开机启动设置失败：\(error.localizedDescription)"
            isRollingBackSystemSetting = true
            settingsStore.update { $0.launchAtLogin = !s.launchAtLogin }
        }

        // Dock icon visibility — always apply regardless of login item outcome
        NSApp.setActivationPolicy(s.showDockIcon ? .regular : .accessory)
    }

    private func observeSettings() {
        settingsStore.$settings
            .dropFirst()
            .sink { [weak self] _ in
                self?.registerCurrentHotkey()
                self?.syncSystemSettings()
            }
            .store(in: &cancellables)
    }

    func startCapture() {
        captureCoordinator.beginCapture()
    }

    func openScreenRecordingSettings() {
        ScreenshotPermissionController().openPrivacyPane()
    }
}
