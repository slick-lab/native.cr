# examples/camera_app/src/main.cr

require "native"

class CameraApp < Native::App
  @photo_view : UI::Image?
  @capture_button : UI::Button?
  @status_label : UI::TextView?
  @camera : Native::Camera::Camera?

  def setup
    set_background_color(30, 30, 35)

    create_ui
    setup_camera
  end

  def create_ui
    @status_label = UI::TextView.new
    @status_label.not_nil!.text = "Camera ready"
    @status_label.not_nil!.text_size = 14
    @status_label.not_nil!.color = Color.from_hex(0xAAAAAA)

    @photo_view = UI::ImageView.new
    @photo_view.not_nil!.width = 300
    @photo_view.not_nil!.height = 300
    @photo_view.not_nil!.scale_mode = Native::Image::ScaleMode::AspectFit
    @photo_view.not_nil!.background_color = Color.from_hex(0x1A1A1A)
    @photo_view.not_nil!.corner_radius = CornerRadius.all(12)

    @capture_button = UI::Button.new
    @capture_button.not_nil!.text = "📸 Capture"
    @capture_button.not_nil!.width = 160
    @capture_button.not_nil!.height = 52
    @capture_button.not_nil!.background_color = Color.from_hex(0x007AFF)
    @capture_button.not_nil!.text_color = Color.white
    @capture_button.not_nil!.corner_radius = CornerRadius.all(26)
    @capture_button.not_nil!.on_click = -> { take_photo }

    column = UI::Column.new
    column.spacing = 20
    column.alignment = Alignment::Center
    column.add_child(@photo_view.not_nil!)
    column.add_child(@capture_button.not_nil!)
    column.add_child(@status_label.not_nil!)

    @root = column
  end

  def setup_camera
    return unless Native::Permissions.has_camera?

    config = Native::Camera::CameraConfig.new
    config.facing = Native::Camera::CameraFacing::Back
    config.quality = Native::Camera::CaptureQuality::High

    @camera = Native::Camera::Camera.new(config)
    @camera.not_nil!.open

    @status_label.not_nil!.text = "Camera ready"
  end

  def take_photo
    return unless @camera && @camera.not_nil!.is_open?

    @status_label.not_nil!.text = "Capturing..."

    @camera.not_nil!.on_photo do |photo|
      @status_label.not_nil!.text = "Photo captured!"
      display_photo(photo)
    end

    @camera.not_nil!.take_photo
  end

  def display_photo(photo : Native::Camera::Photo)
    image_data = Native::Image::ImageLoader.from_bytes(photo.data, "jpg")
    if image_data
      @photo_view.not_nil!.image = image_data
    end
  end

  def on_resume
    if @camera && !@camera.not_nil!.is_open?
      @camera.not_nil!.open
    end
  end

  def on_pause
    if @camera && @camera.not_nil!.is_open?
      @camera.not_nil!.close
    end
  end

end

# Request permission before starting
if Native::Permissions.request_camera
  Native::App.registered_subclass = CameraApp
else
  puts "Camera permission required to run this example"
end
