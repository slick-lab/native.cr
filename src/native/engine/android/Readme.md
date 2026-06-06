
# Android Engine for native.cr

This directory contains the Android platform engine that allows Crystal apps to run natively on Android devices.

## Files

| File | Purpose |
|------|---------|
| `native.c` | C engine with OpenGL ES rendering, input handling, and bridge functions |
| `Makefile` | Build script that compiles the engine using Android NDK |

## How It Works

1. Android launches the app and calls `android_main()` in `native.c`
2. The C engine initializes OpenGL ES and sets up the display
3. The engine calls `crystal_android_main()` (exported from your Crystal code)
4. Your Crystal app runs and calls back into the engine for rendering and events

## Bridge Functions

The C engine provides these functions for Crystal to call:

| Function | Purpose |
|----------|---------|
| `poll_events(state)` | Process pending Android events |
| `destroy_requested(state)` | Check if app should exit |
| `has_window(state)` | Check if window is ready for drawing |
| `set_color(state, r, g, b)` | Set background color (0-255 each) |
| `swap_buffers(state)` | Swap OpenGL buffers to display |

## Building the Engine

```bash
# Set NDK path
export ANDROID_NDK=/path/to/ndk

# Build
make NDK_PATH=$ANDROID_NDK

# Output: libnative_cr_engine.so
```

Requirements

- Android NDK r25 or later
- Target API level: 24 (Android 7.0) or higher
- Architecture: arm64-v8a only

Integration with Crystal

Your Crystal code must export crystal_android_main:

```crystal
@[Export("crystal_android_main")]
fun crystal_android_main(state : Void*) : Void
  GC.init
  # Your app code here
end
```

The state pointer is the android_app struct from the NDK.

Event Loop Pattern

```crystal
loop do
  LibEngine.poll_events(state)
  break if LibEngine.destroy_requested(state)
  
  if LibEngine.has_window(state)
    # Update and render
    LibEngine.set_color(state, 100, 150, 200)
    LibEngine.swap_buffers(state)
  end
end
```

Building Complete APK

1. Compile Crystal code to libnative_cr.so
2. Compile C engine to libnative_cr_engine.so
3. Package both into APK with proper AndroidManifest.xml
4. Sign and align the APK

Notes

- OpenGL ES 2.0 is used for rendering
- Touch events change the background color in the example
- The engine supports single-touch input (multi-touch can be added)

```
```
