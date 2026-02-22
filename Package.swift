// swift-tools-version: 5.9
import PackageDescription

let vendorLibPath = "Vendor/whisper.xcframework/macos-arm64_x86_64"

let package = Package(
    name: "WhisperFlow",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        // C bridge module that wraps whisper.cpp headers
        .target(
            name: "WhisperBridge",
            path: "Sources/WhisperBridge",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                .unsafeFlags(["-L\(vendorLibPath)"]),
                .linkedLibrary("whisper"),
                .linkedLibrary("ggml"),
                .linkedLibrary("ggml-base"),
                .linkedLibrary("ggml-cpu"),
                .linkedLibrary("ggml-metal"),
                .linkedLibrary("ggml-blas"),
                .linkedLibrary("c++"),
                .linkedFramework("Accelerate"),
                .linkedFramework("CoreML"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("Foundation"),
            ]
        ),
        // Main macOS app
        .executableTarget(
            name: "WhisperFlow",
            dependencies: ["WhisperBridge"],
            path: "Sources/WhisperFlow",
            exclude: ["Resources/Info.plist", "Resources/WhisperFlow.entitlements"],
            swiftSettings: [
                .define("SPM_BUILD")
            ],
            linkerSettings: [
                .unsafeFlags(["-L\(vendorLibPath)"]),
                .linkedLibrary("whisper"),
                .linkedLibrary("ggml"),
                .linkedLibrary("ggml-base"),
                .linkedLibrary("ggml-cpu"),
                .linkedLibrary("ggml-metal"),
                .linkedLibrary("ggml-blas"),
                .linkedLibrary("c++"),
                .linkedFramework("Accelerate"),
                .linkedFramework("CoreML"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "WhisperFlowTests",
            dependencies: ["WhisperBridge"],
            path: "Tests/WhisperFlowTests"
        )
    ]
)
