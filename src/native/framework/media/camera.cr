# src/native/framework/media/camera.cr

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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        camera_class = env.FindClass("com/nativecr/CameraHelper")
        if camera_class == Pointer(Void).null
          return
        end

        constructor = env.GetMethodID(camera_class, "<init>", "(Landroid/app/Activity;)V")
        @camera_ptr = env.NewObject(camera_class, constructor, activity).to_i64

        setupCallbacks
      elsif Native::Platform.ios?
        ptr = LibIOS.create_camera_controller
        @camera_ptr = ptr.to_i64
      end
    end

    def facing=(value : Facing)
      @facing = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        set_facing = env.GetMethodID(env.GetObjectClass(@camera_ptr), "setFacing", "(I)V")
        env.CallVoidMethod(@camera_ptr, set_facing, value.value)
      elsif Native::Platform.ios?
        LibIOS.camera_set_facing(@camera_ptr, value.value)
      end
    end

    def facing : Facing
      @facing
    end

    def flash_mode=(value : FlashMode)
      @flash_mode = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        set_flash = env.GetMethodID(env.GetObjectClass(@camera_ptr), "setFlashMode", "(I)V")
        env.CallVoidMethod(@camera_ptr, set_flash, value.value)
      elsif Native::Platform.ios?
        LibIOS.camera_set_flash_mode(@camera_ptr, value.value)
      end
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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0 && view.native_ptr != 0
        start_preview = env.GetMethodID(env.GetObjectClass(@camera_ptr), "startPreview", "(Landroid/view/View;)V")
        env.CallVoidMethod(@camera_ptr, start_preview, view.native_ptr)
      elsif Native::Platform.ios?
        LibIOS.camera_start_preview(@camera_ptr, view.native_ptr)
      end
    end

    def stop_preview
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        stop_preview = env.GetMethodID(env.GetObjectClass(@camera_ptr), "stopPreview", "()V")
        env.CallVoidMethod(@camera_ptr, stop_preview)
      elsif Native::Platform.ios?
        LibIOS.camera_stop_preview(@camera_ptr)
      end
    end

    def take_photo
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        take_photo = env.GetMethodID(env.GetObjectClass(@camera_ptr), "takePhoto", "()V")
        env.CallVoidMethod(@camera_ptr, take_photo)
      elsif Native::Platform.ios?
        LibIOS.camera_take_photo(@camera_ptr)
      end
    end

    def start_recording(output_path : String)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        start_rec = env.GetMethodID(env.GetObjectClass(@camera_ptr), "startRecording", "(Ljava/lang/String;)V")
        env.CallVoidMethod(@camera_ptr, start_rec, env.NewStringUTF(output_path))
      elsif Native::Platform.ios?
        LibIOS.camera_start_recording(@camera_ptr, output_path.to_utf8)
      end
    end

    def stop_recording
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @camera_ptr != 0
        stop_rec = env.GetMethodID(env.GetObjectClass(@camera_ptr), "stopRecording", "()V")
        env.CallVoidMethod(@camera_ptr, stop_rec)
      elsif Native::Platform.ios?
        LibIOS.camera_stop_recording(@camera_ptr)
      end
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
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env && @camera_ptr != 0

      callback_class = env.FindClass("com/nativecr/CameraCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      set_callback = env.GetMethodID(env.GetObjectClass(@camera_ptr), "setCallback", "(Lcom/nativecr/CameraCallback;)V")
      env.CallVoidMethod(@camera_ptr, set_callback, callback_obj)
    end

    def handlePhotoCaptured(data : Bytes, width : Int32, height : Int32)
      @on_photo_captured.try &.call(data, width, height)
    end

    def handleError(error : String)
      @on_error.try &.call(error)
    end
  end
end
