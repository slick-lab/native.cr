# Getting Started

This guide walks you through installing native.cr, creating your first project, and running it on a real device or emulator.

---

## Prerequisites

You need the following tools installed before you begin:

| Tool | Required for | Install |
|---|---|---|
| Crystal 1.20+ | Everything | https://crystal-lang.org/install/ |
| Android NDK r25+ | Android builds | https://developer.android.com/ndk |
| Xcode 14+ | iOS builds (macOS only) | Mac App Store |

Crystal comes bundled with **Shards** (the package manager). You do not need to install it separately.

---

## Install the native.cr CLI

```bash
git clone https://github.com/slick-lab/native.cr
cd native.cr
make install
```

Verify the install:

```bash
native.cr --version
# Native 0.1.3
```

---

## Check your toolchain

```bash
native.cr doctor
```

This prints a checklist of everything native.cr needs. Fix any ✗ items before continuing.

---

## Create a new project

```bash
native.cr create MyApp
cd MyApp
```

Your new project looks like this:

```
MyApp/
├── shard.yml     ← project name, version, and dependencies
├── main.cr       ← your app entry point
└── assets/       ← put images, fonts, and sounds here
```

---

## Open `main.cr`

The file already contains a starter app. Here is a minimal working example — a counter that increments on every tap:

```crystal
require "native"

class MyApp < Native::App
  @[Preserve]             # keeps @count alive across hot reloads
  property count : Int32 = 0

  def setup
    set_background_color(240, 240, 245)

    @label = Native::UI::TextView.new("Taps: 0")
    @label.text_size = 28

    btn = Native::UI::Button.new("Tap Me")
    btn.width  = 180
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

Native::App.start(MyApp)
```

The only method you **must** implement is `setup`. That is where you build your UI and set `@root`.

---

## Build and install

### Android

```bash
# Compile and produce an APK
native.cr build --android

# Install the APK directly on a connected Android device
native.cr android install
```

Make sure your device has **USB Debugging** enabled in Developer Options.

### iOS

```bash
# Compile and wrap in an Xcode project
native.cr build --ios
```

Open the generated Xcode project and run it on a simulator or device using the play button.

---

## Hot reload during development

Full rebuilds are slow. Use hot reload to update the running app instantly as you save:

```bash
native.cr reload main.cr
```

The CLI watches `main.cr` for changes. When it detects a save it:
1. Serialises any `@[Preserve]` state
2. Recompiles
3. Restarts the app and restores the saved state

Your `@count` stays at 42 across a reload because of `@[Preserve]`.

---

## Add dependencies

Edit `shard.yml`:

```yaml
dependencies:
  native:
    github: slick-lab/native.cr
  # add more shards here
  my_lib:
    github: some-user/my_lib
```

Install:

```bash
shards install
```

---

## Project layout conventions

```
MyApp/
├── main.cr           ← app entry point
├── shard.yml         ← dependencies
├── assets/
│   ├── images/       ← .png, .jpg
│   ├── sounds/       ← .wav, .mp3
│   └── fonts/        ← .ttf, .otf
└── src/              ← optional: split your code into multiple files
    ├── screens/
    └── components/
```

Require additional files from `main.cr`:

```crystal
require "native"
require "./src/screens/home_screen"
require "./src/screens/settings_screen"
```

---

## What's next?

| Guide | What to read next |
|---|---|
| [App Lifecycle](./app-lifecycle.md) | How `setup`, callbacks, and `@[Preserve]` work |
| [UI Components](./ui-components.md) | Every widget with full examples |
| [Networking](./networking.md) | HTTP requests and WebSockets |
| [Storage](./storage.md) | Saving data that persists between launches |
| [Permissions](./permissions.md) | Asking for camera, location, etc. |
