# src/native/android/jni.cr

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

  def self.env : Void*
    @@env
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

  def self.attach_current_thread : Bool
    return false if @@vm == Pointer(Void).null
    result = LibJNI.AttachCurrentThread(@@vm, pointerof(@@env), nil)
    result == 0
  end

  def self.detach_current_thread : Nil
    return if @@vm == Pointer(Void).null
    LibJNI.DetachCurrentThread(@@vm)
  end

  def self.find_class(name : String) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.FindClass(name)
  end

  def self.get_method_id(class_ref : Void*, name : String, signature : String) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.GetMethodID(class_ref, name, signature)
  end

  def self.get_static_method_id(class_ref : Void*, name : String, signature : String) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.GetStaticMethodID(class_ref, name, signature)
  end

  def self.get_field_id(class_ref : Void*, name : String, signature : String) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.GetFieldID(class_ref, name, signature)
  end

  def self.get_static_field_id(class_ref : Void*, name : String, signature : String) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.GetStaticFieldID(class_ref, name, signature)
  end

  def self.new_string_utf(str : String) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.NewStringUTF(str)
  end

  def self.get_string_utf_chars(str : Void*) : String
    return "" if @@env == Pointer(Void).null || str == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    chars = env.GetStringUTFChars(str, nil)
    result = String.new(chars)
    env.ReleaseStringUTFChars(str, chars)
    result
  end

  def self.new_object(class_ref : Void*, constructor : Void*, args : Array(Void*)? = nil) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.NewObjectA(class_ref, constructor, args)
    else
      env.NewObject(class_ref, constructor)
    end
  end

  def self.new_object_array(length : Int32, element_class : Void*, initial_element : Void* = Pointer(Void).null) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.NewObjectArray(length, element_class, initial_element)
  end

  def self.set_object_array_element(array : Void*, index : Int32, value : Void*) : Nil
    return if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.SetObjectArrayElement(array, index, value)
  end

  def self.get_object_array_element(array : Void*, index : Int32) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.GetObjectArrayElement(array, index)
  end

  def self.get_array_length(array : Void*) : Int32
    return 0 if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.GetArrayLength(array)
  end

  def self.new_byte_array(length : Int32) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.NewByteArray(length)
  end

  def self.set_byte_array_region(array : Void*, offset : Int32, data : Bytes) : Nil
    return if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.SetByteArrayRegion(array, offset, data.size, data)
  end

  def self.get_byte_array_region(array : Void*, offset : Int32, length : Int32) : Bytes
    return Bytes.new(0) if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    data = Bytes.new(length)
    env.GetByteArrayRegion(array, offset, length, data)
    data
  end

  def self.call_object_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallObjectMethodA(obj, method_id, args)
    else
      env.CallObjectMethod(obj, method_id)
    end
  end

  def self.call_boolean_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Bool
    return false if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallBooleanMethodA(obj, method_id, args)
    else
      env.CallBooleanMethod(obj, method_id)
    end
  end

  def self.call_int_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Int32
    return 0 if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallIntMethodA(obj, method_id, args)
    else
      env.CallIntMethod(obj, method_id)
    end
  end

  def self.call_long_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Int64
    return 0 if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallLongMethodA(obj, method_id, args)
    else
      env.CallLongMethod(obj, method_id)
    end
  end

  def self.call_float_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Float32
    return 0.0f32 if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallFloatMethodA(obj, method_id, args)
    else
      env.CallFloatMethod(obj, method_id)
    end
  end

  def self.call_double_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Float64
    return 0.0 if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallDoubleMethodA(obj, method_id, args)
    else
      env.CallDoubleMethod(obj, method_id)
    end
  end

  def self.call_void_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Nil
    return if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallVoidMethodA(obj, method_id, args)
    else
      env.CallVoidMethod(obj, method_id)
    end
  end

  def self.call_static_object_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallStaticObjectMethodA(class_ref, method_id, args)
    else
      env.CallStaticObjectMethod(class_ref, method_id)
    end
  end

  def self.call_static_boolean_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Bool
    return false if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallStaticBooleanMethodA(class_ref, method_id, args)
    else
      env.CallStaticBooleanMethod(class_ref, method_id)
    end
  end

  def self.call_static_int_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Int32
    return 0 if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallStaticIntMethodA(class_ref, method_id, args)
    else
      env.CallStaticIntMethod(class_ref, method_id)
    end
  end

  def self.call_static_void_method(class_ref : Void*, method_id : Void*, args : Array(Void*)? = nil) : Nil
    return if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    if args
      env.CallStaticVoidMethodA(class_ref, method_id, args)
    else
      env.CallStaticVoidMethod(class_ref, method_id)
    end
  end

  def self.get_object_field(obj : Void*, field_id : Void*) : Void*
    return Pointer(Void).null if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.GetObjectField(obj, field_id)
  end

  def self.get_boolean_field(obj : Void*, field_id : Void*) : Bool
    return false if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.GetBooleanField(obj, field_id)
  end

  def self.get_int_field(obj : Void*, field_id : Void*) : Int32
    return 0 if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.GetIntField(obj, field_id)
  end

  def self.set_object_field(obj : Void*, field_id : Void*, value : Void*) : Nil
    return if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.SetObjectField(obj, field_id, value)
  end

  def self.set_int_field(obj : Void*, field_id : Void*, value : Int32) : Nil
    return if @@env == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.SetIntField(obj, field_id, value)
  end

  def self.delete_local_ref(obj : Void*) : Nil
    return if @@env == Pointer(Void).null || obj == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.DeleteLocalRef(obj)
  end

  def self.get_activity_class_loader : Void*
    return Pointer(Void).null if @@activity_class == Pointer(Void).null
    env = @@env.as(JNIEnv*)
    env.CallObjectMethod(@@activity_class, env.GetMethodID(@@activity_class, "getClassLoader", "()Ljava/lang/ClassLoader;"))
  end
end

@[Link("jnigraphics")]
@[Link("log")]
lib LibJNI
  alias JNIEnv = Void*
  alias JavaVM = Void*
  fun AttachCurrentThread(vm : JavaVM*, env : JNIEnv**, args : Void*) : Int32
  fun DetachCurrentThread(vm : JavaVM*) : Int32
  fun GetEnv(vm : JavaVM*, env : JNIEnv**, version : Int32) : Int32 
end
