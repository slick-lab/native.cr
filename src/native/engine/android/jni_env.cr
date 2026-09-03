# src/native/engine/android/jni_env.cr
# JNIEnvWrapper — typed Crystal wrapper around the raw JNIEnv* pointer.
# Framework files call env.method_name(args) on an instance of this struct.

{% if flag?(:native_android) %}
  struct Pointer(T)
    def to_i64 : Int64
      address.to_i64
    end
  end

  struct Native::Android::JNIEnvWrapper
    def initialize(@raw : Void*)
    end

    def null? : Bool
      @raw.null?
    end

    def to_unsafe : Void*
      @raw
    end

    # ── string helpers ──────────────────────────────────────────────────────────

    def new_string_utf(str : String) : Void*
      Native::Android::JNI.new_string_utf(str)
    end

    def get_string_utf_chars(str : Void*, _flag = nil) : String
      Native::Android::JNI.get_string_utf_chars(str)
    end

    def release_string_utf_chars(str : Void*, chars : UInt8*) : Nil
    end

    # ── class / method / field lookup ───────────────────────────────────────────

    def find_class(name : String) : Void*
      Native::Android::JNI.find_class(name)
    end

    def get_object_class(obj : Void*) : Void*
      Native::Android::JNI.get_object_class(obj)
    end

    def get_object_class(obj : Int64) : Void*
      Native::Android::JNI.get_object_class(Pointer(Void).new(obj.to_u64))
    end

    def is_instance_of(obj : Void*, clazz : Void*) : Bool
      Native::Android::JNI.is_instance_of(obj, clazz)
    end

    def get_method_id(clazz : Void*, name : String, sig : String) : Void*
      Native::Android::JNI.get_method_id(clazz, name, sig)
    end

    def get_static_method_id(clazz : Void*, name : String, sig : String) : Void*
      Native::Android::JNI.get_static_method_id(clazz, name, sig)
    end

    def get_field_id(clazz : Void*, name : String, sig : String) : Void*
      Native::Android::JNI.get_field_id(clazz, name, sig)
    end

    def get_static_field_id(clazz : Void*, name : String, sig : String) : Void*
      Native::Android::JNI.get_static_field_id(clazz, name, sig)
    end

    # ── object creation ──────────────────────────────────────────────────────────

    def new_object(clazz : Void*, constructor : Void*, *jargs) : Void*
      e = ep; return Pointer(Void).null unless e
      jv = jvalues(jargs)
      e.value.new_object_a.call(e.as(Void*), clazz, constructor,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe).as(Void*)
    end

    def new_object_array(length : Int32, element_class : Void*, initial : Void*) : Void*
      Native::Android::JNI.new_object_array(length, element_class, initial)
    end

    def new_object_array(length : Int32, element_class : Void*, initial : Nil) : Void*
      Native::Android::JNI.new_object_array(length, element_class)
    end

    # ── array operations ─────────────────────────────────────────────────────────

    def get_array_length(array : Void*) : Int32
      Native::Android::JNI.get_array_length(array)
    end

    def get_object_array_element(array : Void*, index : Int32) : Void*
      Native::Android::JNI.get_object_array_element(array, index)
    end

    def set_object_array_element(array : Void*, index : Int32, value : Void*) : Nil
      Native::Android::JNI.set_object_array_element(array, index, value)
    end

    def set_object_array_element(array : Void*, index : Int32, value : Int64) : Nil
      Native::Android::JNI.set_object_array_element(array, index, Pointer(Void).new(value.to_u64))
    end

    def new_byte_array(length : Int32) : Void*
      Native::Android::JNI.new_byte_array(length)
    end

    def get_byte_array_region(array : Void*, offset : Int32, length : Int32) : Bytes
      Native::Android::JNI.get_byte_array_region(array, offset, length)
    end

    def set_byte_array_region(array : Void*, offset : Int32, data : Bytes) : Nil
      Native::Android::JNI.set_byte_array_region(array, offset, data)
    end

    # ── field access ─────────────────────────────────────────────────────────────

    def get_object_field(obj : Void*, fid : Void*) : Void*
      Native::Android::JNI.get_object_field(obj, fid)
    end

    def get_boolean_field(obj : Void*, fid : Void*) : Bool
      Native::Android::JNI.get_boolean_field(obj, fid)
    end

    def get_int_field(obj : Void*, fid : Void*) : Int32
      Native::Android::JNI.get_int_field(obj, fid)
    end

    def get_static_object_field(clazz : Void*, fid : Void*) : Void*
      Native::Android::JNI.get_static_object_field(clazz, fid)
    end

    def get_static_int_field(clazz : Void*, fid : Void*) : Int32
      Native::Android::JNI.get_static_int_field(clazz, fid)
    end

    def set_object_field(obj : Void*, fid : Void*, value : Void*) : Nil
      Native::Android::JNI.set_object_field(obj, fid, value)
    end

    def set_int_field(obj : Void*, fid : Void*, value : Int32) : Nil
      Native::Android::JNI.set_int_field(obj, fid, value)
    end

    # ── ref management ───────────────────────────────────────────────────────────

    def delete_local_ref(ref : Void*) : Nil
      Native::Android::JNI.delete_local_ref(ref)
    end

    def delete_local_ref(ref : Int64) : Nil
      Native::Android::JNI.delete_local_ref(Pointer(Void).new(ref.to_u64))
    end

    # ── instance method calls ────────────────────────────────────────────────────

    def call_object_method(obj : Void* | Int64, mid : Void*, *jargs) : Void*
      e = ep; return Pointer(Void).null unless e
      jv = jvalues(jargs)
      e.value.call_object_method_a.call(e.as(Void*), jobj(obj), mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe).as(Void*)
    end

    def call_boolean_method(obj : Void* | Int64, mid : Void*, *jargs) : Bool
      e = ep; return false unless e
      jv = jvalues(jargs)
      e.value.call_boolean_method_a.call(e.as(Void*), jobj(obj), mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe) != 0
    end

    def call_int_method(obj : Void* | Int64, mid : Void*, *jargs) : Int32
      e = ep; return 0 unless e
      jv = jvalues(jargs)
      e.value.call_int_method_a.call(e.as(Void*), jobj(obj), mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe)
    end

    def call_long_method(obj : Void* | Int64, mid : Void*, *jargs) : Int64
      e = ep; return 0i64 unless e
      jv = jvalues(jargs)
      e.value.call_long_method_a.call(e.as(Void*), jobj(obj), mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe)
    end

    def call_float_method(obj : Void* | Int64, mid : Void*, *jargs) : Float32
      e = ep; return 0.0f32 unless e
      jv = jvalues(jargs)
      e.value.call_float_method_a.call(e.as(Void*), jobj(obj), mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe)
    end

    def call_double_method(obj : Void* | Int64, mid : Void*, *jargs) : Float64
      e = ep; return 0.0 unless e
      jv = jvalues(jargs)
      e.value.call_double_method_a.call(e.as(Void*), jobj(obj), mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe)
    end

    def call_void_method(obj : Void* | Int64, mid : Void*, *jargs) : Nil
      e = ep; return unless e
      jv = jvalues(jargs)
      e.value.call_void_method_a.call(e.as(Void*), jobj(obj), mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe)
    end

    # ── static method calls ──────────────────────────────────────────────────────

    def call_static_object_method(clazz : Void*, mid : Void*, *jargs) : Void*
      e = ep; return Pointer(Void).null unless e
      jv = jvalues(jargs)
      e.value.call_static_object_method_a.call(e.as(Void*), clazz, mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe).as(Void*)
    end

    def call_static_boolean_method(clazz : Void*, mid : Void*, *jargs) : Bool
      e = ep; return false unless e
      jv = jvalues(jargs)
      e.value.call_static_boolean_method_a.call(e.as(Void*), clazz, mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe) != 0
    end

    def call_static_int_method(clazz : Void*, mid : Void*, *jargs) : Int32
      e = ep; return 0 unless e
      jv = jvalues(jargs)
      e.value.call_static_int_method_a.call(e.as(Void*), clazz, mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe)
    end

    def call_static_long_method(clazz : Void*, mid : Void*, *jargs) : Int64
      e = ep; return 0i64 unless e
      jv = jvalues(jargs)
      e.value.call_static_long_method_a.call(e.as(Void*), clazz, mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe)
    end

    def call_static_float_method(clazz : Void*, mid : Void*, *jargs) : Float32
      e = ep; return 0.0f32 unless e
      jv = jvalues(jargs)
      e.value.call_static_float_method_a.call(e.as(Void*), clazz, mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe)
    end

    def call_static_double_method(clazz : Void*, mid : Void*, *jargs) : Float64
      e = ep; return 0.0 unless e
      jv = jvalues(jargs)
      e.value.call_static_double_method_a.call(e.as(Void*), clazz, mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe)
    end

    # ── typed field access (long/float/double round out the existing
    #    object/boolean/int accessors) ───────────────────────────────────────

    def get_long_field(obj : Void* | Int64, fid : Void*) : Int64
      e = ep; return 0i64 unless e
      e.value.get_long_field.call(e.as(Void*), jobj(obj), fid)
    end

    def get_float_field(obj : Void* | Int64, fid : Void*) : Float32
      e = ep; return 0.0f32 unless e
      e.value.get_float_field.call(e.as(Void*), jobj(obj), fid)
    end

    def get_double_field(obj : Void* | Int64, fid : Void*) : Float64
      e = ep; return 0.0 unless e
      e.value.get_double_field.call(e.as(Void*), jobj(obj), fid)
    end

    def get_static_long_field(clazz : Void*, fid : Void*) : Int64
      e = ep; return 0i64 unless e
      e.value.get_static_long_field.call(e.as(Void*), clazz, fid)
    end

    def get_static_float_field(clazz : Void*, fid : Void*) : Float32
      e = ep; return 0.0f32 unless e
      e.value.get_static_float_field.call(e.as(Void*), clazz, fid)
    end

    def get_static_double_field(clazz : Void*, fid : Void*) : Float64
      e = ep; return 0.0 unless e
      e.value.get_static_double_field.call(e.as(Void*), clazz, fid)
    end

    def set_long_field(obj : Void* | Int64, fid : Void*, value : Int64) : Nil
      e = ep; return unless e
      e.value.set_long_field.call(e.as(Void*), jobj(obj), fid, value)
    end

    def set_float_field(obj : Void* | Int64, fid : Void*, value : Float32) : Nil
      e = ep; return unless e
      e.value.set_float_field.call(e.as(Void*), jobj(obj), fid, value)
    end

    def set_double_field(obj : Void* | Int64, fid : Void*, value : Float64) : Nil
      e = ep; return unless e
      e.value.set_double_field.call(e.as(Void*), jobj(obj), fid, value)
    end

    # ── exception handling ───────────────────────────────────────────────────────
    # A pending exception makes every subsequent JNI call undefined behaviour.
    # Check after calls that can throw; clear (or inspect via
    # exception_occurred) before continuing.

    def exception_check : Bool
      e = ep; return false unless e
      e.value.exception_check.call(e.as(Void*)) != 0
    end

    def exception_clear : Nil
      e = ep; return unless e
      e.value.exception_clear.call(e.as(Void*))
    end

    def exception_occurred : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.exception_occurred.call(e.as(Void*)).as(Void*)
    end

    def call_static_void_method(clazz : Void*, mid : Void*, *jargs) : Nil
      e = ep; return unless e
      jv = jvalues(jargs)
      e.value.call_static_void_method_a.call(e.as(Void*), clazz, mid,
        jv.empty? ? Pointer(LibJNI::JValue).null : jv.to_unsafe)
    end

    # ── private helpers ──────────────────────────────────────────────────────────

    private def ep : LibJNI::JNINativeInterface*?
      return nil if @raw.null?
      @raw.as(LibJNI::JNINativeInterface**).value
    end

    private def jobj(v : Void*) : Void*
      v
    end

    private def jobj(v : Int64) : Void*
      Pointer(Void).new(v.to_u64)
    end

    private def jvalues(args) : Array(LibJNI::JValue)
      arr = Array(LibJNI::JValue).new(args.size)
      args.each do |a|
        jv = LibJNI::JValue.new
        if a.is_a?(Void*)
          jv.l = a
        elsif a.is_a?(Int64)
          jv.j = a
        elsif a.is_a?(Int32)
          jv.i = a
        elsif a.is_a?(Float32)
          jv.f = a
        elsif a.is_a?(Float64)
          jv.d = a
        elsif a.is_a?(Bool)
          jv.z = a ? 1u8 : 0u8
        else
          jv.j = 0i64
        end
        arr << jv
      end
      arr
    end
  end
{% end %}
