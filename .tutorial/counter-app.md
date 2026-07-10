# Tutorial: Counter App

Build an interactive counter with state management.

**Time:** 15 minutes
**Difficulty:** Beginner

---

## What You'll Build

A counter app with increment/decrement buttons. You'll learn:

- Handling button clicks
- Managing application state
- Updating the UI dynamically
- Using Preferences for persistence

---

## Step 1: Create the App Class

Create a new file `src/app/main.cr`:

```crystal
require "native"

class CounterApp < Native::App
  @[Preserve]
  property count : Int32 = 0

  @layout : Native::UI::LinearLayout
  @count_label : Native::UI::TextView
  @increment_btn : Native::UI::Button
  @decrement_btn : Native::UI::Button

  def setup
    build_ui
    load_count
    update_display
  end

  def build_ui
    # Main vertical layout
    @layout = Native::UI::LinearLayout.new
    @layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    @layout.gravity = Native::UI::LinearLayout::Gravity::Center
    @layout.set_padding(24, 24, 24, 24)

    # Title
    title = Native::UI::TextView.new("Counter")
    title.text_size = 32
    title.text_color = Native::Math::Color.from_rgba(51, 51, 51, 255)
    title.center

    # Count display
    @count_label = Native::UI::TextView.new("0")
    @count_label.text_size = 72
    @count_label.text_color = Native::Math::Color.blue
    @count_label.center

    # Buttons layout (horizontal)
    button_row = Native::UI::LinearLayout.new
    button_row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
    button_row.gravity = Native::UI::LinearLayout::Gravity::CenterHorizontal

    # Decrement button
    @decrement_btn = Native::UI::Button.new("-")
    @decrement_btn.text_size = 24
    @decrement_btn.width = 80
    @decrement_btn.height = 80

    # Increment button
    @increment_btn = Native::UI::Button.new("+")
    @increment_btn.text_size = 24
    @increment_btn.width = 80
    @increment_btn.height = 80

    button_row.addView(@decrement_btn)
    button_row.addView(@increment_btn)

    # Add all to main layout
    @layout.addView(title)
    @layout.addView(@count_label)
    @layout.addView(button_row)

    # Set up click handlers
    @increment_btn.on_click { increment }
    @decrement_btn.on_click { decrement }
  end

  def increment
    @count += 1
    update_display
    save_count
  end

  def decrement
    @count -= 1
    update_display
    save_count
  end

  def update_display
    @count_label.text = @count.to_s

    # Change color based on count
    if @count > 0
      @count_label.text_color = Native::Math::Color.green
    elsif @count < 0
      @count_label.text_color = Native::Math::Color.red
    else
      @count_label.text_color = Native::Math::Color.blue
    end
  end

  def save_count
    prefs = Native::Storage::Preferences.new
    prefs.set("count", @count)
  end

  def load_count
    prefs = Native::Storage::Preferences.new
    @count = prefs.get_int("count", 0)
  end

  def on_pause
    save_count
  end

  def on_resume
    # Could refresh from storage if needed
  end
end

Native::App.registered_subclass = CounterApp
```

---

## Step 2: Understanding State Management

### The @[Preserve] Annotation

```crystal
@[Preserve]
property count : Int32 = 0
```

The `@[Preserve]` annotation marks properties that should survive hot reloads during development. Without this, variables reset to their default values when you reload.

### Updating UI Dynamically

```crystal
def update_display
  @count_label.text = @count.to_s
end
```

When state changes, update the corresponding UI elements. This keeps your display in sync with your data.

---

## Step 3: Working with Buttons

### Creating a Button

```crystal
@increment_btn = Native::UI::Button.new("+")
@increment_btn.text_size = 24
@increment_btn.width = 80
@increment_btn.height = 80
```

Buttons support these properties:

| Property | Description |
|----------|-------------|
| `text` | Button label |
| `text_size` | Font size |
| `text_color` | Text color (Native::Math::Color) |
| `background_color` | Button color (Native::Math::Color) |
| `width`, `height` | Dimensions in pixels |

### Handling Clicks

```crystal
@increment_btn.on_click { increment }
```

Use `on_click` to register a callback that runs when the button is tapped.

### Button Colors

```crystal
@increment_btn.background_color = Native::Math::Color.blue
@increment_btn.text_color = Native::Math::Color.white
```

Colors use `Native::Math::Color`:

```crystal
# Predefined colors
Color.white
Color.black
Color.red
Color.green
Color.blue

# Custom color (RGBA normalized 0-1)
Color.new(0.8, 0.4, 0.2, 1.0)

# From RGBA values (0-255)
Color.from_rgba(200, 100, 50, 255)
```

---

## Step 4: Layout with Horizontals

This tutorial shows both vertical and horizontal layouts:

```crystal
# Main layout - vertical stack
@layout = Native::UI::LinearLayout.new
@layout.orientation = Native::UI::LinearLayout::Orientation::Vertical

# Button row - horizontal
button_row = Native::UI::LinearLayout.new
button_row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
```

Result:

```
┌──────────────────────┐
│                      │
│      Counter         │  <- title
│                      │
│         42           │  <- count_label
│                      │
│    ┌───┐  ┌───┐      │
│    │ - │  │ + │      │  <- button_row (horizontal)
│    └───┘  └───┘      │
│                      │
└──────────────────────┘
```

---

## Step 5: Data Persistence

### Saving Data

```crystal
def save_count
  prefs = Native::Storage::Preferences.new
  prefs.set("count", @count)
end
```

`Preferences` stores key-value pairs:

- `set(key, value)` — Store any JSON-serializable value
- `get_int(key, default)` — Retrieve integer
- `get_string(key)` — Retrieve string
- `get_bool(key, default)` — Retrieve boolean

### Loading Data

```crystal
def load_count
  prefs = Native::Storage::Preferences.new
  @count = prefs.get_int("count", 0)
end
```

Always provide a default value for when the key doesn't exist.

### Lifecycle Hook

```crystal
def on_pause
  save_count  # Save when app goes to background
end
```

`on_pause` is called when your app goes to the background. This is the right time to save unsaved data.

---

## Complete Code with Features

Here's an enhanced version with a reset button and limits:

```crystal
require "native"

class CounterApp < Native::App
  @[Preserve]
  property count : Int32 = 0

  MIN_VALUE = -100
  MAX_VALUE = 100

  @layout : Native::UI::LinearLayout
  @count_label : Native::UI::TextView
  @status_label : Native::UI::TextView

  def setup
    build_ui
    load_count
    update_display
  end

  def build_ui
    @layout = Native::UI::LinearLayout.new
    @layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    @layout.gravity = Native::UI::LinearLayout::Gravity::Center
    @layout.set_padding(24, 24, 24, 24)

    # Title
    title = Native::UI::TextView.new("Counter")
    title.text_size = 28
    title.center

    # Count display
    @count_label = Native::UI::TextView.new("0")
    @count_label.text_size = 72
    @count_label.center

    # Status message
    @status_label = Native::UI::TextView.new("")
    @status_label.text_size = 14
    @status_label.center

    # Buttons row
    button_row = Native::UI::LinearLayout.new
    button_row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
    button_row.gravity = Native::UI::LinearLayout::Gravity::CenterHorizontal

    minus_btn = Native::UI::Button.new("-")
    minus_btn.width = 70
    minus_btn.height = 70
    minus_btn.text_size = 28
    minus_btn.background_color = Native::Math::Color.from_rgba(0.8, 0.2, 0.2, 1.0)
    minus_btn.on_click { decrement }

    reset_btn = Native::UI::Button.new("0")
    reset_btn.width = 70
    reset_btn.height = 70
    reset_btn.text_size = 20
    reset_btn.background_color = Native::Math::Color.from_rgba(0.5, 0.5, 0.5, 1.0)
    reset_btn.on_click { reset }

    plus_btn = Native::UI::Button.new("+")
    plus_btn.width = 70
    plus_btn.height = 70
    plus_btn.text_size = 28
    plus_btn.background_color = Native::Math::Color.from_rgba(0.2, 0.6, 0.2, 1.0)
    plus_btn.on_click { increment }

    button_row.addView(minus_btn)
    button_row.addView(reset_btn)
    button_row.addView(plus_btn)

    # Instructions
    instructions = Native::UI::TextView.new("Range: -100 to 100")
    instructions.text_size = 12
    instructions.text_color = Native::Math::Color.from_rgba(128, 128, 128, 255)
    instructions.center

    @layout.addView(title)
    @layout.addView(@count_label)
    @layout.addView(@status_label)
    @layout.addView(button_row)
    @layout.addView(instructions)
  end

  def increment
    return if @count >= MAX_VALUE
    @count += 1
    update_display
    save_count
  end

  def decrement
    return if @count <= MIN_VALUE
    @count -= 1
    update_display
    save_count
  end

  def reset
    @count = 0
    update_display
    save_count
  end

  def update_display
    @count_label.text = @count.to_s
    @status_label.text = ""

    if @count > 0
      @count_label.text_color = Native::Math::Color.from_rgba(0.2, 0.6, 0.2, 1.0)
    elsif @count < 0
      @count_label.text_color = Native::Math::Color.from_rgba(0.8, 0.2, 0.2, 1.0)
    else
      @count_label.text_color = Native::Math::Color.blue
    end

    if @count >= MAX_VALUE
      @status_label.text = "Maximum reached!"
    elsif @count <= MIN_VALUE
      @status_label.text = "Minimum reached!"
    end
  end

  def save_count
    prefs = Native::Storage::Preferences.new
    prefs.set("count", @count)
  end

  def load_count
    prefs = Native::Storage::Preferences.new
    @count = prefs.get_int("count", 0)
  end

  def on_pause
    save_count
  end
end

Native::App.registered_subclass = CounterApp
```

---

## What You Learned

- Creating interactive buttons with `on_click`
- Managing state with properties
- Using `@[Preserve]` for hot reload
- Updating UI from state changes
- Persisting data with `Preferences`
- Combining vertical and horizontal layouts

---

## Challenges

1. Add a step input to change the increment amount
2. Add haptic feedback on button press using `Native::Platform.vibrate(50)`
3. Save and restore the count on app restart
4. Add animations when the count changes

---

## Next Tutorial

Continue with [Task Manager](task-manager.md) to build a list-based app with input fields.
