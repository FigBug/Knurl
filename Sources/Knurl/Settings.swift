import Foundation

/// One of the controller slots the knob can be assigned to.
struct Slot: Codable, Equatable {
    var cc: Int            // 0...127
    var channel: Int       // 1...16
    var value: Int         // 0...127, remembered per slot
    var enabled: Bool = true

    init(cc: Int, channel: Int = 1, value: Int = 64, enabled: Bool = true) {
        self.cc = cc; self.channel = channel; self.value = value; self.enabled = enabled
    }

    // Tolerate settings saved before `enabled` existed.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cc = try c.decode(Int.self, forKey: .cc)
        channel = try c.decode(Int.self, forKey: .channel)
        value = try c.decode(Int.self, forKey: .value)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
    }
}

final class Settings {
    static let shared = Settings()

    static let slotCount = 10
    // Mod, Volume, Cutoff, Resonance, Attack, Release, Pan, Expression, Reverb, Chorus.
    private static let defaultCCs = [1, 7, 74, 71, 73, 72, 10, 11, 91, 93]

    private let key = "slots"
    private let activeKey = "activeSlot"

    private(set) var slots: [Slot]
    var activeSlot: Int {
        didSet { UserDefaults.standard.set(activeSlot, forKey: activeKey) }
    }

    private init() {
        let defaults = UserDefaults.standard
        var loaded = Settings.defaultCCs.map { Slot(cc: $0) }
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode([Slot].self, from: data) {
            for (i, slot) in saved.prefix(Settings.slotCount).enumerated() { loaded[i] = slot }
        }
        slots = loaded
        activeSlot = min(max(defaults.integer(forKey: activeKey), 0), Settings.slotCount - 1)
    }

    var enabledSlots: [Int] { slots.indices.filter { slots[$0].enabled } }

    /// Index of the next enabled slot after `index`, wrapping. Nil when none are enabled.
    func nextEnabledSlot(after index: Int) -> Int? {
        for step in 1...Settings.slotCount {
            let i = (index + step) % Settings.slotCount
            if slots[i].enabled { return i }
        }
        return nil
    }

    func update(_ index: Int, _ change: (inout Slot) -> Void) {
        var slot = slots[index]
        change(&slot)
        slot.cc = min(max(slot.cc, 0), 127)
        slot.channel = min(max(slot.channel, 1), 16)
        slot.value = min(max(slot.value, 0), 127)
        slots[index] = slot
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
