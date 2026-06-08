@[Link("android")]
@[Link("log")]
lib LibAndroid
  fun __android_log_print(prio : Int32, tag : UInt8*, fmt : UInt8*, ...) : Int32
end

@[Link("native_cr_engine")]
lib LibEngine
  fun get_activity : Void*
  fun get_jni_env : Void*
  fun get_activity_class : Void*
end

@[Export("crystal_android_main")]
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
  
  def self.call_void_method(obj : Void*, method_name : String, signature : String)
    jni = @@env.as(JNIEnv*)
    jni.call_void_method(obj, method_name, signature)
  end
end

# Simplified JNI bindings (full version next)
@[Link("native_cr_engine")]
lib JNI
  type JNIEnv
  type jobject
  type jclass
  type jmethodID
  
  fun get_activity : jobject
  fun get_jni_env : JNIEnv*
  fun get_activity_class : jclass
end

module Native::UI
  class TextView
    def initialize
      env = JNI.get_jni_env
      activity = JNI.get_activity
      
      # Find TextView class
      class_name = "android/widget/TextView"
      text_view_class = env.FindClass(class_name)
      
      # Get constructor
      constructor = env.GetMethodID(text_view_class, "<init>", "(Landroid/content/Context;)V")
      
      # Create instance
      @native = env.NewObject(text_view_class, constructor, activity)
    end
    
    def set_text(text : String)
      env = JNI.get_jni_env
      jni_text = env.NewStringUTF(text)
      set_text_method = env.GetMethodID(env.GetObjectClass(@native), "setText", "(Ljava/lang/CharSequence;)V")
      env.CallVoidMethod(@native, set_text_method, jni_text)
    end
  end
end
