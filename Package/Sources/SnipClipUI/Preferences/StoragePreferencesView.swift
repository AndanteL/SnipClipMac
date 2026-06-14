import SwiftUI

struct StoragePreferencesView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("默认保存目录") {
                SaveLocationPickerView(bookmark: Binding(
                    get: { viewModel.saveDirectoryBookmark },
                    set: { viewModel.setSaveDirectory(bookmark: $0, path: viewModel.saveDirectoryPath) }
                ), path: Binding(
                    get: { viewModel.saveDirectoryPath },
                    set: { viewModel.setSaveDirectory(bookmark: viewModel.saveDirectoryBookmark, path: $0) }
                ))
            }

            Section {
                Toggle("保存后关闭编辑窗口", isOn: Binding(
                    get: { viewModel.closeEditorAfterSave },
                    set: { _ in viewModel.toggleCloseEditorAfterSave() }
                ))
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }
}
