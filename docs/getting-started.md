# Getting Started

This guide walks you through installing native.cr, creating your first project, and running it.

---

## Prerequisites

Before you start, make sure you have:

- **Crystal 1.20+** — the programming language. Install from https://crystal-lang.org/install/
- **Android SDK** (for Android builds) or **Xcode** (for iOS builds)
- A Crystal package manager called **Shards** (it comes bundled with Crystal)

---

## Install the native.cr CLI

The CLI tool is what lets you create, build, and reload your app.

```bash
# Clone and build the CLI
git clone https://github.com/slick-lab/native.cr
cd native.cr
make install
```

Check that it works:

```bash
native.cr --version
# Native 0.1.3
```

---

## Check your toolchain

Run the doctor command — it tells you what is installed and what is missing:

```bash
native.cr doctor
```

Fix any issues it reports before continuing.

---

## Create a new project

```bash
native.cr create MyApp
cd MyApp
```

This creates a folder like this:

```
MyApp/
├── shard.yml         ← project config and dependencies
├── main.cr           ← your app entry point
└── assets/           ← images, fonts, sounds go here
```

---

## Write your app

Open `main.cr`. You will see a starter app. Replace it or extend it — your app is a Crystal class that inherits from `Native::App`:

```crystal
require "native"

class MyApp < Native::App
  def setup
    label = UI::Text.new
    label.text = "Hello, world!"
    label.text_size = 32

    @root = label
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(MyApp)
```

Every app needs at least:
- A `setup` method — runs once when the app starts. Build your UI here.
- A `draw` method — called every frame. Call `@root.draw(renderer)` here.

---

## Build and run

### Android

```bash
native.cr build --android
```

This compiles your Crystal code into a native Android library and packages it as an APK.

To install directly on a connected device:

```bash
native.cr android install
```

### iOS

```bash
native.cr build --ios
```

This compiles your Crystal code and wraps it in an Xcode project you can run on a simulator or device.

---

## Fast reload (development)

Instead of doing a full build every time you change something, you can use hot reload:

```bash
native.cr reload main.cr
```

This watches your file for changes and updates the running app without restarting it. State marked with `@[Preserve]` is restored automatically across reloads.

---

## Add a dependency

Edit `shard.yml` and add to the `dependencies:` section:

```yaml
dependencies:
  native:
    github: slick-lab/native.cr
```

Then run:

```bash
shards install
```

---

## What's next?

- Learn about the [App Lifecycle](./app-lifecycle.md) — how your app starts, pauses, and stops
- Explore [UI Components](./ui-components.md) — all the widgets you can use
- Read about [Networking](./networking.md) to make HTTP requests
