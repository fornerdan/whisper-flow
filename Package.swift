// swift-tools-version: 5.9
import PackageDescription

let vendorLibPath = "Vendor/whisper.xcframework/macos-arm64_x86_64"

let package = Package(
    name: "WhisperFlow",
    platforms: [
        .macOS(.v14),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WhisperCore",
            targets: ["WhisperCore"]
        )
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
        // Shared core library (macOS + iOS)
        .target(
            name: "WhisperCore",
            dependencies: ["WhisperBridge"],
            path: "Sources/WhisperCore",
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
            ]
        ),
        // Main macOS app
        .executableTarget(
            name: "WhisperFlow",
            dependencies: ["WhisperCore", "WhisperBridge"],
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
