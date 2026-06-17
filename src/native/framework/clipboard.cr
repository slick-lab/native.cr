# src/native/framework/clipboard.cr

module Native::Clipboard
  class ClipboardManager
    @@instance : ClipboardManager?

    def self.instance : ClipboardManager
      @@instance ||= ClipboardManager.new
      @@instance.not_nil!
    end

    def set_text(text : String) : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        clipboard = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.NewStringUTF("clipboard"))

        if clipboard
          clip_class = env.FindClass("android/content/ClipData")
          new_plain_text = env.GetStaticMethodID(clip_class, "newPlainText", "(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Landroid/content/ClipData;")
          clip = env.CallStaticObjectMethod(clip_class, new_plain_text, env.NewStringUTF("text"), env.NewStringUTF(text))

          set_clip = env.GetMethodID(env.GetObjectClass(clipboard), "setPrimaryClip", "(Landroid/content/ClipData;)V")
          env.CallVoidMethod(clipboard, set_clip, clip)

          env.DeleteLocalRef(clipboard)
          env.DeleteLocalRef(clip)
          true
        else
          false
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.clipboard_set_text(text.to_utf8)
      {% else %}
        false
      {% end %}
    end

    def get_text : String?
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return nil unless env && activity

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
        nil
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.clipboard_get_text
        if ptr
          result = String.new(ptr)
          LibIOS.free_string(ptr)
          result
        else
          nil
        end
      {% else %}
        nil
      {% end %}
    end

    def has_text? : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        clipboard = env.CallObjectMethod(activity, env.GetMethodID(env.GetObjectClass(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.NewStringUTF("clipboard"))

        if clipboard
          has_text = env.GetMethodID(env.GetObjectClass(clipboard), "hasPrimaryClip", "()Z")
          result = env.CallBooleanMethod(clipboard, has_text)
          env.DeleteLocalRef(clipboard)
          result
        else
          false
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.clipboard_has_text
      {% else %}
        false
      {% end %}
    end

    def clear : Bool
      set_text("")
    end
  end

  module Clipboard
    def self.copy(text : String) : Bool
      ClipboardManager.instance.set_text(text)
    end

    def self.paste : String?
      ClipboardManager.instance.get_text
    end

    def self.has_text? : Bool
      ClipboardManager.instance.has_text?
    end

    def self.clear : Bool
      ClipboardManager.instance.clear
    end
  end
end
