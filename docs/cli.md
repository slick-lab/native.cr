# native.cr CLI Reference

Command-line interface for building native mobile apps in Crystal.

---

## `native.cr doctor`

Check that all required tools are installed and configured.

```bash
native.cr doctor
```

**Output:**

```
✓ Crystal 1.20.1
✓ Android NDK r25c
✓ Xcode 14.3
✓ Java 17
```

Run this before anything else. If something is missing, the CLI tells you exactly what to install.

---

## `native.cr create <app-name> <platform>`

Scaffold a new native.cr project.

```bash
native.cr create MyApp android
native.cr create MyApp ios
```

**Arguments:**

| Argument | Description |
|---|---|
| `app-name` | Name of your app. Used for package name and directory. |
| `platform` | Target platform: `android` or `ios` |

**Generates:**

```
MyApp/
├── src/
│   └── main.cr          ← entry point — your Native::App subclass
├── shard.yml            ← dependencies
├── assets/
│   ├── images/
│   ├── sounds/
│   └── fonts/
└── native.cr.json       ← project config
```

`main.cr` is placed under `src/` — this is where your app logic lives.

---

## `native.cr build <entry-point> [--release] <platform>`

Compile your Crystal app to a native binary for the target platform.

```bash
# Debug build (default)
native.cr build src/main.cr android
native.cr build src/main.cr ios

# Release build — signed, optimized, for distribution
native.cr build src/main.cr --release android
native.cr build src/main.cr --release ios
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `entry-point` | Yes | Path to your main Crystal file (e.g., `src/main.cr`) |
| `--release` | No | Produce a signed, optimized release build. Required for installing on non-developer phones. |
| `platform` | Yes | Target platform: `android` or `ios` |

**Output:**

| Build Type | Output Path |
|---|---|
| Debug (`android`) | `build/app-debug.apk` |
| Release (`android`) | `build/outputs/apk/release/app-release.apk` |
| Debug (`ios`) | `build/MyApp.xcodeproj` (open in Xcode) |
| Release (`ios`) | `build/MyApp.xcodeproj` (signed, archive via Xcode) |

**Notes:**

- Debug APKs are unsigned and only installable via ADB or on devices with USB debugging enabled.
- Release APKs are signed and installable on any Android phone.
- iOS builds always output an `.xcodeproj` — open it in Xcode to run on simulator or device, then archive for App Store.

---

## `native.cr reload <entry-point>`

Start hot-reload development on desktop.

```bash
native.cr reload src/main.cr
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `entry-point` | Yes | Path to your main Crystal file (e.g., `src/main.cr`) |

**What it does:**

- Opens a desktop window (SDL2 + OpenGL) showing your app
- Watches `src/` for file changes
- On save: recompiles incrementally and reloads the running app
- Preserves `@[Preserve]` annotated state across reloads

**Output:**

```
Watching src/main.cr — save to reload…
[12:04:01] Detected change, recompiling…
[12:04:02] Reloaded in 1.3s — state restored
```

**Notes:**

- Hot reload is for **desktop development only** — it does not target Android or iOS.
- Use this for rapid iteration without needing an emulator or physical device.
- When ready to test on device, use `native.cr build`.

---

## Command Summary

| Command | Purpose |
|---|---|
| `native.cr doctor` | Verify toolchain |
| `native.cr create <name> <platform>` | Scaffold new project |
| `native.cr build <entry> [--release] <platform>` | Compile to APK (Android) or Xcode project (iOS) |
| `native.cr reload <entry>` | Hot-reload desktop development |

---

## Platform Quick Reference

| Platform | `create` | `build` | `reload` |
|---|---|---|---|
| `android` | ✅ | ✅ | ❌ |
| `ios` | ✅ | ✅ | ❌ |
| `desktop` | ❌ | ❌ | ✅ (default for reload) |

---

## Common Workflows

### Start a new Android app

```bash
native.cr create MyApp android
cd MyApp
native.cr doctor
native.cr reload src/main.cr     # develop on desktop
native.cr build src/main.cr android --release   # ship APK
```

### Start a new iOS app

```bash
native.cr create MyApp ios
cd MyApp
native.cr doctor
native.cr reload src/main.cr     # develop on desktop
native.cr build src/main.cr ios --release       # open .xcodeproj in Xcode, archive
```

---

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | General error |
| `2` | Missing prerequisite (run `doctor`) |
| `3` | Build failed |
| `4` | Invalid arguments |
