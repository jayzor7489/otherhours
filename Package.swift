// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "WorldClock",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "WorldClockCore"),
        .target(name: "WorldClockViews", dependencies: ["WorldClockCore"]),
        // The setting's type. The module name is part of the name macOS stores it under, so it
        // stays "WorldClockWidget" even though the extension's own module is not called that.
        .target(name: "WorldClockWidget", swiftSettings: [.unsafeFlags(["-application-extension"])]),
        // Linked as an app extension: without -e _NSExtensionMain the process starts at Swift main,
        // traps or exits before handshaking, and the widget never appears (vibes #42, Khayt #1902).
        // build.sh copies this product into the .appex as WorldClockWidget.
        .executableTarget(
            name: "WorldClockExtension",
            dependencies: ["WorldClockCore", "WorldClockViews", "WorldClockWidget"],
            swiftSettings: [.unsafeFlags(["-application-extension"])],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-application_extension", "-Xlinker", "-e", "-Xlinker", "_NSExtensionMain"])]
        ),
        .executableTarget(name: "WorldClock", dependencies: ["WorldClockCore", "WorldClockViews", "WorldClockWidget"]),
        .executableTarget(name: "WorldClockPreview", dependencies: ["WorldClockCore", "WorldClockViews"]),
        .testTarget(name: "WorldClockCoreTests", dependencies: ["WorldClockCore"]),
    ],
    swiftLanguageModes: [.v5]
)
