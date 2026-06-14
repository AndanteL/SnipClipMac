import AppKit
import Foundation

public enum PasteboardError: Error {
    case pngConversionFailed
}

public final class PasteboardService {
    private let exportService: ImageExportService

    public init(exportService: ImageExportService = ImageExportService()) {
        self.exportService = exportService
    }

    public func copyPNG(_ image: NSImage) throws {
        let pngData = try exportService.pngData(from: image)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.setData(pngData, forType: .png) else {
            throw PasteboardError.pngConversionFailed
        }
    }
}
