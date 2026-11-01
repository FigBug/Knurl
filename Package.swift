// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Knurl",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Knurl",
            path: "Sources/Knurl",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("CoreMIDI"),
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
