# native.cr Documentation

**native.cr** is a Crystal framework for building real native mobile apps — for Android and iOS — using the [Crystal programming language](https://crystal-lang.org/). Think of it as "React Native, but for Crystal developers."

You write Crystal code once and it compiles down to a true native app on both platforms.

---

## What can I build with it?

Anything you'd normally build as a mobile app:

- Apps with buttons, text, images, lists, forms
- Apps that talk to the internet (HTTP, WebSockets)
- Apps that use the camera, microphone, GPS
- Games with a game loop
- Apps with push notifications, in-app purchases, and sensors

---

## Documentation index

| Guide | What it covers |
|---|---|
| [Getting Started](./getting-started.md) | Install, create a project, run your first app |
| [App Lifecycle](./app-lifecycle.md) | The `Native::App` base class, setup, callbacks |
| [UI Components](./ui-components.md) | Text, Button, Image, layouts, and all other widgets |
| [Networking](./networking.md) | HTTP requests, WebSockets, streaming |
| [Storage](./storage.md) | Saving key-value data and files on device |
| [Permissions](./permissions.md) | Requesting camera, location, microphone, etc. |
| [Notifications](./notifications.md) | Local push notifications and scheduled reminders |
| [Location](./location.md) | GPS coordinates and real-time location updates |
| [Sensors](./sensors.md) | Accelerometer, gyroscope, light, and more |
| [Camera](./camera.md) | Taking photos and recording video |
| [Audio](./audio.md) | Playing sounds, music, and recording audio |
| [Video](./video.md) | Playing video files inside your app |
| [Payments](./payments.md) | In-app purchases and subscriptions |

---

## Quick example

Here is a complete counter app — a label, a button, persistent storage, and haptic feedback — in about 50 lines of Crystal:

```crystal
require "native"

class CounterApp < Native::App
  @[Preserve]
  property count : Int32 = 0   # @[Preserve] keeps this alive across hot reloads

  def setup
    set_background_color(240, 240, 245)

    @label = UI::Text.new
    @label.text = "Tap count: 0"
    @label.text_size = 24

    button = UI::Button.new
    button.text = "Tap Me"
    button.background_color = Color.from_hex(0x007AFF)
    button.text_color = Color.white
    button.on_click = -> { increment }

    column = UI::Column.new
    column.spacing = 24
    column.alignment = Alignment::Center
    column.add_child(@label)
    column.add_child(button)

    @root = column
  end

  def increment
    @count += 1
    @label.text = "Tap count: #{@count}"
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(CounterApp)
```

---

## Version

Current version: **0.1.3**  
Crystal version required: **1.20+**

## Links

- Homepage: https://slick-lab.github.io/native.cr
- Source: https://github.com/slick-lab/native.cr
- Community: https://discord.gg/nativecr
