# Getting Started

Create your first native.cr app in minutes. This guide covers installation, creating a project, and running it.

---

## What You'll Need

| Tool | For | Install |
|------|-----|---------|
| Crystal 1.20+ | Everything | [crystal-lang.org/install](https://crystal-lang.org/install/) |
| Android NDK r25+ | Android | [developer.android.com/ndk](https://developer.android.com/ndk) |
| Xcode 14+ | iOS (macOS only) | Mac App Store |
| Java 17+ | Android | [adoptium.net](https://adoptium.net/) |

Crystal includes Shards (package manager).

---

## Install the CLI

```bash
git clone https://github.com/slick-lab/native.cr
cd native.cr
make install
```

Verify:

```bash
native.cr --version
# Native 0.1.6
```

---

## Check Your Setup

```bash
native.cr doctor
```

You should see:

```
✓ Crystal 1.20.1
✓ Android NDK r25c
✓ Xcode 14.3
✓ Java 17
```

---

## Create Your First App

```bash
native.cr create MyApp
cd MyApp
```

This creates:

```
MyApp/
├── shard.yml    ← Dependencies
├── main.cr       ← Your app
└── assets/       ← Images, sounds, fonts
```

---

## Understanding the Code

`main.cr` contains a counter app:

```crystal
require "native"

class MyApp < Native::App
  @[Preserve]
  property count : Int32 = 0

  def setup
    set_background_color(240, 240, 245)

    @label = Native::UI::TextView.new("Taps: 0")
    @label.text_size = 28

    btn = Native::UI::Button.new("Tap Me")
    btn.width = 180
    btn.height = 52
    btn.background_color = Native::Math::Color.from_hex(0x007AFF)
    btn.text_color = Native::Math::Color.white
    btn.on_click {
      @count += 1
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

Native::App.registered_subclas = MyApp
```

**Walkthrough:**

1. `require "native"` — Loads the framework
2. `class MyApp < Native::App` — Your app class
3. `@[Preserve]` — Keeps `@count` across hot reloads
4. `def setup` — **Required.** Build your UI here
5. `@root = layout` — Sets what renders

---

## Run with Hot Reload

```bash
native.cr reload main.cr
```

Edit and save — the app updates in ~2 seconds. State marked with `@[Preserve]` is preserved.

---

## Build for Device

### Android

```bash
native.cr build android
native.cr android install
```

### iOS

```bash
native.cr build ios
open ios/MyApp.xcodeproj
```

Run from Xcode.

---

## Project Structure

For larger apps:

```
MyApp/
├── main.cr
├── shard.yml
├── assets/
│   ├── images/
│   ├── sounds/
│   └── fonts/
└── src/
    ├── screens/
    └── components/
```

Require modules:

```crystal
require "native"
require "./src/screens/home_screen"
```

---

## Next Steps

| Topic | Guide |
|-------|-------|
| Lifecycle, callbacks | [App Lifecycle](./app-lifecycle.md) |
| All widgets | [UI Components](./ui-components.md) |
| HTTP, WebSockets | [Networking](./networking.md) |
| Saving data | [Storage](./storage.md) |
