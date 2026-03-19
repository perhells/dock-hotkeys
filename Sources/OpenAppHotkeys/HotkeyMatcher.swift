import CoreGraphics

struct Hotkey {
    let keyCode: UInt16
    let modifiers: CGEventFlags
    let app: String
}

final class HotkeyMatcher {
    private var hotkeys: [Hotkey]

    /// Modifier flags we compare against. Other bits in CGEventFlags
    /// (e.g. maskNumericPad, maskNonCoalesced) are ignored.
    private static let relevantModifiers: CGEventFlags = [
        .maskCommand, .maskShift, .maskAlternate, .maskControl, .maskSecondaryFn,
    ]

    init(hotkeys: [Hotkey]) {
        self.hotkeys = hotkeys
    }

    /// Replaces the current hotkeys with a new set.
    func updateHotkeys(_ newHotkeys: [Hotkey]) {
        hotkeys = newHotkeys
    }

    /// Returns the app identifier if the key event matches a configured hotkey.
    func match(keyCode: UInt16, flags: CGEventFlags) -> String? {
        let masked = flags.intersection(Self.relevantModifiers)

        for hotkey in hotkeys {
            if hotkey.keyCode == keyCode && hotkey.modifiers == masked {
                return hotkey.app
            }
        }
        return nil
    }
}
