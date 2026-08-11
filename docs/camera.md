# Camera

Capture photos and video from device camera.

---

## Request Permission

```crystal
Native::Permissions::Permissions.camera do |status|
  if status == Native::Permissions::PermissionStatus::Granted
    open_camera
  end
end
```

---

## Create Camera

```crystal
camera = Native::Media::Camera.new
camera.facing = Native::Media::Camera::Facing::Back
camera.quality = Native::Media::Camera::Quality::High
camera.flash_mode = Native::Media::Camera::FlashMode::Auto
```

---

## Live Preview

```crystal
@preview = Native::UI::View.new
@preview.width = 360
@preview.height = 480

camera.start_preview(@preview)

# Add @preview to your layout
```

Stop when backgrounded:

```crystal
def on_pause
  @camera.stop_preview
end
```

---

## Capture Photo

```crystal
camera.on_photo_captured do |data, width, height|
  # data = JPEG bytes
  @image_view.setImageData(data)
  
  # Save
  docs = Native::Storage::FileStorage.new(
    Native::Storage::FileStorage::StorageType::Documents
  )
  docs.write("photo.jpg", data)
end

camera.take_photo
```

---

## Switch Camera

```crystal
camera.switch_camera  # Toggle front/back
camera.facing = Native::Media::Camera::Facing::Front
```

---

## Record Video

```crystal
camera.start_recording("/path/output.mp4")
# ... recording ...
camera.stop_recording
```

---

## Errors

```crystal
camera.on_error { |msg| puts "Error: #{msg}" }
```

---

## Example: Photo App

```crystal
class PhotoApp < Native::App
  def setup
    Native::Permissions::Permissions.camera do |status|
      if status == Native::Permissions::PermissionStatus::Granted
        build_camera
      end
    end
  end

  def build_camera
    @camera = Native::Media::Camera.new
    
    @preview = Native::UI::View.new
    @preview.width = 360
    @preview.height = 480
    
    capture = Native::UI::Button.new("Capture")
    capture.on_click { @camera.take_photo }
    
    @camera.on_photo_captured { |data, w, h| save_photo(data) }
    @camera.start_preview(@preview)
    
    layout = Native::UI::LinearLayout.new
    layout.addView(@preview)
    layout.addView(capture)
    @root = layout
  end

  def on_pause
    @camera.stop_preview
  end

  def on_resume
    @camera.start_preview(@preview)
  end
end
```
