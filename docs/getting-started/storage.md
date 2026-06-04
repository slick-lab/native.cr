---
title: Storage & Persistence
---

# Storage & Persistence

Most apps need to save data: user settings, cached content, database records, or files. Native.cr provides three layers of storage to fit different needs: preferences for simple key-value data, file storage for documents and media, and SQLite for structured data.

## Preferences

Preferences are the simplest way to store app data. They store key-value pairs as text strings. Use preferences for settings like user name, theme preference, or app language.

Reading a preference returns a string. If the key doesn't exist, you get nil or a default value:

```crystal
name = Native::Storage::Preferences.get("user_name")
name = Native::Storage::Preferences.get("user_name", default: "Guest")
```

Writing a preference is equally simple:

```crystal
Native::Storage::Preferences.set("user_name", "Alice")
Native::Storage::Preferences.set("theme", "dark")
```

Preferences are stored in the app's private data directory. They're not accessible to other apps and persist until the user uninstalls your app.

### Preference Data Types

Preferences store everything as strings internally, but you can work with other types by converting:

```crystal
# Store a number
count = 42
Native::Storage::Preferences.set("high_score", count.to_s)

# Retrieve and convert back
saved = Native::Storage::Preferences.get("high_score")
score = saved ? saved.to_i : 0
```

For booleans:

```crystal
Native::Storage::Preferences.set("notifications_enabled", "true")
enabled = Native::Storage::Preferences.get("notifications_enabled") == "true"
```

For complex data, convert to JSON:

```crystal
require "json"

data = {name: "Bob", age: 30}
json = data.to_json
Native::Storage::Preferences.set("profile", json)

# Later...
json = Native::Storage::Preferences.get("profile")
profile = Hash(String, String).from_json(json)
```

## File Storage

Use file storage to save documents, images, videos, or any binary data. Each app has a private directory where it can read and write files freely.

```crystal
# Write a file
path = Native::Storage::File.write("data.txt", "Hello, World!")

# Read a file
content = Native::Storage::File.read("data.txt")

# Delete a file
Native::Storage::File.delete("data.txt")

# Check if file exists
exists = Native::Storage::File.exists?("data.txt")
```

File paths are relative to your app's private storage directory. You cannot access files outside this directory for security reasons.

### Listing Files

List all files in your storage directory:

```crystal
files = Native::Storage::File.list
files.each do |name|
  puts name
end
```

### Directory Operations

Create subdirectories to organize your files:

```crystal
Native::Storage::File.mkdir("downloads")
Native::Storage::File.write("downloads/document.pdf", data)
```

## SQLite Databases

For apps with complex data or lots of records, use SQLite. SQLite is a lightweight SQL database embedded in every mobile device. You can query, filter, join, and aggregate data efficiently.

### Creating a Database

```crystal
db = Native::Storage::Database.open("app.db")
```

### Creating Tables

```crystal
db.execute(<<-SQL
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )
SQL
)
```

### Inserting Data

```crystal
db.execute("INSERT INTO users (name, email) VALUES (?, ?)", ["Alice", "alice@example.com"])
```

Always use placeholders (?) to prevent SQL injection attacks.

### Querying Data

```crystal
results = db.query("SELECT * FROM users WHERE id = ?", [1])
results.each do |row|
  puts row["name"]  # Access columns by name
  puts row[0]       # Or by index
end
```

### Updating and Deleting

```crystal
# Update
db.execute("UPDATE users SET email = ? WHERE id = ?", ["newemail@example.com", 1])

# Delete
db.execute("DELETE FROM users WHERE id = ?", [1])
```

### Best Practices

- Close your database when done: `db.close`
- Use transactions for multiple related operations
- Index frequently-queried columns for performance
- Use parameterized queries to prevent SQL injection
- Backup important databases regularly to cloud storage

## Storage Permissions

File storage requires different permissions on Android and iOS. Native.cr handles these automatically, but you should know what's happening:

- **Android**: Requires READ/WRITE_EXTERNAL_STORAGE on older versions
- **iOS**: Uses app sandbox—storage is always private

## Summary

- **Preferences** - Simple strings, user settings
- **Files** - Documents, media, binary data
- **SQLite** - Structured data, complex queries
