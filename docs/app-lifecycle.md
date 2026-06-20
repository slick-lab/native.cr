# App Lifecycle

Every native.cr app is built around a single class that inherits from `Native::App`. This guide explains how your app starts, runs, pauses, and shuts down — and how to preserve state across hot reloads.

---

## The minimal app

```crystal
require "native"

class MyApp < Native::App
  def setup
    label = Native::UI::TextView.new
    label.text = "Hello, world!"
    label.text_size = 28
    @root = label
  end
end

Native::App.start(MyApp)
```

That is a complete, working app. `setup` is the **only** method you are required to implement.

---

## How `Native::App.start` works

```crystal
Native::App.start(MyApp)
```

This does the following steps, in order:

1. Creates a new instance of your class
2. Registers it as the current app (`Native::App.current`)
3. Restores any saved state (from a previous hot reload)
4. Calls your `setup` method
5. Starts the event loop (`run`)

The event loop calls `on_pause`, `on_resume`, `on_destroy`, and the touch callbacks as the user interacts with the device.

---

## `setup` — the one required method

```crystal
def setup : Nil
  # Build your UI here.
  # Set the background colour.
  # Load saved preferences.
  # Wire up callbacks.
end
```

`setup` is called **once** when the app first launches (or after a hot reload). Heavy work like building the layout tree belongs here, not in callbacks.

### Setting the background colour

```crystal
set_background_color(255, 255, 255)    # white  (R, G, B, each 0–255)
set_background_color(30, 30, 35)       # dark background
set_background_color(240, 240, 245)    # light grey
```

### Assigning the root view

Your `setup` method should assign the top-level layout or view to `@root`. The framework uses `@root` to know what to display.

```crystal
@root = my_layout
```

---

## Lifecycle callbacks

Override any of these to react to system events. They are all no-ops by default:

```crystal
# Called when a finger touches the screen
def on_touch_began(x : Float32, y : Float32) : Nil
end

# Called when a finger slides across the screen
def on_touch_moved(x : Float32, y : Float32) : Nil
end

# Called when a finger lifts from the screen
def on_touch_ended(x : Float32, y : Float32) : Nil
end

# Called when a hardware key is pressed (useful in emulators or on devices with keyboards)
def on_key_pressed(key : Int32) : Nil
end

# Called when a hardware key is released
def on_key_released(key : Int32) : Nil
end

# Called when the user switches to another app (app goes to background)
def on_pause : Nil
end

# Called when the user comes back to your app
def on_resume : Nil
end

# Called just before the app is destroyed
def on_destroy : Nil
end
```

### Example — pause the camera when backgrounded

```crystal
def on_pause
  @camera.stop_preview
end

def on_resume
  @camera.start_preview(@preview_view)
end
```

### Example — save a high score when destroyed

```crystal
def on_destroy
  prefs = Native::Storage::Preferences.new("game")
  prefs.set("high_score", @high_score)
end
```

---

## Hot reload and state preservation

When you run `native.cr reload main.cr`, the app is rebuilt and `setup` is called again. Any instance variable that was not marked `@[Preserve]` is reset to its initial value.

To keep a value across reloads, annotate it with `@[Preserve]`:

```crystal
class MyApp < Native::App
  @[Preserve]
  property score : Int32 = 0

  @[Preserve]
  property player_name : String = ""

  @[Preserve]
  property items : Array(String) = [] of String
end
```

`@[Preserve]` works with any JSON-serialisable type:
- `Int32`, `Int64`, `Float32`, `Float64`
- `String`, `Bool`
- `Array(T)` and `Hash(String, T)` where `T` is also serialisable

### How it works under the hood

When a reload is triggered, the framework:
1. Sends `SIGUSR1` to your process, which calls `state_to_json` and writes it to a temp file
2. Terminates the old process
3. Launches the new process, which calls `load_saved_state` → `state_from_json` before `setup`

---

## Customising state serialisation

If you need fine control, override these two methods:

```crystal
def state_to_json : String
  {
    score:  @score,
    name:   @player_name,
    level:  @current_level,
  }.to_json
end

def state_from_json(json : String) : Nil
  data = JSON.parse(json)
  @score         = data["score"].as_i
  @player_name   = data["name"].as_s
  @current_level = data["level"].as_i
rescue
  # Ignore malformed or missing state — safe to skip
end
```

---

## Accessing the running app from anywhere

```crystal
app = Native::App.current   # returns your app instance as Native::App
```

If you need to call a method specific to your subclass:

```crystal
if app = Native::App.current.as?(MyApp)
  app.show_notification("Hello!")
end
```

---

## The `run` loop

You do not normally need to touch `run`. It is the internal event loop:

```crystal
def run : Nil
  loop do
    sleep 0.016.seconds   # ~60 fps heartbeat
  end
end
```

The native engine calls your touch callbacks and lifecycle hooks through a separate JNI/Objective-C bridge, independently of this loop. Override `run` only if you need a fully custom game loop — and if you do, call `super` or implement the same sleep/yield pattern to avoid 100% CPU usage.

---

## Full lifecycle example

```crystal
require "native"

class TodoApp < Native::App
  @[Preserve]
  property todos : Array(String) = [] of String

  @prefs = Native::Storage::Preferences.new("todo_app")

  def setup
    set_background_color(250, 250, 252)

    # Restore todos from persistent storage (survives full app restarts)
    saved = @prefs.get_string("todos", default: "")
    @todos = saved.split("\n").reject(&.empty?) if saved.size > 0

    build_ui
  end

  def build_ui
    @list_view = Native::UI::LinearLayout.new
    @list_view.orientation = Native::UI::LinearLayout::Orientation::Vertical
    refresh_list

    scroll = Native::UI::ScrollView.new
    scroll.addView(@list_view)

    @input = Native::UI::EditText.new
    @input.hint = "Add a todo…"
    @input.width = 280

    add_btn = Native::UI::Button.new("Add")
    add_btn.on_click { add_todo }

    row = Native::UI::LinearLayout.new(Native::UI::LinearLayout::Orientation::Horizontal)
    row.addView(@input)
    row.addView(add_btn)

    root = Native::UI::LinearLayout.new
    root.orientation = Native::UI::LinearLayout::Orientation::Vertical
    root.set_padding(16, 16, 16, 16)
    root.addView(row)
    root.addView(scroll)
    @root = root
  end

  def add_todo
    text = @input.text.strip
    return if text.empty?
    @todos << text
    @input.text = ""
    @prefs.set("todos", @todos.join("\n"))
    refresh_list
  end

  def refresh_list
    @list_view.removeAllViews
    @todos.each do |todo|
      item = Native::UI::TextView.new(todo)
      item.text_size = 16
      @list_view.addView(item)
    end
  end

  def on_pause
    @prefs.set("todos", @todos.join("\n"))
  end
end

Native::App.start(TodoApp)
```
