import AppKit

@MainActor
final class ShortcutManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func registerDefaultShortcut(action: @escaping () -> Void) {
        unregister()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard Self.isDefaultShortcut(event) else { return }
            Task { @MainActor in action() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard Self.isDefaultShortcut(event) else { return event }
            Task { @MainActor in action() }
            return nil
        }
    }

    func unregister() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    private static func isDefaultShortcut(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags == [.command, .shift]
            && event.charactersIgnoringModifiers?.lowercased() == "v"
    }
}
