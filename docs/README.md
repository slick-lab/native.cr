# native.cr Documentation

**native.cr** is a Crystal framework for building real native mobile apps — Android and iOS — using the [Crystal programming language](https://crystal-lang.org/).

Think of it as "React Native, but for Crystal developers." You write Crystal code once, it compiles to native ARM64 binaries. No JavaScript runtime. No WebView. Your UI uses real platform views (Android Views via JNI, UIKit via FFI).

---

## Why native.cr?

| Feature | native.cr | React Native | Flutter |
|---------|-----------|--------------|---------|
| Language | Crystal | JS/TS | Dart |
| Runtime | None (compiled) | JavaScriptCore | Dart VM |
| UI | Real native views | Bridged views | Custom renderer |
| Type safety | Compile-time | Optional | Compile-time |
| Binary size | Small | Large | Medium |
| Hot reload | Yes (with state) | Yes | Yes |

Crystal gives you Ruby-like syntax with C-like speed. Your app is a single compiled binary.

---

## What Can You Build?

- Productivity apps, dashboards, social apps
- Games with custom rendering
- Camera, audio, and video apps
- Location-based apps
- Apps with in-app purchases
- Any native mobile app

---

## Documentation Index

### Getting Started

| Guide | Description |
|-------|-------------|
| [Getting Started](./getting-started.md) | Install, create your first app, run it |
| [CLI Reference](./cli.md) | All CLI commands |

### Core Concepts

| Guide | Description |
|-------|-------------|
| [App Lifecycle](./app-lifecycle.md) | App class, callbacks, state |
| [UI Components](./ui-components.md) | All widgets with examples |
| [Navigation](./navigation.md) | Screen stack, toolbar, transitions |
| [Dialogs](./dialogs.md) | Alerts, toasts, loading |
| [Animations](./animations.md) | ValueAnimator, easing |
| [Gestures](./gestures.md) | Tap, pan, pinch, swipe |

### Data & Networking

| Guide | Description |
|-------|-------------|
| [Networking](./networking.md) | HTTP, WebSockets, streaming |
| [Storage](./storage.md) | Preferences, file storage |

### Device Features

| Guide | Description |
|-------|-------------|
| [Permissions](./permissions.md) | Camera, location, mic access |
| [Notifications](./notifications.md) | Local push notifications |
| [Location](./location.md) | GPS, location updates |
| [Sensors](./sensors.md) | Accelerometer, gyro, etc. |
| [Camera](./camera.md) | Photo and video capture |
| [Audio](./audio.md) | Sound effects, music, recording |
| [Video](./video.md) | Video playback |
| [Biometric](./biometric.md) | Fingerprint, Face ID |

### Platform APIs

| Guide | Description |
|-------|-------------|
| [Platform](./platform.md) | Device info, haptics, battery |
| [Payments](./payments.md) | In-app purchases |

### Game Development

| Guide | Description |
|-------|-------------|
| [Game Loop](./game-loop.md) | Fixed/variable updates |
| [Math Utilities](./math.md) | Vector, Rect, Color |

---

## Quick Example

```crystal
require "native"

class CounterApp < Native::App
  @[Preserve]  # Survives hot reloads
  property count : Int32 = 0

  @prefs = Native::Storage::Preferences.new("counter")

  def setup
    set_background_color(240, 240, 245)
    @count = @prefs.get_int("count", default: 0)

    @label = Native::UI::TextView.new("Taps: #{@count}")
    @label.text_size = 28
    @label.center_horizontal

    btn = Native::UI::Button.new("Tap Me")
    btn.width = 180
    btn.height = 52
    btn.background_color = Native::Math::Color.from_hex(0x007AFF)
    btn.text_color = Native::Math::Color.white
    btn.on_click {
      @count += 1
      @prefs.set("count", @count)
      @label.text = "Taps: #{@count}"
    }

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(@label)
    layout.addView(btn)
    @root = layout
  end
end

Native::App.start(CounterApp)
```

**Key points:**
- `Native::App` is your base class
- `setup` builds your UI, assign `@root`
- `@[Preserve]` keeps state across hot reloads
- `Native::UI::*` widgets compose your interface

---

## Platform Support

| Platform | Minimum | Status |
|----------|---------|--------|
| Android | 7.0+ (API 24) | Stable |
| iOS | 11+ | Stable |
| Desktop | — | Dev only |
| Windows | — | Roadmap |
| Linux | — | Roadmap |

---

## Links

- Source: https://github.com/slick-lab/native.cr
- Community: https://discord.gg/nativecr
