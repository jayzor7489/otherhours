// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "WorldClock",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "WorldClockCore"),
        .target(name: "WorldClockViews", dependencies: ["WorldClockCore"]),
        .executableTarget(name: "WorldClockPreview", dependencies: ["WorldClockCore", "WorldClockViews"]),
        .testTarget(name: "WorldClockCoreTests", dependencies: ["WorldClockCore"]),
    ],
    swiftLanguageModes: [.v5]
)
