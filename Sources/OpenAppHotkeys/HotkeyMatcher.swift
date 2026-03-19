import CoreGraphics
import os

struct Hotkey {
    let keyCode: UInt16
    let modifiers: CGEventFlags
    let app: String
}

final class HotkeyMatcher {
    private let lock: OSAllocatedUnfairLock<[Hotkey]>

    /// Modifier flags we compare against. Other bits in CGEventFlags
    /// (e.g. maskNumericPad, maskNonCoalesced) are ignored.
    private static let relevantModifiers: CGEventFlags = [
        .maskCommand, .maskShift, .maskAlternate, .maskControl, .maskSecondaryFn,
    ]

    init(hotkeys: [Hotkey]) {
        lock = OSAllocatedUnfairLock(initialState: hotkeys)
    }

    /// Replaces the current hotkeys with a new set.
    func updateHotkeys(_ newHotkeys: [Hotkey]) {
        lock.withLock { $0 = newHotkeys }
    }

    /// Returns the app identifier if the key event matches a configured hotkey.
    func match(keyCode: UInt16, flags: CGEventFlags) -> String? {
        let snapshot = lock.withLock { $0 }
        let masked = flags.intersection(Self.relevantModifiers)

        for hotkey in snapshot {
            if hotkey.keyCode == keyCode && hotkey.modifiers == masked {
                return hotkey.app
            }
        }
        return nil
    }
}
