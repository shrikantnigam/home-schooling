// swift-tools-version:5.9
// KingdomCore holds every rule of the app that does not need a screen:
// content, mastery, progression, warm-ups, time limits and the parent gate.
// It builds and tests with `swift test` on macOS or Linux. The SwiftUI app
// in App/ depends on it as a local package.
import PackageDescription

let package = Package(
    name: "KingdomCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KingdomCore", targets: ["KingdomCore"]),
    ],
    targets: [
        .target(
            name: "KingdomCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "KingdomCoreTests",
            dependencies: ["KingdomCore"],
            // Old save files, read by path in SaveSafetyTests.
            exclude: ["Fixtures"]
        ),
    ]
)
