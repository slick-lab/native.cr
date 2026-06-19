# src/native/framework/ui/spinner.cr

module Native::UI
  class Spinner < View
    @items : Array(String) = [] of String
    @selected_position : Int32 = 0
    @on_item_selected : (Int32, String -> Nil)?
    @dropdown_width : Int32 = 0
    @prompt : String = ""

    def initialize
      super()

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        spinner_class = env.find_class("android/widget/Spinner")
        constructor = env.get_method_id(spinner_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(spinner_class, constructor, activity).to_i64

        setupSpinnerListener
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_picker_view
        @native = ptr.to_i64
      {% end %}
    end

    def items=(items : Array(String))
      @items = items
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        array_class = env.find_class("java/util/ArrayList")
        array_constructor = env.get_method_id(array_class, "<init>", "()V")
        array_list = env.new_object(array_class, array_constructor)

        add_method = env.get_method_id(array_class, "add", "(Ljava/lang/Object;)Z")

        items.each do |item|
          env.call_boolean_method(array_list, add_method, env.new_string_utf(item))
        end

        adapter_class = env.find_class("android/widget/ArrayAdapter")
        adapter_constructor = env.get_method_id(adapter_class, "<init>", "(Landroid/content/Context;ILjava/util/List;)V")

        layout = env.get_static_field_id(env.find_class("android/R$layout"), "simple_spinner_item", "I")
        layout_id = env.get_static_int_field(env.find_class("android/R$layout"), layout)

        adapter = env.new_object(adapter_class, adapter_constructor, Native::Android::JNI.activity, layout_id, array_list)

        set_adapter = env.get_method_id(env.get_object_class(@native), "setAdapter", "(Landroid/widget/SpinnerAdapter;)V")
        env.call_void_method(@native, set_adapter, adapter)
      {% elsif flag?(:native_ios) %}
        LibIOS.picker_view_set_items(@native, items.to_utf8)
      {% end %}
    end

    def items : Array(String)
      @items
    end

    def selected_position=(position : Int32)
      @selected_position = position.clamp(0, @items.size - 1)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_selection = env.get_method_id(env.get_object_class(@native), "setSelection", "(I)V")
        env.call_void_method(@native, set_selection, @selected_position)
      {% elsif flag?(:native_ios) %}
        LibIOS.picker_view_set_selected(@native, @selected_position)
      {% end %}
    end

    def selected_position : Int32
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return @selected_position unless env && @native != 0
        get_selection = env.get_method_id(env.get_object_class(@native), "getSelectedItemPosition", "()I")
        @selected_position = env.call_int_method(@native, get_selection)
      {% elsif flag?(:native_ios) %}
        @selected_position = LibIOS.picker_view_get_selected(@native)
      {% end %}
      @selected_position
    end

    def selected_item : String?
      return nil if @selected_position < 0 || @selected_position >= @items.size
      @items[@selected_position]
    end

    def prompt=(value : String)
      @prompt = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_prompt = env.get_method_id(env.get_object_class(@native), "setPrompt", "(Ljava/lang/CharSequence;)V")
        env.call_void_method(@native, set_prompt, env.new_string_utf(value))
      {% end %}
    end

    def prompt : String
      @prompt
    end

    def dropdown_width=(width : Int32)
      @dropdown_width = width
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_width = env.get_method_id(env.get_object_class(@native), "setDropDownWidth", "(I)V")
        env.call_void_method(@native, set_width, width)
      {% end %}
    end

    def dropdown_width : Int32
      @dropdown_width
    end

    def on_item_selected(&block : Int32, String -> Nil)
      @on_item_selected = block
    end

    private def setupSpinnerListener
      {% unless flag?(:native_android) %}
        return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_class = env.find_class("com/nativecr/SpinnerCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(J)V"), 0i64)

      set_listener = env.get_method_id(env.get_object_class(@native), "setOnItemSelectedListener", "(Landroid/widget/AdapterView$OnItemSelectedListener;)V")
      env.call_void_method(@native, set_listener, callback_obj)
    end

    def handleItemSelected(position : Int32)
      @selected_position = position
      item = @items[position] if position >= 0 && position < @items.size
      @on_item_selected.try &.call(position, item || "")
    end
  end
end
