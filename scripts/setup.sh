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

if [ -d "$VENDOR_DIR/whisper.xcframework" ]; then
    echo "  whisper.xcframework already exists, skipping download"
else
    echo "  Cloning whisper.cpp ${WHISPER_VERSION}..."
    mkdir -p "$VENDOR_DIR"

    if [ ! -d "$WHISPER_DIR" ]; then
        git clone --depth 1 --branch "$WHISPER_VERSION" https://github.com/ggerganov/whisper.cpp.git "$WHISPER_DIR"
    fi

    echo "  Building xcframework (this may take a few minutes)..."

    cd "$WHISPER_DIR"

    # Build for macOS arm64
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

    # Create xcframework structure manually
    FRAMEWORK_DIR="$VENDOR_DIR/whisper.xcframework/macos-arm64_x86_64"
    mkdir -p "$FRAMEWORK_DIR/Headers"
    mkdir -p "$FRAMEWORK_DIR"

    # Copy headers
    cp include/whisper.h "$FRAMEWORK_DIR/Headers/"
    cp ggml/include/ggml.h "$FRAMEWORK_DIR/Headers/" 2>/dev/null || true
    cp ggml/include/ggml-alloc.h "$FRAMEWORK_DIR/Headers/" 2>/dev/null || true
    cp ggml/include/ggml-backend.h "$FRAMEWORK_DIR/Headers/" 2>/dev/null || true

    # Copy static libraries
    cp build-macos/src/libwhisper.a "$FRAMEWORK_DIR/"
    find build-macos -name "libggml*.a" -exec cp {} "$FRAMEWORK_DIR/" \; 2>/dev/null || true

    # Create Info.plist for xcframework
    cat > "$VENDOR_DIR/whisper.xcframework/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>HeadersPath</key>
            <string>Headers</string>
            <key>LibraryIdentifier</key>
            <string>macos-arm64_x86_64</string>
            <key>LibraryPath</key>
            <string>libwhisper.a</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
                <string>x86_64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>macos</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>
PLIST

    echo "  xcframework created at $VENDOR_DIR/whisper.xcframework"

    # Cleanup
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
