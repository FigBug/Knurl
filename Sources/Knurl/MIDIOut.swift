import CoreMIDI

/// A virtual MIDI source named "Knurl" that DAWs can pick as an input.
final class MIDIOut {
    private var client = MIDIClientRef()
    private var source = MIDIEndpointRef()

    init?() {
        var status = MIDIClientCreateWithBlock("Knurl" as CFString, &client) { _ in }
        guard status == noErr else { NSLog("MIDIClientCreate failed: %d", status); return nil }

        status = MIDISourceCreateWithProtocol(client, "Knurl" as CFString, ._1_0, &source)
        guard status == noErr else { NSLog("MIDISourceCreate failed: %d", status); return nil }

        // A stable unique ID lets DAWs remember the port across launches.
        MIDIObjectSetIntegerProperty(source, kMIDIPropertyUniqueID, 0x4B_4E_52_4C) // "KNRL"
    }

    deinit {
        MIDIEndpointDispose(source)
        MIDIClientDispose(client)
    }

    func sendControlChange(channel: Int, cc: Int, value: Int) {
        let status = UInt32(0xB0 | ((channel - 1) & 0x0F))
        // UMP MIDI 1.0 channel voice message, group 0.
        let word: UInt32 = (0x2 << 28) | (status << 16) | (UInt32(cc & 0x7F) << 8) | UInt32(value & 0x7F)

        var list = MIDIEventList()
        let packet = MIDIEventListInit(&list, ._1_0)
        _ = MIDIEventListAdd(&list, MemoryLayout<MIDIEventList>.size, packet, 0, 1, [word])
        MIDIReceivedEventList(source, &list)
    }
}
