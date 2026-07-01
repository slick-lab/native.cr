# CLI Reference

Command-line interface for native.cr.

---

## doctor

Check toolchain:

```bash
native.cr doctor
```

Output:

```
✓ Crystal 1.20.1
✓ Android NDK r25c
✓ Xcode 14.3
✓ Java 17
```

---

## create

Create new project:

```bash
native.cr create MyApp
native.cr create MyApp --android
native.cr create MyApp --ios
```

Options:

| Flag | Description |
|------|-------------|
| `--android` | Android only |
| `--ios` | iOS only |
| `-p, --path` | Custom path |
| `-t, --template` | app / game / library |

---

## build

Build for platform:

```bash
# Android
native.cr build android

# Release
native.cr build android --release

# iOS
native.cr build ios
```

Options:

| Flag | Description |
|------|-------------|
| `-e, --entry` | Entry file |
| `-o, --output` | Output dir |
| `--release` | Release mode |
| `--clean` | Clean first |

Output:

| Platform | Output |
|----------|--------|
| Android debug | `android/app/build/outputs/apk/debug/app-debug.apk` |
| Android release | `android/app/build/outputs/apk/release/app-release.apk` |
| iOS | `ios/MyApp.xcodeproj` |

---

## reload

Hot reload on desktop:

```bash
native.cr reload
native.cr reload src/main.cr
```

---

## sign

Sign APK:

```bash
native.cr sign -k release.keystore app.apk
native.cr sign -k keystore.jks -a myalias app.apk -o signed.apk
```

Options:

| Flag | Description |
|------|-------------|
| `-k, --keystore` | Keystore path (required) |
| `-a, --alias` | Key alias |
| `-s, --storepass` | Keystore password |
| `-p, --keypass` | Key password |
| `-o, --output` | Output path |

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `ANDROID_HOME` | Android SDK path |
| `ANDROID_NDK` | NDK path |
| `KEYSTORE_PATH` | Signing keystore |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias |
| `KEY_PASSWORD` | Key password |

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `doctor` | Check tools |
| `create` | New project |
| `build` | Compile |
| `sign` | Sign APK |
| `reload` | Hot reload |
