# Tutorial 1 — Your First App

Build, run, and modify a small native app on Android and iOS. By the end you
will have tapped a real native button that updates a real native label.

---

## 1. Create the project

```bash
native.cr create FirstApp
cd FirstApp
```

You get:

```
FirstApp/
├── shard.yml    ← dependencies (the native.cr shard)
├── src/main.cr  ← your entire app
└── assets/      ← images, sounds, fonts
```

---

## 2. The whole app

Replace `src/main.cr` with:

```crystal
require "native"

class FirstApp < Native::App
  @[Preserve]
  property count : Int32 = 0

  def setup
    set_background_color(245, 245, 250)

    @title = Native::UI::TextView.new("Counter")
    @title.text_size = 32

    @label = Native::UI::TextView.new("Taps: 0")
    @label.text_size = 20

    btn = Native::UI::Button.new("Tap me")
    btn.width = 180
    btn.height = 52
    btn.background_color = Native::Math::Color.from_hex(0x007AFF)
    btn.text_color = Native::Math::Color.white
    btn.on_click do
      @count += 1
      @label.text = "Taps: #{@count}"
    end

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(@title)
    layout.addView(@label)
    layout.addView(btn)

    @root = layout
  end
end

Native::App.registered_subclas = FirstApp
```

### What each part does

| Piece | Meaning |
|-------|---------|
| `class FirstApp < Native::App` | One app class per project. `setup` runs once at launch. |
| `@[Preserve]` | Keeps `@count` alive across hot reloads. Anything you mutate at runtime should carry it. |
| `@root = layout` | Only `@root` renders. Everything else hangs off it. |
| `btn.on_click` | A real click listener on a real native view — not a DOM event. |
| `Native::App.registered_subclas = FirstApp` | Tells the runtime which class to instantiate. |

> Note the spelling: `registered_subclas` (one "s") — that is the real API.

---

## 3. Run it

**Android** (needs the NDK):

```bash
native.cr build android
```

The APK lands in `build/`. Install it:

```bash
adb install build/FirstApp.apk
```

**iOS** (needs a Mac with Xcode):

```bash
native.cr create FirstApp --ios   # emits a complete Xcode project
native.cr build ios               # cross-compiles + packages an IPA
```

Without `APPLE_TEAM_ID` set you get a simulator IPA you can drag into a
simulator; with it, a signed device IPA.

**Hot reload** while iterating:

```bash
native.cr reload src/main.cr
```

---

## 4. Exercises

1. Add a reset button that sets `@count = 0` and updates the label.
2. Give each widget a different `text_size` and `background_color`.
3. Add a `Native::UI::ImageView` showing an image from `assets/`.

Next: [Tutorial 2 — A Persistent To-Do List](02-todo-list.md)
