---
title: Platform & Device
---

# Platform & Device

Your app runs on different devices with different capabilities. Some phones have fingerprint sensors, others don't. Battery levels vary. Geolocation works differently on Android and iOS. Native.cr provides APIs to query device capabilities and access platform-specific features.

## Device Information

Get basic information about the device your app is running on:

```crystal
device = Native::Platform.device_info

device.model        # Device model name (e.g., "iPhone 14")
device.manufacturer # Manufacturer name (e.g., "Apple")
device.os_version   # Operating system version (e.g., "16.0")
device.os_name      # Operating system name ("iOS" or "Android")
device.screen_width # Screen width in pixels
device.screen_height # Screen height in pixels
device.dpi          # Screen DPI (density)
```

Use this information to adapt your app's behavior to the device. For example, you might use larger touch targets on low-DPI devices or simpler graphics on older phones.

## Battery Information

Check the device's battery level and charging status:

```crystal
battery = Native::Platform.battery_info

battery.level       # 0.0 to 1.0 (1.0 = 100%)
battery.is_charging # true or false
battery.state       # "charging", "discharging", "full", "unknown"
```

Use battery information to adjust graphics quality or disable background tasks when the battery is low:

```crystal
if battery.level < 0.2
  # Low battery mode
  disable_animations
  disable_background_sync
end
```

## Sensors

Modern phones have accelerometers, gyroscopes, and magnetometers. These sensors measure motion and orientation. Native.cr provides access to all of them.

### Accelerometer

The accelerometer measures acceleration and gravity. Use it for motion-based interactions, step counting, or fitness tracking.

```crystal
Native::Platform::Accelerometer.start

Native::Platform::Accelerometer.on_change do |x, y, z|
  # x, y, z are acceleration values in m/s²
  puts "Motion: #{x}, #{y}, #{z}"
end

Native::Platform::Accelerometer.stop
```

### Gyroscope

The gyroscope measures rotation. Use it for precise motion controls, 3D games, or AR applications.

```crystal
Native::Platform::Gyroscope.start

Native::Platform::Gyroscope.on_change do |x, y, z|
  # x, y, z are rotation rates in rad/s
  puts "Rotation: #{x}, #{y}, #{z}"
end

Native::Platform::Gyroscope.stop
```

### Magnetometer

The magnetometer measures magnetic field strength and direction (compass):

```crystal
Native::Platform::Magnetometer.start

Native::Platform::Magnetometer.on_change do |x, y, z|
  # x, y, z are magnetic field values in µT
  # You can calculate compass heading from these values
end
```

## Geolocation

Determine the device's location using GPS, network triangulation, or assisted GPS. This is useful for maps, location-based services, or fitness tracking.

Location requires permission from the user. Native.cr handles permission requests automatically:

```crystal
Native::Platform::Geolocation.start_listening(accuracy: 10.0)

Native::Platform::Geolocation.on_location do |location|
  puts "Latitude: #{location.latitude}"
  puts "Longitude: #{location.longitude}"
  puts "Accuracy: #{location.accuracy}m"
end

Native::Platform::Geolocation.on_error do |error|
  puts "Location error: #{error}"
end

Native::Platform::Geolocation.stop_listening
```

The accuracy parameter is in meters. Use 10-100m for most apps. High accuracy (5m) uses more battery.

```crystal
# High accuracy, more battery usage
Native::Platform::Geolocation.start_listening(accuracy: 5.0)

# Low accuracy, less battery usage
Native::Platform::Geolocation.start_listening(accuracy: 100.0)
```

## Display Information

Query display properties to optimize your UI:

```crystal
display = Native::Platform.display_info

display.density       # Screen density (1.0 to 3.0+)
display.width_dp      # Width in device-independent pixels
display.height_dp     # Height in device-independent pixels
display.orientation   # "portrait" or "landscape"
```

Use density to scale elements appropriately:

```crystal
base_size = 16
scaled_size = base_size * display.density
```

## Platform Detection

Sometimes you need different behavior on Android vs iOS:

```crystal
if Native::Platform.android?
  # Android-specific code
else
  # iOS-specific code
end
```

## Best Practices

- Request permissions early and explain why
- Disable high-accuracy location when not needed (saves battery)
- Display battery and location status in your UI
- Handle sensor data on a background thread if processing is expensive
- Stop listening to sensors when your app goes to the background
- Request location permission when the feature is first used
- Provide fallbacks if the device lacks certain sensors
