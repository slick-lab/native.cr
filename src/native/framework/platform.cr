module Native::Platform
  def self.android? : Bool
    {% if flag?(:android) %}
      true
    {% else %}
      false
    {% end %}
  end

  def self.ios? : Bool
    {% if flag?(:ios) %}
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

      get_content_resolver = env.GetMethodID(env.GetObjectClass(activity), "getContentResolver", "()Landroid/content/ContentResolver;")
      resolver = env.CallObjectMethod(activity, get_content_resolver)

      settings_class = env.FindClass("android/provider/Settings$Secure")
      get_string = env.GetStaticMethodID(settings_class, "getString", "(Landroid/content/ContentResolver;Ljava/lang/String;)Ljava/lang/String;")

      android_id = env.NewStringUTF("android_id")
      model = env.CallStaticObjectMethod(settings_class, get_string, resolver, android_id)

      result = if model
                 env.GetStringUTFChars(model, nil).to_s
               else
                 "Unknown"
               end

      env.DeleteLocalRef(resolver)
      env.DeleteLocalRef(model)
      env.DeleteLocalRef(android_id)

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

      version_class = env.FindClass("android/os/Build$VERSION")
      release_field = env.GetStaticFieldID(version_class, "RELEASE", "Ljava/lang/String;")
      release = env.GetStaticObjectField(version_class, release_field)

      if release
        result = env.GetStringUTFChars(release, nil).to_s
        env.DeleteLocalRef(release)
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

      resources = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "getResources", "()Landroid/content/res/Resources;"))
      metrics = env.CallObjectMethod(resources, env.GetMethodID(env.GetObjectClass(resources), "getDisplayMetrics", "()Landroid/util/DisplayMetrics;"))

      width = env.GetIntField(metrics, env.GetFieldID(env.GetObjectClass(metrics), "widthPixels", "I"))

      env.DeleteLocalRef(resources)
      env.DeleteLocalRef(metrics)

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

      resources = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "getResources", "()Landroid/content/res/Resources;"))
      metrics = env.CallObjectMethod(resources, env.GetMethodID(env.GetObjectClass(resources), "getDisplayMetrics", "()Landroid/util/DisplayMetrics;"))

      height = env.GetIntField(metrics, env.GetFieldID(env.GetObjectClass(metrics), "heightPixels", "I"))

      env.DeleteLocalRef(resources)
      env.DeleteLocalRef(metrics)

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

      resources = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "getResources", "()Landroid/content/res/Resources;"))
      metrics = env.CallObjectMethod(resources, env.GetMethodID(env.GetObjectClass(resources), "getDisplayMetrics", "()Landroid/util/DisplayMetrics;"))

      density = env.GetFloatField(metrics, env.GetFieldID(env.GetObjectClass(metrics), "density", "F"))

      env.DeleteLocalRef(resources)
      env.DeleteLocalRef(metrics)

      density
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

      vibrator = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.NewStringUTF("vibrator"))

      if vibrator
        vibrate_method = env.GetMethodID(env.GetObjectClass(vibrator), "vibrate", "(J)V")
        env.CallVoidMethod(vibrator, vibrate_method, duration_ms.to_i64)
        env.DeleteLocalRef(vibrator)
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

      uri_class = env.FindClass("android/net/Uri")
      parse_method = env.GetStaticMethodID(uri_class, "parse", "(Ljava/lang/String;)Landroid/net/Uri;")
      uri = env.CallStaticObjectMethod(uri_class, parse_method, env.NewStringUTF(url))

      intent_class = env.FindClass("android/content/Intent")
      intent_constructor = env.GetMethodID(intent_class, "<init>", "(Ljava/lang/String;Landroid/net/Uri;)V")
      intent = env.NewObject(intent_class, intent_constructor, env.NewStringUTF("android.intent.action.VIEW"), uri)

      start_activity = env.GetMethodID(env.GetObjectClass(activity), "startActivity", "(Landroid/content/Intent;)V")
      env.CallVoidMethod(activity, start_activity, intent)

      env.DeleteLocalRef(uri)
      env.DeleteLocalRef(intent)

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

      intent_class = env.FindClass("android/content/Intent")
      intent_constructor = env.GetMethodID(intent_class, "<init>", "()V")
      intent = env.NewObject(intent_class, intent_constructor)

      set_action = env.GetMethodID(intent_class, "setAction", "(Ljava/lang/String;)Landroid/content/Intent;")
      env.CallObjectMethod(intent, set_action, env.NewStringUTF("android.intent.action.SEND"))

      put_extra = env.GetMethodID(intent_class, "putExtra", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;")
      env.CallObjectMethod(intent, put_extra, env.NewStringUTF("android.intent.extra.TEXT"), env.NewStringUTF(text))

      set_type = env.GetMethodID(intent_class, "setType", "(Ljava/lang/String;)Landroid/content/Intent;")
      env.CallObjectMethod(intent, set_type, env.NewStringUTF("text/plain"))

      create_chooser = env.GetStaticMethodID(intent_class, "createChooser", "(Landroid/content/Intent;Ljava/lang/CharSequence;)Landroid/content/Intent;")
      chooser = env.CallStaticObjectMethod(intent_class, create_chooser, intent, env.NewStringUTF(title))

      start_activity = env.GetMethodID(env.GetObjectClass(activity), "startActivity", "(Landroid/content/Intent;)V")
      env.CallVoidMethod(activity, start_activity, chooser)

      env.DeleteLocalRef(intent)
      env.DeleteLocalRef(chooser)
    elsif ios?
      LibIOS.share(text.to_utf8, title.to_utf8)
    end
  end

  def self.copy_to_clipboard(text : String) : Nil
    if android?
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return unless env && activity

      clipboard = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.NewStringUTF("clipboard"))

      if clipboard
        clip_class = env.FindClass("android/content/ClipData")
        new_plain_text = env.GetStaticMethodID(clip_class, "newPlainText", "(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Landroid/content/ClipData;")
        clip = env.CallStaticObjectMethod(clip_class, new_plain_text, env.NewStringUTF("text"), env.NewStringUTF(text))

        set_clip = env.GetMethodID(env.GetObjectClass(clipboard), "setPrimaryClip", "(Landroid/content/ClipData;)V")
        env.CallVoidMethod(clipboard, set_clip, clip)

        env.DeleteLocalRef(clipboard)
        env.DeleteLocalRef(clip)
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

      clipboard = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.NewStringUTF("clipboard"))

      if clipboard
        has_text = env.GetMethodID(env.GetObjectClass(clipboard), "hasPrimaryClip", "()Z")
        if env.CallBooleanMethod(clipboard, has_text)
          get_clip = env.GetMethodID(env.GetObjectClass(clipboard), "getPrimaryClip", "()Landroid/content/ClipData;")
          clip = env.CallObjectMethod(clipboard, get_clip)

          get_item = env.GetMethodID(env.GetObjectClass(clip), "getItemAt", "(I)Landroid/content/ClipData$Item;")
          item = env.CallObjectMethod(clip, get_item, 0)

          get_text = env.GetMethodID(env.GetObjectClass(item), "getText", "()Ljava/lang/CharSequence;")
          text = env.CallObjectMethod(item, get_text)

          result = env.GetStringUTFChars(text, nil).to_s

          env.DeleteLocalRef(clipboard)
          env.DeleteLocalRef(clip)
          env.DeleteLocalRef(item)

          return result
        end
        env.DeleteLocalRef(clipboard)
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

      intent_filter = env.NewObject(env.FindClass("android/content/IntentFilter"), env.GetMethodID(env.FindClass("android/content/IntentFilter"), "<init>", "(Ljava/lang/String;)V"), env.NewStringUTF("android.intent.action.BATTERY_CHANGED"))
      battery_status = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "registerReceiver", "(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;)Landroid/content/Intent;"), nil, intent_filter)

      if battery_status
        level = env.GetIntField(battery_status, env.GetFieldID(env.GetObjectClass(battery_status), "level", "I"))
        scale = env.GetIntField(battery_status, env.GetFieldID(env.GetObjectClass(battery_status), "scale", "I"))
        result = (level * 100 / scale)
        env.DeleteLocalRef(battery_status)
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

      intent_filter = env.NewObject(env.FindClass("android/content/IntentFilter"), env.GetMethodID(env.FindClass("android/content/IntentFilter"), "<init>", "(Ljava/lang/String;)V"), env.NewStringUTF("android.intent.action.BATTERY_CHANGED"))
      battery_status = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "registerReceiver", "(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;)Landroid/content/Intent;"), nil, intent_filter)

      if battery_status
        plugged = env.GetIntField(battery_status, env.GetFieldID(env.GetObjectClass(battery_status), "plugged", "I"))
        result = plugged != 0
        env.DeleteLocalRef(battery_status)
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
