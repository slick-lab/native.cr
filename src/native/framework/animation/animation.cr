# src/native/framework/animation/animator.cr

module Native::Animation
  enum Interpolator
    Linear
    Accelerate
    Decelerate
    AccelerateDecelerate
    Bounce
    Overshoot
    Anticipate
    AnticipateOvershoot
  end

  class ValueAnimator
    @duration : Int32 = 300
    @start_value : Float64 = 0.0
    @end_value : Float64 = 1.0
    @interpolator : Interpolator = Interpolator::Linear
    @repeat_count : Int32 = 0
    @repeat_mode : Int32 = 1
    @on_update : (Float64 -> Nil)?
    @on_start : (-> Nil)?
    @on_end : (-> Nil)?
    @on_repeat : (-> Nil)?
    @animator_ptr : Int64 = 0

    def initialize(start_value : Float64 = 0.0, end_value : Float64 = 1.0)
      @start_value = start_value
      @end_value = end_value

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        animator_class = env.FindClass("android/animation/ValueAnimator")
        of_float = env.GetStaticMethodID(animator_class, "ofFloat", "(FF)Landroid/animation/ValueAnimator;")
        @animator_ptr = env.CallStaticObjectMethod(animator_class, of_float, start_value.to_f32, end_value.to_f32).to_i64

        setupListeners
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_animator
        @animator_ptr = ptr.to_i64
      {% end %}
    end

    def duration=(value : Int32)
      @duration = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0
        set_duration = env.GetMethodID(env.GetObjectClass(@animator_ptr), "setDuration", "(J)Landroid/animation/ValueAnimator;")
        env.CallObjectMethod(@animator_ptr, set_duration, value.to_i64)
      {% elsif flag?(:native_ios) %}
        LibIOS.animator_set_duration(@animator_ptr, value)
      {% end %}
    end

    def duration : Int32
      @duration
    end

    def interpolator=(value : Interpolator)
      @interpolator = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0

        interpolator_class = case value
                             when Interpolator::Linear
                               env.FindClass("android/view/animation/LinearInterpolator")
                             when Interpolator::Accelerate
                               env.FindClass("android/view/animation/AccelerateInterpolator")
                             when Interpolator::Decelerate
                               env.FindClass("android/view/animation/DecelerateInterpolator")
                             when Interpolator::AccelerateDecelerate
                               env.FindClass("android/view/animation/AccelerateDecelerateInterpolator")
                             when Interpolator::Bounce
                               env.FindClass("android/view/animation/BounceInterpolator")
                             when Interpolator::Overshoot
                               env.FindClass("android/view/animation/OvershootInterpolator")
                             when Interpolator::Anticipate
                               env.FindClass("android/view/animation/AnticipateInterpolator")
                             when Interpolator::AnticipateOvershoot
                               env.FindClass("android/view/animation/AnticipateOvershootInterpolator")
                             end

        interpolator_obj = env.NewObject(interpolator_class, env.GetMethodID(interpolator_class, "<init>", "()V"))
        set_interpolator = env.GetMethodID(env.GetObjectClass(@animator_ptr), "setInterpolator", "(Landroid/animation/TimeInterpolator;)V")
        env.CallVoidMethod(@animator_ptr, set_interpolator, interpolator_obj)
      {% end %}
    end

    def interpolator : Interpolator
      @interpolator
    end

    def repeat_count=(value : Int32)
      @repeat_count = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0
        set_repeat = env.GetMethodID(env.GetObjectClass(@animator_ptr), "setRepeatCount", "(I)V")
        env.CallVoidMethod(@animator_ptr, set_repeat, value)
      {% elsif flag?(:native_ios) %}
        LibIOS.animator_set_repeat_count(@animator_ptr, value)
      {% end %}
    end

    def repeat_count : Int32
      @repeat_count
    end

    def repeat_mode=(value : Int32)
      @repeat_mode = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0
        set_mode = env.GetMethodID(env.GetObjectClass(@animator_ptr), "setRepeatMode", "(I)V")
        env.CallVoidMethod(@animator_ptr, set_mode, value)
      {% end %}
    end

    def repeat_mode : Int32
      @repeat_mode
    end

    def start
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0
        start_method = env.GetMethodID(env.GetObjectClass(@animator_ptr), "start", "()V")
        env.CallVoidMethod(@animator_ptr, start_method)
      {% elsif flag?(:native_ios) %}
        LibIOS.animator_start(@animator_ptr)
      {% end %}
    end

    def cancel
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0
        cancel_method = env.GetMethodID(env.GetObjectClass(@animator_ptr), "cancel", "()V")
        env.CallVoidMethod(@animator_ptr, cancel_method)
      {% elsif flag?(:native_ios) %}
        LibIOS.animator_cancel(@animator_ptr)
      {% end %}
    end

    def end
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0
        end_method = env.GetMethodID(env.GetObjectClass(@animator_ptr), "end", "()V")
        env.CallVoidMethod(@animator_ptr, end_method)
      {% end %}
    end

    def is_running? : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env && @animator_ptr != 0
        is_running = env.GetMethodID(env.GetObjectClass(@animator_ptr), "isRunning", "()Z")
        env.CallBooleanMethod(@animator_ptr, is_running)
      {% else %}
        false
      {% end %}
    end

    def on_update(&block : Float64 -> Nil)
      @on_update = block
    end

    def on_start(&block : -> Nil)
      @on_start = block
    end

    def on_end(&block : -> Nil)
      @on_end = block
    end

    def on_repeat(&block : -> Nil)
      @on_repeat = block
    end

    private def setupListeners
      {% unless flag?(:native_android) %}
      return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @animator_ptr != 0

      callback_class = env.FindClass("com/nativecr/AnimatorCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      add_listener = env.GetMethodID(env.GetObjectClass(@animator_ptr), "addUpdateListener", "(Landroid/animation/ValueAnimator$AnimatorUpdateListener;)V")
      env.CallVoidMethod(@animator_ptr, add_listener, callback_obj)

      add_listener = env.GetMethodID(env.GetObjectClass(@animator_ptr), "addListener", "(Landroid/animation/Animator$AnimatorListener;)V")
      env.CallVoidMethod(@animator_ptr, add_listener, callback_obj)
    end

    def handleUpdate(value : Float32)
      @on_update.try &.call(value.to_f64)
    end

    def handleStart
      @on_start.try &.call
    end

    def handleEnd
      @on_end.try &.call
    end

    def handleRepeat
      @on_repeat.try &.call
    end
  end

  class ObjectAnimator < ValueAnimator
    @target : UI::View?
    @property_name : String = ""

    def initialize(target : UI::View, property_name : String, start_value : Float64, end_value : Float64)
      @target = target
      @property_name = property_name
      super(start_value, end_value)

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && target.native_ptr != 0

        animator_class = env.FindClass("android/animation/ObjectAnimator")
        of_float = env.GetStaticMethodID(animator_class, "ofFloat", "(Ljava/lang/Object;Ljava/lang/String;FF)Landroid/animation/ObjectAnimator;")
        @animator_ptr = env.CallStaticObjectMethod(animator_class, of_float, target.native_ptr, env.NewStringUTF(property_name), start_value.to_f32, end_value.to_f32).to_i64

        setupListeners
      {% end %}
    end
  end

  class AnimatorSet
    @animator_ptr : Int64 = 0
    @animators : Array(ValueAnimator) = [] of ValueAnimator

    def initialize
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        set_class = env.FindClass("android/animation/AnimatorSet")
        @animator_ptr = env.NewObject(set_class, env.GetMethodID(set_class, "<init>", "()V")).to_i64
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_animator_set
        @animator_ptr = ptr.to_i64
      {% end %}
    end

    def play_together(animator : ValueAnimator)
      @animators << animator
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0 && animator.animator_ptr != 0
        play = env.GetMethodID(env.GetObjectClass(@animator_ptr), "play", "(Landroid/animation/Animator;)Landroid/animation/AnimatorSet$Builder;")
        env.CallObjectMethod(@animator_ptr, play, animator.animator_ptr)
      {% end %}
    end

    def play_sequentially(animators : Array(ValueAnimator))
      @animators = animators
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0

        animator_array = env.NewObjectArray(animators.size, env.FindClass("android/animation/Animator"), nil)
        animators.each_with_index do |anim, i|
          env.SetObjectArrayElement(animator_array, i, anim.animator_ptr)
        end

        play_seq = env.GetMethodID(env.GetObjectClass(@animator_ptr), "playSequentially", "([Landroid/animation/Animator;)V")
        env.CallVoidMethod(@animator_ptr, play_seq, animator_array)
      {% elsif flag?(:native_ios) %}
        LibIOS.animator_set_play_sequentially(@animator_ptr)
      {% end %}
    end

    def start
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0
        start_method = env.GetMethodID(env.GetObjectClass(@animator_ptr), "start", "()V")
        env.CallVoidMethod(@animator_ptr, start_method)
      {% elsif flag?(:native_ios) %}
        LibIOS.animator_set_start(@animator_ptr)
      {% end %}
    end

    def cancel
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @animator_ptr != 0
        cancel_method = env.GetMethodID(env.GetObjectClass(@animator_ptr), "cancel", "()V")
        env.CallVoidMethod(@animator_ptr, cancel_method)
      {% end %}
    end

    def duration=(value : Int32)
      @animators.each do |anim|
        anim.duration = value
      end
    end
  end
end
