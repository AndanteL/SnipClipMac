import SwiftUI

struct BasicPreferencesView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("开机时启动", isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { _ in viewModel.toggleLaunchAtLogin() }
                ))
                Toggle("显示 Dock 图标", isOn: Binding(
                    get: { viewModel.showDockIcon },
                    set: { _ in viewModel.toggleShowDockIcon() }
                ))
            }

            if let error = viewModel.systemSettingsError {
                Section {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }
}
