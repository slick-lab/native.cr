# Platform

Device info, haptics, clipboard, sharing, and more.

---

## Platform Detection

```crystal
Native::Platform.android?      # => true on Android
Native::Platform.ios?          # => true on iOS
Native::Platform.desktop?      # => true on desktop
Native::Platform.is_mobile?    # => true on Android or iOS
Native::Platform.os_name       # => "Android", "iOS", or "Desktop"
```

---

## Device Info

```crystal
Native::Platform.device_model   # Device model string
Native::Platform.os_version     # OS version string
Native::Platform.screen_width   # Screen width in pixels
Native::Platform.screen_height  # Screen height in pixels
Native::Platform.screen_density # Density (1.0, 1.5, 2.0, 3.0, etc.)
```

---

## Haptic Feedback

```crystal
Native::Platform.vibrate(100)  # Vibrate 100ms
Native::Platform.vibrate(50)   # Short tap feedback
```

---

## Opening URLs

```crystal
Native::Platform.open_url("https://example.com")
Native::Platform.open_url("mailto:support@app.com")
Native::Platform.open_url("tel:+1234567890")
```

---

## Sharing

Share text or URLs via system share sheet:

```crystal
Native::Platform.share("Check out this app!", "Share")
```

For advanced sharing with images, use the Share module:

```crystal
options = Native::Share::ShareOptions.new
options.text = "Check this out!"
options.url = "https://example.com"
options.title = "Share"

Native::Share::ShareSheet.new(options).show { |success|
  puts "Shared: #{success}"
}
```

Quick helpers:

```crystal
Native::Share.share_text("Hello!") { |ok| }
Native::Share.share_url("https://example.com") { |ok| }
Native::Share.share_image("/path/to/image.jpg") { |ok| }
```

---

## Clipboard

```crystal
Native::Platform.copy_to_clipboard("Copied text")
text = Native::Platform.paste_from_clipboard

# Or via Clipboard module
Native::Clipboard.copy("Text")
pasted = Native::Clipboard.paste
Native::Clipboard.has_text?  # => Bool
Native::Clipboard.clear
```

---

## Battery

```crystal
level = Native::Platform.battery_level   # 0-100
charging = Native::Platform.is_charging? # => Bool
```

---

## Connectivity

Check network status:

```crystal
info = Native::Connectivity.get_network_info
info.is_connected?       # => Bool
info.is_wifi?            # => Bool
info.is_cellular?        # => Bool
info.is_metered?         # => Bool (data saver)
info.signal_strength     # => Int32
```

Monitor changes:

```crystal
Native::Connectivity.start_monitoring { |info|
  update_network_ui(info)
}

Native::Connectivity.stop_monitoring
```

Quick checks:

```crystal
Native::Connectivity.is_connected?
Native::Connectivity.is_wifi?
Native::Connectivity.is_cellular?
```

---

## Image Picker

Pick from gallery or camera:

```crystal
Native::ImagePicker::ImagePicker.pick(
  source: Native::ImagePicker::ImageSource::Gallery,
  quality: Native::ImagePicker::ImageQuality::High
) { |result|
  if result.has_image?
    @image_view.load(result.path) if result.path
  end
}
```

Take photo:

```crystal
Native::ImagePicker::ImagePicker.take_photo(
  quality: Native::ImagePicker::ImageQuality::High
) { |result|
  handle_photo(result)
}
```

---

## Example: Device Info Screen

```crystal
class InfoApp < Native::App
  def setup
    info = build_info
    @root = Native::UI::TextView.new(info)
  end

  def build_info
    "Device: #{Native::Platform.device_model}\n" +
    "OS: #{Native::Platform.os_name} #{Native::Platform.os_version}\n" +
    "Screen: #{Native::Platform.screen_width}x#{Native::Platform.screen_height}\n" +
    "Density: #{Native::Platform.screen_density}\n" +
    "Battery: #{Native::Platform.battery_level}%"
  end
end
```
