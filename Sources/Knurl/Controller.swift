import Foundation

/// Glue: knob gestures -> slot state -> MIDI + LED + menu bar.
final class Controller {
    let powerMate = PowerMate()
    let midi: MIDIOut?
    let settings = Settings.shared

    var onStateChange: (() -> Void)?

    private var rotatedWhileHeld = false

    init() {
        midi = MIDIOut()

        powerMate.onConnectionChange = { [weak self] connected in
            guard let self else { return }
            if connected { self.showValueOnLED() }
            self.onStateChange?()
        }
        powerMate.onRotate = { [weak self] delta in self?.rotate(delta) }
        powerMate.onButton = { [weak self] pressed in self?.button(pressed) }
    }

    var activeSlot: Slot { settings.slots[settings.activeSlot] }

    func selectSlot(_ index: Int) {
        settings.activeSlot = index
        powerMate.blink(count: index + 1)
        showValueOnLED()
        onStateChange?()
    }

    /// Called after a slot's enabled flag changes: leave a slot that was just disabled.
    func slotEnabledChanged(_ index: Int) {
        if index == settings.activeSlot, !activeSlot.enabled,
           let next = settings.nextEnabledSlot(after: index) {
            selectSlot(next)
        } else {
            onStateChange?()
        }
    }

    /// Re-send the current value, e.g. after the CC number was edited.
    func resend() {
        let slot = activeSlot
        midi?.sendControlChange(channel: slot.channel, cc: slot.cc, value: slot.value)
    }

    private func rotate(_ delta: Int) {
        rotatedWhileHeld = true
        let index = settings.activeSlot
        let old = settings.slots[index].value
        settings.update(index) { $0.value += delta }
        let slot = settings.slots[index]
        guard slot.value != old else { return }
        midi?.sendControlChange(channel: slot.channel, cc: slot.cc, value: slot.value)
        showValueOnLED()
        onStateChange?()
    }

    private func button(_ pressed: Bool) {
        if pressed {
            rotatedWhileHeld = false
        } else if !rotatedWhileHeld {
            // A tap (press and release without turning) steps to the next enabled slot.
            if let next = settings.nextEnabledSlot(after: settings.activeSlot) {
                selectSlot(next)
            }
        }
    }

    private func showValueOnLED() {
        powerMate.setBrightness(UInt8(min(activeSlot.value * 2, 255)))
    }
}
