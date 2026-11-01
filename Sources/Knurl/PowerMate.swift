import Foundation
import IOKit.hid

/// Talks to a Griffin PowerMate over plain HID: knob input in, LED control out.
final class PowerMate {
    var onRotate: ((Int) -> Void)?          // signed detent delta, positive = clockwise
    var onButton: ((Bool) -> Void)?         // true = pressed
    var onConnectionChange: ((Bool) -> Void)?

    private(set) var isConnected = false

    private let manager: IOHIDManager
    private var device: IOHIDDevice?
    private let reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
    private var lastButton = false
    private var originalBrightness: UInt8 = 79   // factory idle level, used if the readback fails

    private var blinkTimer: DispatchSourceTimer?
    private var restingBrightness: UInt8 = 0

    init() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let match: [String: Any] = [kIOHIDVendorIDKey: 0x077D, kIOHIDProductIDKey: 0x0410]
        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { ctx, _, _, dev in
            Unmanaged<PowerMate>.fromOpaque(ctx!).takeUnretainedValue().attach(dev)
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { ctx, _, _, dev in
            Unmanaged<PowerMate>.fromOpaque(ctx!).takeUnretainedValue().detach(dev)
        }, context)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            NSLog("IOHIDManagerOpen failed: 0x%x", result)
        }
    }

    // MARK: Connection

    private func attach(_ dev: IOHIDDevice) {
        guard device == nil else { return }
        let result = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            NSLog("PowerMate open failed: 0x%x (Input Monitoring permission?)", result)
            return
        }
        device = dev

        var status = [UInt8](repeating: 0, count: 8)
        var length = CFIndex(status.count)
        if IOHIDDeviceGetReport(dev, kIOHIDReportTypeFeature, 0, &status, &length) == kIOReturnSuccess, length >= 6 {
            originalBrightness = status[3]
        }

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(dev, reportBuffer, 64, { ctx, _, _, _, _, report, length in
            Unmanaged<PowerMate>.fromOpaque(ctx!).takeUnretainedValue().handleReport(report, length)
        }, context)

        setPulse(awake: false)
        isConnected = true
        onConnectionChange?(true)
    }

    private func detach(_ dev: IOHIDDevice) {
        guard dev == device else { return }
        blinkTimer?.cancel(); blinkTimer = nil
        device = nil
        isConnected = false
        onConnectionChange?(false)
    }

    /// Put the LED back the way we found it. Call before quitting.
    func restore() {
        blinkTimer?.cancel(); blinkTimer = nil
        setPulse(awake: false)
        setBrightnessNow(originalBrightness)
    }

    // MARK: Input

    private func handleReport(_ report: UnsafeMutablePointer<UInt8>, _ length: CFIndex) {
        guard length >= 2 else { return }
        let pressed = report[0] & 1 != 0
        let delta = Int(Int8(bitPattern: report[1]))

        if delta != 0 { onRotate?(delta) }
        if pressed != lastButton {
            lastButton = pressed
            onButton?(pressed)
        }
    }

    // MARK: LED

    /// Steady brightness 0...255. Deferred while a blink sequence is playing.
    func setBrightness(_ level: UInt8) {
        restingBrightness = level
        if blinkTimer == nil { setBrightnessNow(level) }
    }

    /// Flash `count` times, then return to the resting brightness.
    func blink(count: Int) {
        blinkTimer?.cancel()
        guard count > 0 else { setBrightnessNow(restingBrightness); return }

        let onMs = 60, offMs = 110
        var step = 0
        let steps = count * 2
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            if step >= steps {
                self.blinkTimer?.cancel(); self.blinkTimer = nil
                self.setBrightnessNow(self.restingBrightness)
                return
            }
            let on = step % 2 == 0
            self.setBrightnessNow(on ? 255 : 0)
            step += 1
            timer.schedule(deadline: .now() + .milliseconds(on ? onMs : offMs))
        }
        blinkTimer = timer
        setBrightnessNow(0)
        timer.schedule(deadline: .now() + .milliseconds(offMs))
        timer.resume()
    }

    private func setBrightnessNow(_ level: UInt8) {
        guard let device else { return }
        var byte = level
        IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, &byte, 1)
    }

    private func setPulse(awake: Bool) {
        // Vendor setup packet carried in the 8-byte feature report:
        // bmRequestType 0x41, bRequest 0x01, wValue = command, wIndex = argument.
        sendCommand(0x03, argument: awake ? 1 : 0)
    }

    private func sendCommand(_ command: UInt8, argument: UInt16, valueHigh: UInt8 = 0) {
        guard let device else { return }
        var packet: [UInt8] = [0x41, 0x01, command, valueHigh, UInt8(argument & 0xFF), UInt8(argument >> 8), 0, 0]
        IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, 0, &packet, packet.count)
    }
}
