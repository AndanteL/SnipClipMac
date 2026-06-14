import AppKit
import SnipClipCore

@MainActor
final class SelectionOverlayController {
    private var windows: [SelectionOverlayWindow] = []
    private var retiredWindows: [SelectionOverlayWindow] = []
    private var keyMonitor: Any?
    private var didFinish = false

    func present(displays: [DisplayInfo], completion: @escaping (CGRect?, CGDirectDisplayID?) -> Void) {
        dismiss()
        didFinish = false

        guard !displays.isEmpty else {
            completion(nil, nil)
            return
        }

        NSApp.activate(ignoringOtherApps: true)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.finish(completion: completion, rect: nil, displayID: nil)
                return nil
            }

            return event
        }

        windows = displays.map { display in
            let window = SelectionOverlayWindow(display: display)
            window.onCancel = { [weak self] in
                self?.finish(completion: completion, rect: nil, displayID: nil)
            }
            window.onCommit = { [weak self] rect, displayID in
                self?.finish(completion: completion, rect: rect, displayID: displayID)
            }
            window.makeKeyAndOrderFront(nil)
            return window
        }
    }

    private func finish(
        completion: @escaping (CGRect?, CGDirectDisplayID?) -> Void,
        rect: CGRect?,
        displayID: CGDirectDisplayID?
    ) {
        guard !didFinish else { return }
        didFinish = true

        dismiss()

        DispatchQueue.main.async {
            completion(rect, displayID)
        }
    }

    private func dismiss() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }

        let closingWindows = windows
        windows.removeAll()
        retiredWindows.append(contentsOf: closingWindows)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            closingWindows.forEach { $0.orderOut(nil) }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.retiredWindows.removeAll { window in
                closingWindows.contains { $0 === window }
            }
        }
    }
}
