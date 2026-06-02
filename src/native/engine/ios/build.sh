#!/bin/bash

set -e

TARGET="aarch64-apple-ios"
CRYSTAL_SRC="bridge.cr"
OUTPUT_LIB="libnative_cr_ios.a"
METAL_SHADER="Shaders.metal"
METAL_OUTPUT="Shaders.air"

echo "[native.cr] Building iOS engine..."

if ! command -v crystal &> /dev/null; then
    echo "Error: Crystal compiler not found"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode not found"
    exit 1
fi

echo "[native.cr] Compiling Crystal to $TARGET..."
crystal build $CRYSTAL_SRC \
    --target $TARGET \
    --release \
    --link-flags="-static" \
    -o $OUTPUT_LIB

echo "[native.cr] Compiling Metal shaders..."
xcrun metal -c $METAL_SHADER -o $METAL_OUTPUT

echo "[native.cr] Compiling Objective-C files..."
clang -c AppDelegate.m -o AppDelegate.o \
    -arch arm64 \
    -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
    -framework UIKit \
    -framework Foundation

clang -c ViewController.m -o ViewController.o \
    -arch arm64 \
    -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
    -framework UIKit \
    -framework Metal \
    -framework QuartzCore

clang -c Renderer.m -o Renderer.o \
    -arch arm64 \
    -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
    -framework Metal \
    -framework QuartzCore

echo "[native.cr] Archiving static library..."
ar rcs libnative_cr_engine.a AppDelegate.o ViewController.o Renderer.o

echo "[native.cr] iOS engine build complete"
echo "[native.cr] Output files:"
echo "  - $OUTPUT_LIB (Crystal static library)"
echo "  - libnative_cr_engine.a (Objective-C static library)"
echo "  - $METAL_OUTPUT (Compiled Metal shader)"
