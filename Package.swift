// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhisperFlow",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "WhisperBridge", targets: ["WhisperBridge"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "WhisperBridge",
            path: "Sources/WhisperBridge",
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("CoreML"),
                .linkedFramework("Metal")
            ]
        ),
        .testTarget(
            name: "WhisperFlowTests",
            dependencies: ["WhisperBridge"],
            path: "Tests/WhisperFlowTests"
        )
    ]
)
