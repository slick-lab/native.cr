# Core Concepts

Understanding the fundamentals of native.cr application development.

---

## The App Class

Every native.cr application has a single entry point: a class that inherits from `Native::App`.

```crystal
class MyApp < Native::App
  def setup
    # Build your UI here
    @root = my_screen
  end

  def on_pause
    # App going to background
  end

  def on_resume
    # App returning to foreground
  end

  def on_destroy
    # App being terminated
  end
end
```

The framework creates an instance of your app class and calls `setup` when the app launches. This is where you construct your user interface and initialize your application state.

---

## The Root View [deprecated not needed!]

The `@root` property defines what appears on screen. It must be assigned a view object in your `setup` method.

```crystal
def setup
  label = Native::UI::TextView.new("Hello, World!")
  @root = label
end
```

The root can be any view: a simple label, a button, a complex layout, or a custom composite view.

```crystal
def setup
  layout = Native::UI::LinearLayout.new
  layout.orientation = Native::UI::LinearLayout::Orientation::Vertical

  layout.addView(Native::UI::TextView.new("Title"))
  layout.addView(Native::UI::Button.new("Action"))
end
```

---

## View Hierarchy

Views are organized in a tree structure. Parent views contain child views, and the hierarchy determines layout and touch event propagation.

```crystal
# A simple hierarchy
LinearLayout (vertical)
├── TextView ("Welcome")
├── ImageView (logo)
├── LinearLayout (horizontal)
│   ├── Button ("Login")
│   └── Button ("Register")
└── TextView ("Footer")
```

Building this hierarchy:

```crystal
def setup
  container = Native::UI::LinearLayout.new
  container.orientation = Native::UI::LinearLayout::Orientation::Vertical

  container.addView(Native::UI::TextView.new("Welcome"))
  container.addView(create_logo_image)

  button_row = Native::UI::LinearLayout.new
  button_row.orientation = Native::UI::LinearLayout::Orientation::Horizontal
  button_row.addView(Native::UI::Button.new("Login"))
  button_row.addView(Native::UI::Button.new("Register"))
  container.addView(button_row)

  container.addView(Native::UI::TextView.new("Footer"))


end
```

---

## Properties and State

Application state lives in instance variables. Mark variables that should survive hot reload with `@[Preserve]`.

```crystal
class MyApp < Native::App
  @[Preserve]
  property counter = 0

  @[Preserve]
  property username = ""

  @[Preserve]
  property items = [] of String
end
```

Without `@[Preserve]`, variables reset to their initial values on hot reload. With `@[Preserve]`, the framework serializes and restores them.

---

## Event Handling

Views emit events through callbacks. Register handlers using `on_*` methods.

```crystal
button.on_click { handle_tap }
edittext.on_text_change { |text| validate(text) }
view.on_touch_down { |x, y| start_drag(x, y) }
```

Callbacks capture variables from their enclosing scope:

```crystal
def setup
  items = ["A", "B", "C"]

  items.each_with_index do |item, index|
    btn = Native::UI::Button.new(item)
    btn.on_click { select_item(index) }
    container.addView(btn)
  end
end

def select_item(index : Int32)
  @selected_index = index
end
```

---

## Layouts

Layouts are views that arrange their children.

### LinearLayout

Arranges children in a row or column:

```crystal
layout = Native::UI::LinearLayout.new
layout.orientation = Native::UI::LinearLayout::Orientation::Vertical

# Or horizontal
layout.orientation = Native::UI::LinearLayout::Orientation::Horizontal
```

### FrameLayout

Stacks children on top of each other:

```crystal
frame = Native::UI::FrameLayout.new
frame.addView(background_image)
frame.addView(foreground_content)
```

### ScrollView

Makes content scrollable:

```crystal
scroll = Native::UI::ScrollView.new
scroll.addView(long_content_layout)
```

---

## View Properties

Common properties on all views:

```crystal
view.width = 200          # Width in pixels
view.height = 100         # Height in pixels
view.padding = 16         # All sides
view.padding_left = 8
view.background_color = 0xFFFFFFFF
view.alpha = 0.8          # Opacity 0-1
view.visible = true
view.enabled = true
```

---

## Lifecycle

The app lifecycle follows the platform's Activity (Android) or Scene (iOS) lifecycle.

```
┌─────────────────────────────────────────────────────────────────┐
│                        App Launch                               │
│                            │                                    │
│                            ▼                                    │
│                     setup() called                              │
│                            │                                    │
│                            ▼                                    │
│                    [App is Visible]                             │
│                            │                                    │
│            ┌───────────────┴───────────────┐                   │
│            ▼                               ▼                   │
│      on_pause()                     on_resume()                 │
│   (backgrounded)                  (foregrounded)               │
│            │                               │                   │
│            └───────────────┬───────────────┘                   │
│                            │                                    │
│                            ▼                                    │
│                    on_destroy()                                 │
│                    (terminated)                                 │
└─────────────────────────────────────────────────────────────────┘
```

Use lifecycle callbacks for:

- `setup`: Build UI, initialize state
- `on_pause`: Save data, pause media, release sensors
- `on_resume`: Resume media, restart sensors
- `on_destroy`: Cleanup resources

---

## Threading

The Crystal runtime uses fibers (lightweight threads). UI operations must run on the main fiber.

```crystal
# Wrong: Network on main fiber blocks UI
response = HTTP::Client.get("https://api.example.com/data")

# Right: Spawn a fiber for background work
spawn do
  response = HTTP::Client.get("https://api.example.com/data")
  # Update UI on main fiber
  schedule_on_main { update_ui(response) }
end
```

For network operations, the framework provides async helpers:

```crystal
Native::Network::HTTPClient.get("https://api.example.com/data") { |response|
  # Callback runs on main fiber
  update_ui(response)
}
```

---

## Memory Management

Crystal uses a garbage collector. Objects created in your app are automatically managed.

To release resources explicitly:

```crystal
def on_destroy
  @music.stop if @music
  @camera.stop_preview if @camera
  Native::Sensors::SensorManager.instance.stop_all
end
```

---

## Platform Detection

Write platform-specific code using compile-time flags:

```crystal
{% if flag?(:native_android) %}
  # Android-specific code
  show_toast("Hello from Android")
{% elsif flag?(:native_ios) %}
  # iOS-specific code
  show_alert("Hello from iOS")
{% end %}
```

Or runtime checks:

```crystal
if Native::Platform.android?
  # Android behavior
elsif Native::Platform.ios?
  # iOS behavior
end
```

---

## The Module Structure

native.cr organizes functionality into modules:

| Module | Purpose |
|--------|---------|
| `Native::UI` | View widgets |
| `Native::Network` | HTTP, WebSocket |
| `Native::Storage` | Preferences, files |
| `Native::Media` | Camera, audio, video |
| `Native::Sensors` | Accelerometer, etc. |
| `Native::Location` | GPS |
| `Native::Animation` | Animators |
| `Native::Dialog` | Alerts, toasts |
| `Native::Navigation` | Toolbar |
| `Native::Biometric` | Fingerprint, Face ID |

---

## Next Steps

Now that you understand the fundamentals:

- [UI Components](ui-components.md) — Explore available widgets
- [Layouts and Styling](layout.md) — Position and style views
- [Tutorial: First App](tutorial.md) — Build something real
