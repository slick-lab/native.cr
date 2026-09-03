# src/native/android/jni.cr

{% if flag?(:native_android) %}
  lib LibJNI
    union JValue
      z : UInt8
      b : Int8
      c : UInt16
      s : Int16
      i : Int32
      j : Int64
      f : Float32
      d : Float64
      l : Void*
    end

    struct JNINativeInterface
      _p0 : Void*[6]                                                          # 0-5
      find_class : (Void*, UInt8*) -> Void*                                   # 6
      _p1 : Void*[8]                                                          # 7-14
      exception_occurred : (Void*, Void*) -> Void*                            # 15
      exception_describe : (Void*) -> Void                                    # 16
      exception_clear : (Void*) -> Void                                       # 17
      _p1b : Void*[5]                                                         # 18-22
      delete_local_ref : (Void*, Void*) -> Void                               # 23
      _p2 : Void*[6]                                                          # 24-29
      new_object_a : (Void*, Void*, Void*, JValue*) -> Void*                  # 30
      get_object_class : (Void*, Void*) -> Void*                              # 31
      is_instance_of : (Void*, Void*, Void*) -> UInt8                         # 32
      get_method_id : (Void*, Void*, UInt8*, UInt8*) -> Void*                 # 33
      _p3 : Void*[2]                                                          # 34-35
      call_object_method_a : (Void*, Void*, Void*, JValue*) -> Void*          # 36
      _p4 : Void*[2]                                                          # 37-38
      call_boolean_method_a : (Void*, Void*, Void*, JValue*) -> UInt8         # 39
      _p5 : Void*[11]                                                         # 40-50
      call_int_method_a : (Void*, Void*, Void*, JValue*) -> Int32             # 51
      _p6 : Void*[2]                                                          # 52-53
      call_long_method_a : (Void*, Void*, Void*, JValue*) -> Int64            # 54
      _p6b : Void*[2]                                                         # 55-56
      call_float_method_a : (Void*, Void*, Void*, JValue*) -> Float32         # 57
      _p7 : Void*[2]                                                          # 58-59
      call_double_method_a : (Void*, Void*, Void*, JValue*) -> Float64        # 60
      _p7b : Void*[2]                                                         # 61-62
      call_void_method_a : (Void*, Void*, Void*, JValue*) -> Void             # 63
      _p8 : Void*[30]                                                         # 64-93
      get_field_id : (Void*, Void*, UInt8*, UInt8*) -> Void*                  # 94
      get_object_field : (Void*, Void*, Void*) -> Void*                       # 95
      get_boolean_field : (Void*, Void*, Void*) -> UInt8                      # 96
      _p9 : Void*[3]                                                          # 97-99
      get_int_field : (Void*, Void*, Void*) -> Int32                          # 100
      get_long_field : (Void*, Void*, Void*) -> Int64                         # 101
      get_float_field : (Void*, Void*, Void*) -> Float32                      # 102
      get_double_field : (Void*, Void*, Void*) -> Float64                     # 103
      set_object_field : (Void*, Void*, Void*, Void*) -> Void                 # 104
      _p11 : Void*[4]                                                         # 105-108
      set_int_field : (Void*, Void*, Void*, Int32) -> Void                    # 109
      set_long_field : (Void*, Void*, Void*, Int64) -> Void                   # 110
      set_float_field : (Void*, Void*, Void*, Float32) -> Void                # 111
      set_double_field : (Void*, Void*, Void*, Float64) -> Void               # 112
      get_static_method_id : (Void*, Void*, UInt8*, UInt8*) -> Void*          # 113
      _p13 : Void*[2]                                                         # 114-115
      call_static_object_method_a : (Void*, Void*, Void*, JValue*) -> Void*   # 116
      _p14 : Void*[2]                                                         # 117-118
      call_static_boolean_method_a : (Void*, Void*, Void*, JValue*) -> UInt8  # 119
      _p15 : Void*[11]                                                        # 120-130
      call_static_int_method_a : (Void*, Void*, Void*, JValue*) -> Int32      # 131
      _p16 : Void*[2]                                                         # 132-133
      call_static_long_method_a : (Void*, Void*, Void*, JValue*) -> Int64     # 134
      _p17 : Void*[2]                                                         # 135-136
      call_static_float_method_a : (Void*, Void*, Void*, JValue*) -> Float32  # 137
      _p17b : Void*[2]                                                        # 138-139
      call_static_double_method_a : (Void*, Void*, Void*, JValue*) -> Float64 # 140
      _p18 : Void*[2]                                                         # 141-142
      call_static_void_method_a : (Void*, Void*, Void*, JValue*) -> Void      # 143
      get_static_field_id : (Void*, Void*, UInt8*, UInt8*) -> Void*           # 144
      get_static_object_field : (Void*, Void*, Void*) -> Void*                # 145
      _p19 : Void*[4]                                                         # 146-149
      get_static_int_field : (Void*, Void*, Void*) -> Int32                   # 150
      get_static_long_field : (Void*, Void*, Void*) -> Int64                  # 151
      get_static_float_field : (Void*, Void*, Void*) -> Float32               # 152
      get_static_double_field : (Void*, Void*, Void*) -> Float64              # 153
      _p20 : Void*[13]                                                        # 154-166
      new_string_utf : (Void*, UInt8*) -> Void*                               # 167
      _p21 : Void*                                                            # 168
      get_string_utf_chars : (Void*, Void*, UInt8*) -> UInt8*                 # 169
      release_string_utf_chars : (Void*, Void*, UInt8*) -> Void               # 170
      # NOTE: the real JNI function table continues directly at 171 — there
      # are no entries between ReleaseStringUTFChars (170) and
      # GetArrayLength (171). The old layout had a phantom Void*[4] gap
      # here, shifting every array function +4 slots so they bound to the
      # WRONG JNI functions on device (new_byte_array hit NewIntArray,
      # get/set_byte_array_region hit float/double region functions).
      # Indexes below verified against OpenJDK jni.h JNINativeInterface_.
      get_array_length : (Void*, Void*) -> Int32                              # 171
      new_object_array : (Void*, Int32, Void*, Void*) -> Void*                # 172
      get_object_array_element : (Void*, Void*, Int32) -> Void*               # 173
      set_object_array_element : (Void*, Void*, Int32, Void*) -> Void         # 174
      _p22 : Void*                                                            # 175 (NewBooleanArray)
      new_byte_array : (Void*, Int32) -> Void*                                # 176
      _p24 : Void*[23]                                                        # 177-199
      get_byte_array_region : (Void*, Void*, Int32, Int32, UInt8*) -> Void    # 200
      _p25 : Void*[7]                                                         # 201-207
      set_byte_array_region : (Void*, Void*, Int32, Int32, UInt8*) -> Void    # 208
      _p26 : Void*[19]                                                        # 209-227
      exception_check : (Void*, Void*) -> UInt8                               # 228
    end

    alias JavaVM = Void*
    fun AttachCurrentThread(vm : JavaVM*, env : Void**, args : Void*) : Int32
    fun DetachCurrentThread(vm : JavaVM*) : Int32
    fun GetEnv(vm : JavaVM*, env : Void**, version : Int32) : Int32
  end
{% end %}

module Native::Android::JNI
  @@env : Void* = Pointer(Void).null
  @@activity : Void* = Pointer(Void).null
  @@activity_class : Void* = Pointer(Void).null
  @@vm : Void* = Pointer(Void).null

  def self.set_env(env : Void*) : Nil
    @@env = env
  end

  def self.set_activity(activity : Void*) : Nil
    @@activity = activity
  end

  def self.set_activity_class(activity_class : Void*) : Nil
    @@activity_class = activity_class
  end

  def self.set_vm(vm : Void*) : Nil
    @@vm = vm
  end

  def self.activity : Void*
    @@activity
  end

  def self.activity_class : Void*
    @@activity_class
  end

  def self.vm : Void*
    @@vm
  end

  {% if flag?(:native_android) %}
    def self.env : Native::Android::JNIEnvWrapper?
      return nil if @@env.null?
      Native::Android::JNIEnvWrapper.new(@@env)
    end

    private def self.ep : LibJNI::JNINativeInterface*?
      return nil if @@env.null?
      @@env.as(LibJNI::JNINativeInterface**).value
    end

    def self.attach_current_thread : Bool
      return false if @@vm.null?
      result = LibJNI.AttachCurrentThread(@@vm.as(LibJNI::JavaVM*), pointerof(@@env), nil)
      result == 0
    end

    def self.detach_current_thread : Nil
      return if @@vm.null?
      LibJNI.DetachCurrentThread(@@vm.as(LibJNI::JavaVM*))
    end

    def self.find_class(name : String) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.find_class.call(e.as(Void*), name.to_unsafe).as(Void*)
    end

    def self.get_method_id(class_ref : Void*, name : String, signature : String) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.get_method_id.call(e.as(Void*), class_ref, name.to_unsafe, signature.to_unsafe).as(Void*)
    end

    def self.get_static_method_id(class_ref : Void*, name : String, signature : String) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.get_static_method_id.call(e.as(Void*), class_ref, name.to_unsafe, signature.to_unsafe).as(Void*)
    end

    def self.get_field_id(class_ref : Void*, name : String, signature : String) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.get_field_id.call(e.as(Void*), class_ref, name.to_unsafe, signature.to_unsafe).as(Void*)
    end

    def self.get_static_field_id(class_ref : Void*, name : String, signature : String) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.get_static_field_id.call(e.as(Void*), class_ref, name.to_unsafe, signature.to_unsafe).as(Void*)
    end

    def self.get_object_class(obj : Void*) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.get_object_class.call(e.as(Void*), obj).as(Void*)
    end

    def self.is_instance_of(obj : Void*, clazz : Void*) : Bool
      e = ep; return false unless e
      e.value.is_instance_of.call(e.as(Void*), obj, clazz) != 0
    end

    def self.new_string_utf(str : String) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.new_string_utf.call(e.as(Void*), str.to_unsafe).as(Void*)
    end

    def self.get_string_utf_chars(str : Void*) : String
      e = ep; return "" unless e
      return "" if str.null?
      chars = e.value.get_string_utf_chars.call(e.as(Void*), str, Pointer(UInt8).null)
      result = String.new(chars)
      e.value.release_string_utf_chars.call(e.as(Void*), str, chars)
      result
    end

    def self.new_object(class_ref : Void*, constructor : Void*) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.new_object_a.call(e.as(Void*), class_ref, constructor, Pointer(LibJNI::JValue).null).as(Void*)
    end

    def self.new_object_array(length : Int32, element_class : Void*, initial_element : Void* = Pointer(Void).null) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.new_object_array.call(e.as(Void*), length, element_class, initial_element).as(Void*)
    end

    def self.set_object_array_element(array : Void*, index : Int32, value : Void*) : Nil
      e = ep; return unless e
      e.value.set_object_array_element.call(e.as(Void*), array, index, value)
    end

    def self.get_object_array_element(array : Void*, index : Int32) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.get_object_array_element.call(e.as(Void*), array, index).as(Void*)
    end

    def self.get_array_length(array : Void*) : Int32
      e = ep; return 0 unless e
      e.value.get_array_length.call(e.as(Void*), array)
    end

    def self.new_byte_array(length : Int32) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.new_byte_array.call(e.as(Void*), length).as(Void*)
    end

    def self.set_byte_array_region(array : Void*, offset : Int32, data : Bytes) : Nil
      e = ep; return unless e
      e.value.set_byte_array_region.call(e.as(Void*), array, offset, data.size, data.to_unsafe)
    end

    def self.get_byte_array_region(array : Void*, offset : Int32, length : Int32) : Bytes
      e = ep; return Bytes.new(0) unless e
      data = Bytes.new(length)
      e.value.get_byte_array_region.call(e.as(Void*), array, offset, length, data.to_unsafe)
      data
    end

    def self.call_object_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Void*
      e = ep; return Pointer(Void).null unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_object_method_a.call(e.as(Void*), obj, method_id, jv.to_unsafe).as(Void*)
      else
        e.value.call_object_method_a.call(e.as(Void*), obj, method_id, Pointer(LibJNI::JValue).null).as(Void*)
      end
    end

    def self.call_boolean_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Bool
      e = ep; return false unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_boolean_method_a.call(e.as(Void*), obj, method_id, jv.to_unsafe) != 0
      else
        e.value.call_boolean_method_a.call(e.as(Void*), obj, method_id, Pointer(LibJNI::JValue).null) != 0
      end
    end

    def self.call_int_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Int32
      e = ep; return 0 unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_int_method_a.call(e.as(Void*), obj, method_id, jv.to_unsafe)
      else
        e.value.call_int_method_a.call(e.as(Void*), obj, method_id, Pointer(LibJNI::JValue).null)
      end
    end

    def self.call_long_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Int64
      e = ep; return 0i64 unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_long_method_a.call(e.as(Void*), obj, method_id, jv.to_unsafe)
      else
        e.value.call_long_method_a.call(e.as(Void*), obj, method_id, Pointer(LibJNI::JValue).null)
      end
    end

    def self.call_float_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Float32
      e = ep; return 0.0f32 unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_float_method_a.call(e.as(Void*), obj, method_id, jv.to_unsafe)
      else
        e.value.call_float_method_a.call(e.as(Void*), obj, method_id, Pointer(LibJNI::JValue).null)
      end
    end

    def self.call_double_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Float64
      e = ep; return 0.0 unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_double_method_a.call(e.as(Void*), obj, method_id, jv.to_unsafe)
      else
        e.value.call_double_method_a.call(e.as(Void*), obj, method_id, Pointer(LibJNI::JValue).null)
      end
    end

    def self.call_void_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Nil
      e = ep; return unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_void_method_a.call(e.as(Void*), obj, method_id, jv.to_unsafe)
      else
        e.value.call_void_method_a.call(e.as(Void*), obj, method_id, Pointer(LibJNI::JValue).null)
      end
    end

    def self.call_static_object_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Void*
      e = ep; return Pointer(Void).null unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_static_object_method_a.call(e.as(Void*), class_ref, method_id, jv.to_unsafe).as(Void*)
      else
        e.value.call_static_object_method_a.call(e.as(Void*), class_ref, method_id, Pointer(LibJNI::JValue).null).as(Void*)
      end
    end

    def self.call_static_boolean_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Bool
      e = ep; return false unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_static_boolean_method_a.call(e.as(Void*), class_ref, method_id, jv.to_unsafe) != 0
      else
        e.value.call_static_boolean_method_a.call(e.as(Void*), class_ref, method_id, Pointer(LibJNI::JValue).null) != 0
      end
    end

    def self.call_static_int_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Int32
      e = ep; return 0 unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_static_int_method_a.call(e.as(Void*), class_ref, method_id, jv.to_unsafe)
      else
        e.value.call_static_int_method_a.call(e.as(Void*), class_ref, method_id, Pointer(LibJNI::JValue).null)
      end
    end

    def self.call_static_long_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Int64
      e = ep; return 0i64 unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_static_long_method_a.call(e.as(Void*), class_ref, method_id, jv.to_unsafe)
      else
        e.value.call_static_long_method_a.call(e.as(Void*), class_ref, method_id, Pointer(LibJNI::JValue).null)
      end
    end

    def self.call_static_float_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Float32
      e = ep; return 0.0f32 unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_static_float_method_a.call(e.as(Void*), class_ref, method_id, jv.to_unsafe)
      else
        e.value.call_static_float_method_a.call(e.as(Void*), class_ref, method_id, Pointer(LibJNI::JValue).null)
      end
    end

    def self.call_static_double_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Float64
      e = ep; return 0.0 unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_static_double_method_a.call(e.as(Void*), class_ref, method_id, jv.to_unsafe)
      else
        e.value.call_static_double_method_a.call(e.as(Void*), class_ref, method_id, Pointer(LibJNI::JValue).null)
      end
    end

    def self.call_static_void_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Nil
      e = ep; return unless e
      if a = args
        jv = a.map { |x| jval_l(x) }
        e.value.call_static_void_method_a.call(e.as(Void*), class_ref, method_id, jv.to_unsafe)
      else
        e.value.call_static_void_method_a.call(e.as(Void*), class_ref, method_id, Pointer(LibJNI::JValue).null)
      end
    end

    def self.get_object_field(obj : Void*, field_id : Void*) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.get_object_field.call(e.as(Void*), obj, field_id).as(Void*)
    end

    def self.get_boolean_field(obj : Void*, field_id : Void*) : Bool
      e = ep; return false unless e
      e.value.get_boolean_field.call(e.as(Void*), obj, field_id) != 0
    end

    def self.get_int_field(obj : Void*, field_id : Void*) : Int32
      e = ep; return 0 unless e
      e.value.get_int_field.call(e.as(Void*), obj, field_id)
    end

    def self.get_long_field(obj : Void*, field_id : Void*) : Int64
      e = ep; return 0i64 unless e
      e.value.get_long_field.call(e.as(Void*), obj, field_id)
    end

    def self.get_float_field(obj : Void*, field_id : Void*) : Float32
      e = ep; return 0.0f32 unless e
      e.value.get_float_field.call(e.as(Void*), obj, field_id)
    end

    def self.get_double_field(obj : Void*, field_id : Void*) : Float64
      e = ep; return 0.0 unless e
      e.value.get_double_field.call(e.as(Void*), obj, field_id)
    end

    def self.get_static_object_field(class_ref : Void*, field_id : Void*) : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.get_static_object_field.call(e.as(Void*), class_ref, field_id).as(Void*)
    end

    def self.get_static_int_field(class_ref : Void*, field_id : Void*) : Int32
      e = ep; return 0 unless e
      e.value.get_static_int_field.call(e.as(Void*), class_ref, field_id)
    end

    def self.get_static_long_field(class_ref : Void*, field_id : Void*) : Int64
      e = ep; return 0i64 unless e
      e.value.get_static_long_field.call(e.as(Void*), class_ref, field_id)
    end

    def self.get_static_float_field(class_ref : Void*, field_id : Void*) : Float32
      e = ep; return 0.0f32 unless e
      e.value.get_static_float_field.call(e.as(Void*), class_ref, field_id)
    end

    def self.get_static_double_field(class_ref : Void*, field_id : Void*) : Float64
      e = ep; return 0.0 unless e
      e.value.get_static_double_field.call(e.as(Void*), class_ref, field_id)
    end

    def self.set_object_field(obj : Void*, field_id : Void*, value : Void*) : Nil
      e = ep; return unless e
      e.value.set_object_field.call(e.as(Void*), obj, field_id, value)
    end

    def self.set_int_field(obj : Void*, field_id : Void*, value : Int32) : Nil
      e = ep; return unless e
      e.value.set_int_field.call(e.as(Void*), obj, field_id, value)
    end

    def self.set_long_field(obj : Void*, field_id : Void*, value : Int64) : Nil
      e = ep; return unless e
      e.value.set_long_field.call(e.as(Void*), obj, field_id, value)
    end

    def self.set_float_field(obj : Void*, field_id : Void*, value : Float32) : Nil
      e = ep; return unless e
      e.value.set_float_field.call(e.as(Void*), obj, field_id, value)
    end

    def self.set_double_field(obj : Void*, field_id : Void*, value : Float64) : Nil
      e = ep; return unless e
      e.value.set_double_field.call(e.as(Void*), obj, field_id, value)
    end

    # Exception handling — a pending JNI exception makes every subsequent
    # JNI call undefined behaviour (usually a crash). Check after calls
    # that can throw (most of them) and clear before continuing.
    def self.exception_check : Bool
      e = ep; return false unless e
      e.value.exception_check.call(e.as(Void*)) != 0
    end

    def self.exception_clear : Nil
      e = ep; return unless e
      e.value.exception_clear.call(e.as(Void*))
    end

    def self.exception_occurred : Void*
      e = ep; return Pointer(Void).null unless e
      e.value.exception_occurred.call(e.as(Void*)).as(Void*)
    end

    def self.delete_local_ref(obj : Void*) : Nil
      return if obj.null?
      e = ep; return unless e
      e.value.delete_local_ref.call(e.as(Void*), obj)
    end

    def self.get_activity_class_loader : Void*
      e = ep; return Pointer(Void).null unless e
      ac = @@activity_class
      return Pointer(Void).null if ac.null?
      mid = e.value.get_method_id.call(e.as(Void*), ac, "getClassLoader".to_unsafe, "()Ljava/lang/ClassLoader;".to_unsafe)
      e.value.call_object_method_a.call(e.as(Void*), ac, mid, Pointer(LibJNI::JValue).null).as(Void*)
    end

    private def self.jval_l(ptr : Void*) : LibJNI::JValue
      jv = LibJNI::JValue.new
      jv.l = ptr
      jv
    end
  {% else %}
    def self.env : Nil
      nil
    end

    def self.attach_current_thread : Bool
      false
    end

    def self.detach_current_thread : Nil; end

    def self.find_class(name : String) : Void*
      Pointer(Void).null
    end

    def self.get_method_id(c : Void*, n : String, s : String) : Void*
      Pointer(Void).null
    end

    def self.get_static_method_id(c : Void*, n : String, s : String) : Void*
      Pointer(Void).null
    end

    def self.get_field_id(c : Void*, n : String, s : String) : Void*
      Pointer(Void).null
    end

    def self.get_static_field_id(c : Void*, n : String, s : String) : Void*
      Pointer(Void).null
    end

    def self.get_object_class(obj : Void*) : Void*
      Pointer(Void).null
    end

    def self.is_instance_of(obj : Void*, c : Void*) : Bool
      false
    end

    def self.new_string_utf(str : String) : Void*
      Pointer(Void).null
    end

    def self.get_string_utf_chars(str : Void*) : String
      ""
    end

    def self.new_object(c : Void*, m : Void*) : Void*
      Pointer(Void).null
    end

    def self.new_object_array(len : Int32, c : Void*, init : Void* = Pointer(Void).null) : Void*
      Pointer(Void).null
    end

    def self.set_object_array_element(a : Void*, i : Int32, v : Void*) : Nil; end

    def self.get_object_array_element(a : Void*, i : Int32) : Void*
      Pointer(Void).null
    end

    def self.get_array_length(a : Void*) : Int32
      0
    end

    def self.new_byte_array(len : Int32) : Void*
      Pointer(Void).null
    end

    def self.set_byte_array_region(a : Void*, off : Int32, data : Bytes) : Nil; end

    def self.get_byte_array_region(a : Void*, off : Int32, len : Int32) : Bytes
      Bytes.new(0)
    end

    def self.call_object_method(o : Void*, m : Void*, args : Array(Void*)? = nil) : Void*
      Pointer(Void).null
    end

    def self.call_boolean_method(o : Void*, m : Void*, args : Array(Void*)? = nil) : Bool
      false
    end

    def self.call_int_method(o : Void*, m : Void*, args : Array(Void*)? = nil) : Int32
      0
    end

    def self.call_long_method(o : Void*, m : Void*, args : Array(Void*)? = nil) : Int64
      0i64
    end

    def self.call_float_method(o : Void*, m : Void*, args : Array(Void*)? = nil) : Float32
      0.0f32
    end

    def self.call_double_method(o : Void*, m : Void*, args : Array(Void*)? = nil) : Float64
      0.0
    end

    def self.call_void_method(o : Void*, m : Void*, args : Array(Void*)? = nil) : Nil; end

    def self.call_static_object_method(c : Void*, m : Void*, args : Array(Void*)? = nil) : Void*
      Pointer(Void).null
    end

    def self.call_static_boolean_method(c : Void*, m : Void*, args : Array(Void*)? = nil) : Bool
      false
    end

    def self.call_static_int_method(c : Void*, m : Void*, args : Array(Void*)? = nil) : Int32
      0
    end

    def self.call_static_long_method(c : Void*, m : Void*, args : Array(Void*)? = nil) : Int64
      0i64
    end

    def self.call_static_float_method(c : Void*, m : Void*, args : Array(Void*)? = nil) : Float32
      0.0f32
    end

    def self.call_static_double_method(c : Void*, m : Void*, args : Array(Void*)? = nil) : Float64
      0.0
    end

    def self.call_static_void_method(c : Void*, m : Void*, args : Array(Void*)? = nil) : Nil; end

    def self.get_object_field(o : Void*, f : Void*) : Void*
      Pointer(Void).null
    end

    def self.get_boolean_field(o : Void*, f : Void*) : Bool
      false
    end

    def self.get_int_field(o : Void*, f : Void*) : Int32
      0
    end

    def self.get_long_field(o : Void*, f : Void*) : Int64
      0i64
    end

    def self.get_float_field(o : Void*, f : Void*) : Float32
      0.0f32
    end

    def self.get_double_field(o : Void*, f : Void*) : Float64
      0.0
    end

    def self.get_static_object_field(c : Void*, f : Void*) : Void*
      Pointer(Void).null
    end

    def self.get_static_int_field(c : Void*, f : Void*) : Int32
      0
    end

    def self.get_static_long_field(c : Void*, f : Void*) : Int64
      0i64
    end

    def self.get_static_float_field(c : Void*, f : Void*) : Float32
      0.0f32
    end

    def self.get_static_double_field(c : Void*, f : Void*) : Float64
      0.0
    end

    def self.set_long_field(o : Void*, f : Void*, v : Int64) : Nil; end

    def self.set_float_field(o : Void*, f : Void*, v : Float32) : Nil; end

    def self.set_double_field(o : Void*, f : Void*, v : Float64) : Nil; end

    def self.exception_check : Bool
      false
    end

    def self.exception_clear : Nil; end

    def self.exception_occurred : Void*
      Pointer(Void).null
    end

    def self.set_object_field(o : Void*, f : Void*, v : Void*) : Nil; end

    def self.set_int_field(o : Void*, f : Void*, v : Int32) : Nil; end

    def self.delete_local_ref(obj : Void*) : Nil; end

    def self.get_activity_class_loader : Void*
      Pointer(Void).null
    end
  {% end %}
end
