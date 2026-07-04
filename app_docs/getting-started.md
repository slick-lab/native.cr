# Getting Started

Set up your development environment and create your first native.cr app.

---

## Prerequisites

Before you begin, ensure you have the following installed:

### For All Platforms

| Requirement | Description |
|-------------|-------------|
| Crystal | Version 1.10 or higher |
| Git | For project setup |
| Text Editor | VS Code with Crystal extension recommended |

### For Android Development

| Requirement | Description |
|-------------|-------------|
| Android Studio | Latest version |
| Android SDK | API level 24+ |
| JDK | Version 17 or higher |
| NDK | For native compilation |

### For iOS Development (macOS only)

| Requirement | Description |
|-------------|-------------|
| Xcode | Version 15+ (from Mac App Store) |
| Xcode CLI Tools | `xcode-select --install` |
| CocoaPods | `sudo gem install cocoapods` |

---

## Install Crystal

### macOS

```bash
brew install crystal
```

### Linux (Debian/Ubuntu)

```bash
curl -fsSL https://crystal-lang.org/install.sh | bash
```

### Linux (Arch)

```bash
sudo pacman -S crystal
```

Verify installation:

```bash
crystal --version
# Crystal 1.12.2 (or higher)
```

---

## Platform Setup

### Android Setup

1. Install Android Studio from https://developer.android.com/studio

2. Open Android Studio → Settings → Appearance & Behavior → System Settings → Android SDK

3. Install:
   - Android SDK Platform (API 34+)
   - Android SDK Build-Tools
   - NDK (Side by side)
   - CMake

4. Set environment variables:

```bash
# Add to ~/.bashrc, ~/.zshrc, or equivalent
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

5. Verify:

```bash
adb version
```

### iOS Setup (macOS)

1. Install Xcode from Mac App Store

2. Install command-line tools:

```bash
xcode-select --install
```

3. Install CocoaPods:

```bash
sudo gem install cocoapods
```

4. Verify:

```bash
xcodebuild -version
# Xcode 15.0 (or higher)
```

---

## Verify Your Setup

Run the doctor command to check your environment:

```bash
crystal main.cr doctor
```

You'll see output like:

```
native.cr Doctor
================

Checking Crystal... ✓ Crystal 1.12.2
Checking Android SDK... ✓ API 34
Checking Android NDK... ✓ r26
Checking Xcode... ✓ 15.0 (macOS only)

All checks passed!
```

---

## Create Your First App

Create a new project:

```bash
crystal main.cr create MyApp
cd MyApp
```

This generates:

```
MyApp/
├── src/
│   └── app/
│       └── main.cr      # Your app code
├── android/             # Android project
├── ios/                 # iOS project (macOS only)
├── assets/              # Images, fonts, sounds
├── shard.yml            # Dependencies
└── Makefile             # Build commands
```

---

## Project Structure

```
MyApp/
├── src/
│   ├── app/
│   │   ├── main.cr         # App entry point
│   │   ├── screens/        # Screen components
│   │   ├── components/     # Reusable widgets
│   │   └── models/         # Data models
│   └── native.cr           # Framework (via shard)
│
├── android/
│   ├── app/
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── java/
│   │       └── res/
│   └── build.gradle
│
├── ios/
│   ├── MyApp/
│   │   ├── AppDelegate.swift
│   │   └── Info.plist
│   └── Podfile
│
├── assets/
│   ├── images/
│   ├── fonts/
│   └── sounds/
│
├── shard.yml
└── Makefile
```

---

## Run Your App

### Android

```bash
crystal main.cr build android
```

Or for development with hot reload:

```bash
crystal main.cr build android --dev
```

Install on connected device or emulator:

```bash
adb install -r build/android/app.apk
```

### iOS

```bash
crystal main.cr build ios
```

Open Xcode and run:

```bash
open ios/MyApp.xcworkspace
```

Press Play in Xcode, or:

```bash
crystal main.cr build ios --device
```

---

## Development Workflow

### Hot Reload

For rapid development, use hot reload. Changes to your Crystal code appear instantly on your device without rebuilding:

```bash
# Terminal 1: Run the dev server
crystal main.cr dev

# Terminal 2: Reload on file changes
crystal main.cr reload
```

State is preserved across reloads when you use `@[Preserve]`:

```crystal
class MyApp < Native::App
  @[Preserve]
  property items = [] of String  # Survives hot reload

  def setup
    # This runs on first launch and after reload
  end
end
```

### Debugging

View logs in real-time:

```bash
# Android
adb logcat | grep -i nativecr

# iOS (Xcode console)
# Or: crystal main.cr logs
```

---

## Editor Setup

### VS Code

1. Install the Crystal extension:

```bash
code --install-extension crystal-lang-tools.crystal-lang
```

2. Configure `crystal.mainFile` in settings:

```json
{
  "crystal.mainFile": "src/app/main.cr"
}
```

### Features

- Syntax highlighting
- Code completion
- Go to definition
- Inline documentation
- Format on save

---

## Troubleshooting

### Crystal Not Found

```bash
# Ensure Crystal is in PATH
which crystal
# Add to ~/.bashrc or ~/.zshrc:
export PATH="/usr/local/bin:$PATH"
```

### Android SDK Not Detected

```bash
# Check ANDROID_HOME
echo $ANDROID_HOME
# Set if empty:
export ANDROID_HOME=$HOME/Android/Sdk
```

### Build Fails

```bash
# Clean and rebuild
crystal main.cr build android --clean
```

### iOS Build Fails

```bash
# Update pods
cd ios && pod install && cd ..
```

---

## Next Steps

Now that your environment is ready:

- [Core Concepts](core-concepts.md) — Understand how native.cr works
- [Tutorial: First App](tutorial-first-app.md) — Build a complete app
- [Project Structure](project-structure.md) — Learn the file organization
