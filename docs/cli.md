
# Native.cr CLI Reference

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

## `native.cr create <app-name>`

Scaffold a new native.cr project.

```bash
native.cr create MyApp
native.cr create MyApp --android
native.cr create MyApp --ios
```

**Options:**

| Option | Description |
|--------|-------------|
| `--android` | Generate Android only project (default if not specified) |
| `--ios` | Generate iOS only project |
| `-p, --path DIR` | Project directory path [default: ./PROJECT_NAME] |
| `-t, --template TYPE` | Template type [app, game, library] [default: app] |

**Generates:**

```
MyApp/
├── src/
│   └── main.cr          ← entry point — your Native::App subclass
├── shard.yml            ← dependencies
├── assets/              ← images, sounds, fonts
└── android/             ← Android project (if --android)
    ├── app/
    ├── gradle/
    └── gradlew
```

**Notes:**
- `native.cr create` now generates a **complete Android project** with `gradlew` and `gradle-wrapper.jar` bundled.
- The generated `shard.yml` does **not** pin a specific version, so users always get the latest `native.cr` release.
- The `android/` folder is **self-contained** – no manual Gradle installation required.

---

## `native.cr build [PLATFORM] [OPTIONS]`

Compile your Crystal app to a native binary for the target platform.

```bash
# Android (default)
native.cr build android

# Release build (signed)
native.cr build android --release

# iOS (requires macOS)
native.cr build ios
```

**Options:**

| Option | Description |
|--------|-------------|
| `-e, --entry FILE` | Entry point file [default: src/main.cr] |
| `-o, --output DIR` | Output directory [default: ./build] |
| `--release` | Build in release mode (requires signing configuration) |
| `--clean` | Clean build directory before building |

**Platforms:**

| Platform | Description |
|----------|-------------|
| `android` | Build APK for Android (default) |
| `ios` | Build for iOS (requires macOS and Xcode) |

**Outputs:**

| Build Mode | Output Path |
|------------|-------------|
| Debug (`android`) | `android/app/build/outputs/apk/debug/app-debug.apk` |
| Release (`android`) | `android/app/build/outputs/apk/release/app-release.apk` |
| iOS (any) | `ios/MyApp.xcodeproj` (open in Xcode) |

**Signing:**

For release builds, `native.cr` uses the signing configuration in `app/build.gradle`. You can set credentials via environment variables:

```bash
export KEYSTORE_PATH=/path/to/keystore.jks
export KEYSTORE_PASSWORD=your_password
export KEY_ALIAS=your_alias
export KEY_PASSWORD=your_key_password

native.cr build android --release
```

**Notes:**

- Debug APKs are signed with the **auto-generated debug keystore** and can be installed via ADB.
- Release APKs require a **production keystore** configured in `android/app/build.gradle` or via environment variables.

---

## `native.cr sign <APK_PATH> [OPTIONS]`

Sign an APK using the Android SDK's `apksigner` tool. Useful for signing APKs manually or when you have a keystore but don't want to configure Gradle.

```bash
# Quick debug signing
native.cr sign -k debug.keystore app-debug.apk

# Release signing with custom alias
native.cr sign -k release.keystore -a myalias app-release.apk

# Sign and save to a different file
native.cr sign -k release.keystore app-release.apk -o app-signed.apk
```

**Options:**

| Option | Description |
|--------|-------------|
| `-k, --keystore PATH` | Path to keystore file **(required)** |
| `-a, --alias ALIAS` | Key alias [default: androiddebugkey] |
| `-s, --storepass PASS` | Keystore password [default: android] |
| `-p, --keypass PASS` | Key password [default: android] |
| `-o, --output PATH` | Output path [default: overwrite original] |
| `-h, --help` | Show help |

**How it works:**

1. **Validates** that the keystore and APK exist.
2. **Locates `apksigner`** automatically by searching:
   - `$ANDROID_HOME/build-tools/` for the latest version
   - Or falls back to `PATH`
3. **Executes** `apksigner` with the provided credentials:
   ```bash
   apksigner sign --ks my.keystore --ks-key-alias myalias \
     --ks-pass pass:mypass --key-pass pass:keypass \
     --out app-signed.apk app.apk
   ```
4. **Reports** success or failure with clear output.

**Why this is useful:**

- Sign APKs without editing `build.gradle`
- Quick debug signing without generating a keystore first
- Works with any keystore format (`.jks`, `.keystore`, `.pk12`)
- Uses the modern `apksigner` (supports APK Signature Scheme v2/v3)
- Auto-detects Android SDK path

---

## `native.cr reload [ENTRY_POINT]`

Start hot-reload development on desktop.

```bash
native.cr reload
native.cr reload src/main.cr
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `entry-point` | No | Path to your main Crystal file [default: src/main.cr] |

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
|---------|---------|
| `native.cr doctor` | Verify toolchain |
| `native.cr create <name>` | Scaffold new project with Android (and optional iOS) |
| `native.cr build [android\|ios]` | Compile to APK or Xcode project |
| `native.cr sign <apk>` | Sign an APK with a keystore |
| `native.cr reload` | Hot-reload desktop development |
| `native.cr --version` | Show version |

---

## Platform Quick Reference

| Platform | `create` | `build` | `sign` | `reload` |
|----------|----------|---------|--------|----------|
| `android` | ✅ | ✅ | ✅ | ❌ |
| `ios` | ✅ (via `--ios`) | ✅ | ❌ | ❌ |
| `desktop` | ❌ | ❌ | ❌ | ✅ |

---

## Common Workflows

### Start a new Android app

```bash
native.cr create MyApp
cd MyApp
native.cr doctor
native.cr reload                  # develop on desktop
native.cr build android           # build debug APK
native.cr build android --release # build signed release APK
```

### Sign an existing APK manually

```bash
# Generate a debug keystore (if you don't have one)
keytool -genkey -v -keystore debug.keystore \
  -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000

# Sign your APK
native.cr sign -k debug.keystore app-debug.apk
```

### Build and sign in one step (with environment variables)

```bash
export KEYSTORE_PATH=~/release.keystore
export KEYSTORE_PASSWORD=secure123
export KEY_ALIAS=myapp
export KEY_PASSWORD=keypass123

native.cr build android --release
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General error |
| `2` | Missing prerequisite (run `doctor`) |
| `3` | Build failed |
| `4` | Invalid arguments |

---

## Environment Variables

| Variable | Used By | Description |
|----------|---------|-------------|
| `ANDROID_HOME` | `build`, `sign` | Path to Android SDK |
| `ANDROID_NDK` | `build` | Path to Android NDK |
| `KEYSTORE_PATH` | `build` (release) | Path to keystore for signing |
| `KEYSTORE_PASSWORD` | `build` (release) | Keystore password |
| `KEY_ALIAS` | `build` (release) | Key alias |
| `KEY_PASSWORD` | `build` (release) | Key password |

---
