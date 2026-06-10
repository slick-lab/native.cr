# src/native/framework/ui/image_view.cr

module Native::UI
  class ImageView < View
    enum ScaleType
      FitXY
      FitCenter
      FitStart
      FitEnd
      Center
      CenterCrop
      CenterInside
    end

    def initialize
      super()

      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        image_class = env.FindClass("android/widget/ImageView")
        constructor = env.GetMethodID(image_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(image_class, constructor, activity).to_i64
      elsif Native::Platform.ios?
        ptr = LibIOS.create_image_view
        @native = ptr.to_i64
      end
    end

    def setImageResource(resource_id : Int32)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_image = env.GetMethodID(env.GetObjectClass(@native), "setImageResource", "(I)V")
        env.CallVoidMethod(@native, set_image, resource_id)
      elsif Native::Platform.ios?
        LibIOS.image_view_set_resource(@native, resource_id)
      end
    end

    def setImagePath(path : String)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jpath = env.NewStringUTF(path)
        set_image = env.GetMethodID(env.GetObjectClass(@native), "setImageURI", "(Landroid/net/Uri;)V")
        uri_class = env.FindClass("android/net/Uri")
        parse_method = env.GetStaticMethodID(uri_class, "parse", "(Ljava/lang/String;)Landroid/net/Uri;")
        uri = env.CallStaticObjectMethod(uri_class, parse_method, jpath)
        env.CallVoidMethod(@native, set_image, uri)
      elsif Native::Platform.ios?
        LibIOS.image_view_set_path(@native, path.to_utf8)
      end
    end

    def setImageData(data : Bytes)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        byte_array = env.NewByteArray(data.size)
        env.SetByteArrayRegion(byte_array, 0, data.size, data)
        set_image = env.GetMethodID(env.GetObjectClass(@native), "setImageBitmap", "(Landroid/graphics/Bitmap;)V")
        bitmap_class = env.FindClass("android/graphics/BitmapFactory")
        decode_method = env.GetStaticMethodID(bitmap_class, "decodeByteArray", "([BII)Landroid/graphics/Bitmap;")
        bitmap = env.CallStaticObjectMethod(bitmap_class, decode_method, byte_array, 0, data.size)
        env.CallVoidMethod(@native, set_image, bitmap)
      elsif Native::Platform.ios?
        LibIOS.image_view_set_data(@native, data, data.size)
      end
    end

    def scale_type=(type : ScaleType)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        scale_value = case type
                      when ScaleType::FitXY        then "FIT_XY"
                      when ScaleType::FitCenter    then "FIT_CENTER"
                      when ScaleType::FitStart     then "FIT_START"
                      when ScaleType::FitEnd       then "FIT_END"
                      when ScaleType::Center       then "CENTER"
                      when ScaleType::CenterCrop   then "CENTER_CROP"
                      when ScaleType::CenterInside then "CENTER_INSIDE"
                      end
        scale_field = env.GetStaticFieldID(env.FindClass("android/widget/ImageView$ScaleType"), scale_value, "Landroid/widget/ImageView$ScaleType;")
        scale_obj = env.GetStaticObjectField(env.FindClass("android/widget/ImageView$ScaleType"), scale_field)
        set_scale = env.GetMethodID(env.GetObjectClass(@native), "setScaleType", "(Landroid/widget/ImageView$ScaleType;)V")
        env.CallVoidMethod(@native, set_scale, scale_obj)
      elsif Native::Platform.ios?
        scale_value = type.value
        LibIOS.image_view_set_scale_type(@native, scale_value)
      end
    end

    def scale_type : ScaleType
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return ScaleType::FitCenter unless env && @native != 0
        get_scale = env.GetMethodID(env.GetObjectClass(@native), "getScaleType", "()Landroid/widget/ImageView$ScaleType;")
        scale_obj = env.CallObjectMethod(@native, get_scale)
        scale_name = env.CallObjectMethod(scale_obj, env.GetMethodID(env.GetObjectClass(scale_obj), "toString", "()Ljava/lang/String;"))
        name = env.GetStringUTFChars(scale_name, nil).to_s
        case name
        when "FIT_XY"        then ScaleType::FitXY
        when "FIT_CENTER"    then ScaleType::FitCenter
        when "FIT_START"     then ScaleType::FitStart
        when "FIT_END"       then ScaleType::FitEnd
        when "CENTER"        then ScaleType::Center
        when "CENTER_CROP"   then ScaleType::CenterCrop
        when "CENTER_INSIDE" then ScaleType::CenterInside
        else                      ScaleType::FitCenter
        end
      else
        ScaleType::FitCenter
      end
    end

    def alpha=(value : Float32)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_alpha = env.GetMethodID(env.GetObjectClass(@native), "setAlpha", "(F)V")
        env.CallVoidMethod(@native, set_alpha, value)
      elsif Native::Platform.ios?
        LibIOS.image_view_set_alpha(@native, value)
      end
    end

    def alpha : Float32
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return 1.0f32 unless env && @native != 0
        get_alpha = env.GetMethodID(env.GetObjectClass(@native), "getAlpha", "()F")
        env.CallFloatMethod(@native, get_alpha)
      else
        1.0f32
      end
    end
  end
end
