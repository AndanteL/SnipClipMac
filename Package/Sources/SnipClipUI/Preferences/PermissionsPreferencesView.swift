import SnipClipCore
import SwiftUI

struct PermissionsPreferencesView: View {
    @State private var state: ScreenRecordingPermissionState = .deniedOrNotDetermined
    private let permissionController = ScreenshotPermissionController()

    var body: some View {
        Form {
            Section("屏幕录制") {
                HStack {
                    Text("状态")
                    Spacer()
                    Text(state == .granted ? "已授权" : "未授权")
                        .foregroundStyle(state == .granted ? .green : .red)
                }

                Button("打开系统设置") {
                    permissionController.openPrivacyPane()
                }

                Button("刷新状态") {
                    state = permissionController.currentState()
                }
            }
        }
        .formStyle(.grouped)
        .padding(16)
        .onAppear {
            state = permissionController.currentState()
        }
    }
}
