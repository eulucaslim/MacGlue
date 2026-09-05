import AppKit
import Carbon.HIToolbox

@MainActor
final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let onPress: () -> Void

    init(onPress: @escaping () -> Void) {
        self.onPress = onPress
        register()
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func register() {
        let hotKeyID = EventHotKeyID(
            signature: OSType(0x4D_47_4C_55),
            id: 1
        )
        let keyCode = UInt32(kVK_ANSI_V)
        let modifiers = UInt32(cmdKey | shiftKey)

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else {
                    return noErr
                }
                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                hotKey.onPress()
                return noErr
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }
}
