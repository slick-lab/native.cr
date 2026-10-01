# Image Picker

`Native::ImagePicker` wraps the platform gallery and camera pickers
(Intent system on Android, `UIImagePickerController` on iOS). Results come
back through a callback carrying a file path, decoded data, and dimensions.

---

## Quick start

```crystal
Native::ImagePicker::ImagePicker.pick do |result|
  if result.success
    puts result.path       # => readable file path
    puts result.width      # pixel width
    puts result.height     # pixel height
  else
    puts result.error_message
  end
end
```

`pick` opens the **gallery** by default. One callback, one result — the
picker dismisses itself and the callback fires once.

---

## Sources and quality

```crystal
enum ImageSource
  Camera
  Gallery
  Both
end

enum ImageQuality
  Low      # 20 %
  Medium   # 50 %
  High     # 100 %
  Original
end
```

Take a photo with the camera at full quality:

```crystal
Native::ImagePicker::ImagePicker.pick(
  source: Native::ImagePicker::ImageSource::Camera,
  quality: Native::ImagePicker::ImageQuality::High
) do |result|
  # same result shape as above
end
```

Shorthand for the camera:

```crystal
Native::ImagePicker::ImagePicker.take_photo do |result|
end
```

---

## Resizing on pick

Ask the platform to downscale during picking — cheaper than doing it in
Crystal afterwards:

```crystal
Native::ImagePicker::ImagePicker.pick(max_width: 1024, max_height: 1024) do |result|
end
```

The convenience module offers `pick_image`, `take_photo` and
`pick_and_resize` aliases:

```crystal
Native::ImagePicker::ImagePickerAPI.pick_and_resize(
  source: Native::ImagePicker::ImageSource::Gallery,
  max_width: 512, max_height: 512
) do |result|
end
```

---

## Multiple images

`pick_multiple` exists but is a placeholder in this version — it always
calls back with an empty array:

```crystal
Native::ImagePicker::ImagePicker.pick_multiple(max_count: 5) do |results|
  # results is empty for now
end
```

---

## Result fields

| Field | Type | Meaning |
|-------|------|---------|
| `success` | `Bool` | Pick completed (cancellation is `success: false`) |
| `path` | `String?` | Path you can open/read/share |
| `data` | `Bytes?` | Raw image bytes |
| `width` / `height` | `Int32` | Pixel dimensions |
| `mime_type` | `String` | e.g. `image/jpeg` |
| `error_message` | `String?` | Human-readable failure reason |

Handy helper: `result.has_image?` is true when `success` and either a path
or bytes are present.

---

## Platform notes

- **Android**: needs the `CAMERA` permission for the camera source; the
  framework handles the content-resolver round-trip for you.
- **iOS**: the first pick triggers the system photo-library permission
  prompt; camera use requires the camera usage description in Info.plist —
  the `native.cr create --ios` template already includes it.

See also [permissions.md](permissions.md) and [camera.md](camera.md).
