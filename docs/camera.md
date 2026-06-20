# Camera

native.cr lets you show a live camera preview, capture photos as JPEG bytes, and record video — all through `Native::Media::Camera`.

> **Permission required.** You must request camera permission before opening the camera. See the [Permissions guide](./permissions.md).

---

## Creating a camera object

```crystal
camera = Native::Media::Camera.new

# Choose which camera to use
camera.facing = Native::Media::Camera::Facing::Back    # rear camera (default)
camera.facing = Native::Media::Camera::Facing::Front   # front/selfie camera

# Set photo quality
camera.quality = Native::Media::Camera::Quality::High    # (default)
camera.quality = Native::Media::Camera::Quality::Medium
camera.quality = Native::Media::Camera::Quality::Low

# Set flash mode
camera.flash_mode = Native::Media::Camera::FlashMode::Auto   # (default)
camera.flash_mode = Native::Media::Camera::FlashMode::On
camera.flash_mode = Native::Media::Camera::FlashMode::Off
camera.flash_mode = Native::Media::Camera::FlashMode::Torch  # keep torch on continuously
```

---

## Showing a live preview

Pass any `Native::UI::View` to `start_preview`. The camera feed fills that view.

```crystal
@preview = Native::UI::View.new
@preview.width  = 360
@preview.height = 480

camera.start_preview(@preview)

# Add @preview to your layout as normal
layout = Native::UI::LinearLayout.new
layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
layout.addView(@preview)
@root = layout
```

Stop the preview when you leave the screen or the app is backgrounded:

```crystal
camera.stop_preview
```

---

## Capturing a photo

Set up the callback **before** calling `take_photo`. The block receives raw JPEG bytes plus the image dimensions.

```crystal
camera.on_photo_captured do |data, width, height|
  puts "Captured #{width}×#{height} JPEG, #{data.size} bytes"

  # Display it in an ImageView
  @photo_view.setImageData(data)

  # Save it to the Documents folder
  storage = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Documents
  )
  filename = "photo_#{Time.utc.to_unix}.jpg"
  storage.write(filename, data)
  puts "Saved as #{filename}"
end

# Trigger the shutter
camera.take_photo
```

---

## Switching between front and back cameras

```crystal
camera.switch_camera   # toggles automatically

# Or set explicitly
camera.facing = Native::Media::Camera::Facing::Front
```

---

## Recording video

```crystal
output_path = "/path/to/output.mp4"

camera.start_recording(output_path)

# ... user records ...

camera.stop_recording
# The video is now saved at output_path
```

---

## Handling errors

```crystal
camera.on_error do |message|
  puts "Camera error: #{message}"
  @status_label.text = "Camera unavailable: #{message}"
end
```

Common error messages: permission denied, camera hardware in use by another app, flash not available.

---

## Pause and resume

The camera is exclusive hardware — if you hold it while the app is in the background, other apps cannot use it. Always release it in `on_pause`:

```crystal
def on_pause
  @camera.stop_preview
end

def on_resume
  @camera.start_preview(@preview_view)
end
```

---

## Full example — photo capture app with preview

```crystal
require "native"

class PhotoApp < Native::App
  def setup
    request_camera_and_start
  end

  def request_camera_and_start
    Native::Permissions::Permissions.camera do |status|
      if status == Native::Permissions::PermissionStatus::Granted
        build_ui
      else
        show_error("Camera access was denied.")
      end
    end
  end

  def build_ui
    set_background_color(20, 20, 25)

    @camera = Native::Media::Camera.new
    @camera.facing    = Native::Media::Camera::Facing::Back
    @camera.quality   = Native::Media::Camera::Quality::High
    @camera.flash_mode = Native::Media::Camera::FlashMode::Auto

    # Preview area
    @preview = Native::UI::View.new
    @preview.width  = 360
    @preview.height = 440

    # Status label
    @status = Native::UI::TextView.new("Ready to shoot")
    @status.text_size  = 14
    @status.text_color = Native::Math::Color.from_hex(0xAAAAAA)
    @status.center_horizontal

    # Capture button
    capture_btn = Native::UI::Button.new("📸  Capture")
    capture_btn.width            = 200
    capture_btn.height           = 56
    capture_btn.background_color = Native::Math::Color.from_hex(0xFF3B30)
    capture_btn.text_color       = Native::Math::Color.white
    capture_btn.on_click { take_photo }

    # Flip button
    flip_btn = Native::UI::Button.new("⟳ Flip")
    flip_btn.width  = 120
    flip_btn.height = 48
    flip_btn.on_click { @camera.switch_camera }

    btn_row = Native::UI::LinearLayout.new(
      Native::UI::LinearLayout::Orientation::Horizontal
    )
    btn_row.gravity = Native::UI::LinearLayout::Gravity::Center
    btn_row.addView(flip_btn)
    btn_row.addView(capture_btn)

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.set_padding(0, 16, 0, 24)
    layout.addView(@preview)
    layout.addView(@status)
    layout.addView(btn_row)
    @root = layout

    # Register callbacks
    @camera.on_photo_captured do |data, w, h|
      @status.text = "Photo saved (#{w}×#{h})"
      save_photo(data)
    end

    @camera.on_error do |msg|
      @status.text = "Error: #{msg}"
    end

    @camera.start_preview(@preview)
  end

  def take_photo
    @status.text = "Capturing…"
    @camera.take_photo
  end

  def save_photo(data : Bytes)
    docs = Native::Storage::FileStorage.new(
      Native::Storage::FileStorage::StorageType::Documents
    )
    filename = "photo_#{Time.utc.to_unix}.jpg"
    docs.write(filename, data)
  end

  def show_error(msg : String)
    label = Native::UI::TextView.new(msg)
    label.text_size  = 16
    label.text_color = Native::Math::Color.red
    label.center

    layout = Native::UI::LinearLayout.new
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(label)
    @root = layout
  end

  def on_pause
    @camera.stop_preview if @camera
  end

  def on_resume
    @camera.start_preview(@preview) if @camera && @preview
  end
end

Native::App.start(PhotoApp)
```
