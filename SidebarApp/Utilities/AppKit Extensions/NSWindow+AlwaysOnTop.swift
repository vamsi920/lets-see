import AppKit
import Carbon.HIToolbox
import Foundation

final class GlobalHotKeyMonitor {
    private static let signature: OSType = 0x4C545331

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let handler: () -> Void

    init(
        keyCode: UInt32 = UInt32(kVK_Space),
        modifiers: UInt32 = UInt32(optionKey) | UInt32(cmdKey),
        handler: @escaping () -> Void
    ) {
        self.handler = handler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let monitor = Unmanaged<GlobalHotKeyMonitor>.fromOpaque(userData).takeUnretainedValue()
                return monitor.handlePressedEvent()
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    private func handlePressedEvent() -> OSStatus {
        DispatchQueue.main.async {
            self.handler()
        }

        return noErr
    }
}

extension NSWindow {
    var alwaysOnTop: Bool {
        get {
            level.rawValue >= Int(CGWindowLevelForKey(.statusWindow))
        }
        set {
            level = newValue
                ? NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)))
                : NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.normalWindow)))
        }
    }
}
