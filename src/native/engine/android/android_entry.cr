# src/native/android_entry.cr

@[Export("crystal_android_main")]
fun crystal_android_main(state : Void*) : Void
  GC.init
  app = NativeApp.current
  app.renderer = state
  app.run
end
