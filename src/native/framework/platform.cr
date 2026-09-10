module Native::Platform
  def self.android? : Bool
    {% if flag?(:native_android) %}
      true
    {% else %}
      false
    {% end %}
  end

  def self.ios? : Bool
    {% if flag?(:native_ios) %}
      true
    {% else %}
      false
    {% end %}
  end

  def self.desktop? : Bool
    !android? && !ios?
  end

  def self.os_name : String
    if android?
      "Android"
    elsif ios?
      "iOS"
    else
      "Desktop"
    end
  end

  def self.is_mobile? : Bool
    android? || ios?
  end

  def self.device_model : String
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return "Unknown" unless env && activity

      resolver = JNIHelpers.call_object(env, activity, "getContentResolver", "()Landroid/content/ContentResolver;")

      settings_class = env.find_class("android/provider/Settings$Secure")
      get_string = env.get_static_method_id(settings_class, "getString", "(Landroid/content/ContentResolver;Ljava/lang/String;)Ljava/lang/String;")

      android_id = env.new_string_utf("android_id")
      model = env.call_static_object_method(settings_class, get_string, resolver, android_id)
      env.delete_local_ref(settings_class) unless settings_class.null?

      result = if model
                 env.get_string_utf_chars(model).to_s
               else
                 "Unknown"
               end

      env.delete_local_ref(resolver)
      env.delete_local_ref(model)
      env.delete_local_ref(android_id)

      result
    elsif ios?
      ptr = LibIOS.get_device_model
      if ptr
        result = String.new(ptr)
        LibIOS.free_string(ptr)
        result
      else
        "Unknown"
      end
    else
      "Desktop"
    end
  end

  def self.os_version : String
    if android?
      env = Native::Android::JNI.env
      return "Unknown" unless env

      version_class = env.find_class("android/os/Build$VERSION")
      release_field = env.get_static_field_id(version_class, "RELEASE", "Ljava/lang/String;")
      release = env.get_static_object_field(version_class, release_field)
      env.delete_local_ref(version_class) unless version_class.null?

      if release
        result = env.get_string_utf_chars(release).to_s
        env.delete_local_ref(release)
        result
      else
        "Unknown"
      end
    elsif ios?
      ptr = LibIOS.get_os_version
      if ptr
        result = String.new(ptr)
        LibIOS.free_string(ptr)
        result
      else
        "Unknown"
      end
    else
      "Unknown"
    end
  end

  def self.screen_width : Int32
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return 0 unless env && activity

      resources = JNIHelpers.call_object(env, activity, "getResources", "()Landroid/content/res/Resources;")
      metrics = JNIHelpers.call_object(env, resources, "getDisplayMetrics", "()Landroid/util/DisplayMetrics;")

      width = JNIHelpers.get_int_field_by_name(env, metrics.to_i64, "widthPixels", "I")

      env.delete_local_ref(resources)
      env.delete_local_ref(metrics)

      width
    elsif ios?
      LibIOS.get_screen_width
    else
      0
    end
  end

  def self.screen_height : Int32
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return 0 unless env && activity

      resources = JNIHelpers.call_object(env, activity, "getResources", "()Landroid/content/res/Resources;")
      metrics = JNIHelpers.call_object(env, resources, "getDisplayMetrics", "()Landroid/util/DisplayMetrics;")

      height = JNIHelpers.get_int_field_by_name(env, metrics.to_i64, "heightPixels", "I")

      env.delete_local_ref(resources)
      env.delete_local_ref(metrics)

      height
    elsif ios?
      LibIOS.get_screen_height
    else
      0
    end
  end

  def self.screen_density : Float32
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return 0.0f32 unless env && activity

      resources = JNIHelpers.call_object(env, activity, "getResources", "()Landroid/content/res/Resources;")
      metrics = JNIHelpers.call_object(env, resources, "getDisplayMetrics", "()Landroid/util/DisplayMetrics;")

      # densityDpi is Int32 — use get_int_field instead of the missing get_float_field
      density_dpi = JNIHelpers.get_int_field_by_name(env, metrics.to_i64, "densityDpi", "I")

      env.delete_local_ref(resources)
      env.delete_local_ref(metrics)

      (density_dpi / 160.0).to_f32
    elsif ios?
      LibIOS.get_screen_density
    else
      0.0f32
    end
  end

  def self.vibrate(duration_ms : Int32) : Nil
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return unless env && activity

      vibrator = JNIHelpers.with_jstring(env, "vibrator") do |jname|
        JNIHelpers.call_object(env, activity.to_i64, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;", jname)
      end

      if vibrator && !vibrator.null?
        begin
          JNIHelpers.call_void(env, vibrator.to_i64, "vibrate", "(J)V", duration_ms.to_i64)
        ensure
          env.delete_local_ref(vibrator)
        end
      end
    elsif ios?
      LibIOS.vibrate
    end
  end

  def self.open_url(url : String) : Bool
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return false unless env && activity

      uri_class = env.find_class("android/net/Uri")
      parse_method = env.get_static_method_id(uri_class, "parse", "(Ljava/lang/String;)Landroid/net/Uri;")
      uri = env.call_static_object_method(uri_class, parse_method, env.new_string_utf(url))
      env.delete_local_ref(uri_class) unless uri_class.null?

      intent_class = env.find_class("android/content/Intent")
      intent_constructor = env.get_method_id(intent_class, "<init>", "(Ljava/lang/String;Landroid/net/Uri;)V")
      intent = env.new_object(intent_class, intent_constructor, env.new_string_utf("android.intent.action.VIEW"), uri)
      env.delete_local_ref(intent_class) unless intent_class.null?

      JNIHelpers.call_void(env, activity.to_i64, "startActivity", "(Landroid/content/Intent;)V", intent)

      env.delete_local_ref(uri)
      env.delete_local_ref(intent)

      true
    elsif ios?
      LibIOS.open_url(url.to_utf8)
    else
      false
    end
  end

  def self.share(text : String, title : String = "") : Nil
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return unless env && activity

      intent_class = env.find_class("android/content/Intent")
      intent_constructor = env.get_method_id(intent_class, "<init>", "()V")
      intent = env.new_object(intent_class, intent_constructor)

      set_action = env.get_method_id(intent_class, "setAction", "(Ljava/lang/String;)Landroid/content/Intent;")
      env.call_object_method(intent, set_action, env.new_string_utf("android.intent.action.SEND"))

      put_extra = env.get_method_id(intent_class, "putExtra", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;")
      env.call_object_method(intent, put_extra, env.new_string_utf("android.intent.extra.TEXT"), env.new_string_utf(text))

      set_type = env.get_method_id(intent_class, "setType", "(Ljava/lang/String;)Landroid/content/Intent;")
      env.call_object_method(intent, set_type, env.new_string_utf("text/plain"))

      create_chooser = env.get_static_method_id(intent_class, "createChooser", "(Landroid/content/Intent;Ljava/lang/CharSequence;)Landroid/content/Intent;")
      chooser = env.call_static_object_method(intent_class, create_chooser, intent, env.new_string_utf(title))
      env.delete_local_ref(intent_class) unless intent_class.null?

      JNIHelpers.call_void(env, activity.to_i64, "startActivity", "(Landroid/content/Intent;)V", chooser)

      env.delete_local_ref(intent)
      env.delete_local_ref(chooser)
    elsif ios?
      LibIOS.share(text.to_utf8, title.to_utf8)
    end
  end

  def self.copy_to_clipboard(text : String) : Nil
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return unless env && activity

      clipboard = JNIHelpers.with_jstring(env, "clipboard") do |jname|
        JNIHelpers.call_object(env, activity.to_i64, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;", jname)
      end

      if clipboard && !clipboard.null?
        clip = JNIHelpers.call_static_object(env, "android/content/ClipData", "newPlainText", "(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Landroid/content/ClipData;", "text", text)
        if clip && !clip.null?
          begin
            JNIHelpers.call_void(env, clipboard.to_i64, "setPrimaryClip", "(Landroid/content/ClipData;)V", clip)
          ensure
            env.delete_local_ref(clip)
          end
        end
        env.delete_local_ref(clipboard)
      end
    elsif ios?
      LibIOS.copy_to_clipboard(text.to_utf8)
    end
  end

  def self.paste_from_clipboard : String
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return "" unless env && activity

      clipboard = JNIHelpers.with_jstring(env, "clipboard") do |jname|
        JNIHelpers.call_object(env, activity.to_i64, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;", jname)
      end

      if clipboard && !clipboard.null?
        begin
          has_clip = JNIHelpers.call_boolean(env, clipboard.to_i64, "hasPrimaryClip", "()Z")
          unless has_clip
            return ""
          end

          clip = JNIHelpers.call_object(env, clipboard.to_i64, "getPrimaryClip", "()Landroid/content/ClipData;")
          return "" if clip.null?
          begin
            item = JNIHelpers.call_object(env, clip.to_i64, "getItemAt", "(I)Landroid/content/ClipData$Item;", 0)
            return "" if item.null?
            begin
              text_obj = JNIHelpers.call_object(env, item.to_i64, "getText", "()Ljava/lang/CharSequence;")
              result = ""
              if text_obj && !text_obj.null?
                begin
                  result = env.get_string_utf_chars(text_obj)
                ensure
                  env.delete_local_ref(text_obj)
                end
              end
              result
            ensure
              env.delete_local_ref(item)
            end
          ensure
            env.delete_local_ref(clip)
          end
        ensure
          env.delete_local_ref(clipboard)
        end
      else
        ""
      end
    elsif ios?
      ptr = LibIOS.paste_from_clipboard
      if ptr
        result = String.new(ptr)
        LibIOS.free_string(ptr)
        result
      else
        ""
      end
    else
      ""
    end
  end

  def self.battery_level : Int32
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return 0 unless env && activity

      intent_filter = env.new_object(env.find_class("android/content/IntentFilter"), env.get_method_id(env.find_class("android/content/IntentFilter"), "<init>", "(Ljava/lang/String;)V"), env.new_string_utf("android.intent.action.BATTERY_CHANGED"))
      battery_status = JNIHelpers.call_object(env, activity, "registerReceiver", "(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;)Landroid/content/Intent;", nil, intent_filter)

      if battery_status
        level = JNIHelpers.get_int_field_by_name(env, battery_status.to_i64, "level", "I")
        scale = JNIHelpers.get_int_field_by_name(env, battery_status.to_i64, "scale", "I")
        result = (level * 100 / scale)
        env.delete_local_ref(battery_status)
        result
      else
        0
      end
    elsif ios?
      LibIOS.get_battery_level
    else
      0
    end
  end

  def self.is_charging? : Bool
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return false unless env && activity

      intent_filter = env.new_object(env.find_class("android/content/IntentFilter"), env.get_method_id(env.find_class("android/content/IntentFilter"), "<init>", "(Ljava/lang/String;)V"), env.new_string_utf("android.intent.action.BATTERY_CHANGED"))
      battery_status = JNIHelpers.call_object(env, activity, "registerReceiver", "(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;)Landroid/content/Intent;", nil, intent_filter)

      if battery_status
        plugged = JNIHelpers.get_int_field_by_name(env, battery_status.to_i64, "plugged", "I")
        result = plugged != 0
        env.delete_local_ref(battery_status)
        result
      else
        false
      end
    elsif ios?
      LibIOS.is_charging
    else
      false
    end
  end
end
