# Debugging and Testing

Debug your app and write tests.

---

## Logging

### Basic Logging

```crystal
puts "Debug message"
p! @some_variable  # Prints variable name and value
```

### Platform Logs

View logs in real-time:

**Android:**

```bash
adb logcat | grep -i nativecr
```

Or filter by tag:

```bash
adb logcat -s nativecr:V
```

**iOS:**

View in Xcode console, or:

```bash
crystal main.cr logs
```

### Structured Logging

Create a logging helper:

```crystal
module Log
  def self.debug(message : String)
    puts "[DEBUG] #{message}"
  end

  def self.info(message : String)
    puts "[INFO] #{message}"
  end

  def self.error(message : String)
    puts "[ERROR] #{message}"
  end

  def self.tag(tag : String, message : String)
    puts "[#{tag}] #{message}"
  end
end

# Usage
Log.debug("Loading users...")
Log.error("Failed to connect: #{error}")
Log.tag("API", "Request took #{duration}ms")
```

---

## Debug Builds

### Conditional Code

Use debug mode for development-only features:

```crystal
{% if flag?(:debug) %}
  # Debug-only UI
  add_debug_panel
{% end %}
```

### Debug Menu

Add a hidden debug panel:

```crystal
def build_debug_menu
  return unless debug_mode?

  container = Native::UI::LinearLayout.new
  container.orientation = Native::UI::LinearLayout::Orientation::Vertical
  container.background_color = 0x80FF0000  # Semi-transparent red

  # Reset data
  reset_btn = Native::UI::Button.new("Reset App Data")
  reset_btn.on_click { reset_app_data }
  container.addView(reset_btn)

  # Force crash
  crash_btn = Native::UI::Button.new("Test Crash")
  crash_btn.on_click { raise "Test crash" }
  container.addView(crash_btn)

  # Show state
  state_btn = Native::UI::Button.new("Show State")
  state_btn.on_click { show_state_dialog }
  container.addView(state_btn)

  container
end

def debug_mode? : Bool
  {% if flag?(:debug) %}
    true
  {% else %}
    false
  {% end %}
end
```

---

## Error Handling

### Global Error Handler

Catch unhandled errors:

```crystal
class MyApp < Native::App
  def setup
    # ... build UI ...
  rescue ex
    handle_error(ex)
    @root = build_error_screen(ex)
  end

  def handle_error(ex : Exception)
    Log.error("Uncaught exception: #{ex.message}")
    Log.error(ex.backtrace.join("\n"))

    # Optionally send to crash reporting service
    report_crash(ex)
  end
end
```

### Try/Catch in Callbacks

```crystal
button.on_click do
  begin
    risky_operation
  rescue ex
    show_error_dialog(ex.message)
  end
end
```

---

## Performance Profiling

### Timing Operations

```crystal
def timed(label : String)
  start = Time.monotonic
  yield
  elapsed = (Time.monotonic - start).total_milliseconds
  puts "#{label}: #{elapsed.round(2)}ms"
end

# Usage
timed("Load users") { fetch_users }
```

### FPS Monitoring

```crystal
class PerformanceMonitor
  @frame_times = [] of Float64
  @max_samples = 60

  def record_frame(duration : Float64)
    @frame_times << duration
    @frame_times.shift if @frame_times.size > @max_samples
  end

  def fps : Float64
    return 0.0 if @frame_times.empty?
    avg = @frame_times.sum / @frame_times.size
    1000.0 / avg  # Convert ms to FPS
  end

  def summary : String
    "FPS: #{fps.round(1)}"
  end
end
```

---

## Memory Debugging

### Checking Memory

```crystal
def log_memory
  # Crystal's GC stats
  gc_stats = GC.stats
  puts "GC Collections: #{gc_stats.collections_count}"
  puts "Bytes allocated: #{gc_stats.bytes_allocated_since_gc}"
  puts "Total bytes: #{gc_stats.total_bytes_allocated}"
end
```

### Leaking References

Common memory leaks:

1. **Retaining views after removal**
   ```crystal
   # Bad: Keep reference after removing
   @cache << view
   @container.remove_view(view)
   ```

2. **Unbounded arrays**
   ```crystal
   # Bad: Array grows forever
   @history << event  # Never cleared

   # Good: Limit size
   @history << event
   @history.shift if @history.size > 100
   ```

3. **Unclosed resources**
   ```crystal
   # Bad: Not released
   @camera.start_preview

   def on_pause
     # Forgot to stop!
   end

   # Good:
   def on_pause
     @camera.stop_preview
   end
   ```

---

## Unit Testing

### Test Structure

Tests go in `spec/` directory:

```
spec/
├── spec_helper.cr
├── models/
│   └── user_spec.cr
└── utils/
    └── cache_spec.cr
```

### spec_helper.cr

```crystal
require "spec"
require "../src/app/models"

# Mock platform functions for testing
module Native
  module Platform
    def self.android? : Bool
      false
    end

    def self.ios? : Bool
      false
    end
  end
end
```

### Writing Tests

```crystal
# spec/models/user_spec.cr
require "../spec_helper"

describe User do
  describe "#full_name" do
    it "combines first and last name" do
      user = User.new(first_name: "John", last_name: "Doe")
      user.full_name.should eq "John Doe"
    end
  end

  describe "#valid?" do
    it "requires email" do
      user = User.new(email: "")
      user.valid?.should be_false
    end

    it "validates email format" do
      user = User.new(email: "invalid")
      user.valid?.should be_false

      user = User.new(email: "test@example.com")
      user.valid?.should be_true
    end
  end
end
```

### Running Tests

```bash
crystal spec
```

Or with specific file:

```bash
crystal spec spec/models/user_spec.cr
```

---

## UI Testing

For UI, create preview/example apps:

```crystal
# examples/button_preview.cr
require "native"

class ButtonPreview < Native::App
  def setup
    container = Native::UI::LinearLayout.new
    container.orientation = Native::UI::LinearLayout::Orientation::Vertical
    container.padding = 16

    # Primary button
    primary = Native::UI::Button.new("Primary Button")
    container.addView(primary)

    # Disabled button
    disabled = Native::UI::Button.new("Disabled")
    disabled.enabled = false
    container.addView(disabled)

    @root = container
  end
end
```

Run with hot reload to quickly iterate on UI design.

---

## Common Issues

### App Doesn't Start

1. Check logs for errors
2. Verify `main.cr` has correct app class
3. Check for nil pointer exceptions in `setup`

### UI Not Updating

1. Ensure you're modifying UI on main thread
2. Check that you're updating the correct view instance
3. Verify visibility isn't set to `gone` or `invisible`

### Network Requests Fail

1. Check internet permission (Android)
2. Verify URL is correct
3. Check for HTTPS issues on Android (SSL)
4. Test the endpoint with curl/Postman

### Hot Reload Not Working

1. Ensure `@[Preserve]` on state variables
2. Check dev server is running
3. Verify network connectivity for reload signal

### Crashes

1. Review stack trace in logs
2. Add try/catch around suspect code
3. Check for nil references

---

## Remote Debugging

### Android Studio Profiler

1. Open Android Studio
2. Run app on device/emulator
3. View > Tool Windows > Profiler
4. Select your app process

### Xcode Instruments

1. Open Xcode
2. Product > Profile (Cmd+I)
3. Select template (Allocations, Leaks, etc.)

---

## Next Steps

- [Testing Strategies](testing.md) — Comprehensive testing guide
- [Publishing](publishing.md) — Prepare for release
