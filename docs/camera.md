# Camera

native.cr lets you take photos, record video, and show a live camera preview through `Native::Media::Camera`.

> **Remember:** You must request camera permission before using the camera. See the [Permissions guide](./permissions.md).

---

## Setup

```crystal
camera = Native::Media::Camera.new

# Choose front or back camera
camera.facing = Native::Media::Camera::Facing::Back   # or ::Front

# Set photo quality
camera.quality = Native::Media::Camera::Quality::High  # High, Medium, Low

# Set flash mode
camera.flash_mode = Native::Media::Camera::FlashMode::Auto  # Off, On, Auto, Torch
```

---

## Showing a camera preview

Pass any `UI::View` to display the live camera feed inside it:

```crystal
preview_view = UI::View.new
preview_view.width = 300
preview_view.height = 400

camera.start_preview(preview_view)

# Add preview_view to your layout
col = UI::Column.new
col.add_child(preview_view)
@root = col
```

Stop the preview when you no longer need it:

```crystal
camera.stop_preview
```

---

## Taking a photo

```crystal
camera.on_photo_captured do |data, width, height|
  puts "Got photo: #{width}×#{height}, #{data.size} bytes"

  # Save to storage
  storage = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Documents
  )
  storage.write("photo.jpg", data)
end

# Trigger the capture
camera.take_photo
```

The callback receives:
- `data` — raw JPEG bytes (`Bytes`)
- `width` — image width in pixels (`Int32`)
- `height` — image height in pixels (`Int32`)

---

## Switching between front and back

```crystal
camera.switch_camera   # toggles between Front and Back
```

Or set it explicitly:

```crystal
camera.facing = Native::Media::Camera::Facing::Front
```

---

## Recording video

```crystal
output_path = "/path/to/output.mp4"

camera.start_recording(output_path)

# ... later ...
camera.stop_recording
```

---

## Handling errors

```crystal
camera.on_error do |message|
  puts "Camera error: #{message}"
end
```

---

## Pause and resume

Always release the camera when the app goes into the background — holding it prevents other apps from using it:

```crystal
def on_pause
  camera.stop_preview
end

def on_resume
  camera.start_preview(preview_view)
end
```

---

## Full example — photo capture app

```crystal
require "native"

class PhotoApp < Native::App
  def setup
    return unless Native::Permissions::Permissions.camera_granted?

    @camera = Native::Media::Camera.new
    @camera.facing = Native::Media::Camera::Facing::Back
    @camera.quality = Native::Media::Camera::Quality::High

    @preview = UI::View.new
    @preview.width = 320
    @preview.height = 420

    capture_btn = UI::Button.new
    capture_btn.text = "Take Photo"
    capture_btn.on_click { take_photo }

    @status = UI::Text.new
    @status.text = "Ready"

    @camera.on_photo_captured do |data, w, h|
      @status.text = "Saved #{w}×#{h} photo (#{data.size} bytes)"
    end

    @camera.start_preview(@preview)

    col = UI::Column.new
    col.spacing = 16
    col.alignment = Alignment::Center
    col.add_child(@preview)
    col.add_child(capture_btn)
    col.add_child(@status)
    @root = col
  end

  def take_photo
    @status.text = "Capturing..."
    @camera.take_photo
  end

  def on_pause
    @camera.stop_preview
  end

  def on_resume
    @camera.start_preview(@preview)
  end

  def draw
    @root.draw(renderer)
  end
end

if Native::Permissions::Permissions.camera_granted?
  Native::App.start(PhotoApp)
else
  Native::Permissions::Permissions.camera do |status|
    Native::App.start(PhotoApp) if status == Native::Permissions::PermissionStatus::Granted
  end
end
```
