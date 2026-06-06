# src/native/# src/native/engine/android/android_entry.cr

fun crystal_android_main(state : Void*) : Void
  GC.init
  app = NativeApp.current
  app.renderer = state
  app.run
end
