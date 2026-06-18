# src/native/framework/ui/linear_layout.cr

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
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        layout_class = env.find_class("android/widget/LinearLayout")
        constructor = env.get_method_id(layout_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(layout_class, constructor, activity).to_i64

        set_orientation
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_stack_view
        @native = ptr.to_i64
      {% end %}
    end

    def orientation=(value : Orientation)
      @orientation = value
      {% if flag?(:native_android) %}
        set_orientation
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
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_gravity = env.get_method_id(env.get_object_class(@native), "setGravity", "(I)V")
        env.call_void_method(@native, set_gravity, value.value)
      {% end %}
    end

    def gravity : Gravity
      @gravity
    end

    def weight_sum=(value : Float32)
      @weight_sum = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_weight_sum = env.get_method_id(env.get_object_class(@native), "setWeightSum", "(F)V")
        env.call_void_method(@native, set_weight_sum, value)
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
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_padding = env.get_method_id(env.get_object_class(@native), "setPadding", "(IIII)V")
        env.call_void_method(@native, set_padding, left, top, right, bottom)
      {% elsif flag?(:native_ios) %}
        LibIOS.stack_view_set_padding(@native, left, top, right, bottom)
      {% end %}
    end

    def addView(view : View, weight : Float32 = 0.0)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0

        add_view = env.get_method_id(env.get_object_class(@native), "addView", "(Landroid/view/View;)V")
        env.call_void_method(@native, add_view, view.native_ptr)

        if weight > 0
          layout_params = env.call_object_method(view.native_ptr, env.get_method_id(env.get_object_class(view.native_ptr), "getLayoutParams", "()Landroid/view/ViewGroup$LayoutParams;"))
          if layout_params
            linear_params_class = env.find_class("android/widget/LinearLayout$LayoutParams")
            if env.is_instance_of(layout_params, linear_params_class)
              set_weight = env.get_method_id(linear_params_class, "setWeight", "(F)V")
              env.call_void_method(layout_params, set_weight, weight)
              set_layout = env.get_method_id(env.get_object_class(view.native_ptr), "setLayoutParams", "(Landroid/view/ViewGroup$LayoutParams;)V")
              env.call_void_method(view.native_ptr, set_layout, layout_params)
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
        env = Native::Android::JNI.env
        return unless env && @native != 0 && view.native_ptr != 0
        remove_view = env.get_method_id(env.get_object_class(@native), "removeView", "(Landroid/view/View;)V")
        env.call_void_method(@native, remove_view, view.native_ptr)
      {% elsif flag?(:native_ios) %}
        LibIOS.stack_view_remove_view(@native, view.native_ptr)
      {% end %}
    end

    def removeAllViews
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        remove_all = env.get_method_id(env.get_object_class(@native), "removeAllViews", "()V")
        env.call_void_method(@native, remove_all)
      {% elsif flag?(:native_ios) %}
        LibIOS.stack_view_remove_all_views(@native)
      {% end %}
    end

    def getChildAt(index : Int32) : View?
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return nil unless env && @native != 0
        get_child = env.get_method_id(env.get_object_class(@native), "getChildAt", "(I)Landroid/view/View;")
        child_ptr = env.call_object_method(@native, get_child, index)
        if child_ptr != Pointer(Void).null
          view = View.new
          view.native = child_ptr.to_i64
          view
        else
          nil
        end
      {% else %}
        nil
      {% end %}
    end

    def childCount : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return 0 unless env && @native != 0
        get_count = env.get_method_id(env.get_object_class(@native), "getChildCount", "()I")
        env.call_int_method(@native, get_count)
      {% else %}
        0
      {% end %}
    end

    private def set_orientation
      env = Native::Android::JNI.env
      return unless env && @native != 0
      set_orientation = env.get_method_id(env.get_object_class(@native), "setOrientation", "(I)V")
      env.call_void_method(@native, set_orientation, @orientation == Orientation::Vertical ? 1 : 0)
    end
  end
end
