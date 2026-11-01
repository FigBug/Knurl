import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: Controller!
    private var statusMenu: StatusMenu!

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = Controller()
        statusMenu = StatusMenu(controller: controller)
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.powerMate.restore()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
