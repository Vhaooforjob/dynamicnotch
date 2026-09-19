import AppKit

@MainActor
final class ShortcutManager {
    private var monitor: Any?

    func registerDefaultShortcut(action: @escaping () -> Void) {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains([.command, .shift]), event.charactersIgnoringModifiers?.lowercased() == "v" {
                Task { @MainActor in action() }
            }
        }
    }

    func unregister() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
