# Storage

native.cr provides two storage systems:

- **Preferences** — for small key-value data (settings, counters, user preferences)
- **FileStorage** — for larger binary or text data (images, documents, cache files)

---

## Preferences

`Native::Storage::Preferences` wraps Android's `SharedPreferences` and iOS's `UserDefaults`. Data is persisted between app launches automatically.

### Creating a preferences store

```crystal
# "my_app" is a namespace — use different names for different stores
prefs = Native::Storage::Preferences.new("my_app")
```

### Saving values

```crystal
prefs.set("username", "alice")          # String
prefs.set("score", 42)                  # Int32
prefs.set("high_score", 9999_i64)       # Int64
prefs.set("volume", 0.75_f32)           # Float32
prefs.set("dark_mode", true)            # Bool
```

### Reading values

```crystal
name       = prefs.get_string("username", default: "Guest")
score      = prefs.get_int("score", default: 0)
high_score = prefs.get_int64("high_score", default: 0_i64)
volume     = prefs.get_float("volume", default: 1.0_f32)
dark_mode  = prefs.get_bool("dark_mode", default: false)
```

Always provide a `default:` value — it is returned when the key does not exist yet.

### Checking and deleting

```crystal
prefs.contains?("username")   # => true or false
prefs.delete("username")      # remove one key
prefs.clear                   # remove ALL keys in this store
prefs.all_keys                # => Array(String)
```

### Real example — counter that persists across launches

```crystal
class CounterApp < Native::App
  @prefs = Native::Storage::Preferences.new("counter_app")
  @count : Int32 = 0

  def setup
    @count = @prefs.get_int("count", default: 0)

    @label = UI::Text.new
    @label.text = "Count: #{@count}"

    btn = UI::Button.new
    btn.text = "Increment"
    btn.on_click { increment }

    col = UI::Column.new
    col.add_child(@label)
    col.add_child(btn)
    @root = col
  end

  def increment
    @count += 1
    @prefs.set("count", @count)       # save immediately
    @label.text = "Count: #{@count}"
  end
end
```

---

## FileStorage

`Native::Storage::FileStorage` reads and writes files to sandboxed directories on the device.

### Storage types

```crystal
# Documents — user-facing files, included in backups
docs = Native::Storage::FileStorage.new(Native::Storage::FileStorage::StorageType::Documents)

# Cache — files the system may delete when storage is low
cache = Native::Storage::FileStorage.new(Native::Storage::FileStorage::StorageType::Cache)

# Temporary — short-lived scratch files
tmp = Native::Storage::FileStorage.new(Native::Storage::FileStorage::StorageType::Temporary)
```

### Writing files

```crystal
# Write raw bytes
data = Bytes[72, 101, 108, 108, 111]   # "Hello" in ASCII
docs.write("hello.bin", data)           # => Bool (true on success)

# Write a text string
docs.write_text("note.txt", "This is my note.")
```

### Reading files

```crystal
# Read raw bytes
bytes = docs.read("hello.bin")          # => Bytes? (nil if file not found)

# Read as text
text = docs.read_text("note.txt")       # => String? (nil if file not found)

if text
  puts text
else
  puts "File not found"
end
```

### Checking, deleting, listing

```crystal
docs.exists?("note.txt")               # => Bool
docs.delete("note.txt")                # => Bool (true on success)
docs.list                              # => Array(String) — filenames in root
docs.list("subfolder")                 # => Array(String) — filenames in subfolder
```

### Real example — saving a photo

```crystal
# After taking a photo, save it to the Documents directory
def save_photo(photo_bytes : Bytes)
  storage = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Documents
  )

  filename = "photo_#{Time.utc.to_unix}.jpg"
  if storage.write(filename, photo_bytes)
    puts "Saved as #{filename}"
  else
    puts "Failed to save"
  end
end
```
