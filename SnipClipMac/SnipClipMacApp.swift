import AppKit
import SnipClipCore
import SnipClipUI
import SwiftUI

@main
struct SnipClipMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("SnipClip", systemImage: "camera.viewfinder") {
            Button("开始截图") {
                appDelegate.startCapture()
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])

            Divider()

            Button("偏好设置...") {
                appDelegate.showSettingsWindow()
            }
            .keyboardShortcut(",", modifiers: [.command])

            Button("打开屏幕录制权限") {
                appDelegate.openScreenRecordingSettings()
            }

            Divider()

            Button("退出") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView(viewModel: appDelegate.settingsViewModel)
        }
    }
}
