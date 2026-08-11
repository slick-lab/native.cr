
# Android Engine for native.cr

This directory contains the Android platform engine that allows Crystal apps to run natively on Android devices.

## Overview

The Android engine provides:
- JNI bridge between Crystal and Android Java/Kotlin
- Native C engine for event loop and OpenGL (fallback)
- Precompiled Java helper classes for common operations
- Build scripts for NDK compilation

## Architecture

```

┌─────────────────────────────────────────────────────────┐
│  Crystal App Code (src/main.cr)                        │
├─────────────────────────────────────────────────────────┤
│  native.cr Framework                                    │
├─────────────────────────────────────────────────────────┤
│  bridge.cr (Crystal → JNI bridge)                      │
├─────────────────────────────────────────────────────────┤
│  libnative_app.so (single combined library)           │
│  libnative_cr_android.jar (Java helper classes)        │
├─────────────────────────────────────────────────────────┤
│  Android Runtime (ART) + NDK                           │
└─────────────────────────────────────────────────────────┘

```

## Files

| File | Purpose |
|------|---------|
| `native.c` | C engine entry point (`android_main`), JNI setup, event loop |
| `bridge.cr` | Crystal entry point called from C |
| `jni.cr` | JNI helper functions for Crystal |
| `Makefile` | Builds `native_engine.o` and `libnative_cr_android.jar` |
| `java/` | Java helper classes (HTTP, audio, camera, notifications, etc.) |

## Java Helper Classes

| Class | Purpose |
|-------|---------|
| `HTTPClient` | HTTP/HTTPS requests |
| `SoundPlayer` | Short sound effects |
| `MusicPlayer` | Long audio playback |
| `AudioRecorder` | Microphone recording |
| `NotificationHelper` | Push/local notifications |
| `BillingHelper` | In-app purchases |
| `LocationHelper` | GPS location |
| `ImagePickerHelper` | Camera and gallery |
| `BiometricCallback` | Fingerprint/Face ID |
| `SensorListener` | Accelerometer, gyroscope |
| `ConnectivityHelper` | Network status |
| `WebViewClientCallback` | WebView events |
| `VideoPlayer` | Video playback |
| `RecyclerViewAdapter` | List view adapter |
| Callback classes | UI event handling |

## Building the Engine

### Prerequisites

- Android NDK r25 or later
- JDK 8 or later
- Android SDK (for Java compilation)

### Build Commands

```bash
# Build both .o and .jar
make

# Build only C engine object
make native_engine.o

# Build only Java JAR
make libnative_cr_android.jar

# Clean build artifacts
make clean
```

Environment Variables

| Variable | Required | Default Purpose |
| ----- | ----- | ----- |
| ANDROID_NDK | Yes | Path to Android NDK |
| JAVA_HOME | For JAR | Path to JDK |

Output Files

File Description
- native_engine.o Object file for ARM64 Android (linked with user code)
- libnative_cr_android.jar Compiled Java helper classes

Integration with User Projects

The CLI handles distribution:

1. User runs shards install
2. postinstall.sh downloads prebuilt .o and .jar from GitHub Releases
3. native.cr create copies templates to user's Android project
4. native.cr build android compiles Crystal code and links with native_engine.o into single libnative_app.so

Notes

- Minimum Android API level: 24 (Android 7.0)
- Architecture: arm64-v8a only
- The C engine is minimal; most Android operations use Java via JNI
- Java classes are compiled to JAR for faster user builds
- User code and C engine are linked into a single shared library

Troubleshooting

Issue Solution
ANDROID_NDK not set Export path: export ANDROID_NDK=/path/to/ndk
javac: command not found Install JDK: sudo apt install openjdk-11-jdk
cannot find -llog NDK path incorrect; check ANDROID_NDK
cannot find symbol Java source files missing; check java/ directory

Maintenance

When updating Java helper classes:

1. Modify .java files in java/com/nativecr/
2. Run make to regenerate libnative_cr_android.jar
3. Upload both .o and .jar to GitHub Releases
4. Users get updates via shards install
