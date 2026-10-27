// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "WorldClock",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "WorldClockCore"),
        .testTarget(name: "WorldClockCoreTests", dependencies: ["WorldClockCore"]),
    ],
    swiftLanguageModes: [.v5]
)
