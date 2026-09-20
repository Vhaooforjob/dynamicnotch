import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let container = DependencyContainer()
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        container.start()
        menuBarController = MenuBarController(notchController: container.notchController)
        container.notchController.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        container.stop()
    }
}
