# src/native/framework/media/camera.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::Media
  class Camera
    enum Facing
      Back
      Front
    end

    enum FlashMode
      Off
      On
      Auto
      Torch
    end

    enum Quality
      Low
      Medium
      High
    end

    @camera_ptr : Int64 = 0
    @facing : Facing = Facing::Back
    @flash_mode : FlashMode = FlashMode::Off
    @quality : Quality = Quality::High
    @on_photo_captured : (Bytes, Int32, Int32 -> Nil)?
    @on_error : (String -> Nil)?

    def initialize
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        camera_class = env.find_class("com/nativecr/CameraHelper")
        if camera_class == Pointer(Void).null
          return
        end

        constructor = env.get_method_id(camera_class, "<init>", "(Landroid/app/Activity;)V")
        @camera_ptr = env.new_object(camera_class, constructor, activity).to_i64
        env.delete_local_ref(camera_class) unless camera_class.null?

        setupCallbacks
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_camera_controller
        @camera_ptr = ptr.to_i64
      {% end %}
    end

    def facing=(value : Facing)
      @facing = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        JNIHelpers.call_void(env, @camera_ptr, "setFacing", "(I)V", , value.value)
      {% elsif flag?(:native_ios) %}
        LibIOS.camera_set_facing(@camera_ptr, value.value)
      {% end %}
    end

    def facing : Facing
      @facing
    end

    def flash_mode=(value : FlashMode)
      @flash_mode = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        JNIHelpers.call_void(env, @camera_ptr, "setFlashMode", "(I)V", , value.value)
      {% elsif flag?(:native_ios) %}
        LibIOS.camera_set_flash_mode(@camera_ptr, value.value)
      {% end %}
    end

    def flash_mode : FlashMode
      @flash_mode
    end

    def quality=(value : Quality)
      @quality = value
    end

    def quality : Quality
      @quality
    end

    def start_preview(view : UI::View)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0 && view.native_ptr != 0
        JNIHelpers.call_void(env, @camera_ptr, "startPreview", "(Landroid/view/View;)V", view.native_ptr)
      {% elsif flag?(:native_ios) %}
        LibIOS.camera_start_preview(@camera_ptr, view.native_ptr)
      {% end %}
    end

    def stop_preview
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        JNIHelpers.call_void(env, @camera_ptr, "stopPreview", "()V")
      {% elsif flag?(:native_ios) %}
        LibIOS.camera_stop_preview(@camera_ptr)
      {% end %}
    end

    def take_photo
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        JNIHelpers.call_void(env, @camera_ptr, "takePhoto", "()V")
      {% elsif flag?(:native_ios) %}
        LibIOS.camera_take_photo(@camera_ptr)
      {% end %}
    end

    def start_recording(output_path : String)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        JNIHelpers.call_void(env, @camera_ptr, "startRecording", "(Ljava/lang/String;)V", , env.new_string_utf(output_path))
      {% elsif flag?(:native_ios) %}
        LibIOS.camera_start_recording(@camera_ptr, output_path.to_utf8)
      {% end %}
    end

    def stop_recording
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        JNIHelpers.call_void(env, @camera_ptr, "stopRecording", "()V")
      {% elsif flag?(:native_ios) %}
        LibIOS.camera_stop_recording(@camera_ptr)
      {% end %}
    end

    def switch_camera
      if @facing == Facing::Back
        self.facing = Facing::Front
      else
        self.facing = Facing::Back
      end
    end

    def on_photo_captured(&block : Bytes, Int32, Int32 -> Nil)
      @on_photo_captured = block
    end

    def on_error(&block : String -> Nil)
      @on_error = block
    end

    private def setupCallbacks
      {% unless flag?(:native_android) %}
        return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @camera_ptr != 0

      callback_class = env.find_class("com/nativecr/CameraCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(J)V"), 0i64)
      env.delete_local_ref(callback_class) unless callback_class.null?

      JNIHelpers.call_void(env, @camera_ptr, "setCallback", "(Lcom/nativecr/CameraCallback;)V", , callback_obj)
    end

    def handlePhotoCaptured(data : Bytes, width : Int32, height : Int32)
      @on_photo_captured.try &.call(data, width, height)
    end

    def handleError(error : String)
      @on_error.try &.call(error)
    end
  end
end
