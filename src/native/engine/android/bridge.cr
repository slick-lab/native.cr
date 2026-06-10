# src/native/engine/android/bridge.cr

@[Link("android")]
@[Link("log")]
@[Link("native_cr_engine")]
lib LibAndroid
  fun __android_log_print(prio : Int32, tag : UInt8*, fmt : UInt8*, ...) : Int32
  fun get_activity : Void*
  fun get_jni_env : Void*
  fun get_activity_class : Void*
end

fun crystal_android_main(env : Void*, activity : Void*, activity_class : Void*) : Void
  GC.init
  
  Native::Android::JNI.set_env(env)
  Native::Android::JNI.set_activity(activity)
  Native::Android::JNI.set_activity_class(activity_class)
  
  app = Native::App.current
  app.load_saved_state
  app.setup
  app.run
end

module Native::Android::JNI
  @@env : Void* = Pointer(Void).null
  @@activity : Void* = Pointer(Void).null
  @@activity_class : Void* = Pointer(Void).null
  
  def self.set_env(env : Void*) : Nil
    @@env = env
  end
  
  def self.set_activity(activity : Void*) : Nil
    @@activity = activity
  end
  
  def self.set_activity_class(activity_class : Void*) : Nil
    @@activity_class = activity_class
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
  
  def self.find_class(name : String) : Void*
    env_ptr = @@env
    return Pointer(Void).null if env_ptr.null?
    env = env_ptr.as(JNIEnv*)
    env.FindClass(name)
  end
  
  def self.get_method_id(class_ref : Void*, name : String, sig : String) : Void*
    env_ptr = @@env
    return Pointer(Void).null if env_ptr.null?
    env = env_ptr.as(JNIEnv*)
    env.GetMethodID(class_ref, name, sig)
  end
  
  def self.new_string_utf(str : String) : Void*
    env_ptr = @@env
    return Pointer(Void).null if env_ptr.null?
    env = env_ptr.as(JNIEnv*)
    env.NewStringUTF(str)
  end
  
  def self.new_object(class_ref : Void*, constructor : Void*, args : Array(Void*)? = nil) : Void*
    env_ptr = @@env
    return Pointer(Void).null if env_ptr.null?
    env = env_ptr.as(JNIEnv*)
    env.NewObject(class_ref, constructor)
  end
  
  def self.call_void_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Nil
    env_ptr = @@env
    return if env_ptr.null?
    env = env_ptr.as(JNIEnv*)
    env.CallVoidMethod(obj, method_id)
  end
  
  def self.call_object_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Void*
    env_ptr = @@env
    return Pointer(Void).null if env_ptr.null?
    env = env_ptr.as(JNIEnv*)
    env.CallObjectMethod(obj, method_id)
  end
  
  def self.call_boolean_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Bool
    env_ptr = @@env
    return false if env_ptr.null?
    env = env_ptr.as(JNIEnv*)
    env.CallBooleanMethod(obj, method_id)
  end
  
  def self.call_int_method(obj : Void*, method_id : Void*, args : Array(Void*)? = nil) : Int32
    env_ptr = @@env
    return 0 if env_ptr.null?
    env = env_ptr.as(JNIEnv*)
    env.CallIntMethod(obj, method_id)
  end
end

@[Link("jnigraphics")]
lib JNIEnv
  fun FindClass(env : Void*, name : UInt8*) : Void*
  fun GetMethodID(clazz : Void*, name : UInt8*, sig : UInt8*) : Void*
  fun NewObject(clazz : Void*, methodID : Void*, ...) : Void*
  fun NewStringUTF(env : Void*, bytes : UInt8*) : Void*
  fun CallVoidMethod(obj : Void*, methodID : Void*, ...) : Void*
  fun CallObjectMethod(obj : Void*, methodID : Void*, ...) : Void*
  fun CallBooleanMethod(obj : Void*, methodID : Void*, ...) : Bool
  fun CallIntMethod(obj : Void*, methodID : Void*, ...) : Int32
  fun GetObjectClass(obj : Void*) : Void*
  fun GetStringUTFChars(str : Void*, isCopy : Int32*) : UInt8*
  fun ReleaseStringUTFChars(str : Void*, chars : UInt8*)
end

module Native::UI
  class TextView
    def initialize
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return unless env && activity
      
      class_name = "android/widget/TextView"
      text_view_class = Native::Android::JNI.find_class(class_name)
      return unless text_view_class
      
      constructor = Native::Android::JNI.get_method_id(text_view_class, "<init>", "(Landroid/content/Context;)V")
      return unless constructor
      
      @native = Native::Android::JNI.new_object(text_view_class, constructor)
    end
    
    def set_text(text : String)
      return unless @native
      env = Native::Android::JNI.env
      return unless env
      
      jni_text = Native::Android::JNI.new_string_utf(text)
      return unless jni_text
      
      text_view_class = Native::Android::JNI.get_object_class(@native)
      set_text_method = Native::Android::JNI.get_method_id(text_view_class, "setText", "(Ljava/lang/CharSequence;)V")
      return unless set_text_method
      
      Native::Android::JNI.call_void_method(@native, set_text_method)
    end
    
    def native_ptr : Void*
      @native
    end
  end
end
