import AppKit
import Foundation

public enum ImageExportFormat {
    case png
}

public enum ImageExportError: Error {
    case tiffConversionFailed
    case pngConversionFailed
}

public final class ImageExportService {
    public init() {}

    public func pngData(from image: NSImage) throws -> Data {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            throw ImageExportError.pngConversionFailed
        }
        return png
    }

    public func savePNG(_ image: NSImage, to url: URL) throws {
        let data = try pngData(from: image)
        try data.write(to: url, options: .atomic)
    }

    public func defaultFileName(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "SnipClip_\(formatter.string(from: now)).png"
    }
}
