import SwiftUI

public struct PreferencesRootView: View {
    @ObservedObject private var viewModel: SettingsViewModel
    @State private var selectedTab: PreferenceTab = .basic

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .frame(width: 640, height: 430)
        .background(.regularMaterial)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("偏好设置")
                .font(.system(size: 17, weight: .semibold))

            HStack(spacing: 14) {
                ForEach(PreferenceTab.allCases) { tab in
                    PreferenceTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }

            if let error = viewModel.systemSettingsError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .basic:
            BasicPreferencesView(viewModel: viewModel)
        case .capture:
            CapturePreferencesView(viewModel: viewModel)
        case .annotation:
            AnnotationPreferencesView(viewModel: viewModel)
        case .storage:
            StoragePreferencesView(viewModel: viewModel)
        case .permissions:
            PermissionsPreferencesView()
        case .about:
            AboutPreferencesView()
        }
    }
}
