import Foundation

struct DockApp {
    let bundleIdentifier: String
    let label: String
}

enum DockReaderError: Error, CustomStringConvertible {
    case plistNotFound
    case noPersistentApps

    var description: String {
        switch self {
        case .plistNotFound:
            return "Could not read ~/Library/Preferences/com.apple.dock.plist"
        case .noPersistentApps:
            return "No pinned apps found in the Dock"
        }
    }
}

func readDockApps() throws -> [DockApp] {
    guard let dockDefaults = UserDefaults(suiteName: "com.apple.dock") else {
        throw DockReaderError.plistNotFound
    }

    guard let persistentApps = dockDefaults.array(forKey: "persistent-apps") as? [[String: Any]],
          !persistentApps.isEmpty else {
        throw DockReaderError.noPersistentApps
    }

    return persistentApps.compactMap { entry in
        guard let tileData = entry["tile-data"] as? [String: Any],
              let bundleId = tileData["bundle-identifier"] as? String else {
            return nil
        }
        let label = tileData["file-label"] as? String ?? bundleId
        return DockApp(bundleIdentifier: bundleId, label: label)
    }
}
