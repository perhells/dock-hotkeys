import AppKit
import UserNotifications

final class AppLauncher {
    private let debounceInterval: TimeInterval = 0.3
    private var lastLaunch: [String: Date] = [:]
    private let queue = DispatchQueue(label: "AppLauncher.debounce")

    /// Opens an application by bundle identifier or absolute path.
    /// Dispatched asynchronously to avoid blocking the event tap callback.
    func open(app: String) {
        // Debounce rapid launches of the same app
        let now = Date()
        let shouldLaunch: Bool = queue.sync {
            if let last = lastLaunch[app], now.timeIntervalSince(last) < debounceInterval {
                return false
            }
            lastLaunch[app] = now
            return true
        }
        guard shouldLaunch else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let url: URL?

            if app.hasPrefix("/") {
                url = URL(fileURLWithPath: app)
            } else {
                url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app)
            }

            guard let appURL = url else {
                fputs("Warning: Could not resolve app '\(app)'\n", stderr)
                Self.postNotification(title: "OpenAppHotkeys", body: "Could not find app: \(app)")
                return
            }

            NSWorkspace.shared.openApplication(
                at: appURL,
                configuration: NSWorkspace.OpenConfiguration()
            ) { _, error in
                if let error {
                    fputs("Warning: Failed to open '\(app)': \(error.localizedDescription)\n", stderr)
                    Self.postNotification(title: "OpenAppHotkeys", body: "Failed to open \(app): \(error.localizedDescription)")
                }
            }
        }
    }

    private static func postNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else {
                fputs("Warning: Notification permission not granted, cannot show alert.\n", stderr)
                return
            }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    }
}
