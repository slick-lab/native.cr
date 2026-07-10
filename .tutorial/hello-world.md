# Tutorial: Hello World

Build your first native.cr app that displays text on screen.

**Time:** 5 minutes
**Difficulty:** Beginner

---

## What You'll Build

A simple app that displays "Hello, native.cr!" on the screen. You'll learn:

- How to create a native.cr app class
- How to display text using TextView
- How layouts work
- How to run your app

---

## Step 1: Create Project

If you haven't created a project yet:

```bash
crystal main.cr create HelloWorld
cd HelloWorld
```

This creates the project structure with `src/app/main.cr` as your entry point.

---

## Step 2: Write the App

Open `src/app/main.cr` and replace its contents:

```crystal
require "native"

class HelloWorldApp < Native::App
  def setup
    # Create a vertical layout
    @layout = Native::UI::LinearLayout.new
    @layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    @layout.gravity = Native::UI::LinearLayout::Gravity::Center
    @layout.set_padding(16, 16, 16, 16)

    # Create a text label
    @label = Native::UI::TextView.new("Hello, native.cr!")
    @label.text_size = 24
    @label.center

    # Add label to layout
    @layout.addView(@label)
  end

  def on_pause
    # App going to background
  end

  def on_resume
    # App returning to foreground
  end
end

# Register and start the app
Native::App.registered_subclass = HelloWorldApp
```

---

## Step 3: Understanding the Code

### The App Class

```crystal
class HelloWorldApp < Native::App
```

Every native.cr app inherits from `Native::App`. This is your main application class.

### The setup Method

```crystal
def setup
  # Build your UI here
end
```

The `setup` method is called once when your app launches. This is where you create your user interface.

### LinearLayout

```crystal
@layout = Native::UI::LinearLayout.new
@layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
```

`LinearLayout` arranges child views in a row (horizontal) or column (vertical).

- `Orientation::Vertical` — Stack children top to bottom
- `Orientation::Horizontal` — Arrange children left to right

### Gravity

```crystal
@layout.gravity = Native::UI::LinearLayout::Gravity::Center
```

Gravity controls alignment. Options:

| Gravity | Effect |
|---------|--------|
| `Top` | Align to top |
| `Bottom` | Align to bottom |
| `Left` | Align to left |
| `Right` | Align to right |
| `Center` | Center both horizontally and vertically |
| `CenterHorizontal` | Center horizontally |
| `CenterVertical` | Center vertically |

### TextView

```crystal
@label = Native::UI::TextView.new("Hello, native.cr!")
@label.text_size = 24
```

`TextView` displays text. Key properties:

- `text = "..."` — Set the text content
- `text_size = 24` — Font size in sp (scaled pixels)
- `text_color = Native::Math::Color.red` — Text color
- `center` — Center the text
- `left` — Align left
- `right` — Align right

### Adding Views

```crystal
@layout.addView(@label)
```

Use `addView` to add child views to a layout.

### Registration

```crystal
Native::App.registered_subclass = HelloWorldApp
```

This tells the framework which class is your app. Required for Android builds.

---

## Step 4: Run the App

### Android

Build and install:

```bash
# Build debug APK
crystal src/native.cr build android

# Install on connected device/emulator
adb install -r build/android/app-debug.apk
```

### iOS (macOS only)

```bash
# Build for iOS
crystal src/native.cr build ios

# Open in Xcode to run
open ios/HelloWorld.xcworkspace
```

---

## Step 5: Customize

Try these modifications:

### Change the Text

```crystal
@label = Native::UI::TextView.new("Welcome to native mobile development!")
@label.text_size = 20
@label.text_color = Native::Math::Color.blue
```

### Add Another Label

```crystal
@subtitle = Native::UI::TextView.new("Build native apps with Crystal")
@subtitle.text_size = 16
@subtitle.text_color = Native::Math::Color.from_rgba(100, 100, 100, 255)
@subtitle.center

@layout.addView(@label)
@layout.addView(@subtitle)  # Add after main label
```

### Add Padding Between Views

LinearLayout doesn't have spacing between children. Wrap each child in a padding container:

```crystal
# Create a wrapper layout for spacing
def create_spaced_view(view : Native::UI::View, top : Int32 = 0) : Native::UI::View
  container = Native::UI::LinearLayout.new
  container.set_padding(0, top, 0, 0)
  container.addView(view)
  container
end
```

---

## Complete Code

```crystal
require "native"

class HelloWorldApp < Native::App
  @layout : Native::UI::LinearLayout
  @label : Native::UI::TextView

  def setup
    # Create vertical layout centered on screen
    @layout = Native::UI::LinearLayout.new
    @layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    @layout.gravity = Native::UI::LinearLayout::Gravity::Center
    @layout.set_padding(16, 16, 16, 16)

    # Main greeting
    @label = Native::UI::TextView.new("Hello, native.cr!")
    @label.text_size = 28
    @label.text_color = Native::Math::Color.from_rgba(51, 51, 51, 255)
    @label.center

    @layout.addView(@label)
  end

  def on_pause
  end

  def on_resume
  end
end

Native::App.registered_subclass = HelloWorldApp
```

---

## What You Learned

- Creating app classes with `Native::App`
- Building UIs with `LinearLayout`
- Displaying text with `TextView`
- Setting gravity for alignment
- Adding views to layouts

---

## Next Tutorial

Continue with [Counter App](counter-app.md) to learn about user interaction and state management.
