#!/bin/bash
set -euo pipefail

# WhisperFlow Setup Script
# Downloads whisper.cpp xcframework and generates the Xcode project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENDOR_DIR="$PROJECT_DIR/Vendor"

echo "=== WhisperFlow Setup ==="
echo ""

# Step 1: Download whisper.cpp xcframework
echo "Step 1: Setting up whisper.cpp..."

WHISPER_VERSION="v1.7.4"
WHISPER_DIR="$VENDOR_DIR/whisper.cpp"

if [ -d "$VENDOR_DIR/whisper.xcframework" ] && [ -d "$VENDOR_DIR/whisper.xcframework/ios-arm64" ]; then
    echo "  whisper.xcframework (macOS + iOS) already exists, skipping build"
else
    echo "  Cloning whisper.cpp ${WHISPER_VERSION}..."
    mkdir -p "$VENDOR_DIR"

    if [ ! -d "$WHISPER_DIR" ]; then
        git clone --depth 1 --branch "$WHISPER_VERSION" https://github.com/ggerganov/whisper.cpp.git "$WHISPER_DIR"
    fi

    echo "  Building xcframework (this may take a few minutes)..."

    cd "$WHISPER_DIR"

    # =============================================
    # Build for macOS (arm64 + x86_64)
    # =============================================
    echo "  Building for macOS..."
    mkdir -p build-macos
    cd build-macos
    cmake .. \
        -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
        -DWHISPER_METAL=ON \
        -DWHISPER_COREML=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build . --config Release -j$(sysctl -n hw.ncpu)
    cd ..

    # =============================================
    # Build for iOS (arm64 only)
    # =============================================
    echo "  Building for iOS..."
    mkdir -p build-ios
    cd build-ios
    cmake .. \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_ARCHITECTURES="arm64" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
        -DWHISPER_METAL=ON \
        -DWHISPER_COREML=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build . --config Release -j$(sysctl -n hw.ncpu)
    cd ..

    # =============================================
    # Build for iOS Simulator (arm64 + x86_64)
    # =============================================
    echo "  Building for iOS Simulator..."
    mkdir -p build-ios-sim
    cd build-ios-sim
    cmake .. \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT=iphonesimulator \
        -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
        -DWHISPER_METAL=ON \
        -DWHISPER_COREML=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build . --config Release -j$(sysctl -n hw.ncpu)
    cd ..

    # =============================================
    # Create xcframework structure
    # =============================================
    echo "  Creating multi-platform xcframework..."

    # Remove old xcframework if it exists (may be macOS-only)
    rm -rf "$VENDOR_DIR/whisper.xcframework"

    # Prepare header directory
    HEADERS_DIR="$WHISPER_DIR/xcframework-headers"
    mkdir -p "$HEADERS_DIR"
    cp include/whisper.h "$HEADERS_DIR/"
    cp ggml/include/ggml.h "$HEADERS_DIR/" 2>/dev/null || true
    cp ggml/include/ggml-alloc.h "$HEADERS_DIR/" 2>/dev/null || true
    cp ggml/include/ggml-backend.h "$HEADERS_DIR/" 2>/dev/null || true

    # Collect all static libs for each platform into a single combined .a
    # macOS
    MACOS_LIBS_DIR="$WHISPER_DIR/build-macos-combined"
    mkdir -p "$MACOS_LIBS_DIR"
    cp build-macos/src/libwhisper.a "$MACOS_LIBS_DIR/" 2>/dev/null || true
    find build-macos -name "libggml*.a" -exec cp {} "$MACOS_LIBS_DIR/" \; 2>/dev/null || true
    libtool -static -o "$MACOS_LIBS_DIR/libwhisper-combined.a" "$MACOS_LIBS_DIR"/*.a

    # iOS
    IOS_LIBS_DIR="$WHISPER_DIR/build-ios-combined"
    mkdir -p "$IOS_LIBS_DIR"
    cp build-ios/src/libwhisper.a "$IOS_LIBS_DIR/" 2>/dev/null || true
    find build-ios -name "libggml*.a" -exec cp {} "$IOS_LIBS_DIR/" \; 2>/dev/null || true
    libtool -static -o "$IOS_LIBS_DIR/libwhisper-combined.a" "$IOS_LIBS_DIR"/*.a

    # iOS Simulator
    IOS_SIM_LIBS_DIR="$WHISPER_DIR/build-ios-sim-combined"
    mkdir -p "$IOS_SIM_LIBS_DIR"
    cp build-ios-sim/src/libwhisper.a "$IOS_SIM_LIBS_DIR/" 2>/dev/null || true
    find build-ios-sim -name "libggml*.a" -exec cp {} "$IOS_SIM_LIBS_DIR/" \; 2>/dev/null || true
    libtool -static -o "$IOS_SIM_LIBS_DIR/libwhisper-combined.a" "$IOS_SIM_LIBS_DIR"/*.a

    # Create xcframework with all three platform slices
    xcodebuild -create-xcframework \
        -library "$MACOS_LIBS_DIR/libwhisper-combined.a" -headers "$HEADERS_DIR" \
        -library "$IOS_LIBS_DIR/libwhisper-combined.a" -headers "$HEADERS_DIR" \
        -library "$IOS_SIM_LIBS_DIR/libwhisper-combined.a" -headers "$HEADERS_DIR" \
        -output "$VENDOR_DIR/whisper.xcframework"

    echo "  xcframework created at $VENDOR_DIR/whisper.xcframework"

    # Also copy individual ggml libs for targets that link them separately
    # macOS slice
    MACOS_FRAMEWORK_DIR="$VENDOR_DIR/whisper.xcframework/macos-arm64_x86_64"
    find build-macos -name "libggml*.a" -exec cp {} "$MACOS_FRAMEWORK_DIR/" \; 2>/dev/null || true
    cp build-macos/src/libwhisper.a "$MACOS_FRAMEWORK_DIR/" 2>/dev/null || true

    # iOS slice
    IOS_FRAMEWORK_DIR=$(find "$VENDOR_DIR/whisper.xcframework" -type d -name "ios-arm64" 2>/dev/null | head -1)
    if [ -n "$IOS_FRAMEWORK_DIR" ]; then
        find build-ios -name "libggml*.a" -exec cp {} "$IOS_FRAMEWORK_DIR/" \; 2>/dev/null || true
        cp build-ios/src/libwhisper.a "$IOS_FRAMEWORK_DIR/" 2>/dev/null || true
    fi

    # iOS Simulator slice
    IOS_SIM_FRAMEWORK_DIR=$(find "$VENDOR_DIR/whisper.xcframework" -type d -name "ios-arm64_x86_64-simulator" 2>/dev/null | head -1)
    if [ -n "$IOS_SIM_FRAMEWORK_DIR" ]; then
        find build-ios-sim -name "libggml*.a" -exec cp {} "$IOS_SIM_FRAMEWORK_DIR/" \; 2>/dev/null || true
        cp build-ios-sim/src/libwhisper.a "$IOS_SIM_FRAMEWORK_DIR/" 2>/dev/null || true
    fi

    # Cleanup build artifacts
    rm -rf "$WHISPER_DIR"
fi

# Step 2: Generate Xcode project (if xcodegen is available)
echo ""
echo "Step 2: Generating Xcode project..."

if command -v xcodegen &> /dev/null; then
    cd "$PROJECT_DIR"
    xcodegen generate
    echo "  Xcode project generated"
else
    echo "  xcodegen not found. Install with: brew install xcodegen"
    echo "  Or open Package.swift in Xcode to use SPM directly."
fi

# Step 3: Download a test model
echo ""
echo "Step 3: Downloading test model..."

MODELS_DIR="$HOME/Library/Application Support/WhisperFlow/Models"
MODEL_FILE="$MODELS_DIR/ggml-tiny.bin"

if [ -f "$MODEL_FILE" ]; then
    echo "  Tiny model already exists, skipping download"
else
    mkdir -p "$MODELS_DIR"
    echo "  Downloading ggml-tiny.bin (75 MB)..."
    curl -L -o "$MODEL_FILE" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin" \
        --progress-bar
    echo "  Model downloaded to $MODEL_FILE"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Open WhisperFlow.xcodeproj in Xcode (or Package.swift for SPM)"
echo "  2. Build and run (Cmd+R)"
echo "  3. Grant Microphone and Accessibility permissions when prompted"
echo "  4. Press Cmd+Shift+Space to start recording"
echo ""
echo "For iOS development:"
echo "  - Select the WhisperFlowiOS scheme in Xcode"
echo "  - Build and run on a physical device for full audio/Metal support"
echo "  - Enable the WhisperFlow keyboard in Settings > General > Keyboard > Keyboards"
