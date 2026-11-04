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

    # In-memory child tracking: keeps the tree introspectable on every
    # platform (desktop included) and drives spacing/first-child logic on
    # Android without an extra JNI round-trip.
    @children = [] of View

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
        @native = ptr.address.to_i64
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
      @children << view
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return if @native == 0 || view.native_ptr == 0

          JNIHelpers.call_void(env, @native, "addView", "(Landroid/view/View;)V", view.native_ptr)

          if weight > 0 || @spacing > 0
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
                    if weight > 0
                      fid = env.get_field_id(params_class, "weight", "F")
                      unless fid.null?
                        env.set_float_field(params, fid, weight)
                      end
                    end
                    apply_spacing_margins(env, view, params_class, params)
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
        LibIOS.stack_view_set_spacing(@native, @spacing.to_f32) if @spacing > 0
      {% end %}
    end

    # ── spacing / alignment DSL ──────────────────────────────────────────────
    # `spacing = 20` inserts a 20dp gap between children; `alignment =`
    # maps the Alignment constants onto gravity. Pure state here, applied
    # per child at addView/add_child time (margins on Android, uniform
    # spacing on iOS) — desktop keeps the value for tree introspection.

    @spacing : Int32 = 0

    def spacing : Int32
      @spacing
    end

    def spacing=(value : Int32)
      @spacing = value
      {% if flag?(:native_ios) %}
        LibIOS.stack_view_set_spacing(@native, value.to_f32) if @native != 0
      {% end %}
    end

    def alignment=(value : LinearLayout::Gravity)
      self.gravity = value
    end

    def alignment : LinearLayout::Gravity
      gravity
    end

    # snake_case aliases — the old camelCase names stay as deprecated
    # aliases; new code and all docs use add_child / add_view.
    def add_child(view : View, weight : Float32 = 0.0)
      addView(view, weight)
    end

    def add_view(view : View, weight : Float32 = 0.0)
      addView(view, weight)
    end

    def add_view(view : View, width : Int32, height : Int32, weight : Float32 = 0.0)
      addView(view, width, height, weight)
    end

    def remove_child(view : View)
      removeView(view)
    end

    def remove_view(view : View)
      removeView(view)
    end

    # Applies @spacing as child margins (Android): vertical layouts add a
    # top margin (except for the very first child), horizontal layouts a
    # left margin. Matches what a user expects `spacing` to do visually.
    private def apply_spacing_margins(env, view, params_class, params)
      return unless @spacing > 0 && childCount > 0
      mid = env.get_method_id(params_class, "setMargins", "(IIII)V")
      return if mid.null?
      vertical = orientation == Orientation::Vertical
      first = childCount == 0
      # childCount has already been bumped by addView at this point, so
      # "first child" is childCount == 1.
      left = vertical ? 0 : (childCount <= 1 ? 0 : @spacing)
      top = vertical ? (childCount <= 1 ? 0 : @spacing) : 0
      env.call_void_method(params, mid, left.to_i32, top.to_i32, 0, 0)
    end

    def addView(view : View, width : Int32, height : Int32, weight : Float32 = 0.0)
      view.width = width
      view.height = height
      addView(view, weight)
    end

    def removeView(view : View)
      @children.reject! { |child| child.same?(view) }
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
      @children.clear
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
            view.native = child_ptr.address.to_i64
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
      {% unless flag?(:native_android) %}
        return @children.size
      {% else %}
        # with_env's block result flows through a nilable wrapper — the
        # || 0 keeps the declared Int32 return honest when env is nil.
        count = JNIHelpers.with_env do |env|
          return 0 if @native == 0
          JNIHelpers.call_int(env, @native, "getChildCount", "()I")
        end
        count || 0
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
