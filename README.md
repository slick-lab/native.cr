
# <picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/slick-lab/native.cr/main/assets/logo.svg">
  <img src="https://raw.githubusercontent.com/slick-lab/native.cr/main/assets/logo.svg" width="120" alt="Native.cr">
</picture>

# Native.cr

[![Crystal](https://img.shields.io/badge/Crystal-1.20%2B-000000?logo=crystal)](https://crystal-lang.org/)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue)](https://github.com/slick-lab/native.cr)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](CONTRIBUTING.md)
[![Discord](https://img.shields.io/badge/chat-discord-5865F2)](https://discord.gg/nativecr)

**React Native, but for Crystal developers.**

Write mobile apps in Crystal. Compile directly to native ARM64 code. No JavaScript bridge. No interpreter. Just Crystal talking to Android and iOS through raw FFI.

---

## Why I Built This

I love Crystal. I love its speed, its Ruby-like syntax, its type system. But every time I wanted to build a mobile app, I had to leave Crystal behind.

React Native proved that cross-platform mobile development works. But JavaScript shouldn't have all the fun. Crystal is faster, safer, and just as expressive.

So I built native.cr. Not because it was easy. Because it was necessary.

---

## Quick Start

```bash
# Install native.cr
git clone https://github.com/slick-lab/native.cr
cd native.cr && make install

# Create your first app
native.cr create my_app
cd my_app

# Build for Android
native.cr build android

# Build for iOS
native.cr build ios
```

Then open Android Studio or Xcode to package your APK or IPA. I compile Crystal to native libraries. You handle the final packaging with the tools you already know.

---

What It Looks Like

```crystal
class MyApp < Native::App
  @[Preserve]
  property counter : Int32 = 0

  def setup
    set_background_color(240, 240, 245)
    
    label = UI::Text.new
    label.text = "Hello, native.cr!"
    label.text_size = 24
    
    button = UI::Button.new
    button.text = "Tap me"
    button.on_click = ->{ increment_counter }
    
    column = UI::Column.new
    column.spacing = 20
    column.add_child(label)
    column.add_child(button)
    
    @root = column
  end
  
  def increment_counter
    @counter += 1
    change_color(100 + (@counter * 10) % 155, 100, 100)
  end
end

Native::App.start(MyApp)
```

---

Features

|Feature | Android |  iOS |
| ----- | ----- | ----- |
|UI Components (View, Text, Button, etc.  ) |  ✅ | ✅ | 
|Touch Events & Gestures|  ✅ | ✅ | 
|Animations | ✅|  ✅ |
|Camera|  ✅ | ✅ |
|Notifications| ✅  | ✅ |
|Biometric Auth (Fingerprint/Face ID) | ✅ | ✅ |
|In-App Purchases | ✅ | ✅ |
|HTTP & WebSocket|  ✅ | ✅ |
|SQLite Storage | ✅ | ✅ | 
|Audio Playback & Recording | ✅  | ✅ |
|Video Playback | ✅ | ✅
|Game Loop | ✅ |  ✅ |

---

The Challenges I Faced

1. Android Has No Crystal Support

Android does not know what Crystal is. It speaks Java and C++ through the NDK. I had to write a C engine that embeds the Crystal runtime and bridges to JNI. Thousands of lines of C code just to get "Hello World" on screen.

2. iOS Requires Objective-C

You cannot write a pure C entry point on iOS. Every iOS app must have a UIApplication and UIViewController written in Objective-C or Swift. I wrote a thin Obj-C wrapper that loads a Crystal static library and calls into it.

3. No JIT on Mobile

Crystal's JIT is experimental and not available on mobile. I rely entirely on AOT compilation. Fast restarts are not hot reload. They are "save state, recompile, restart, restore state." It takes ~300ms. I decided that is good enough.

4. Platform APIs Are Different

Android cameras work through JNI and Java objects. iOS cameras work through AVFoundation and Objective-C. I wrapped both behind the same Crystal interface. You write one camera call. The framework compiles to the right platform code.

5. The Bridge Problem

React Native has a JSON bridge between JS and native. It is slow. Crystal has no bridge. It compiles directly to native code. But that means I cannot change code at runtime. Hot reload is not possible the way React Native does it. I had to invent a different approach: fast restart with state preservation.

6. Keeping It Simple

I could have built a full APK packager, a Gradle plugin, an Xcode integration. That would have taken months. I decided to stop at compiling Crystal to .so and .framework files. You already know how to use Android Studio and Xcode. You handle the final packaging.

---

## Decisions I Made

Decision Why
AOT only, no JIT Mobile platforms restrict runtime code generation
Fast restart instead of hot reload Crystal compiles to native code. State preservation works well enough
User handles APK/IPA packaging Android Studio and Xcode already exist. I focus on the Crystal part
Direct FFI, no bridge Serialization is slow. Crystal calls C/Obj-C directly
Metal on iOS, OpenGL on Android Metal is required for modern iOS. OpenGL works everywhere on Android
State preservation via @[Preserve] macro Developers mark what to save. I handle the rest

---

## Documentation

Full documentation is available at: [docs](https://github.com/slick-lab/native.cr/blob/main/docs)

For API reference, guides, and examples, visit the docs site.

---

Community

- Discord - Chat with me and other developers
- GitHub Issues - Report bugs or request features
- Twitter - Follow for updates

---

License

MIT License. See LICENSE for details.

---

Built with frustration. Released with love.
