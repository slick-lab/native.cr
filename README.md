
# <picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/slick-lab/native.cr/main/assets/logo.svg">
  <img src="https://raw.githubusercontent.com/slick-lab/native.cr/main/assets/logo.svg" width="120" alt="Native.cr">
</picture>

# Native.cr

[![Crystal](https://img.shields.io/badge/Crystal-1.20%2B-000000?logo=crystal)](https://crystal-lang.org/)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Desktop-blue)](https://github.com/slick-lab/native.cr)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](CONTRIBUTING.md)
[![Discord](https://img.shields.io/badge/chat-discord-5865F2)](https://discord.gg/nativecr)

**React Native, but for Crystal developers.**

Write mobile apps in Crystal. Compile directly to native ARM64 code. No JavaScript bridge. No interpreter. Just Crystal talking to Android and iOS through raw FFI.

---

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  native:
    github: slick-lab/native.cr
    version: ~> 0.1.0
```

Then run:

```bash
shards install
```

The post-install script will:

- Build the native.cr CLI
- Install it to /usr/local/bin
- Compile Android and iOS engines (if NDK/Xcode available)

Verify installation:

```bash
native.cr doctor
```

---

## Quick Start

```bash
# Create a new project
native.cr create my_app
cd my_app

# Build APK directly
native.cr build android
# APK created at build/app.apk

# Or build for iOS
native.cr build ios
# Framework created at build/NativeCr.framework

# Desktop preview (development)
native.cr reload
# Opens a window showing your app
```

---

## What It Looks Like

```crystal
class MyApp < Native::App
  @[Preserve]
  property count : Int32 = 0

  def setup
    @label = UI::Text.new
    @label.text = "Tap: 0"
    @label.text_size = 24
    
    button = UI::Button.new
    button.text = "Tap Me"
    button.width = 120
    button.height = 44
    button.on_click = ->{ increment }
    
    column = UI::Column.new
    column.spacing = 20
    column.add_child(@label)
    column.add_child(button)
    
    @root = column
  end
  
  def increment
    @count += 1
    @label.text = "Tap: #{@count}"
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(MyApp)
```

---

## Features

Feature | Android | iOS |
| ----- | ----- | ----- |
| UI Components|  ✅ | ✅ |
| Touch Events & Gestures|  ✅ | ✅ |
| Animations | ✅ | ✅ |
| Camera | ✅ | ✅ |
| Notifications| ✅|  ✅ |
| Biometric Auth| ✅ | ✅ |
| In-App Purchases| ✅| ✅ |
| HTTP & WebSocket| ✅| ✅ |
| SQLite Storage| ✅ |✅ |
| Audio| ✅| ✅ |
| Video| ✅| ✅ |
| Game Loop| ✅| ✅ |

---

## Commands

| Command |  Description | 
| ----- | ----- |
| native.cr create NAME | Create new project |
| native.cr build | android Build APK |
| native.cr build ios | Build iOS framework|
| native.cr reload | Desktop preview with fast restart|
| native.cr doctor | Check toolchain|
| native.cr --version | Show version|

---

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  Your Crystal App (src/main.cr)                            │
├─────────────────────────────────────────────────────────────┤
│  native.cr Framework                                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   Android   │ │     iOS     │ │  Desktop    │           │
│  │  C + JNI    │ │  Obj-C +    │ │  SDL2 +     │           │
│  │  OpenGL     │ │  Metal      │ │  OpenGL     │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│  Android NDK │ iOS SDK │ SDL2                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Requirements

Platform Requirements
Android Android NDK, Android SDK, Java 11+
iOS macOS, Xcode 14+, CocoaPods
Desktop SDL2 (brew install sdl2 or apt install libsdl2-dev)

---

## Documentation

- API Reference
- UI Components Guide
- Examples

---

## License

MIT License

---

Built with frustration. Released with love.
