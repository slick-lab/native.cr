# Platform-Specific Development

Handle differences between Android and iOS.

---

## Platform Detection

### Compile-Time

Use Crystal's compile-time flags:

```crystal
{% if flag?(:native_android) %}
  # Android-only code
  show_android_toast("Hello")
{% elsif flag?(:native_ios) %}
  # iOS-only code
  show_ios_alert("Hello")
{% end %}
```

Useful for:
- Importing platform-specific modules
- Conditional compilation of features
- Platform-specific implementations

### Runtime

Check at runtime:

```crystal
if Native::Platform.android?
  # Android behavior
elsif Native::Platform.ios?
  # iOS behavior
end

Native::Platform.mobile?   # => true on Android/iOS
Native::Platform.desktop?  # => true in simulator
Native::Platform.os_name   # => "Android" or "iOS"
```

---

## Device Information

```crystal
Native::Platform.device_model   # => "Pixel 7" or "iPhone14,2"
Native::Platform.os_version     # => "14" or "17.2"
Native::Platform.screen_width   # => pixels
Native::Platform.screen_height  # => pixels
Native::Platform.screen_density # => 1.0, 2.0, 3.0, etc.
```

---

## Permissions

### Android Permissions

Add to `AndroidManifest.xml`:

```xml
<!-- Camera -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />

<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Storage -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Microphone -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Internet -->
<uses-permission android:name="android.permission.INTERNET" />
```

Request at runtime:

```crystal
Native::Permissions::PermissionManager.request_camera { |granted|
  if granted
    open_camera
  else
    show_permission_denied_message
  end
}
```

### iOS Permissions

Add to `Info.plist`:

```xml
<!-- Camera -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos</string>

<!-- Location -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location to show nearby places</string>

<!-- Microphone -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio</string>

<!-- Photo Library -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save photos</string>

<!-- Face ID -->
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID for secure authentication</string>
```

Request at runtime (same code as Android):

```crystal
Native::Permissions::PermissionManager.request_location { |granted|
  # Same handling as Android
}
```

---

## Back Button (Android)

Android devices have a hardware back button:

```crystal
class MyApp < Native::App
  def on_back_pressed : Bool
    if @has_modal_open
      close_modal
      return true  # Consumed
    end

    if @nav.can_go_back?
      @nav.pop
      return true
    end

    false  # Let system handle (exit app)
  end
end
```

iOS doesn't have a physical back button. Include on-screen navigation.

---

## Navigation Bar

### Android: Toolbar

```crystal
toolbar = Native::Navigation::Toolbar.new
toolbar.title = "My App"
toolbar.setupWithActivity  # Sets as ActionBar
```

### iOS: NavigationBar

```crystal
toolbar = Native::Navigation::Toolbar.new
toolbar.title = "My App"
# iOS uses UINavigationBar automatically
```

---

## Sharing

Android uses Intents, iOS uses UIActivityViewController. The API is unified:

```crystal
Native::Platform.share("Check out this app!", "Share")
```

Or with more control:

```crystal
options = Native::Share::ShareOptions.new
options.text = "Check this out!"
options.url = "https://example.com"
options.image_path = "/path/to/image.jpg"

Native::Share::ShareSheet.new(options).show { |success|
  puts "Shared: #{success}"
}
```

---

## Notifications

### Android Channels

Required for Android 8+:

```crystal
# Create channel before scheduling
Native::Notifications.create_channel(
  id: "messages",
  name: "Messages",
  importance: Native::Notifications::Importance::HIGH
)
```

### iOS Settings

Configure in `Info.plist` or request at runtime:

```crystal
Native::Notifications::NotificationManager.request_permission { |granted|
  if granted
    schedule_notification
  else
    show_permission_required_message
  end
}
```

### Scheduling

```crystal
# Works on both platforms
Native::Notifications.schedule(
  title: "Reminder",
  body: "Don't forget!",
  delay_seconds: 3600  # 1 hour
)
```

---

## Haptic Feedback

```crystal
Native::Platform.vibrate(50)  # Short tap

# On iOS, this uses HapticFeedback
# On Android, this uses VibrationEffect
```

---

## File Storage Paths

Platform-specific paths are handled automatically:

```crystal
# Documents - App's private document storage
docs = Native::Storage::FileStorage.new(
  Native::Storage::FileStorage::StorageType::Documents
)

# Cache - Temporary files
cache = Native::Storage::FileStorage.new(
  Native::Storage::FileStorage::StorageType::Cache
)

# Temporary - Cleared by system
temp = Native::Storage::FileStorage.new(
  Native::Storage::FileStorage::StorageType::Temporary
)

# Read/write works the same on both
docs.write("data.json", json)
content = docs.read("data.json")
```

Paths map to:
- Android: `getFilesDir()`, `getCacheDir()`, `getExternalCacheDir()`
- iOS: `Documents/`, `Library/Caches/`, `tmp/`

---

## Conditional UI

Different layouts for different platforms:

```crystal
def build_back_button
  if Native::Platform.ios?
    # iOS shows back button in UI
    btn = Native::UI::Button.new("< Back")
    btn.on_click { go_back }
    btn
  else
    # Android uses hardware back button or toolbar navigation
    Native::UI::View.new  # Empty on Android
  end
end

def build_status_bar
  if Native::Platform.android?
    # Android has status bar at top
    # May need to adjust for notches
    adjust_for_status_bar
  else
    # iOS has safe areas
    adjust_for_safe_area
  end
end

def build_bottom_nav
  if Native::Platform.android?
    # Material Design bottom nav
    build_material_bottom_nav
  else
    # iOS tab bar
    build_ios_tab_bar
  end
end
```

---

## Platform Differences Table

| Feature | Android | iOS |
|---------|---------|-----|
| Back button | Hardware + Navigation | Navigation only |
| Share | Intent chooser | Activity sheet |
| Permissions | Runtime request | Runtime request + plist |
| Notifications | Channels required | Permission request |
| Status bar | Top, customizable | Top, safe area |
| Navigation gestures | System back | Swipe from edge |
| App lifecycle | Activity | Scene/ViewController |

---

## Example: Platform-Aware Header

```crystal
def build_header(title : String, show_back : Bool = false) : Native::UI::View
  container = Native::UI::LinearLayout.new
  container.orientation = Native::UI::LinearLayout::Orientation::Horizontal
  container.padding = 16
  container.background_color = PRIMARY_COLOR

  # Back button (iOS needs explicit button, Android uses navigation icon)
  if show_back && Native::Platform.ios?
    back = Native::UI::Button.new("<")
    back.text_color = 0xFFFFFFFF
    back.on_click { go_back }
    container.addView(back)
  end

  # Title
  label = Native::UI::TextView.new(title)
  label.text_color = 0xFFFFFFFF
  label.text_size = 20.0
  label.layout_weight = 1.0
  label.gravity = Native::UI::Gravity::CENTER_VERTICAL
  container.addView(label)

  container
end
```

---

## Next Steps

- [Publishing](publishing.md) — Submit to app stores
- [Debugging](debugging.md) — Platform-specific debugging
