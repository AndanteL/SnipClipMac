import SwiftUI

struct CapturePreferencesView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("快捷键") {
                HotkeyRecorderView(
                    hotkey: $viewModel.captureHotkey,
                    onCommit: { viewModel.commitCaptureHotkey(viewModel.captureHotkey) }
                )
                .frame(height: 32)

                if let error = viewModel.hotkeyRegistrationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("截图后行为") {
                Toggle("打开编辑窗口", isOn: Binding(
                    get: { viewModel.openEditorAfterCapture },
                    set: { _ in viewModel.toggleOpenEditor() }
                ))

                Toggle("自动复制到粘贴板", isOn: Binding(
                    get: { viewModel.copyAfterCapture },
                    set: { _ in viewModel.toggleCopyAfterCapture() }
                ))
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }
}
