import ApplicationServices

/// Checks if the process has Accessibility permissions.
/// If `prompt` is true, shows the system dialog to grant access.
func checkAccessibility(prompt: Bool = true) -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): prompt] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}
