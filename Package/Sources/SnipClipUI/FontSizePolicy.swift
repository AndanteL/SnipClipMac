import Foundation

public enum FontSizePolicy {
    public static let min: CGFloat = 10
    public static let max: CGFloat = 72
    public static let step: CGFloat = 2
    public static let defaultValue: CGFloat = 18

    public static func clamped(_ value: CGFloat) -> CGFloat {
        if value < min { return min }
        if value > max { return max }
        return value
    }

    public static func rounded(_ value: CGFloat) -> CGFloat {
        (value / step).rounded() * step
    }

    public static func displayText(_ value: CGFloat) -> String {
        String(format: "%.0f", clamped(value))
    }
}
