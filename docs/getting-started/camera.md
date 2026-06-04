---
title: Camera
---

# Camera

Mobile devices have powerful cameras built-in. Native.cr provides a complete camera API that lets you capture photos, record videos, and access the camera preview directly. You can build photo-sharing apps, video chat applications, or document scanning tools.

## Camera Permissions

Before using the camera, you must request permission from the user. This is a platform requirement on both Android and iOS. Users need to explicitly grant camera access before your app can use it.

Native.cr handles permission requests automatically when you first try to use the camera. A system dialog appears asking the user to allow or deny camera access. You can check the permission status anytime with `Camera.has_permission?`.

```crystal
if Native::Camera.has_permission?
  # Camera is available, start capturing
else
  # Request permission from user
  Native::Camera.request_permission
end
```

## Capturing Photos

The simplest camera operation is taking a single photo. Native.cr provides the `capture_photo` method that opens the camera interface, lets the user take a photo, and returns the result.

When you call `capture_photo`, the system camera app opens. The user points the device, taps the shutter button, and optionally reviews and confirms the photo. Your app receives the photo as an image file path.

```crystal
Native::Camera.capture_photo do |path|
  if path
    # Photo captured successfully
    image = UI::Image.new
    image.path = path
    @root = image
  else
    # User cancelled
  end
end
```

## Recording Video

Video recording works similarly to photo capture. Call `record_video` to open the camera in video recording mode. The user records video and can review it before confirmation.

```crystal
Native::Camera.record_video do |path|
  if path
    # Video recorded successfully
    puts "Video saved to: #{path}"
  else
    # User cancelled
  end
end
```

## Camera Configuration

You can configure camera behavior using the `CameraConfig` struct:

```crystal
config = Native::Camera::CameraConfig.new
config.quality = Native::Camera::Quality::High
config.save_to_gallery = true

Native::Camera.capture_photo(config) do |path|
  # Handle photo
end
```

Quality options are:

- `Quality::Low` - Smallest file size, fastest processing
- `Quality::Medium` - Balanced quality and file size
- `Quality::High` - Best quality, larger file size

## Accessing Camera Preview

For advanced use cases, you can access the camera preview stream directly. This is useful for AR applications, real-time image processing, or custom camera interfaces.

```crystal
Native::Camera.start_preview do |frame|
  # Process camera frame
  # frame is a raw image buffer
end
```

Processing happens on a background thread. Be careful with expensive operations—they can cause frame drops. Keep processing lightweight.

## Handling Errors

Camera operations can fail for several reasons: no permission, camera in use, low memory, or unsupported hardware. Always handle errors gracefully:

```crystal
Native::Camera.capture_photo do |path|
  if path
    process_photo(path)
  else
    show_error("Failed to capture photo")
  end
end
```

## Best Practices

- Request permission early in your app's lifecycle, not deep in a feature
- Show the user why you need camera access before requesting it
- Handle permission denial gracefully—don't crash or show ugly errors
- For performance-critical apps like AR, use low quality initially and upgrade based on device capabilities
- Clean up resources when done with the camera to save battery
