# src/native/framework/dialog/alert_dialog.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

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
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        builder_class = env.find_class("android/app/AlertDialog$Builder")
        constructor = env.get_method_id(builder_class, "<init>", "(Landroid/content/Context;)V")
        @dialog_ptr = env.new_object(builder_class, constructor, activity).to_i64
        env.delete_local_ref(builder_class) unless builder_class.null?
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_alert_controller
        @dialog_ptr = ptr.to_i64
      {% end %}
    end

    def title=(value : String)
      @title = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        JNIHelpers.call_object(env, @dialog_ptr, "setTitle", "(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;", , env.new_string_utf(value))
      {% elsif flag?(:native_ios) %}
        LibIOS.alert_set_title(@dialog_ptr, value.to_utf8)
      {% end %}
    end

    def title : String
      @title
    end

    def message=(value : String)
      @message = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        JNIHelpers.call_object(env, @dialog_ptr, "setMessage", "(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;", , env.new_string_utf(value))
      {% elsif flag?(:native_ios) %}
        LibIOS.alert_set_message(@dialog_ptr, value.to_utf8)
      {% end %}
    end

    def message : String
      @message
    end

    def positive_button=(value : String)
      @positive_button = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        set_positive = env.get_method_id(env.get_object_class(@dialog_ptr), "setPositiveButton", "(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;")
        callback_class = env.find_class("com/nativecr/DialogCallback")
        callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(JI)V"), 0i64, 0)
        env.delete_local_ref(callback_class) unless callback_class.null?
        env.call_object_method(@dialog_ptr, set_positive, env.new_string_utf(value), callback_obj)
      {% elsif flag?(:native_ios) %}
        LibIOS.alert_add_action(@dialog_ptr, value.to_utf8, 0)
      {% end %}
    end

    def negative_button=(value : String)
      @negative_button = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        set_negative = env.get_method_id(env.get_object_class(@dialog_ptr), "setNegativeButton", "(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;")
        callback_class = env.find_class("com/nativecr/DialogCallback")
        callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(JI)V"), 0i64, 1)
        env.delete_local_ref(callback_class) unless callback_class.null?
        env.call_object_method(@dialog_ptr, set_negative, env.new_string_utf(value), callback_obj)
      {% elsif flag?(:native_ios) %}
        LibIOS.alert_add_action(@dialog_ptr, value.to_utf8, 1)
      {% end %}
    end

    def neutral_button=(value : String)
      @neutral_button = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        set_neutral = env.get_method_id(env.get_object_class(@dialog_ptr), "setNeutralButton", "(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;")
        callback_class = env.find_class("com/nativecr/DialogCallback")
        callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(JI)V"), 0i64, 2)
        env.delete_local_ref(callback_class) unless callback_class.null?
        env.call_object_method(@dialog_ptr, set_neutral, env.new_string_utf(value), callback_obj)
      {% end %}
    end

    def cancelable=(value : Bool)
      @cancelable = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        JNIHelpers.call_object(env, @dialog_ptr, "setCancelable", "(Z)Landroid/app/AlertDialog$Builder;", , value)
      {% end %}
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
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        create = env.get_method_id(env.get_object_class(@dialog_ptr), "create", "()Landroid/app/AlertDialog;")
        dialog = env.call_object_method(@dialog_ptr, create)
        JNIHelpers.call_void(env, dialog, "show", "()V")
      {% elsif flag?(:native_ios) %}
        LibIOS.alert_show(@dialog_ptr)
      {% end %}
    end

    def dismiss
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @dialog_ptr != 0
        create = env.get_method_id(env.get_object_class(@dialog_ptr), "create", "()Landroid/app/AlertDialog;")
        dialog = env.call_object_method(@dialog_ptr, create)
        JNIHelpers.call_void(env, dialog, "dismiss", "()V")
      {% elsif flag?(:native_ios) %}
        LibIOS.alert_dismiss(@dialog_ptr)
      {% end %}
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
