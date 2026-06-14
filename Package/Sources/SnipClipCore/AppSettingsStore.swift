import Foundation

public final class AppSettingsStore: ObservableObject {
    @Published public private(set) var settings: AppSettings
    @Published public var hotkeyRegistrationError: String?
    @Published public var systemSettingsError: String?

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public convenience init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("SnipClipMac", isDirectory: true)
        self.init(directoryURL: directory)
    }

    public init(directoryURL: URL) {
        fileURL = directoryURL.appendingPathComponent("settings.json")

        if let loaded = Self.load(from: fileURL, decoder: decoder) {
            settings = loaded
        } else {
            settings = AppSettings()
        }

        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    public func update(_ mutate: (inout AppSettings) -> Void) {
        var copy = settings
        mutate(&copy)
        settings = copy
        save()
    }

    public func reload() {
        if let loaded = Self.load(from: fileURL, decoder: decoder) {
            settings = loaded
        }
    }

    public func save() {
        guard let data = try? encoder.encode(settings) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func load(from url: URL, decoder: JSONDecoder) -> AppSettings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            #if DEBUG
            print("[AppSettingsStore] decode failed: \(error), falling back to defaults")
            #endif
            return nil
        }
    }
}
