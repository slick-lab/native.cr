# Permissions

Request access to sensitive features like camera, location, and microphone.

---

## Permission Types

```crystal
Native::Permissions::PermissionType::Camera
Native::Permissions::PermissionType::Microphone
Native::Permissions::PermissionType::Location
Native::Permissions::PermissionType::LocationFine
Native::Permissions::PermissionType::LocationCoarse
Native::Permissions::PermissionType::Notifications
Native::Permissions::PermissionType::Storage
Native::Permissions::PermissionType::Contacts
Native::Permissions::PermissionType::Calendar
Native::Permissions::PermissionType::CameraRoll
Native::Permissions::PermissionType::Bluetooth
```

---

## Quick Check

```crystal
Native::Permissions::Permissions.camera_granted?
Native::Permissions::Permissions.location_granted?
Native::Permissions::Permissions.microphone_granted?
```

---

## Request Permission

```crystal
Native::Permissions::Permissions.camera do |status|
  if status == Native::Permissions::PermissionStatus::Granted
    open_camera
  end
end

Native::Permissions::Permissions.location { |s| start_gps }
Native::Permissions::Permissions.microphone { |s| record_audio }
```

---

## Check Status

```crystal
status = Native::Permissions::PermissionManager.check(
  Native::Permissions::PermissionType::Camera
)

case status
when .granted? then puts "Allowed"
when .denied? then puts "Denied"
when .not_determined? then puts "Not asked"
end
```

---

## Multiple Permissions

```crystal
types = [
  Native::Permissions::PermissionType::Camera,
  Native::Permissions::PermissionType::Microphone
]

Native::Permissions::PermissionManager.request_multiple(types) do |results|
  if results.all? { |_, s| s.granted? }
    start_video_call
  end
end
```

---

## Open Settings

When permanently denied, send user to Settings:

```crystal
Native::Permissions::PermissionManager.open_settings
```

---

## Example

```crystal
def open_camera
  Native::Permissions::Permissions.camera do |status|
    case status
    when .granted?
      launch_camera
    when .denied?
      show_error("Camera access denied. Enable in Settings.")
    end
  end
end
```

---

## Platform Setup

### Android — AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS — Info.plist

```xml
<key>NSCameraUsageDescription</key>
<string>Used for profile photos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used for nearby places</string>
```
