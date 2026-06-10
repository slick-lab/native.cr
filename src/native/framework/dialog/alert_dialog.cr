# src/native/framework/dialog/alert_dialog.cr

module Native::Dialog
  class AlertDialog
    property title : String = ""
    property message : String = ""
    property positive_button : String = ""
    property negative_button : String = ""
    property neutral_button : String = ""
    property on_positive : (-> Nil)? = nil
    property on_negative : (-> Nil)? = nil
    property on_neutral : (-> Nil)? = nil
    property cancelable : Bool = true
    property dialog_ptr : Int64 = 0

    def initialize
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        builder_class = env.FindClass("android/app/AlertDialog$Builder")
        constructor = env.GetMethodID(builder_class, "<init>", "(Landroid/content/Context;)V")
        @dialog_ptr = env.NewObject(builder_class, constructor, activity).to_i64
      elsif Native::Platform.ios?
        ptr = LibIOS.create_alert_controller
        @dialog_ptr = ptr.to_i64
      end
    end

    def title=(value : String)
      @title = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        set_title = env.GetMethodID(env.GetObjectClass(@dialog_ptr), "setTitle", "(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;")
        env.CallObjectMethod(@dialog_ptr, set_title, env.NewStringUTF(value))
      elsif Native::Platform.ios?
        LibIOS.alert_set_title(@dialog_ptr, value.to_utf8)
      end
    end

    def title : String
      @title
    end

    def message=(value : String)
      @message = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        set_message = env.GetMethodID(env.GetObjectClass(@dialog_ptr), "setMessage", "(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;")
        env.CallObjectMethod(@dialog_ptr, set_message, env.NewStringUTF(value))
      elsif Native::Platform.ios?
        LibIOS.alert_set_message(@dialog_ptr, value.to_utf8)
      end
    end

    def message : String
      @message
    end

    def positive_button=(value : String)
      @positive_button = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        set_positive = env.GetMethodID(env.GetObjectClass(@dialog_ptr), "setPositiveButton", "(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;")
        callback_class = env.FindClass("com/nativecr/DialogCallback")
        callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(JI)V"), Pointer(Void).address.to_i64, 0)
        env.CallObjectMethod(@dialog_ptr, set_positive, env.NewStringUTF(value), callback_obj)
      elsif Native::Platform.ios?
        LibIOS.alert_add_action(@dialog_ptr, value.to_utf8, 0)
      end
    end

    def negative_button=(value : String)
      @negative_button = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        set_negative = env.GetMethodID(env.GetObjectClass(@dialog_ptr), "setNegativeButton", "(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;")
        callback_class = env.FindClass("com/nativecr/DialogCallback")
        callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(JI)V"), Pointer(Void).address.to_i64, 1)
        env.CallObjectMethod(@dialog_ptr, set_negative, env.NewStringUTF(value), callback_obj)
      elsif Native::Platform.ios?
        LibIOS.alert_add_action(@dialog_ptr, value.to_utf8, 1)
      end
    end

    def neutral_button=(value : String)
      @neutral_button = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        set_neutral = env.GetMethodID(env.GetObjectClass(@dialog_ptr), "setNeutralButton", "(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;")
        callback_class = env.FindClass("com/nativecr/DialogCallback")
        callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(JI)V"), Pointer(Void).address.to_i64, 2)
        env.CallObjectMethod(@dialog_ptr, set_neutral, env.NewStringUTF(value), callback_obj)
      end
    end

    def cancelable=(value : Bool)
      @cancelable = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        set_cancelable = env.GetMethodID(env.GetObjectClass(@dialog_ptr), "setCancelable", "(Z)Landroid/app/AlertDialog$Builder;")
        env.CallObjectMethod(@dialog_ptr, set_cancelable, value)
      end
    end

    def cancelable? : Bool
      @cancelable
    end

    def on_positive(&block : -> Nil)
      @on_positive = block
    end

    def on_negative(&block : -> Nil)
      @on_negative = block
    end

    def on_neutral(&block : -> Nil)
      @on_neutral = block
    end

    def show
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        create = env.GetMethodID(env.GetObjectClass(@dialog_ptr), "create", "()Landroid/app/AlertDialog;")
        dialog = env.CallObjectMethod(@dialog_ptr, create)
        show_method = env.GetMethodID(env.GetObjectClass(dialog), "show", "()V")
        env.CallVoidMethod(dialog, show_method)
      elsif Native::Platform.ios?
        LibIOS.alert_show(@dialog_ptr)
      end
    end

    def dismiss
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        create = env.GetMethodID(env.GetObjectClass(@dialog_ptr), "create", "()Landroid/app/AlertDialog;")
        dialog = env.CallObjectMethod(@dialog_ptr, create)
        dismiss_method = env.GetMethodID(env.GetObjectClass(dialog), "dismiss", "()V")
        env.CallVoidMethod(dialog, dismiss_method)
      elsif Native::Platform.ios?
        LibIOS.alert_dismiss(@dialog_ptr)
      end
    end

    def handleButtonClick(which : Int32)
      case which
      when 0
        @on_positive.try &.call
      when 1
        @on_negative.try &.call
      when 2
        @on_neutral.try &.call
      end
    end
  end
end
