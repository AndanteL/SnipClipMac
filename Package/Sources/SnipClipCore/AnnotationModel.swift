import CoreGraphics
import Foundation

public enum AnnotationTool: String, CaseIterable, Codable, Equatable {
    case rectangle
    case ellipse
    case pen
    case mosaic
    case text
}

public struct AnnotationStyle: Codable, Equatable {
    public var lineWidth: CGFloat
    public var colorHex: String
    public var fontSize: CGFloat

    private enum CodingKeys: String, CodingKey {
        case lineWidth, colorHex, fontSize
    }

    public init(lineWidth: CGFloat = 2, colorHex: String = "#FF3B30", fontSize: CGFloat = 18) {
        self.lineWidth = lineWidth
        self.colorHex = colorHex
        self.fontSize = fontSize
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        fontSize = try container.decodeIfPresent(CGFloat.self, forKey: .fontSize) ?? 18
    }
}

public struct AnnotationItem: Codable, Equatable, Identifiable {
    public let id: UUID
    public var tool: AnnotationTool
    public var bounds: CGRect
    public var text: String?
    public var style: AnnotationStyle

    public init(
        id: UUID = UUID(),
        tool: AnnotationTool,
        bounds: CGRect,
        text: String? = nil,
        style: AnnotationStyle = AnnotationStyle()
    ) {
        self.id = id
        self.tool = tool
        self.bounds = bounds
        self.text = text
        self.style = style
    }
}
