# App Lifecycle

Every native.cr app is built around a single class that inherits from `Native::App`. This class is the heart of your application.

---

## Creating your app class

```crystal
require "native"

class MyApp < Native::App
  def setup
    # your UI setup goes here
  end

  def draw
    @root.draw(renderer)
  end
end

Native::App.start(MyApp)
```

`Native::App.start(MyApp)` creates an instance of your class, restores any saved state, and calls `setup`.

---

## Required methods

### `setup : Nil`

Called **once** when the app first launches. This is where you:
- Create UI components
- Load saved data
- Set up callbacks
- Set the background color

```crystal
def setup
  set_background_color(255, 255, 255)  # white background (R, G, B)

  @label = UI::Text.new
  @label.text = "Welcome!"

  @root = @label
end
```

### `draw : Nil`

Called **every frame** (roughly 60 times per second). You must call `@root.draw(renderer)` here to paint your UI.

```crystal
def draw
  @root.draw(renderer)
end
```

---

## Optional lifecycle callbacks

Override any of these to react to events:

```crystal
# Called when the user touches the screen (finger goes down)
def on_touch_began(x : Float32, y : Float32) : Nil
end

# Called when the user moves their finger
def on_touch_moved(x : Float32, y : Float32) : Nil
end

# Called when the user lifts their finger
def on_touch_ended(x : Float32, y : Float32) : Nil
end

# Called when a key is pressed (useful on desktop/emulator)
def on_key_pressed(key : Int32) : Nil
end

# Called when a key is released
def on_key_released(key : Int32) : Nil
end

# Called when the app goes into the background (user switches away)
def on_pause : Nil
end

# Called when the app comes back to the foreground
def on_resume : Nil
end

# Called just before the app is destroyed
def on_destroy : Nil
end
```

### Example — pause and resume the camera

```crystal
def on_pause
  @camera.close if @camera
end

def on_resume
  @camera.open if @camera && !@camera.is_open?
end
```

---

## State preservation (hot reload)

When you use fast reload (`native.cr reload`), the app restarts but your instance variables are lost — unless you mark them with `@[Preserve]`.

```crystal
class MyApp < Native::App
  @[Preserve]
  property score : Int32 = 0

  @[Preserve]
  property player_name : String = ""
end
```

State is serialised to JSON between reloads and restored automatically. Any field marked `@[Preserve]` must be a JSON-serialisable type (`Int32`, `String`, `Bool`, `Float64`, `Array`, `Hash`, etc.).

---

## Saving and loading state manually

You can override `state_to_json` and `state_from_json` if you want fine-grained control:

```crystal
def state_to_json : String
  { score: @score, name: @player_name }.to_json
end

def state_from_json(json : String) : Nil
  data = JSON.parse(json)
  @score = data["score"].as_i
  @player_name = data["name"].as_s
rescue
  # ignore malformed state
end
```

---

## Background colour

Set the screen background colour in `setup` (or any time):

```crystal
set_background_color(240, 240, 245)       # light grey (R, G, B, each 0-255)
set_background_color(30, 30, 35)          # dark theme
```

---

## Accessing the running app instance

From anywhere in your code you can get the current app:

```crystal
app = Native::App.current
```

This is useful when a callback in a child component needs to call a method on the app.
