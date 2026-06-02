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
```

## process.cr

Provides development mode with file watching and fast restart.

Components:

- Config - Configuration for entry point, watch paths, output location
- Watcher - Monitors .cr files for changes using file modification times
- Manager - Orchestrates compilation, process management, and restarts

Modes:

Mode Platform Behavior
Desktop macOS/Linux Full process management with signals and fast restart
Mobile Android/iOS Simple compile and run (no hot reload in production)

Usage:

```crystal
config = Native::Core::Process::Config.new
config.entry_point = "src/main.cr"
config.watch_paths = ["./src"]

manager = Native::Core::Process::Manager.new(config)
manager.start
```

How Fast Restart Works (Desktop Mode)

1. File watcher detects change in .cr file
2. Signal USR1 sent to running app to save state
3. Running process terminates
4. Crystal recompiles entry point
5. New process starts with restored state

Platform Notes

- Android/iOS: Process management uses simple mode (no signals)
- Desktop: Full fast restart with state preservation
- State file: Stored in ./.native_cache/ on desktop, platform-specific paths on mobile
