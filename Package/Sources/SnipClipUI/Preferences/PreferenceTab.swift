import Foundation

public enum PreferenceTab: String, CaseIterable, Identifiable {
    case basic
    case capture
    case annotation
    case storage
    case permissions
    case about

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .basic: "基础"
        case .capture: "截图"
        case .annotation: "标注"
        case .storage: "存储"
        case .permissions: "权限"
        case .about: "关于"
        }
    }

    var symbolName: String {
        switch self {
        case .basic: "gearshape"
        case .capture: "camera.viewfinder"
        case .annotation: "pencil.tip"
        case .storage: "folder"
        case .permissions: "hand.raised"
        case .about: "info.circle"
        }
    }
}
