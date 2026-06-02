# Native.cr Core

This directory contains the core runtime components for native.cr applications.

## Files

| File | Description |
|------|-------------|
| `state.cr` | JSON serialization for app state preservation across fast restarts |
| `process.cr` | File watcher, process manager, and fast restart system |

## state.cr

Provides state serialization and deserialization for preserving app state during fast restarts.

**Key Functions:**

- `save(obj)` - Serializes object to JSON string
- `load(json, obj)` - Deserializes JSON into object
- `capture_and_restore(obj, &block)` - Saves state, runs block, restores state
- `valid_json?(json)` - Checks if string is valid JSON
- `pretty(obj)` - Returns pretty-printed JSON

**Usage:**

```crystal
class MyApp
  include JSON::Serializable
  
  property score : Int32 = 0
  property name : String = ""
end

app = MyApp.new
app.score = 100

json = Native::Core::State.save(app)
Native::Core::State.load(json, app)
