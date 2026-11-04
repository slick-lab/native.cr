# examples/camera_app/src/main.cr
#
# Camera capture example — uses the REAL framework surface:
#   Native::Media::Camera, ImageView#setImageData, Permissions.request.
# Compile-checked on desktop/Android/iOS by the examples CI job.

require "native"

class CameraApp < Native::App
  @photo_view : UI::ImageView?
  @capture_button : UI::Button?
  @status_label : UI::TextView?
  @camera : Native::Media::Camera?

  def setup : Nil
    set_background_color(30, 30, 35)
    create_ui
    setup_camera
  end

  def create_ui
    @status_label = UI::TextView.new("Camera ready")
    @status_label.not_nil!.text_size = 14
    @status_label.not_nil!.color = Color.from_hex(0xAAAAAA)

    @photo_view = UI::ImageView.new
    @photo_view.not_nil!.width = 300
    @photo_view.not_nil!.height = 300
    @photo_view.not_nil!.scale_type = UI::ImageView::ScaleType::FitCenter
    @photo_view.not_nil!.background_color = Color.from_hex(0x1A1A1A)
    @photo_view.not_nil!.corner_radius = CornerRadius.all(12)

    @capture_button = UI::Button.new("Capture")
    @capture_button.not_nil!.width = 160
    @capture_button.not_nil!.height = 52
    @capture_button.not_nil!.on_click = ->capture

    column = UI::Column.new
    column.spacing = 20
    column.alignment = Alignment::Center
    column.add_child(@photo_view.not_nil!)
    column.add_child(@capture_button.not_nil!)
    column.add_child(@status_label.not_nil!)

    @root = column
  end

  def setup_camera
    # Ask before creating the camera — on refusal we still show the UI,
    # with a status label explaining why capture is disabled.
    Native::Permissions.request(Native::Permissions::PermissionType::Camera) do |status|
      if Native::Permissions.status_granted?(status)
        @camera = Native::Media::Camera.new
        @camera.not_nil!.facing = Native::Media::Camera::Facing::Back
        @camera.not_nil!.quality = Native::Media::Camera::Quality::High
        @camera.not_nil!.on_photo_captured { |data, width, height| display_photo(data, width, height) }
        @camera.not_nil!.on_error { |message| set_status("Camera error: #{message}") }
        @camera.not_nil!.take_photo
      else
        set_status("Camera permission denied")
      end
    end
  end

  def capture : Nil
    return unless @camera
    set_status("Capturing...")
    @camera.not_nil!.take_photo
  end

  def display_photo(data : Bytes, width : Int32, height : Int32)
    @photo_view.not_nil!.setImageData(data)
    set_status("Photo captured: #{width}x#{height}")
  end

  def set_status(text : String)
    @status_label.not_nil!.text = text
  end
end

Native::App.registered_subclass = CameraApp
