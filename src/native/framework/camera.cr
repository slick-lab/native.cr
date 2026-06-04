# src/native/framework/camera.cr

require "./ui"

module Native
  module Camera
    enum CameraFacing
      Back
      Front
    end

    enum FlashMode
      Off
      On
      Auto
      Torch
    end

    enum CaptureQuality
      Low
      Medium
      High
      Max
    end

    struct CameraConfig
      property facing : CameraFacing = CameraFacing::Back
      property flash_mode : FlashMode = FlashMode::Off
      property quality : CaptureQuality = CaptureQuality::High
      property resolution_width : Int32 = 0
      property resolution_height : Int32 = 0
      property enable_audio : Bool = true

      def initialize
      end
    end

    struct Photo
      property data : Bytes
      property width : Int32
      property height : Int32
      property mime_type : String
      property file_path : String?

      def initialize(@data = Bytes.empty, @width = 0, @height = 0,
                     @mime_type = "image/jpeg", @file_path = nil)
      end

      def save(path : String) : Bool
        File.write(path, @data)
        @file_path = path
        true
      rescue
        false
      end
    end

    struct Video
      property file_path : String
      property duration : Float64
      property width : Int32
      property height : Int32
      property file_size : Int64

      def initialize(@file_path = "", @duration = 0.0, @width = 0,
                     @height = 0, @file_size = 0)
      end
    end

    class Camera
      @camera_ptr : Void*? = nil
      @is_open : Bool = false
      @is_recording : Bool = false
      @config : CameraConfig
      @preview_view : PreviewView? = nil
      @photo_callback : (Photo -> Nil)?
      @video_callback : (Video -> Nil)?
      @error_callback : (String -> Nil)?

      def initialize(config : CameraConfig = CameraConfig.new)
        @config = config
      end

      def open : Bool
        return true if @is_open
        
        {% if flag?(:android) %}
          @camera_ptr = LibCamera.android_camera_open(
            @config.facing.to_i32,
            @config.flash_mode.to_i32
          )
        {% elsif flag?(:ios) %}
          @camera_ptr = LibCamera.ios_camera_open(
            @config.facing.to_i32,
            @config.flash_mode.to_i32
          )
        {% else %}
          return false
        {% end %}
        
        @is_open = @camera_ptr ? true : false
        
        if @is_open && @preview_view
          attach_preview
        end
        
        @is_open
      end

      def close : Nil
        return unless @is_open && @camera_ptr
        
        {% if flag?(:android) %}
          LibCamera.android_camera_close(@camera_ptr)
        {% elsif flag?(:ios) %}
          LibCamera.ios_camera_close(@camera_ptr)
        {% end %}
        
        @camera_ptr = nil
        @is_open = false
        @is_recording = false
      end

      def start_preview(view : PreviewView) : Nil
        @preview_view = view
        
        if @is_open && @camera_ptr
          attach_preview
        end
      end

      def stop_preview : Nil
        return unless @is_open && @camera_ptr && @preview_view
        
        {% if flag?(:android) %}
          LibCamera.android_camera_stop_preview(@camera_ptr)
        {% elsif flag?(:ios) %}
          LibCamera.ios_camera_stop_preview(@camera_ptr)
        {% end %}
      end

      def take_photo : Nil
        return unless @is_open && @camera_ptr
        
        {% if flag?(:android) %}
          LibCamera.android_camera_take_photo(@camera_ptr, @config.quality.to_i32)
        {% elsif flag?(:ios) %}
          LibCamera.ios_camera_take_photo(@camera_ptr, @config.quality.to_i32)
        {% end %}
      end

      def start_recording(file_path : String) : Bool
        return false unless @is_open && @camera_ptr && !@is_recording
        
        {% if flag?(:android) %}
          result = LibCamera.android_camera_start_recording(@camera_ptr, file_path.to_utf8, @config.enable_audio)
        {% elsif flag?(:ios) %}
          result = LibCamera.ios_camera_start_recording(@camera_ptr, file_path.to_utf8, @config.enable_audio)
        {% else %}
          result = false
        {% end %}
        
        if result
          @is_recording = true
        end
        
        result
      end

      def stop_recording : Video?
        return nil unless @is_open && @camera_ptr && @is_recording
        
        {% if flag?(:android) %}
          path_ptr = LibCamera.android_camera_stop_recording(@camera_ptr)
        {% elsif flag?(:ios) %}
          path_ptr = LibCamera.ios_camera_stop_recording(@camera_ptr)
        {% else %}
          return nil
        {% end %}
        
        @is_recording = false
        
        if path_ptr
          video = Video.new
          video.file_path = String.new(path_ptr)
          {% if flag?(:android) %}
            video.duration = LibCamera.android_video_get_duration(path_ptr)
            video.width = LibCamera.android_video_get_width(path_ptr)
            video.height = LibCamera.android_video_get_height(path_ptr)
            video.file_size = File.size(video.file_path)
          {% elsif flag?(:ios) %}
            video.duration = LibCamera.ios_video_get_duration(path_ptr)
            video.width = LibCamera.ios_video_get_width(path_ptr)
            video.height = LibCamera.ios_video_get_height(path_ptr)
            video.file_size = File.size(video.file_path)
          {% end %}
          LibCamera.free_string(path_ptr)
          video
        else
          nil
        end
      end

      def switch_facing : Nil
        return unless @is_open && @camera_ptr
        
        new_facing = @config.facing == CameraFacing::Back ? CameraFacing::Front : CameraFacing::Back
        @config.facing = new_facing
        
        {% if flag?(:android) %}
          LibCamera.android_camera_switch_facing(@camera_ptr, new_facing.to_i32)
        {% elsif flag?(:ios) %}
          LibCamera.ios_camera_switch_facing(@camera_ptr, new_facing.to_i32)
        {% end %}
      end

      def flash_mode=(mode : FlashMode)
        @config.flash_mode = mode
        
        {% if flag?(:android) %}
          LibCamera.android_camera_set_flash_mode(@camera_ptr, mode.to_i32)
        {% elsif flag?(:ios) %}
          LibCamera.ios_camera_set_flash_mode(@camera_ptr, mode.to_i32)
        {% end %}
      end

      def flash_mode : FlashMode
        @config.flash_mode
      end

      def set_zoom(level : Float32) : Nil
        return unless @is_open && @camera_ptr
        zoom = level.clamp(0.0, 1.0)
        
        {% if flag?(:android) %}
          LibCamera.android_camera_set_zoom(@camera_ptr, zoom)
        {% elsif flag?(:ios) %}
          LibCamera.ios_camera_set_zoom(@camera_ptr, zoom)
        {% end %}
      end

      def set_focus(x : Float32, y : Float32) : Nil
        return unless @is_open && @camera_ptr
        fx = x.clamp(0.0, 1.0)
        fy = y.clamp(0.0, 1.0)
        
        {% if flag?(:android) %}
          LibCamera.android_camera_set_focus(@camera_ptr, fx, fy)
        {% elsif flag?(:ios) %}
          LibCamera.ios_camera_set_focus(@camera_ptr, fx, fy)
        {% end %}
      end

      def on_photo(&block : Photo -> Nil) : Nil
        @photo_callback = block
        setup_callbacks
      end

      def on_video(&block : Video -> Nil) : Nil
        @video_callback = block
        setup_callbacks
      end

      def on_error(&block : String -> Nil) : Nil
        @error_callback = block
        setup_callbacks
      end

      def is_open? : Bool
        @is_open
      end

      def is_recording? : Bool
        @is_recording
      end

      private def attach_preview : Nil
        return unless @camera_ptr && @preview_view
        
        {% if flag?(:android) %}
          LibCamera.android_camera_attach_preview(@camera_ptr, @preview_view.not_nil!.native_ptr)
        {% elsif flag?(:ios) %}
          LibCamera.ios_camera_attach_preview(@camera_ptr, @preview_view.not_nil!.native_ptr)
        {% end %}
      end

      private def setup_callbacks : Nil
        return unless @camera_ptr
        
        {% if flag?(:android) %}
          LibCamera.android_camera_set_callbacks(
            @camera_ptr,
            ->(data_ptr : UInt8*, size : Int32, width : Int32, height : Int32) {
              Camera.handle_photo(data_ptr, size, width, height)
            },
            ->(path_ptr : UInt8*) {
              Camera.handle_video(path_ptr)
            },
            ->(error_ptr : UInt8*) {
              Camera.handle_error(error_ptr)
            }
          )
        {% elsif flag?(:ios) %}
          # Similar for iOS
        {% end %}
      end

      private def self.handle_photo(data_ptr : UInt8*, size : Int32, width : Int32, height : Int32) : Nil
        data = Bytes.new(size) { |i| data_ptr[i] }
        photo = Photo.new(data, width, height)
        
        instance = @@current_instance
        instance.try(&.photo_callback.try &.call(photo))
        
        LibCamera.free_buffer(data_ptr)
      end

      private def self.handle_video(path_ptr : UInt8*) : Nil
        return unless path_ptr
        
        video = Video.new
        video.file_path = String.new(path_ptr)
        
        instance = @@current_instance
        instance.try(&.video_callback.try &.call(video))
        
        LibCamera.free_string(path_ptr)
      end

      private def self.handle_error(error_ptr : UInt8*) : Nil
        return unless error_ptr
        
        error = String.new(error_ptr)
        
        instance = @@current_instance
        instance.try(&.error_callback.try &.call(error))
        
        LibCamera.free_string(error_ptr)
      end

      @@current_instance : Camera? = nil
      
      private def photo_callback : (Photo -> Nil)?
        @photo_callback
      end
      
      private def video_callback : (Video -> Nil)?
        @video_callback
      end
      
      private def error_callback : (String -> Nil)?
        @error_callback
      end
    end

    class PreviewView < UI::View
      @native_ptr : Void*? = nil

      def initialize
        super
        
        {% if flag?(:android) %}
          @native_ptr = LibCamera.android_create_preview_view
        {% elsif flag?(:ios) %}
          @native_ptr = LibCamera.ios_create_preview_view
        {% end %}
      end

      def native_ptr : Void*
        @native_ptr.not_nil!
      end

      def draw(renderer : Void*) : Nil
        super
        # Preview is rendered by native camera, not Crystal
      end
    end

    module CameraModule
      def self.take_photo(config : CameraConfig = CameraConfig.new) : Photo?
        camera = Camera.new(config)
        
        if camera.open
          photo = nil
          wait = Channel(Nil).new
          
          camera.on_photo do |p|
            photo = p
            wait.send(nil)
          end
          
          camera.take_photo
          wait.receive
          camera.close
          
          photo
        else
          nil
        end
      end

      def self.record_video(config : CameraConfig = CameraConfig.new, duration_seconds : Float64? = nil) : Video?
        camera = Camera.new(config)
        
        if camera.open
          video = nil
          wait = Channel(Nil).new
          
          camera.on_video do |v|
            video = v
            wait.send(nil)
          end
          
          temp_path = "#{Storage.temp_dir}/video_#{Time.utc.to_unix}.mp4"
          
          if camera.start_recording(temp_path)
            if duration_seconds
              sleep duration_seconds.seconds
              video = camera.stop_recording
            else
              wait.receive
            end
          end
          
          camera.close
          video
        else
          nil
        end
      end

      def self.request_permission : Bool
        {% if flag?(:android) %}
          LibCamera.android_request_camera_permission
        {% elsif flag?(:ios) %}
          LibCamera.ios_request_camera_permission
        {% else %}
          false
        {% end %}
      end

      def self.has_permission? : Bool
        {% if flag?(:android) %}
          LibCamera.android_has_camera_permission
        {% elsif flag?(:ios) %}
          LibCamera.ios_has_camera_permission
        {% else %}
          false
        {% end %}
      end

      def self.available_cameras : Array(CameraFacing)
        cameras = [] of CameraFacing
        
        {% if flag?(:android) %}
          if LibCamera.android_has_back_camera
            cameras << CameraFacing::Back
          end
          if LibCamera.android_has_front_camera
            cameras << CameraFacing::Front
          end
        {% elsif flag?(:ios) %}
          if LibCamera.ios_has_back_camera
            cameras << CameraFacing::Back
          end
          if LibCamera.ios_has_front_camera
            cameras << CameraFacing::Front
          end
        {% end %}
        
        cameras
      end
    end
  end
end
