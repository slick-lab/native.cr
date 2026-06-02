
# Android Engine for native.cr

This directory contains the Android platform engine that allows Crystal apps to run natively on Android devices.

## Overview

The Android engine uses Google's NativeActivity to run Crystal code directly without any Java or Kotlin.

## File Structure

```

engine/android/
├── native.c                    # C rendering engine (OpenGL ES 2.0)
├── android_native_app_glue.c   # Google's event loop and lifecycle
├── android_main.cr             # Crystal entry point
├── CMakeLists.txt              # Build configuration
└── AndroidManifest.xml         # App manifest

```

## How Each File Works

| File | Purpose |
|------|---------|
| native.c | Creates OpenGL context, draws frames, handles touch input, communicates with Android NDK |
| android_native_app_glue.c | Bridges Android Java lifecycle to C, manages event loop, queues input |
| android_main.cr | Exports crystal_android_main to C, runs Crystal app logic, calls C rendering functions |
| CMakeLists.txt | Compiles C files with NDK, cross-compiles Crystal to ARM64, links into .so |
| AndroidManifest.xml | Tells Android to launch NativeActivity and load libnative_cr_engine.so |

## Build Process

1. CMake reads CMakeLists.txt
2. C files are compiled with Android NDK toolchain
3. Crystal compiler cross-compiles android_main.cr to ARM64 Linux
4. Both are linked into libnative_cr_engine.so
5. .so is packaged with AndroidManifest.xml into an APK

## Runtime Flow

1. Android launches NativeActivity
2. android_native_app_glue.c creates event loop thread
3. Glue calls android_main() from native.c
4. native.c initializes OpenGL and calls crystal_android_main
5. Crystal code takes over and runs the app

## Requirements

- Android NDK r25 or later
- Crystal compiler with Android ARM64 target support
- CMake 3.10 or later

## Commands

```bash
# Build the engine
mkdir build && cd build
cmake -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-24 ..
make

# Output: build/libnative_cr_engine.so
```

Notes

- Minimum Android SDK: 24 (Android 7.0)
- Only arm64-v8a architecture is supported
- No Java/Kotlin code required
- OpenGL ES 2.0 for rendering
