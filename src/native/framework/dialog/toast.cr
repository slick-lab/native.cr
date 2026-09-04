# src/native/framework/dialog/toast.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::Dialog
  class Toast
    enum Length
      Short = 0
      Long  = 1
    end

    @text : String = ""
    @duration : Length = Length::Short

    def initialize(text : String = "", duration : Length = Length::Short)
      @text = text
      @duration = duration
    end

    def text=(value : String)
      @text = value
    end

    def text : String
      @text
    end

    def duration=(value : Length)
      @duration = value
    end

    def duration : Length
      @duration
    end

    def show
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        toast_class = env.find_class("android/widget/Toast")
        make_text = env.get_static_method_id(toast_class, "makeText", "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;")
        toast = env.call_static_object_method(toast_class, make_text, activity, env.new_string_utf(@text), @duration.value)

        show_method = env.get_method_id(toast_class, "show", "()V")
        env.delete_local_ref(toast_class) unless toast_class.null?
        env.call_void_method(toast, show_method)
      {% elsif flag?(:native_ios) %}
        LibIOS.show_toast(@text.to_utf8, @duration == Length::Long ? 3.5 : 2.0)
      {% end %}
    end

    def self.show(text : String, duration : Length = Length::Short)
      toast = Toast.new(text, duration)
      toast.show
    end

    def self.show_short(text : String)
      show(text, Length::Short)
    end

    def self.show_long(text : String)
      show(text, Length::Long)
    end
  end
end
