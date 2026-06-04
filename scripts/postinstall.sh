#!/bin/bash

set -e

echo "[native.cr] Post-install setup"

# Build CLI
echo "[native.cr] Building CLI..."
shards build --release

# Install CLI
if [ -w /usr/local/bin ]; then
    cp bin/native.cr /usr/local/bin/
else
    sudo cp bin/native.cr /usr/local/bin/
fi
chmod +x /usr/local/bin/native.cr

# Build Android engine
if command -v cmake &> /dev/null && [ -n "$ANDROID_NDK" ] && [ -n "$ANDROID_HOME" ]; then
    echo "[native.cr] Building Android engine..."
    cd src/native/engine/android
    mkdir -p build
    cd build
    cmake -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
          -DANDROID_ABI=arm64-v8a \
          -DANDROID_PLATFORM=android-24 ..
    make
    cd ../../../..
    echo "[native.cr] Android engine built"
else
    echo "[native.cr] Skipping Android engine (NDK or CMake not found)"
fi

# Build iOS engine
if [[ "$OSTYPE" == "darwin"* ]] && command -v xcodebuild &> /dev/null; then
    echo "[native.cr] Building iOS engine..."
    cd src/native/engine/ios
    make
    cd ../../../..
    echo "[native.cr] iOS engine built"
else
    echo "[native.cr] Skipping iOS engine (not on macOS or Xcode missing)"
fi

echo "[native.cr] Installation complete"
echo "[native.cr] Run 'native.cr doctor' to verify setup"
