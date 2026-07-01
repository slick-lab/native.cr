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

# Android entry point — called from native.c's crystal_thread pthread.
#
# On Android the user's main.cr is not executed as a normal program
# entry point; instead the framework calls this function directly.
# Therefore we cannot assume Native::App.current has been set.
# Use App.start_registered which starts the subclass the user
# registered via Native::App.registered_subclass = MyApp.
fun crystal_android_main(env : Void*, activity : Void*, activity_class : Void*) : Void
  GC.init

  Native::Android::JNI.set_env(env)
  Native::Android::JNI.set_activity(activity)
  Native::Android::JNI.set_activity_class(activity_class)

  begin
    # Start the registered app subclass. On Android the user should
    # set Native::App.registered_subclass = MyApp in their main.cr
    # instead of calling Native::App.start directly.
    Native::App.start_registered
  rescue ex
    # Log the error to Android logcat so it's visible in crash logs.
    # Avoid calling Crystal's stdlib logging which may trigger
    # Thread::current and crash again on Android's bionic libc.
    msg = "native.cr fatal: #{ex.class.name}: #{ex.message}"
    LibAndroid.__android_log_print(6, "native.cr", msg) # ANDROID_LOG_ERROR = 6
  end
end
