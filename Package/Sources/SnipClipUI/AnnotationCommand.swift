import SnipClipCore
import Foundation

public enum AnnotationCommand: Equatable {
    case add(AnnotationItem)
    case remove(UUID)
    case update(AnnotationItem)
}
