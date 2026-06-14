import AppKit
import Carbon

public final class HotkeyService {
    public typealias Callback = () -> Void

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let callback: Callback

    public init(callback: @escaping Callback) {
        self.callback = callback
    }

    deinit {
        unregister()
    }

    public func register(keyCode: UInt32, modifiers: UInt32) -> Bool {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else { return noErr }
                let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                service.callback()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        guard status == noErr else { return false }

        let hotkeyID = EventHotKeyID(signature: 0x534E4950, id: 1) // "SNIP"
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if registerStatus != noErr {
            unregister()
            return false
        }

        return true
    }

    public func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}

public extension HotkeyService {
    static var defaultKeyCode: UInt32 { 18 } // "1"
    static var defaultModifiers: UInt32 {
        UInt32(cmdKey | shiftKey)
    }
}
