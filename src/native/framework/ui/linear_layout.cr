# src/native/framework/ui/linear_layout.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::UI
  class LinearLayout < View
    enum Orientation
      Vertical
      Horizontal
    end

    enum Gravity
      Top              =  48
      Bottom           =  80
      Left             =   3
      Right            =   5
      Center           =  17
      CenterHorizontal =   1
      CenterVertical   =  16
      Fill             = 119
      FillHorizontal   =   7
      FillVertical     = 112
    end

    @orientation : Orientation = Orientation::Vertical
    @gravity : Gravity = Gravity::Top
    @weight_sum : Float32 = 0.0
    @padding_left : Int32 = 0
    @padding_top : Int32 = 0
    @padding_right : Int32 = 0
    @padding_bottom : Int32 = 0

    def initialize(orientation : Orientation = Orientation::Vertical)
      super()
      @orientation = orientation

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity

          @native = JNIHelpers.new_widget(env, "android/widget/LinearLayout", activity)

          set_orientation(env)
        end
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_stack_view
        @native = ptr.to_i64
      {% end %}
    end

    def orientation=(value : Orientation)
      @orientation = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          set_orientation(env)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.stack_view_set_axis(@native, value == Orientation::Vertical ? 0 : 1)
      {% end %}
    end

    def orientation : Orientation
      @orientation
    end

    def gravity=(value : Gravity)
      @gravity = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void(env, @native, "setGravity", "(I)V", value.value)
        end
      {% end %}
    end

    def gravity : Gravity
      @gravity
    end

    def weight_sum=(value : Float32)
      @weight_sum = value
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void(env, @native, "setWeightSum", "(F)V", value)
        end
      {% end %}
    end

    def weight_sum : Float32
      @weight_sum
    end

    def set_padding(left : Int32, top : Int32, right : Int32, bottom : Int32)
      @padding_left = left
      @padding_top = top
      @padding_right = right
      @padding_bottom = bottom

      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void(env, @native, "setPadding", "(IIII)V", left, top, right, bottom)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.stack_view_set_padding(@native, left, top, right, bottom)
      {% end %}
    end

    def addView(view : View, weight : Float32 = 0.0)
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0 || view.native_ptr == 0

          JNIHelpers.call_void(env, @native, "addView", "(Landroid/view/View;)V", view.native_ptr)

          if weight > 0
            params = JNIHelpers.call_object(
              env, view.native_ptr, "getLayoutParams",
              "()Landroid/view/ViewGroup$LayoutParams;"
            )
            if !params.null?
              JNIHelpers.with_class(env, "android/widget/LinearLayout$LayoutParams") do |params_class|
                unless params_class.null?
                  if env.is_instance_of(params, params_class)
                    # LinearLayout.LayoutParams exposes `weight` as a public
                    # float field. The old code looked up a nonexistent
                    # setWeight method and handed a NULL method id to JNI,
                    # which aborts the process — a crash on every weighted
                    # addView. Set the field instead.
                    fid = env.get_field_id(params_class, "weight", "F")
                    unless fid.null?
                      env.set_float_field(params, fid, weight)
                    end
                    JNIHelpers.call_void(
                      env, view.native_ptr, "setLayoutParams",
                      "(Landroid/view/ViewGroup$LayoutParams;)V", params
                    )
                  end
                end
              end
              # The ref returned by getLayoutParams belongs to us.
              env.delete_local_ref(params)
            end
          end
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.stack_view_add_view(@native, view.native_ptr)
      {% end %}
    end

    def addView(view : View, width : Int32, height : Int32, weight : Float32 = 0.0)
      view.width = width
      view.height = height
      addView(view, weight)
    end

    def removeView(view : View)
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0 || view.native_ptr == 0
          JNIHelpers.call_void(env, @native, "removeView", "(Landroid/view/View;)V", view.native_ptr)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.stack_view_remove_view(@native, view.native_ptr)
      {% end %}
    end

    def removeAllViews
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0
          JNIHelpers.call_void(env, @native, "removeAllViews", "()V")
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.stack_view_remove_all_views(@native)
      {% end %}
    end

    def getChildAt(index : Int32) : View?
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return nil if @native == 0
          child_ptr = JNIHelpers.call_object(env, @native, "getChildAt", "(I)Landroid/view/View;", index)
          if !child_ptr.null?
            view = View.new
            view.native = child_ptr.to_i64
            view
          else
            nil
          end
        end
      {% else %}
        nil
      {% end %}
    end

    def childCount : Int32
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return 0 if @native == 0
          JNIHelpers.call_int(env, @native, "getChildCount", "()I")
        end
      {% else %}
        0
      {% end %}
    end

    private def set_orientation(env : Native::Android::JNIEnvWrapper)
      {% unless flag?(:native_android) %}
        return
      {% end %}
      return if @native == 0
      JNIHelpers.call_void(env, @native, "setOrientation", "(I)V", @orientation == Orientation::Vertical ? 1 : 0)
    end
  end
end
