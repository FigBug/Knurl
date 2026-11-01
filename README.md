# Knurl

A macOS menu bar app that turns a Griffin PowerMate USB knob into a ten-slot MIDI CC controller. No driver required.

Griffin's own software stopped working years ago, but the hardware is a plain USB HID device and still works fine on current macOS, including Apple Silicon. Knurl talks to it directly through IOKit and publishes a virtual MIDI port that any DAW or synth can use as an input.

## How it works

- **Spin** the knob to change the active slot's value (0–127). The blue LED brightness follows the value.
- **Tap** the knob to step to the next enabled slot. The LED blinks the slot number so you know where you are.
- The **menu bar** shows `slot · CC · value` and lists the enabled slots. Press ⌘1–⌘9 or ⌘0 to jump straight to a slot.
- **Configure Slots…** opens a window where each of the ten slots can be enabled or disabled and given a MIDI CC number and channel. Disabled slots are skipped when tapping and hidden from the menu.
- Each slot remembers its own value, so switching back to a slot picks up where you left it.

MIDI goes out on a virtual source named **Knurl**. Pick it as an input in your DAW and use MIDI Learn.

Default slots: CC 1 (Modulation), 7 (Volume), 74 (Cutoff), 71 (Resonance), 73 (Attack), 72 (Release), 10 (Pan), 11 (Expression), 91 (Reverb), 93 (Chorus), all on channel 1.

## Building

```
./build_app.sh            # release, produces bin/Knurl.app
./build_app.sh debug
```

Requires Xcode 15 or later (Swift 5.9, macOS 13 SDK). No dependencies. Local builds are ad-hoc signed, so on first launch you may need to allow the app under System Settings → Privacy & Security. Builds from the [Releases](https://github.com/FigBug/Knurl/releases) page are Developer ID signed and notarized.

## Releasing

Every push runs `ci/build.sh` on GitHub Actions, which signs and notarizes the app when the repository secrets are set and uploads the zip as a build artifact. To cut a release: bump `VERSION`, add a matching entry to `Changelist.txt`, commit, then run `./tag.sh`. The tag triggers the release workflow, which builds, notarizes and publishes a GitHub release with the changelog entry as notes.

Secrets used by the workflows: `APPLICATION` (base64 Developer ID Application .p12), `P12_PASSWORD`, `APPLE_USER` and `APPLE_PASS` (Apple ID and app-specific password for notarytool). Without them the build still succeeds but produces an ad-hoc signed app.

## Notes

- Settings are stored in UserDefaults under `com.socalabs.Knurl`.
- The LED is restored to its previous brightness when the app quits.
- Hot-plugging is supported. The menu bar reads "No PowerMate" while the knob is unplugged.
- The PowerMate's HID protocol, including the LED commands sent as an 8-byte feature report, is documented in `Sources/Knurl/PowerMate.swift`.

Griffin and PowerMate are trademarks of their respective owners. Knurl is not affiliated with Griffin Technology.

## License

MIT. See [LICENSE](LICENSE).
