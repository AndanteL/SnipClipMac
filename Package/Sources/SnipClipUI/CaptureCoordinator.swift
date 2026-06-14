import AppKit
import SnipClipCore

@MainActor
public final class CaptureCoordinator {
    private let permissionController: ScreenshotPermissionController
    private let screenInfoProvider: ScreenInfoProvider
    private let captureSession = CaptureSession()
    private let selectionOverlayController = SelectionOverlayController()
    private let captureService = ScreenCaptureService()
    private let settingsStore: AppSettingsStore
    private var editorWindows: [AnnotationEditorWindow] = []
    private var pinnedControllers: [PinnedImageWindowController] = []

    public var onImageCaptured: ((NSImage) -> Void)?

    public init(
        permissionController: ScreenshotPermissionController,
        screenInfoProvider: ScreenInfoProvider,
        settingsStore: AppSettingsStore
    ) {
        self.permissionController = permissionController
        self.screenInfoProvider = screenInfoProvider
        self.settingsStore = settingsStore
    }

    public func beginCapture() {
        guard permissionController.requestIfNeeded() else {
            permissionController.openPrivacyPane()
            return
        }

        captureSession.beginSelection()
        selectionOverlayController.present(displays: screenInfoProvider.allDisplays()) { [weak self] rect, displayID in
            guard let self else { return }
            if let rect, let displayID {
                self.performCapture(rect: rect, displayID: displayID)
            } else {
                self.captureSession.cancel()
            }
        }
    }

    private func performCapture(rect: CGRect, displayID: CGDirectDisplayID) {
        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 200_000_000)
            do {
                let image = try await self.captureService.capture(rect: rect, displayID: displayID)
                self.captureSession.finishSelection(rect: rect, displayID: displayID, image: image)
                self.onImageCaptured?(image)

                let settings = self.settingsStore.settings

                if settings.copyAfterCapture {
                    let pasteboard = PasteboardService()
                    try? pasteboard.copyPNG(image)
                }

                if settings.openEditorAfterCapture {
                    self.openEditor(with: image, style: settings.defaultAnnotationStyle)
                }
            } catch {
                self.captureSession.cancel()
            }
        }
    }

    private func openEditor(with image: NSImage, style: AnnotationStyle) {
        let window = AnnotationEditorWindow(
            image: image,
            style: style,
            saveDirectoryBookmark: settingsStore.settings.defaultSaveDirectoryBookmark,
            saveDirectoryPath: settingsStore.settings.defaultSaveDirectoryPath,
            closeEditorAfterSave: settingsStore.settings.closeEditorAfterSave
        )
        window.onPin = { [weak self] controller in
            controller.onClose = { [weak self, weak controller] in
                guard let controller else { return }
                self?.pinnedControllers.removeAll { $0 === controller }
            }
            self?.pinnedControllers.append(controller)
        }
        window.onClose = { [weak self, weak window] in
            guard let window else { return }
            self?.editorWindows.removeAll { $0 === window }
        }
        editorWindows.removeAll { !$0.isVisible }
        editorWindows.append(window)
    }
}
