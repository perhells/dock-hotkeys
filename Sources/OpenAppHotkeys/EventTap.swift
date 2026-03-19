import CoreGraphics
import Foundation

enum EventTapError: Error, CustomStringConvertible {
    case creationFailed

    var description: String {
        switch self {
        case .creationFailed:
            return "Failed to create event tap. Ensure Accessibility permission is granted in System Settings > Privacy & Security > Accessibility."
        }
    }
}

final class EventTapManager {
    let matcher: HotkeyMatcher
    let launcher: AppLauncher
    private var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var healthTimer: DispatchSourceTimer?

    init(matcher: HotkeyMatcher, launcher: AppLauncher) {
        self.matcher = matcher
        self.launcher = launcher
    }

    func start() throws {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: userInfo
        ) else {
            throw EventTapError.creationFailed
        }

        machPort = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        startHealthTimer()
    }

    func stop() {
        stopHealthTimer()
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
        if let port = machPort {
            CGEvent.tapEnable(tap: port, enable: false)
            CFMachPortInvalidate(port)
            machPort = nil
        }
    }

    /// Periodically checks that the event tap is still enabled and that
    /// Accessibility permission hasn't been revoked.
    private func startHealthTimer() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 5, repeating: 5)
        timer.setEventHandler { [weak self] in
            self?.checkHealth()
        }
        timer.resume()
        healthTimer = timer
    }

    private func stopHealthTimer() {
        healthTimer?.cancel()
        healthTimer = nil
    }

    private func checkHealth() {
        guard let port = machPort else { return }

        if !checkAccessibility(prompt: false) {
            fputs("Accessibility permission was revoked. Hotkeys are disabled.\n", stderr)
            return
        }

        if !CGEvent.tapIsEnabled(tap: port) {
            fputs("Event tap was disabled, re-enabling...\n", stderr)
            CGEvent.tapEnable(tap: port, enable: true)
        }
    }

    /// Re-enables the tap after macOS disables it due to timeout.
    fileprivate func reenable() {
        if let port = machPort {
            CGEvent.tapEnable(tap: port, enable: true)
        }
    }

    deinit {
        stop()
    }
}

/// C-compatible callback — no captures allowed.
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let manager = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()

    // Handle tap being disabled by the system
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        manager.reenable()
        return Unmanaged.passUnretained(event)
    }

    guard type == .keyDown else {
        return Unmanaged.passUnretained(event)
    }

    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    let flags = event.flags

    if let app = manager.matcher.match(keyCode: keyCode, flags: flags) {
        manager.launcher.open(app: app)
        return nil // Suppress the event
    }

    return Unmanaged.passUnretained(event)
}
