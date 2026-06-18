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

        clipboard = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.new_string_utf("clipboard"))

        if clipboard
          clip_class = env.find_class("android/content/ClipData")
          new_plain_text = env.get_static_method_id(clip_class, "newPlainText", "(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Landroid/content/ClipData;")
          clip = env.call_static_object_method(clip_class, new_plain_text, env.new_string_utf("text"), env.new_string_utf(text))

          set_clip = env.get_method_id(env.get_object_class(clipboard), "setPrimaryClip", "(Landroid/content/ClipData;)V")
          env.call_void_method(clipboard, set_clip, clip)

          env.delete_local_ref(clipboard)
          env.delete_local_ref(clip)
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

            result = env.get_string_utf_chars(text, nil).to_s

            env.delete_local_ref(clipboard)
            env.delete_local_ref(clip)
            env.delete_local_ref(item)

            return result
          end
          env.delete_local_ref(clipboard)
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

        clipboard = env.call_object_method(activity, env.get_method_id(env.get_object_class(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), env.new_string_utf("clipboard"))

        if clipboard
          has_text = env.get_method_id(env.get_object_class(clipboard), "hasPrimaryClip", "()Z")
          result = env.call_boolean_method(clipboard, has_text)
          env.delete_local_ref(clipboard)
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
