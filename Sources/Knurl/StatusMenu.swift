import AppKit

/// Menu bar item: shows "2 · CC74 · 96", lists the slots, opens settings.
final class StatusMenu: NSObject {
    private let controller: Controller
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var slotItems: [NSMenuItem] = []
    private lazy var settingsWindow = SettingsWindowController(controller: controller)

    init(controller: Controller) {
        self.controller = controller
        super.init()

        for i in 0..<Settings.slotCount {
            let mi = NSMenuItem(title: "", action: #selector(pickSlot(_:)), keyEquivalent: String((i + 1) % 10))
            mi.target = self
            mi.tag = i
            menu.addItem(mi)
            slotItems.append(mi)
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Configure Slots…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Knurl", action: #selector(quit), keyEquivalent: "q").target = self
        menu.autoenablesItems = false
        item.menu = menu

        controller.onStateChange = { [weak self] in self?.refresh() }
        refresh()
    }

    func refresh() {
        let settings = controller.settings
        for (i, mi) in slotItems.enumerated() {
            let s = settings.slots[i]
            mi.title = "Slot \(i + 1):  CC \(s.cc)  ch \(s.channel)  =  \(s.value)"
            mi.state = i == settings.activeSlot ? .on : .off
            mi.isHidden = !s.enabled
        }

        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let text: String
        if controller.powerMate.isConnected {
            let s = controller.activeSlot
            text = "\(settings.activeSlot + 1) · CC\(s.cc) · \(s.value)"
        } else {
            text = "No PowerMate"
        }
        item.button?.attributedTitle = NSAttributedString(string: text, attributes: [.font: font])
    }

    @objc private func pickSlot(_ sender: NSMenuItem) { controller.selectSlot(sender.tag) }

    @objc private func openSettings() {
        settingsWindow.window?.center()
        settingsWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
