# Permissions

Before your app can access sensitive features — camera, microphone, location, contacts — it must request the user's permission. On Android this shows a system dialog; on iOS the OS prompts the user the first time.

native.cr handles both platforms through a unified API in `Native::Permissions`.

---

## Available permission types

```crystal
Native::Permissions::PermissionType::Camera
Native::Permissions::PermissionType::Microphone
Native::Permissions::PermissionType::Location          # fine (GPS)
Native::Permissions::PermissionType::LocationFine      # same as Location
Native::Permissions::PermissionType::LocationCoarse    # network-based only
Native::Permissions::PermissionType::Notifications
Native::Permissions::PermissionType::Storage           # general read/write
Native::Permissions::PermissionType::StorageRead
Native::Permissions::PermissionType::StorageWrite
Native::Permissions::PermissionType::Contacts
Native::Permissions::PermissionType::Calendar
Native::Permissions::PermissionType::CameraRoll        # photo library
Native::Permissions::PermissionType::Bluetooth
Native::Permissions::PermissionType::Speech            # speech recognition
Native::Permissions::PermissionType::Motion            # Core Motion / activity
```

---

## Permission statuses

| Status | Meaning |
|---|---|
| `Granted` | User allowed it — you can use the feature |
| `NotDetermined` | Never been asked — safe to request |
| `Denied` | User said no — do not re-request silently |
| `Restricted` | Blocked by parental controls or MDM policy |
| `Limited` | Partial access (iOS 14+ photo library) |

---

## Quick helper module — `Native::Permissions::Permissions`

The `Permissions` module has one-liner shortcuts for the most common permissions.

### Check without requesting

```crystal
Native::Permissions::Permissions.camera_granted?          # => Bool
Native::Permissions::Permissions.microphone_granted?      # => Bool
Native::Permissions::Permissions.location_granted?        # => Bool
Native::Permissions::Permissions.notifications_granted?   # => Bool
Native::Permissions::Permissions.storage_granted?         # => Bool
```

### Request with a callback

```crystal
Native::Permissions::Permissions.camera do |status|
  if status == Native::Permissions::PermissionStatus::Granted
    open_camera
  else
    show_alert("Camera access is required to take photos.")
  end
end

Native::Permissions::Permissions.microphone { |s| start_recording if s == Native::Permissions::PermissionStatus::Granted }
Native::Permissions::Permissions.location   { |s| start_gps       if s == Native::Permissions::PermissionStatus::Granted }
Native::Permissions::Permissions.notifications { |s| puts "Notifications: #{s}" }
Native::Permissions::Permissions.storage    { |s| access_files    if s == Native::Permissions::PermissionStatus::Granted }
```

---

## Full control — `Native::Permissions::PermissionManager`

### Check the current status (no dialog)

```crystal
status = Native::Permissions::PermissionManager.check(
  Native::Permissions::PermissionType::Camera
)

case status
when Native::Permissions::PermissionStatus::Granted
  puts "Already granted — proceed"
when Native::Permissions::PermissionStatus::NotDetermined
  puts "Not asked yet — safe to request"
when Native::Permissions::PermissionStatus::Denied
  puts "User denied — show settings link"
when Native::Permissions::PermissionStatus::Restricted
  puts "Blocked by policy — cannot request"
when Native::Permissions::PermissionStatus::Limited
  puts "Limited access"
end
```

### Request a single permission

The block is called immediately if the status is already `Granted` or `Denied`. It is called asynchronously (after the user taps the dialog) if the status is `NotDetermined`.

```crystal
Native::Permissions::PermissionManager.request(
  Native::Permissions::PermissionType::Location
) do |status|
  if status == Native::Permissions::PermissionStatus::Granted
    start_location_tracking
  end
end
```

### Request multiple permissions at once

```crystal
types = [
  Native::Permissions::PermissionType::Camera,
  Native::Permissions::PermissionType::Microphone,
]

Native::Permissions::PermissionManager.request_multiple(types) do |results|
  camera_ok = results[Native::Permissions::PermissionType::Camera] ==
              Native::Permissions::PermissionStatus::Granted

  mic_ok    = results[Native::Permissions::PermissionType::Microphone] ==
              Native::Permissions::PermissionStatus::Granted

  if camera_ok && mic_ok
    start_video_call
  else
    show_alert("Camera and microphone access are both required for video calls.")
  end
end
```

### Convenience boolean checks

```crystal
Native::Permissions::PermissionManager.is_granted?(type)  # => Bool
Native::Permissions::PermissionManager.is_denied?(type)   # => Bool (Denied or Restricted)
```

### Send the user to Settings

When a user has permanently denied a permission (tapped "Don't allow" on iOS, or revoked via Android settings), you cannot request it again. The only option is to guide them to the Settings app:

```crystal
Native::Permissions::PermissionManager.open_settings
```

Always do this in response to a user action (e.g. tapping a "Open Settings" button) — not automatically.

---

## Best practices

### 1. Check before you request

```crystal
if Native::Permissions::PermissionManager.is_granted?(
     Native::Permissions::PermissionType::Camera
   )
  launch_camera    # already have permission — skip the dialog
else
  Native::Permissions::Permissions.camera { |s| launch_camera if s == Native::Permissions::PermissionStatus::Granted }
end
```

### 2. Request at the right moment

Request a permission **when the user triggers the feature that needs it**, not during app launch. The system dialog will make more sense to the user when they understand why they're being asked.

```crystal
# ✓ Good — user tapped "Take a selfie"
def on_selfie_button_tapped
  Native::Permissions::Permissions.camera { |s| open_front_camera if s == Native::Permissions::PermissionStatus::Granted }
end

# ✗ Bad — asking during app launch with no context
def setup
  Native::Permissions::Permissions.camera { }   # user has no idea why
end
```

### 3. Handle denial gracefully

```crystal
def open_camera_feature
  type = Native::Permissions::PermissionType::Camera

  case Native::Permissions::PermissionManager.check(type)
  when Native::Permissions::PermissionStatus::Granted
    launch_camera

  when Native::Permissions::PermissionStatus::NotDetermined
    Native::Permissions::Permissions.camera do |status|
      if status == Native::Permissions::PermissionStatus::Granted
        launch_camera
      else
        show_permission_denied_message
      end
    end

  else
    # Denied or Restricted — offer Settings
    show_settings_prompt
  end
end

def show_settings_prompt
  label = Native::UI::TextView.new(
    "Camera access was denied. Open Settings to allow it."
  )
  btn = Native::UI::Button.new("Open Settings")
  btn.on_click { Native::Permissions::PermissionManager.open_settings }

  # ... add label and btn to your layout
end
```

### 4. iOS: add usage descriptions to your `Info.plist`

Apple requires a human-readable explanation for every permission your app requests. Add these to your iOS project's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to let you take profile photos.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We use the microphone to record voice notes.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to show nearby places.</string>
```

Your app will be rejected from the App Store without these.

### 5. Android: declare permissions in `AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

native.cr handles the runtime request dialog; you still need the manifest declaration for the app to be able to ask.
