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
