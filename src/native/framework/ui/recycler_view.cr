# src/native/framework/ui/recycler_view.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::UI
  abstract class RecyclerViewAdapter
    abstract def item_count : Int32
    abstract def create_view(env : Void*, position : Int32) : Int64
    abstract def bind_view(env : Void*, view : Int64, position : Int32) : Void

    def get_item_id(position : Int32) : Int64
      position.to_i64
    end

    def on_item_click(position : Int32)
    end

    def on_item_long_click(position : Int32)
    end
  end

  class RecyclerView < View
    @adapter : RecyclerViewAdapter?
    @layout_manager : Int32 = 1
    @on_item_click : (Int32 -> Nil)?
    @on_item_long_click : (Int32 -> Nil)?

    enum LayoutManager
      Linear
      Grid
      StaggeredGrid
    end

    def initialize
      super()

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        rv_class = env.find_class("androidx/recyclerview/widget/RecyclerView")
        constructor = env.get_method_id(rv_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(rv_class, constructor, activity).to_i64
        env.delete_local_ref(rv_class) unless rv_class.null?

        set_layout_manager(LayoutManager::Linear)
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_table_view
        @native = ptr.to_i64
      {% end %}
    end

    def adapter=(adapter : RecyclerViewAdapter)
      @adapter = adapter

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        rv_adapter_class = env.find_class("com/nativecr/RecyclerViewAdapter")
        if rv_adapter_class == Pointer(Void).null
          return
        end

        adapter_obj = env.new_object(rv_adapter_class, env.get_method_id(rv_adapter_class, "<init>", "(J)V"), 0i64)
        env.delete_local_ref(rv_adapter_class) unless rv_adapter_class.null?

        JNIHelpers.call_void(env, @native, "setAdapter", "(Landroidx/recyclerview/widget/RecyclerView$Adapter;)V", adapter_obj)
      {% elsif flag?(:native_ios) %}
        LibIOS.table_view_set_delegate(@native, 0i64)
      {% end %}
    end

    def adapter : RecyclerViewAdapter?
      @adapter
    end

    def layout_manager=(manager : LayoutManager)
      @layout_manager = manager.value
      set_layout_manager(manager)
    end

    def layout_manager : LayoutManager
      LayoutManager.from_value(@layout_manager)
    end

    def set_layout_manager(manager : LayoutManager)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        lm_class = case manager
                   when LayoutManager::Linear
                     env.find_class("androidx/recyclerview/widget/LinearLayoutManager")
                   when LayoutManager::Grid
                     env.find_class("androidx/recyclerview/widget/GridLayoutManager")
                   when LayoutManager::StaggeredGrid
                     env.find_class("androidx/recyclerview/widget/StaggeredGridLayoutManager")
                   end

        if manager == LayoutManager::Linear
          constructor = env.get_method_id(lm_class, "<init>", "(Landroid/content/Context;IZ)V")
          lm = env.new_object(lm_class, constructor, activity, 1, false)
        elsif manager == LayoutManager::Grid
          constructor = env.get_method_id(lm_class, "<init>", "(Landroid/content/Context;I)V")
          lm = env.new_object(lm_class, constructor, activity, 2)
        else
          constructor = env.get_method_id(lm_class, "<init>", "(II)V")
          lm = env.new_object(lm_class, constructor, 2, 1)
        end

        JNIHelpers.call_void(env, @native, "setLayoutManager", "(Landroidx/recyclerview/widget/RecyclerView$LayoutManager;)V", lm)
      {% elsif flag?(:native_ios) %}
        LibIOS.table_view_set_style(@native, manager.value)
      {% end %}
    end

    def on_item_click(&block : Int32 -> Nil)
      @on_item_click = block
    end

    def on_item_long_click(&block : Int32 -> Nil)
      @on_item_long_click = block
    end

    def scroll_to_position(position : Int32, smooth : Bool = false)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        if smooth
          JNIHelpers.call_void(env, @native, "smoothScrollToPosition", "(I)V", position)
        else
          JNIHelpers.call_void(env, @native, "scrollToPosition", "(I)V", position)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.table_view_scroll_to_row(@native, position, smooth)
      {% end %}
    end

    def scroll_to_top(smooth : Bool = false)
      scroll_to_position(0, smooth)
    end

    def notify_data_changed
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        get_adapter = env.get_method_id(env.get_object_class(@native), "getAdapter", "()Landroidx/recyclerview/widget/RecyclerView$Adapter;")
        adapter_obj = env.call_object_method(@native, get_adapter)

        if adapter_obj
          JNIHelpers.call_void(env, adapter_obj, "notifyDataSetChanged", "()V")
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.table_view_reload_data(@native)
      {% end %}
    end

    def notify_item_inserted(position : Int32)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        get_adapter = env.get_method_id(env.get_object_class(@native), "getAdapter", "()Landroidx/recyclerview/widget/RecyclerView$Adapter;")
        adapter_obj = env.call_object_method(@native, get_adapter)

        if adapter_obj
          JNIHelpers.call_void(env, adapter_obj, "notifyItemInserted", "(I)V", position)
        end
      {% end %}
    end

    def notify_item_removed(position : Int32)
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        get_adapter = env.get_method_id(env.get_object_class(@native), "getAdapter", "()Landroidx/recyclerview/widget/RecyclerView$Adapter;")
        adapter_obj = env.call_object_method(@native, get_adapter)

        if adapter_obj
          JNIHelpers.call_void(env, adapter_obj, "notifyItemRemoved", "(I)V", position)
        end
      {% end %}
    end

    def handleItemClick(position : Int32)
      @adapter.try(&.on_item_click(position))
      @on_item_click.try &.call(position)
    end

    def handleItemLongClick(position : Int32)
      @adapter.try(&.on_item_long_click(position))
      @on_item_long_click.try &.call(position)
    end

    def getItemCount : Int32
      @adapter.try(&.item_count) || 0
    end

    def createViewHolder(position : Int32, env : Void*) : Int64
      @adapter.try(&.create_view(env, position)) || 0
    end

    def bindViewHolder(view : Int64, position : Int32, env : Void*)
      @adapter.try(&.bind_view(env, view, position))
    end
  end

  class SimpleAdapter < RecyclerViewAdapter
    @items : Array(String)
    @on_bind : (TextView, String, Int32 -> Nil)?

    def initialize(items : Array(String))
      @items = items
    end

    def item_count : Int32
      @items.size
    end

    def create_view(env : Void*, position : Int32) : Int64
      text_view = TextView.new
      text_view.native_ptr
    end

    def bind_view(env : Void*, view : Int64, position : Int32) : Void
      text_view = TextView.new
      text_view.native = view
      text_view.text = @items[position]
      @on_bind.try &.call(text_view, @items[position], position)
    end

    def on_bind(&block : TextView, String, Int32 -> Nil)
      @on_bind = block
    end
  end
end
