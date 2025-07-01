#!/bin/bash

# Build script for agenda CLI tool
# Builds for different macOS architectures and creates release artifacts

set -e

PROJECT_NAME="agenda"
VERSION=${1:-"dev"}
BUILD_DIR="build"
RELEASE_DIR="releases"

echo "🔨 Building $PROJECT_NAME version $VERSION"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build
rm -rf $BUILD_DIR
rm -rf $RELEASE_DIR
mkdir -p $BUILD_DIR
mkdir -p $RELEASE_DIR

# Build for Apple Silicon (arm64)
echo "🍎 Building for Apple Silicon (arm64)..."
swift build -c release --arch arm64
cp .build/arm64-apple-macosx/release/$PROJECT_NAME $BUILD_DIR/${PROJECT_NAME}-arm64

# Build for Intel (x86_64)
echo "💻 Building for Intel (x86_64)..."
swift build -c release --arch x86_64
cp .build/x86_64-apple-macosx/release/$PROJECT_NAME $BUILD_DIR/${PROJECT_NAME}-x86_64

# Create universal binary
echo "🔗 Creating universal binary..."
lipo -create \
    $BUILD_DIR/${PROJECT_NAME}-arm64 \
    $BUILD_DIR/${PROJECT_NAME}-x86_64 \
    -output $BUILD_DIR/${PROJECT_NAME}-universal

echo "✅ Verifying universal binary..."
lipo -info $BUILD_DIR/${PROJECT_NAME}-universal

# Create release packages
echo "📦 Creating release packages..."

# Individual architecture releases
cp $BUILD_DIR/${PROJECT_NAME}-arm64 $RELEASE_DIR/${PROJECT_NAME}-${VERSION}-macos-arm64
cp $BUILD_DIR/${PROJECT_NAME}-x86_64 $RELEASE_DIR/${PROJECT_NAME}-${VERSION}-macos-x86_64
cp $BUILD_DIR/${PROJECT_NAME}-universal $RELEASE_DIR/${PROJECT_NAME}-${VERSION}-macos-universal

# Make all binaries executable
chmod +x $RELEASE_DIR/*

# Create checksums
echo "🔐 Creating checksums..."
cd $RELEASE_DIR
shasum -a 256 * > checksums.txt
cd ..

echo "🎉 Build complete!"
echo ""
echo "Release artifacts created in $RELEASE_DIR/:"
ls -la $RELEASE_DIR/
echo ""
echo "Usage examples:"
echo "  ./releases/${PROJECT_NAME}-${VERSION}-macos-universal --date today"
echo "  ./releases/${PROJECT_NAME}-${VERSION}-macos-arm64 --date today"
echo "  ./releases/${PROJECT_NAME}-${VERSION}-macos-x86_64 --date today"
echo ""
echo "To install system-wide:"
echo "  cp ./releases/${PROJECT_NAME}-${VERSION}-macos-universal /usr/local/bin/$PROJECT_NAME"
