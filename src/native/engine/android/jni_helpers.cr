# src/native/engine/android/jni_helpers.cr
# Safe JNI helpers with automatic local reference cleanup.
# Use these instead of raw JNIEnvWrapper calls to prevent memory leaks.
#
# Example:
#   JNIHelpers.with_env do |env|
#     JNIHelpers.set_text(env, @native, "Hello")
#   end

{% if flag?(:native_android) %}
  module Native::Android::JNIHelpers
    # ── Environment guard ─────────────────────────────────────────────────────
    # Yields env if available, returns nil otherwise.
    # Usage: JNIHelpers.with_env { |e| ... }
    def self.with_env(&block : JNIEnvWrapper -> T?) : T? forall T
      env = Native::Android::JNI.env
      return nil unless env
      yield env
    end

    # ── Safe string creation (auto-deleted) ──────────────────────────────────
    def self.with_jstring(env : JNIEnvWrapper, str : String, &block : Void* -> T) : T forall T
      jstr = env.new_string_utf(str)
      begin
        yield jstr
      ensure
        env.delete_local_ref(jstr) unless jstr.null?
      end
    end

    # ── Safe class lookup (auto-deleted) ─────────────────────────────────────
    def self.with_class(env : JNIEnvWrapper, name : String, &block : Void* -> T) : T forall T
      jclass = env.find_class(name)
      begin
        yield jclass
      ensure
        env.delete_local_ref(jclass) unless jclass.null?
      end
    end

    # ── Safe object class + method lookup (auto-deleted class ref) ──────────
    def self.with_object_class(env : JNIEnvWrapper, obj : Int64, &block : Void* -> T) : T forall T
      jclass = env.get_object_class(obj)
      begin
        yield jclass
      ensure
        env.delete_local_ref(jclass) unless jclass.null?
      end
    end

    # ── One-shot void call on an object ──────────────────────────────────────
    # Looks up class, method, calls it, cleans up intermediate refs.
    def self.call_void(env : JNIEnvWrapper, obj : Int64, method_name : String, sig : String, *args)
      with_object_class(env, obj) do |jclass|
        return if jclass.null?
        mid = env.get_method_id(jclass, method_name, sig)
        return if mid.null?
        env.call_void_method(obj, mid, *args)
      end
    end

    # ── One-shot void call with a string arg ─────────────────────────────────
    def self.call_void_string(env : JNIEnvWrapper, obj : Int64, method_name : String, sig : String, str : String)
      with_jstring(env, str) do |jstr|
        call_void(env, obj, method_name, sig, jstr)
      end
    end

    # ── One-shot int call on an object ───────────────────────────────────────
    def self.call_int(env : JNIEnvWrapper, obj : Int64, method_name : String, sig : String, *args) : Int32
      with_object_class(env, obj) do |jclass|
        return 0 if jclass.null?
        mid = env.get_method_id(jclass, method_name, sig)
        return 0 if mid.null?
        env.call_int_method(obj, mid, *args)
      end
    end

    # ── One-shot float call on an object ─────────────────────────────────────
    def self.call_float(env : JNIEnvWrapper, obj : Int64, method_name : String, sig : String, *args) : Float32
      with_object_class(env, obj) do |jclass|
        return 0.0f32 if jclass.null?
        mid = env.get_method_id(jclass, method_name, sig)
        return 0.0f32 if mid.null?
        env.call_float_method(obj, mid, *args)
      end
    end

    # ── One-shot object call on an object ────────────────────────────────────
    def self.call_object(env : JNIEnvWrapper, obj : Int64, method_name : String, sig : String, *args) : Void*
      with_object_class(env, obj) do |jclass|
        return Pointer(Void).null if jclass.null?
        mid = env.get_method_id(jclass, method_name, sig)
        return Pointer(Void).null if mid.null?
        env.call_object_method(obj, mid, *args)
      end
    end

    # ── Static void call on a class ──────────────────────────────────────────
    def self.call_static_void(env : JNIEnvWrapper, class_name : String, method_name : String, sig : String, *args)
      with_class(env, class_name) do |jclass|
        return if jclass.null?
        mid = env.get_static_method_id(jclass, method_name, sig)
        return if mid.null?
        env.call_static_void_method(jclass, mid, *args)
      end
    end

    # ── Static object call on a class ────────────────────────────────────────
    def self.call_static_object(env : JNIEnvWrapper, class_name : String, method_name : String, sig : String, *args) : Void*
      with_class(env, class_name) do |jclass|
        return Pointer(Void).null if jclass.null?
        mid = env.get_static_method_id(jclass, method_name, sig)
        return Pointer(Void).null if mid.null?
        env.call_static_object_method(jclass, mid, *args)
      end
    end

    # ── Widget creation helpers ──────────────────────────────────────────────

    # Create a widget with a Context constructor: new Widget(Context)
    def self.new_widget(env : JNIEnvWrapper, class_name : String, context : Void*) : Int64
      with_class(env, class_name) do |jclass|
        return 0i64 if jclass.null?
        ctor = env.get_method_id(jclass, "<init>", "(Landroid/content/Context;)V")
        return 0i64 if ctor.null?
        obj = env.new_object(jclass, ctor, context)
        obj ? obj.to_i64 : 0i64
      end
    end

    # Create a callback object with a long constructor: new Callback(J)
    def self.new_callback(env : JNIEnvWrapper, class_name : String, handle : Int64) : Void*
      with_class(env, class_name) do |jclass|
        return Pointer(Void).null if jclass.null?
        ctor = env.get_method_id(jclass, "<init>", "(J)V")
        return Pointer(Void).null if ctor.null?
        env.new_object(jclass, ctor, handle)
      end
    end

    # ── Common UI property setters ───────────────────────────────────────────

    def self.set_text(env : JNIEnvWrapper, obj : Int64, text : String)
      with_jstring(env, text) do |jstr|
        call_void(env, obj, "setText", "(Ljava/lang/CharSequence;)V", jstr)
      end
    end

    def self.set_text_size(env : JNIEnvWrapper, obj : Int64, size : Int32)
      call_void(env, obj, "setTextSize", "(F)V", size.to_f32)
    end

    def self.set_text_color(env : JNIEnvWrapper, obj : Int64, color : Int32)
      call_void(env, obj, "setTextColor", "(I)V", color)
    end

    def self.set_visibility(env : JNIEnvWrapper, obj : Int64, visible : Bool)
      call_void(env, obj, "setVisibility", "(I)V", visible ? 0 : 8)
    end

    def self.set_enabled(env : JNIEnvWrapper, obj : Int64, enabled : Bool)
      call_void(env, obj, "setEnabled", "(Z)V", enabled)
    end

    def self.set_gravity(env : JNIEnvWrapper, obj : Int64, gravity : Int32)
      call_void(env, obj, "setGravity", "(I)V", gravity)
    end

    def self.set_max_lines(env : JNIEnvWrapper, obj : Int64, lines : Int32)
      call_void(env, obj, "setMaxLines", "(I)V", lines)
    end

    def self.set_background_color(env : JNIEnvWrapper, obj : Int64, color : Int32)
      call_void(env, obj, "setBackgroundColor", "(I)V", color)
    end

    def self.set_padding(env : JNIEnvWrapper, obj : Int64, left : Int32, top : Int32, right : Int32, bottom : Int32)
      call_void(env, obj, "setPadding", "(IIII)V", left, top, right, bottom)
    end

    def self.set_alpha(env : JNIEnvWrapper, obj : Int64, alpha : Float32)
      call_void(env, obj, "setAlpha", "(F)V", alpha)
    end

    def self.set_all_caps(env : JNIEnvWrapper, obj : Int64, all_caps : Bool)
      call_void(env, obj, "setAllCaps", "(Z)V", all_caps)
    end

    # ── Position / Size helpers ──────────────────────────────────────────────

    def self.set_x(env : JNIEnvWrapper, obj : Int64, x : Float32)
      call_void(env, obj, "setX", "(F)V", x)
    end

    def self.set_y(env : JNIEnvWrapper, obj : Int64, y : Float32)
      call_void(env, obj, "setY", "(F)V", y)
    end

    def self.set_position(env : JNIEnvWrapper, obj : Int64, x : Int32, y : Int32)
      set_x(env, obj, x.to_f32)
      set_y(env, obj, y.to_f32)
    end

    # ── LayoutParams helpers ─────────────────────────────────────────────────

    def self.get_layout_params(env : JNIEnvWrapper, obj : Int64) : Void*
      call_object(env, obj, "getLayoutParams", "()Landroid/view/ViewGroup$LayoutParams;")
    end

    def self.set_layout_params_size(env : JNIEnvWrapper, obj : Int64, width : Int32, height : Int32)
      params = get_layout_params(env, obj)
      return if params.null?

      begin
        JNIHelpers.with_object_class(env, params.to_i64) do |params_class|
          return if params_class.null?
          width_fid = env.get_field_id(params_class, "width", "I")
          height_fid = env.get_field_id(params_class, "height", "I")
          env.set_int_field(params, width_fid, width)
          env.set_int_field(params, height_fid, height)
        end
        call_void(env, obj, "setLayoutParams", "(Landroid/view/ViewGroup$LayoutParams;)V", params)
      ensure
        env.delete_local_ref(params)
      end
    end

    # ── Layout helpers ───────────────────────────────────────────────────────

    def self.add_view(env : JNIEnvWrapper, parent : Int64, child : Int64)
      call_void(env, parent, "addView", "(Landroid/view/View;)V", child)
    end

    def self.remove_view(env : JNIEnvWrapper, parent : Int64, child : Int64)
      call_void(env, parent, "removeView", "(Landroid/view/View;)V", child)
    end

    # ── Tag helpers ──────────────────────────────────────────────────────────

    def self.set_tag(env : JNIEnvWrapper, obj : Int64, tag : String)
      with_jstring(env, tag) do |jtag|
        call_void(env, obj, "setTag", "(Ljava/lang/Object;)V", jtag)
      end
    end

    # ── Click listener helpers ───────────────────────────────────────────────

    def self.set_on_click_listener(env : JNIEnvWrapper, obj : Int64, callback : Void*)
      call_void(env, obj, "setOnClickListener", "(Landroid/view/View$OnClickListener;)V", callback)
    end

    def self.set_on_long_click_listener(env : JNIEnvWrapper, obj : Int64, callback : Void*)
      call_void(env, obj, "setOnLongClickListener", "(Landroid/view/View$OnLongClickListener;)V", callback)
    end
  end
{% end %}
