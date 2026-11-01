import AppKit

/// One row per slot: enable checkbox, CC number, channel. Saved as you edit.
final class SettingsWindowController: NSWindowController, NSTextFieldDelegate {
    private let controller: Controller
    private var ccFields: [NSTextField] = []
    private var channelPopups: [NSPopUpButton] = []
    private var enableBoxes: [NSButton] = []

    init(controller: Controller) {
        self.controller = controller
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Knurl Slots"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildUI() {
        guard let content = window?.contentView else { return }
        let grid = NSGridView()
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 6
        grid.columnSpacing = 12

        grid.addRow(with: [label("Slot", bold: true), label("On", bold: true), label("CC", bold: true), label("Channel", bold: true)])

        let formatter = NumberFormatter()
        formatter.minimum = 0; formatter.maximum = 127; formatter.allowsFloats = false

        for i in 0..<Settings.slotCount {
            let slot = controller.settings.slots[i]

            let enable = NSButton(checkboxWithTitle: "", target: self, action: #selector(enableChanged(_:)))
            enable.state = slot.enabled ? .on : .off
            enable.tag = i
            enableBoxes.append(enable)

            let cc = NSTextField(string: String(slot.cc))
            cc.formatter = formatter
            cc.alignment = .right
            cc.tag = i
            cc.delegate = self
            cc.widthAnchor.constraint(equalToConstant: 56).isActive = true
            ccFields.append(cc)

            let channel = NSPopUpButton()
            channel.addItems(withTitles: (1...16).map(String.init))
            channel.selectItem(at: slot.channel - 1)
            channel.tag = i
            channel.target = self
            channel.action = #selector(channelChanged(_:))
            channelPopups.append(channel)

            grid.addRow(with: [label("\(i + 1)"), enable, cc, channel])
        }

        content.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 16),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),
            grid.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -16),
        ])
    }

    private func label(_ text: String, bold: Bool = false) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        if bold { l.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize) }
        return l
    }

    func controlTextDidChange(_ note: Notification) {
        guard let field = note.object as? NSTextField, let value = Int(field.stringValue) else { return }
        apply(field.tag) { $0.cc = value }
    }

    @objc private func channelChanged(_ sender: NSPopUpButton) {
        apply(sender.tag) { $0.channel = sender.indexOfSelectedItem + 1 }
    }

    @objc private func enableChanged(_ sender: NSButton) {
        controller.settings.update(sender.tag) { $0.enabled = sender.state == .on }
        controller.slotEnabledChanged(sender.tag)
    }

    private func apply(_ index: Int, _ change: (inout Slot) -> Void) {
        controller.settings.update(index, change)
        if index == controller.settings.activeSlot { controller.resend() }
        controller.onStateChange?()
    }
}
