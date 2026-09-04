# src/native/framework/clipboard.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::Clipboard
  class ClipboardManager
    @@instance : ClipboardManager?

    def self.instance : ClipboardManager
      @@instance ||= ClipboardManager.new
      @@instance.not_nil!
    end

    # Yields the system clipboard service, cleaning up the service ref and
    # the "clipboard" jstring afterwards.
    private def with_clipboard(env : Native::Android::JNIEnvWrapper, &block : Void* -> T?) : T? forall T
      activity = Native::Android::JNI.activity
      return nil if activity.null?

      service = JNIHelpers.with_jstring(env, "clipboard") do |jname|
        JNIHelpers.call_object(env, activity.to_i64, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;", jname)
      end
      return nil if service.null?
      begin
        yield service
      ensure
        env.delete_local_ref(service)
      end
    end

    def set_text(text : String) : Bool
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          with_clipboard(env) do |clipboard|
            clip = JNIHelpers.with_jstring(env, "text") do |jlabel|
              JNIHelpers.with_jstring(env, text) do |jtext|
                JNIHelpers.call_static_object(env, "android/content/ClipData", "newPlainText", "(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Landroid/content/ClipData;", jlabel, jtext)
              end
            end
            next false if clip.null?
            begin
              JNIHelpers.call_void(env, clipboard.to_i64, "setPrimaryClip", "(Landroid/content/ClipData;)V", clip)
              true
            ensure
              env.delete_local_ref(clip)
            end
          end || false
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.clipboard_set_text(text.to_utf8)
      {% else %}
        false
      {% end %}
    end

    def get_text : String?
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          with_clipboard(env) do |clipboard|
            next nil unless JNIHelpers.call_boolean(env, clipboard.to_i64, "hasPrimaryClip", "()Z")

            clip = JNIHelpers.call_object(env, clipboard.to_i64, "getPrimaryClip", "()Landroid/content/ClipData;")
            next nil if clip.null?
            begin
              item = JNIHelpers.call_object(env, clip.to_i64, "getItemAt", "(I)Landroid/content/ClipData$Item;", 0)
              next nil if item.null?
              begin
                text = JNIHelpers.call_object(env, item.to_i64, "getText", "()Ljava/lang/CharSequence;")
                next nil if text.null?
                begin
                  JNIHelpers.call_string(env, text.to_i64, "toString", "()Ljava/lang/String;")
                ensure
                  env.delete_local_ref(text)
                end
              ensure
                env.delete_local_ref(item)
              end
            ensure
              env.delete_local_ref(clip)
            end
          end
        end
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
        JNIHelpers.with_env do |env|
          result = with_clipboard(env) do |clipboard|
            JNIHelpers.call_boolean(env, clipboard.to_i64, "hasPrimaryClip", "()Z")
          end
          result || false
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
