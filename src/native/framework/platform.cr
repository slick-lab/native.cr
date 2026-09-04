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

      get_content_resolver = env.get_method_id(env.get_object_class(activity), "getContentResolver", "()Landroid/content/ContentResolver;")
      resolver = env.call_object_method(activity, get_content_resolver)

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

      resources = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "getResources", "()Landroid/content/res/Resources;"))
      metrics = env.call_object_method(resources, env.get_method_id(env.get_object_class(resources), "getDisplayMetrics", "()Landroid/util/DisplayMetrics;"))

      width = env.get_int_field(metrics, env.get_field_id(env.get_object_class(metrics), "widthPixels", "I"))

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

      resources = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "getResources", "()Landroid/content/res/Resources;"))
      metrics = env.call_object_method(resources, env.get_method_id(env.get_object_class(resources), "getDisplayMetrics", "()Landroid/util/DisplayMetrics;"))

      height = env.get_int_field(metrics, env.get_field_id(env.get_object_class(metrics), "heightPixels", "I"))

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

      resources = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "getResources", "()Landroid/content/res/Resources;"))
      metrics = env.call_object_method(resources, env.get_method_id(env.get_object_class(resources), "getDisplayMetrics", "()Landroid/util/DisplayMetrics;"))

      # densityDpi is Int32 — use get_int_field instead of the missing get_float_field
      density_dpi = env.get_int_field(metrics, env.get_field_id(env.get_object_class(metrics), "densityDpi", "I"))

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

      vibrator = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.new_string_utf("vibrator"))

      if vibrator
        JNIHelpers.call_void(env, vibrator, "vibrate", "(J)V", duration_ms.to_i64)
        env.delete_local_ref(vibrator)
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

      JNIHelpers.call_void(env, activity, "startActivity", "(Landroid/content/Intent;)V", intent)

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

      JNIHelpers.call_void(env, activity, "startActivity", "(Landroid/content/Intent;)V", chooser)

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

      clipboard = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.new_string_utf("clipboard"))

      if clipboard
        clip_class = env.find_class("android/content/ClipData")
        new_plain_text = env.get_static_method_id(clip_class, "newPlainText", "(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Landroid/content/ClipData;")
        clip = env.call_static_object_method(clip_class, new_plain_text, env.new_string_utf("text"), env.new_string_utf(text))
        env.delete_local_ref(clip_class) unless clip_class.null?

        JNIHelpers.call_void(env, clipboard, "setPrimaryClip", "(Landroid/content/ClipData;)V", clip)

        env.delete_local_ref(clipboard)
        env.delete_local_ref(clip)
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

      clipboard = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.new_string_utf("clipboard"))

      if clipboard
        has_text = env.get_method_id(env.get_object_class(clipboard), "hasPrimaryClip", "()Z")
        if env.call_boolean_method(clipboard, has_text)
          get_clip = env.get_method_id(env.get_object_class(clipboard), "getPrimaryClip", "()Landroid/content/ClipData;")
          clip = env.call_object_method(clipboard, get_clip)

          get_item = env.get_method_id(env.get_object_class(clip), "getItemAt", "(I)Landroid/content/ClipData$Item;")
          item = env.call_object_method(clip, get_item, 0)

          get_text = env.get_method_id(env.get_object_class(item), "getText", "()Ljava/lang/CharSequence;")
          text = env.call_object_method(item, get_text)

          result = env.get_string_utf_chars(text).to_s

          env.delete_local_ref(clipboard)
          env.delete_local_ref(clip)
          env.delete_local_ref(item)

          return result
        end
        env.delete_local_ref(clipboard)
      end
      ""
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
      battery_status = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "registerReceiver", "(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;)Landroid/content/Intent;"), nil, intent_filter)

      if battery_status
        level = env.get_int_field(battery_status, env.get_field_id(env.get_object_class(battery_status), "level", "I"))
        scale = env.get_int_field(battery_status, env.get_field_id(env.get_object_class(battery_status), "scale", "I"))
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
      battery_status = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "registerReceiver", "(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;)Landroid/content/Intent;"), nil, intent_filter)

      if battery_status
        plugged = env.get_int_field(battery_status, env.get_field_id(env.get_object_class(battery_status), "plugged", "I"))
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
