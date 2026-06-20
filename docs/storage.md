# Storage

native.cr provides two storage systems for persisting data on the device:

- **`Native::Storage::Preferences`** — key/value pairs (settings, counters, tokens). Backed by `SharedPreferences` on Android and `UserDefaults` on iOS.
- **`Native::Storage::FileStorage`** — binary or text files written to sandboxed device storage.

---

## Preferences

### Creating a store

```crystal
# The string argument is a namespace — use it to separate different stores
prefs = Native::Storage::Preferences.new("my_app")

# You can have multiple stores
user_prefs    = Native::Storage::Preferences.new("user")
game_prefs    = Native::Storage::Preferences.new("game")
session_prefs = Native::Storage::Preferences.new("session")
```

### Writing values

All values are stored as strings internally and converted when you read them back.

```crystal
prefs.set("username",  "alice")           # String
prefs.set("score",     1500)              # Int32
prefs.set("xp",        999_999_i64)       # Int64
prefs.set("volume",    0.75_f32)          # Float32
prefs.set("dark_mode", true)              # Bool
```

### Reading values

Always supply a `default:` — it is returned if the key has never been written.

```crystal
username  = prefs.get_string("username",  default: "Guest")
score     = prefs.get_int("score",        default: 0)
xp        = prefs.get_int64("xp",         default: 0_i64)
volume    = prefs.get_float("volume",     default: 1.0_f32)
dark_mode = prefs.get_bool("dark_mode",   default: false)
high      = prefs.get_double("high",      default: 0.0)
```

| Method | Crystal type | Use for |
|---|---|---|
| `get_string(key, default:)` | `String` | Text, tokens, IDs |
| `get_int(key, default:)` | `Int32` | Counts, indices, small numbers |
| `get_int64(key, default:)` | `Int64` | Timestamps, large numbers |
| `get_float(key, default:)` | `Float32` | Volume, progress, percentages |
| `get_double(key, default:)` | `Float64` | High-precision decimals |
| `get_bool(key, default:)` | `Bool` | Flags, settings |

### Checking and deleting

```crystal
prefs.contains?("username")  # => true / false
prefs.delete("username")     # remove a single key
prefs.clear                  # remove ALL keys in this store
prefs.all_keys               # => Array(String)
```

### Persisting complex data (JSON trick)

Preferences only stores primitive types. For structured data, serialise to JSON:

```crystal
# Save
settings = { theme: "dark", font_size: 16, show_tips: true }
prefs.set("settings", settings.to_json)

# Load
raw = prefs.get_string("settings", default: "{}")
settings = JSON.parse(raw)
theme     = settings["theme"].as_s
font_size = settings["font_size"].as_i
```

### Real example — persistent counter

```crystal
class CounterApp < Native::App
  @prefs = Native::Storage::Preferences.new("counter")
  @count : Int32 = 0

  def setup
    # Load the saved count when the app starts
    @count = @prefs.get_int("count", default: 0)

    @label = Native::UI::TextView.new("Count: #{@count}")
    @label.text_size = 24

    btn = Native::UI::Button.new("Increment")
    btn.on_click { increment }

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(@label)
    layout.addView(btn)
    @root = layout
  end

  def increment
    @count += 1
    @prefs.set("count", @count)   # written immediately to disk
    @label.text = "Count: #{@count}"
  end

  def on_destroy
    @prefs.set("count", @count)   # double-save just in case
  end
end
```

---

## FileStorage

`Native::Storage::FileStorage` reads and writes files to the device's sandboxed directories.

### Storage types

```crystal
# Documents — user-facing, included in iOS backups and Android app backups
docs = Native::Storage::FileStorage.new(
  Native::Storage::FileStorage::StorageType::Documents
)

# Cache — files the OS can delete when storage is low
cache = Native::Storage::FileStorage.new(
  Native::Storage::FileStorage::StorageType::Cache
)

# Temporary — short-lived scratch space
tmp = Native::Storage::FileStorage.new(
  Native::Storage::FileStorage::StorageType::Temporary
)
```

### Writing files

```crystal
# Write raw bytes
data = Bytes[72, 101, 108, 108, 111]   # "Hello" in ASCII
success = docs.write("hello.bin", data) # => Bool

# Write a text string (converts to UTF-8 bytes internally)
success = docs.write_text("note.txt", "This is my note.")
```

`write` and `write_text` return `true` on success, `false` on failure.

### Reading files

```crystal
# Read as raw bytes — returns nil if the file does not exist
bytes = docs.read("hello.bin")   # => Bytes?

# Read as a String — returns nil if the file does not exist
text = docs.read_text("note.txt") # => String?

if text
  puts text
else
  puts "File not found"
end
```

### Checking and deleting

```crystal
docs.exists?("note.txt")        # => Bool
docs.delete("note.txt")         # => Bool (true on success)
docs.list                       # => Array(String) — filenames in root
docs.list("subfolder")          # => Array(String) — filenames in "subfolder/"
```

### Real example — download and cache an image

```crystal
def load_avatar(url : String) : Bytes?
  cache = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Cache
  )

  cache_key = "avatar_#{url.hash}.jpg"

  # Return cached version if available
  if cache.exists?(cache_key)
    return cache.read(cache_key)
  end

  # Download and cache
  response = Native::Network::HTTP.get(url)
  if response.ok?
    data = response.body.to_slice
    cache.write(cache_key, data)
    data
  else
    nil
  end
end
```

### Real example — saving a recorded audio clip

```crystal
def save_recording(audio_bytes : Bytes) : String?
  docs = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Documents
  )

  filename = "recording_#{Time.utc.to_unix}.pcm"

  if docs.write(filename, audio_bytes)
    filename
  else
    nil
  end
end

def list_recordings : Array(String)
  docs = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Documents
  )
  docs.list.select { |f| f.ends_with?(".pcm") }
end
```

---

## Preferences vs FileStorage — when to use which

| Use case | Use |
|---|---|
| User settings (dark mode, language) | `Preferences` |
| Session token or API key | `Preferences` |
| High score, streak, progress | `Preferences` |
| Small JSON config | `Preferences` (serialised) |
| Photos, audio recordings | `FileStorage::Documents` |
| Downloaded thumbnails, cache data | `FileStorage::Cache` |
| Scratch data during a session | `FileStorage::Temporary` |
| Anything > a few KB | `FileStorage` |
