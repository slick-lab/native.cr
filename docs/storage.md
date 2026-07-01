# Storage

Two storage systems: `Preferences` for key/values, `FileStorage` for files.

---

## Preferences

Key-value storage backed by SharedPreferences (Android) and UserDefaults (iOS).

### Create

```crystal
prefs = Native::Storage::Preferences.new("my_app")
```

### Write

```crystal
prefs.set("username", "alice")
prefs.set("score", 1500)
prefs.set("volume", 0.75_f32)
prefs.set("dark_mode", true)
```

### Read

Always provide a default:

```crystal
name = prefs.get_string("username", default: "Guest")
score = prefs.get_int("score", default: 0)
volume = prefs.get_float("volume", default: 1.0_f32)
dark = prefs.get_bool("dark_mode", default: false)
```

### Manage

```crystal
prefs.contains?("username")  # => true/false
prefs.delete("username")
prefs.clear
prefs.all_keys
```

### JSON for Complex Data

```crystal
settings = {theme: "dark", font: 16}
prefs.set("settings", settings.to_json)

raw = prefs.get_string("settings", default: "{}")
data = JSON.parse(raw)
```

---

## FileStorage

Read/write files to sandboxed directories.

### Types

```crystal
# Documents — persisted, backed up
docs = Native::Storage::FileStorage.new(
  Native::Storage::FileStorage::StorageType::Documents
)

# Cache — can be cleared by OS
cache = Native::Storage::FileStorage.new(
  Native::Storage::FileStorage::StorageType::Cache
)

# Temporary — short-lived
tmp = Native::Storage::FileStorage.new(
  Native::Storage::FileStorage::StorageType::Temporary
)
```

### Write

```crystal
docs.write("file.bin", bytes)
docs.write_text("note.txt", "content")
```

### Read

```crystal
bytes = docs.read("file.bin")     # => Bytes?
text = docs.read_text("note.txt") # => String?
```

### Manage

```crystal
docs.exists?("file.bin")
docs.delete("file.bin")
docs.list
```

---

## When to Use Which?

| Use Case | Use |
|----------|-----|
| Settings, tokens | Preferences |
| Small config | Preferences (as JSON) |
| Photos, recordings | FileStorage::Documents |
| Downloaded cache | FileStorage::Cache |
| Large data | FileStorage |
