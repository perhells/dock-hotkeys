import CoreServices
import Foundation

enum DockWatcherError: Error, CustomStringConvertible {
    case streamCreationFailed

    var description: String {
        switch self {
        case .streamCreationFailed:
            return "Could not create FSEvent stream for Dock monitoring."
        }
    }
}

final class DockWatcher {
    private let matcher: HotkeyMatcher
    private var stream: FSEventStreamRef?
    private var debounceWork: DispatchWorkItem?

    /// Debounce interval — the Dock may write the plist multiple
    /// times in quick succession when apps are rearranged.
    private static let debounceInterval: DispatchTimeInterval = .seconds(1)

    /// Called after a successful reload with the new dock apps and hotkeys.
    var onReload: (([DockApp], [Hotkey]) -> Void)?

    init(matcher: HotkeyMatcher) {
        self.matcher = matcher
    }

    func stop() {
        debounceWork?.cancel()
        debounceWork = nil
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    deinit {
        stop()
    }

    func start() throws {
        let dockPlistDir = (NSHomeDirectory() + "/Library/Preferences") as CFString
        let pathsToWatch = [dockPlistDir] as CFArray

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            fsEventCallback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0, // latency — we handle debouncing ourselves
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        ) else {
            throw DockWatcherError.streamCreationFailed
        }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
        print("Watching Dock for changes...")
    }

    fileprivate func handleDockChange() {
        debounceWork?.cancel()

        let work = DispatchWorkItem { [weak self] in
            self?.reload()
        }
        debounceWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.debounceInterval, execute: work)
    }

    private func reload() {
        do {
            let dockApps = try readDockApps()
            let hotkeys = buildHotkeys(from: dockApps)
            matcher.updateHotkeys(hotkeys)
            onReload?(dockApps, hotkeys)

            let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
            print("Dock changed — reloaded \(hotkeys.count) hotkey(s):")
            for (i, hk) in hotkeys.enumerated() {
                guard i < dockApps.count else { break }
                let label = dockApps[i].label
                print("  Ctrl+\(keys[i]) → \(label) (\(hk.app))")
            }
        } catch {
            fputs("Dock reload error: \(error)\n", stderr)
        }
    }
}

/// C-compatible FSEvents callback.
private func fsEventCallback(
    stream: ConstFSEventStreamRef,
    clientInfo: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let clientInfo else { return }
    let watcher = Unmanaged<DockWatcher>.fromOpaque(clientInfo).takeUnretainedValue()

    let cfArray = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue()
    guard let paths = cfArray as? [String] else { return }
    for path in paths {
        if path.hasSuffix("com.apple.dock.plist") {
            watcher.handleDockChange()
            return
        }
    }
}
