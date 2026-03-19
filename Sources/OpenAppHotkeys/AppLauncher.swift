import AppKit

final class AppLauncher {
    /// Opens an application by bundle identifier or absolute path.
    /// Dispatched asynchronously to avoid blocking the event tap callback.
    func open(app: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let url: URL?

            if app.hasPrefix("/") {
                // Absolute path
                url = URL(fileURLWithPath: app)
            } else {
                // Assume bundle identifier
                url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app)
            }

            guard let appURL = url else {
                fputs("Warning: Could not resolve app '\(app)'\n", stderr)
                return
            }

            NSWorkspace.shared.openApplication(
                at: appURL,
                configuration: NSWorkspace.OpenConfiguration()
            ) { _, error in
                if let error {
                    fputs("Warning: Failed to open '\(app)': \(error.localizedDescription)\n", stderr)
                }
            }
        }
    }
}
