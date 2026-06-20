# native.cr Documentation

**native.cr** is a Crystal-language framework for building real native mobile apps — for Android and iOS — using the [Crystal programming language](https://crystal-lang.org/). Think of it as "React Native, but for Crystal developers."

You write Crystal code once. The CLI compiles it into a native Android APK or an iOS app. No JavaScript, no WebView — your UI is rendered with OpenGL ES on Android and Metal on iOS.

---

## What can I build with it?

- Productivity apps, social apps, dashboards
- Games with custom rendering
- Apps that use the camera, GPS, microphone, sensors
- Apps with in-app purchases and subscriptions
- Anything you'd normally build as a native mobile app

---

## Documentation index

| Guide | What it covers |
|---|---|
| [Getting Started](./getting-started.md) | Install the CLI, create a project, run your first app |
| [App Lifecycle](./app-lifecycle.md) | `Native::App`, `setup`, lifecycle callbacks, hot-reload state |
| [UI Components](./ui-components.md) | All widgets — text, buttons, images, layouts, inputs, lists |
| [Networking](./networking.md) | HTTP requests, WebSockets, streaming |
| [Storage](./storage.md) | Saving key-value data and files on device |
| [Permissions](./permissions.md) | Requesting camera, location, microphone, etc. |
| [Notifications](./notifications.md) | Local push notifications and scheduled reminders |
| [Location](./location.md) | GPS coordinates and real-time location updates |
| [Sensors](./sensors.md) | Accelerometer, gyroscope, light, proximity, and more |
| [Camera](./camera.md) | Live preview, photo capture, and video recording |
| [Audio](./audio.md) | Sound effects, background music, and microphone recording |
| [Video](./video.md) | In-app video playback |
| [Payments](./payments.md) | In-app purchases and subscriptions |

---

## Quick example

A complete counter app — a label, a button, and persistent storage — in under 40 lines:

```crystal
require "native"

class CounterApp < Native::App
  @[Preserve]                    # survives hot reloads
  property count : Int32 = 0

  @prefs = Native::Storage::Preferences.new("counter")

  def setup
    set_background_color(240, 240, 245)

    # Restore the count from the last session
    @count = @prefs.get_int("count", default: 0)

    @label = Native::UI::TextView.new("Taps: #{@count}")
    @label.text_size = 28
    @label.center_horizontal

    btn = Native::UI::Button.new("Tap Me")
    btn.width            = 180
    btn.height           = 52
    btn.background_color = Native::Math::Color.from_hex(0x007AFF)
    btn.text_color       = Native::Math::Color.white
    btn.on_click {
      @count += 1
      @prefs.set("count", @count)
      @label.text = "Taps: #{@count}"
    }

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity     = Native::UI::LinearLayout::Gravity::Center
    layout.addView(@label)
    layout.addView(btn)
    @root = layout
  end
end

Native::App.start(CounterApp)
```

Key things to notice:

- `Native::App` is the base class — your app inherits from it
- `setup` is the only required method — build your UI here and assign `@root`
- `@[Preserve]` keeps `@count` alive across hot reloads
- `Native::UI::TextView`, `Native::UI::Button`, `Native::UI::LinearLayout` are the core widgets
- `addView` adds children to a layout
- `@root` is what gets rendered

---

## Version

Current version: **0.1.3**
Crystal version required: **1.20+**

## Links

- Source: https://github.com/slick-lab/native.cr
- Homepage: https://slick-lab.github.io/native.cr
- Community: https://discord.gg/nativecr
