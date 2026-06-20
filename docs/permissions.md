# Permissions

Before your app can use sensitive features — camera, microphone, location, etc. — it must ask the user for permission. native.cr provides a clean API to check and request permissions on both Android and iOS.

---

## Available permissions

| Permission | Constant |
|---|---|
| Camera | `PermissionType::Camera` |
| Microphone | `PermissionType::Microphone` |
| Location (fine/GPS) | `PermissionType::Location` / `PermissionType::LocationFine` |
| Location (coarse/network) | `PermissionType::LocationCoarse` |
| Push notifications | `PermissionType::Notifications` |
| Storage (read) | `PermissionType::StorageRead` |
| Storage (write) | `PermissionType::StorageWrite` |
| Contacts | `PermissionType::Contacts` |
| Calendar | `PermissionType::Calendar` |
| Camera roll / Photo library | `PermissionType::CameraRoll` |
| Bluetooth | `PermissionType::Bluetooth` |

---

## Permission status values

| Status | Meaning |
|---|---|
| `Granted` | The user allowed it |
| `Denied` | The user said no |
| `Restricted` | Blocked by parental controls / policy |
| `NotDetermined` | Never asked yet |
| `Limited` | Partial access (iOS only, e.g. limited photo library) |

---

## Quick helper methods

The `Native::Permissions::Permissions` module has simple shortcut methods:

```crystal
# Check without requesting
if Native::Permissions::Permissions.camera_granted?
  puts "Camera is available"
end

# Request with a callback
Native::Permissions::Permissions.camera do |status|
  if status == Native::Permissions::PermissionStatus::Granted
    open_camera
  else
    show_message("Camera access is required.")
  end
end

# Available shortcuts
Native::Permissions::Permissions.camera { |s| ... }
Native::Permissions::Permissions.microphone { |s| ... }
Native::Permissions::Permissions.location { |s| ... }
Native::Permissions::Permissions.notifications { |s| ... }
Native::Permissions::Permissions.storage { |s| ... }

# Quick boolean checks
Native::Permissions::Permissions.camera_granted?
Native::Permissions::Permissions.microphone_granted?
Native::Permissions::Permissions.location_granted?
Native::Permissions::Permissions.notifications_granted?
Native::Permissions::Permissions.storage_granted?
```

---

## Using the PermissionManager directly

For more control, use `Native::Permissions::PermissionManager`:

### Check the current status (without asking)

```crystal
status = Native::Permissions::PermissionManager.check(
  Native::Permissions::PermissionType::Camera
)

case status
when Native::Permissions::PermissionStatus::Granted
  puts "Good to go"
when Native::Permissions::PermissionStatus::Denied
  puts "User denied it"
when Native::Permissions::PermissionStatus::NotDetermined
  puts "Need to ask"
end
```

### Request a permission

```crystal
Native::Permissions::PermissionManager.request(
  Native::Permissions::PermissionType::Location
) do |status|
  if Native::Permissions::PermissionManager.is_granted?(
       Native::Permissions::PermissionType::Location
     )
    start_tracking
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
    puts "Need both camera and microphone"
  end
end
```

### Helper booleans

```crystal
Native::Permissions::PermissionManager.is_granted?(type)  # => Bool
Native::Permissions::PermissionManager.is_denied?(type)   # => Bool (Denied or Restricted)
```

### Send the user to app settings

If a user permanently denied a permission, you can send them to the Settings app so they can change it:

```crystal
Native::Permissions::PermissionManager.open_settings
```

---

## Best practices

1. **Always check before requesting.** If the permission is already `Granted`, don't ask again.
2. **Handle `Denied` gracefully.** Explain to the user why the feature is unavailable, and optionally offer the `open_settings` link.
3. **Request at the right moment.** Ask for a permission when the user triggers the feature that needs it, not on app launch. That context makes the system dialog more persuasive.

```crystal
# Example pattern
def open_camera_feature
  status = Native::Permissions::PermissionManager.check(
    Native::Permissions::PermissionType::Camera
  )

  case status
  when Native::Permissions::PermissionStatus::Granted
    launch_camera
  when Native::Permissions::PermissionStatus::NotDetermined
    Native::Permissions::Permissions.camera do |s|
      launch_camera if s == Native::Permissions::PermissionStatus::Granted
    end
  else
    show_alert("Camera access denied. Go to Settings to enable it.")
  end
end
```
