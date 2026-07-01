# App Lifecycle

Every native.cr app has a lifecycle. This guide explains how to handle startup, backgrounding, and state preservation.

---

## The App Class

```crystal
class MyApp < Native::App
  def setup
    @root = build_ui
  end
end

Native::App.start(MyApp)
```

`setup` is **the only required method**. Build your UI and assign `@root`.

---

## What Happens on Start

`Native::App.start(MyApp)`:

1. Creates instance of `MyApp`
2. Registers as `Native::App.current`
3. Restores saved state (hot reload)
4. Calls `setup`
5. Starts event loop

---

## Lifecycle Callbacks

```crystal
class MyApp < Native::App
  def setup           # App launches
  def on_pause        # Goes to background
  def on_resume       # Returns to foreground
  def on_destroy      # Process terminating
  def on_touch_began(x, y)   # Touch starts
  def on_touch_moved(x, y)   # Touch moves
  def on_touch_ended(x, y)   # Touch ends
  def on_key_pressed(key)    # Keyboard input
end
```

### When Callbacks Fire

| Event | on_pause | on_resume | on_destroy |
|-------|----------|------------|------------|
| Home button | Yes | — | — |
| Reopen app | — | Yes | — |
| Swipe away | — | — | Maybe* |
| Phone call | Yes | Yes | — |

*Note: `on_destroy` is not guaranteed. Always save in `on_pause`.

---

## Example: Camera App

```crystal
class CameraApp < Native::App
  def setup
    @camera = Native::Media::Camera.new
    @preview = Native::UI::View.new
    @camera.start_preview(@preview)
  end

  def on_pause
    @camera.stop_preview  # Release for other apps
  end

  def on_resume
    @camera.start_preview(@preview)
  end
end
```

---

## State Preservation

Hot reload restarts your app. Preserve state with `@[Preserve]`:

```crystal
class MyApp < Native::App
  @[Preserve]
  property score : Int32 = 0

  @[Preserve]
  property name : String = ""

  @[Preserve]
  property items : Array(String) = [] of String
end
```

**Supported types:** Int, Float, String, Bool, Array, Hash

---

## Custom Serialization

Override for full control:

```crystal
def state_to_json : String
  { score: @score, name: @name }.to_json
end

def state_from_json(json : String)
  data = JSON.parse(json)
  @score = data["score"].as_i
  @name = data["name"].as_s
rescue
end
```

---

## Access App Anywhere

```crystal
app = Native::App.current

# Cast to your type
if app = Native::App.current.as?(MyApp)
  app.update_score(100)
end
```

---

## Summary

| Method | Required? | When |
|--------|-----------|------|
| `setup` | Yes | Launch |
| `on_pause` | No | Background |
| `on_resume` | No | Foreground |
| `on_destroy` | No | Terminate |
| `on_touch_*` | No | Touch events |
