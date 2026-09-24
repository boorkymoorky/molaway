// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "Molaway",
    platforms: [.macOS("15.0")],
    products: [.executable(name: "Molaway", targets: ["Offscreen"])],
    targets: [
        .executableTarget(name: "Offscreen", path: "Sources/Offscreen",
            swiftSettings: [.defaultIsolation(MainActor.self)]),
        .testTarget(name: "OffscreenTests", dependencies: ["Offscreen"],
            path: "Tests/OffscreenTests", swiftSettings: [.defaultIsolation(MainActor.self)])
    ]
)
