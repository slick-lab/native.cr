# src/native/framework/dialog/toast.cr

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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        toast_class = env.FindClass("android/widget/Toast")
        make_text = env.GetStaticMethodID(toast_class, "makeText", "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;")
        toast = env.CallStaticObjectMethod(toast_class, make_text, activity, env.NewStringUTF(@text), @duration.value)

        show_method = env.GetMethodID(toast_class, "show", "()V")
        env.CallVoidMethod(toast, show_method)
      elsif Native::Platform.ios?
        LibIOS.show_toast(@text.to_utf8, @duration == Length::Long ? 3.5 : 2.0)
      end
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
