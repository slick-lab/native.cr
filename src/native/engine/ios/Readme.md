
# iOS Engine for native.cr

This directory contains the iOS platform engine that allows Crystal apps to run natively on iOS devices.

## Overview

The iOS engine uses Metal for graphics and Objective-C as the bridge between the iOS system and Crystal code. Unlike Android, iOS requires an Objective-C/Swift entry point, so Crystal code is compiled into a static library that is called from Objective-C.

## Architecture

```

Crystal App Logic → Crystal Bridge → Objective-C Wrapper → Metal Renderer → iOS Device

```

## File Structure

```

engine/ios/
├── AppDelegate.m          # iOS app entry point
├── ViewController.m       # Manages Metal layer and touch events
├── Renderer.m             # Metal rendering pipeline
├── Shaders.metal          # Vertex and fragment shaders
├── bridge.cr              # Crystal bridge with exports
├── Info.plist             # iOS app configuration
├── build.sh               # Build script
├── Makefile               # Build automation
└── README.md              # This file

```

## How Each File Works

| File | Purpose |
|------|---------|
| AppDelegate.m | Creates the app window and calls ios_app_main() to start Crystal |
| ViewController.m | Sets up CAMetalLayer, handles touch events, calls Crystal render frame |
| Renderer.m | Creates Metal pipeline, clears screen, draws full-screen triangle |
| Shaders.metal | Metal shaders that fill every pixel on screen |
| bridge.cr | Exports Crystal functions to Objective-C, manages app state |
| Info.plist | Configuration: bundle ID, version, required device capabilities |
| build.sh | Script that compiles all components |
| Makefile | Build automation with crystal, objc, and metal targets |

## Runtime Flow

1. iOS launches the app and calls main() in AppDelegate.m
2. UIApplicationMain creates the app delegate
3. AppDelegate creates UIWindow and ViewController
4. ViewController initializes Metal and CADisplayLink
5. CADisplayLink calls ios_render_frame() every frame
6. ios_render_frame() calls Crystal's render_frame method
7. Crystal calls Metal renderer to draw the frame
8. Touch events call ios_handle_touch() back into Crystal

## Requirements

- macOS with Xcode installed
- iOS SDK (comes with Xcode)
- Crystal compiler with aarch64-apple-ios target support
- iOS device or simulator for testing (arm64 only)

## Build Commands

```bash
# Build everything
make

# Build only Crystal component
make crystal

# Build only Objective-C component
make objc

# Build only Metal component
make metal

# Clean all build artifacts
make clean
```

Integration with Xcode

After running make, you will have:

- libnative_cr_ios.a - Crystal static library
- libnative_cr_engine.a - Objective-C static library
- default.metallib - Compiled Metal shaders

Add these to your Xcode project along with Info.plist to create the final iOS app.

Notes

- Minimum iOS version: 11.0 (Metal support)
- Architecture: arm64 only (iPhone 5s and newer)
- OpenGL ES is deprecated on iOS, Metal is the modern path
- The app runs at screen refresh rate via CADisplayLink
- Touch actions: 0 = began, 1 = moved, 2 = ended
