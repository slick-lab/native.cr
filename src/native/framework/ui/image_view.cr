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

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        image_class = env.find_class("android/widget/ImageView")
        constructor = env.get_method_id(image_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(image_class, constructor, activity).to_i64
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_image_view
        @native = ptr.to_i64
      {% end %}
    end

    def setImageResource(resource_id : Int32)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_image = env.get_method_id(env.get_object_class(@native), "setImageResource", "(I)V")
        env.call_void_method(@native, set_image, resource_id)
      {% elsif flag?(:native_ios) %}
        LibIOS.image_view_set_resource(@native, resource_id)
      {% end %}
    end

    def setImagePath(path : String)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        jpath = env.new_string_utf(path)
        set_image = env.get_method_id(env.get_object_class(@native), "setImageURI", "(Landroid/net/Uri;)V")
        uri_class = env.find_class("android/net/Uri")
        parse_method = env.get_static_method_id(uri_class, "parse", "(Ljava/lang/String;)Landroid/net/Uri;")
        uri = env.call_static_object_method(uri_class, parse_method, jpath)
        env.call_void_method(@native, set_image, uri)
      {% elsif flag?(:native_ios) %}
        LibIOS.image_view_set_path(@native, path.to_utf8)
      {% end %}
    end

    def setImageData(data : Bytes)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        byte_array = env.new_byte_array(data.size)
        env.set_byte_array_region(byte_array, 0, data.size, data)
        set_image = env.get_method_id(env.get_object_class(@native), "setImageBitmap", "(Landroid/graphics/Bitmap;)V")
        bitmap_class = env.find_class("android/graphics/BitmapFactory")
        decode_method = env.get_static_method_id(bitmap_class, "decodeByteArray", "([BII)Landroid/graphics/Bitmap;")
        bitmap = env.call_static_object_method(bitmap_class, decode_method, byte_array, 0, data.size)
        env.call_void_method(@native, set_image, bitmap)
      {% elsif flag?(:native_ios) %}
        LibIOS.image_view_set_data(@native, data, data.size)
      {% end %}
    end

    def scale_type=(type : ScaleType)
      {% if flag?(:native_android) %}
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
        scale_field = env.get_static_field_id(env.find_class("android/widget/ImageView$ScaleType"), scale_value, "Landroid/widget/ImageView$ScaleType;")
        scale_obj = env.get_static_object_field(env.find_class("android/widget/ImageView$ScaleType"), scale_field)
        set_scale = env.get_method_id(env.get_object_class(@native), "setScaleType", "(Landroid/widget/ImageView$ScaleType;)V")
        env.call_void_method(@native, set_scale, scale_obj)
      {% elsif flag?(:native_ios) %}
        scale_value = type.value
        LibIOS.image_view_set_scale_type(@native, scale_value)
      {% end %}
    end

    def scale_type : ScaleType
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return ScaleType::FitCenter unless env && @native != 0
        get_scale = env.get_method_id(env.get_object_class(@native), "getScaleType", "()Landroid/widget/ImageView$ScaleType;")
        scale_obj = env.call_object_method(@native, get_scale)
        scale_name = env.call_object_method(scale_obj, env.get_method_id(env.get_object_class(scale_obj), "toString", "()Ljava/lang/String;"))
        name = env.get_string_utf_chars(scale_name, nil).to_s
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
      {% else %}
        ScaleType::FitCenter
      {% end %}
    end

    def alpha=(value : Float32)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_alpha = env.get_method_id(env.get_object_class(@native), "setAlpha", "(F)V")
        env.call_void_method(@native, set_alpha, value)
      {% elsif flag?(:native_ios) %}
        LibIOS.image_view_set_alpha(@native, value)
      {% end %}
    end

    def alpha : Float32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 1.0f32 unless env && @native != 0
        get_alpha = env.get_method_id(env.get_object_class(@native), "getAlpha", "()F")
        env.call_float_method(@native, get_alpha)
      {% else %}
        1.0f32
      {% end %}
    end
  end
end
