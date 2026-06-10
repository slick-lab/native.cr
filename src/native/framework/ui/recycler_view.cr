# src/native/framework/ui/recycler_view.cr

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

      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        rv_class = env.FindClass("androidx/recyclerview/widget/RecyclerView")
        constructor = env.GetMethodID(rv_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(rv_class, constructor, activity).to_i64

        set_layout_manager(LayoutManager::Linear)
      elsif Native::Platform.ios?
        ptr = LibIOS.create_table_view
        @native = ptr.to_i64
      end
    end

    def adapter=(adapter : RecyclerViewAdapter)
      @adapter = adapter

      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0

        rv_adapter_class = env.FindClass("com/nativecr/RecyclerViewAdapter")
        if rv_adapter_class == Pointer(Void).null
          return
        end

        adapter_obj = env.NewObject(rv_adapter_class, env.GetMethodID(rv_adapter_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

        set_adapter = env.GetMethodID(env.GetObjectClass(@native), "setAdapter", "(Landroidx/recyclerview/widget/RecyclerView$Adapter;)V")
        env.CallVoidMethod(@native, set_adapter, adapter_obj)
      elsif Native::Platform.ios?
        LibIOS.table_view_set_delegate(@native, Pointer(Void).address.to_i64)
      end
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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0

        lm_class = case manager
                   when LayoutManager::Linear
                     env.FindClass("androidx/recyclerview/widget/LinearLayoutManager")
                   when LayoutManager::Grid
                     env.FindClass("androidx/recyclerview/widget/GridLayoutManager")
                   when LayoutManager::StaggeredGrid
                     env.FindClass("androidx/recyclerview/widget/StaggeredGridLayoutManager")
                   end

        if manager == LayoutManager::Linear
          constructor = env.GetMethodID(lm_class, "<init>", "(Landroid/content/Context;IZ)V")
          lm = env.NewObject(lm_class, constructor, activity, 1, false)
        elsif manager == LayoutManager::Grid
          constructor = env.GetMethodID(lm_class, "<init>", "(Landroid/content/Context;I)V")
          lm = env.NewObject(lm_class, constructor, activity, 2)
        else
          constructor = env.GetMethodID(lm_class, "<init>", "(II)V")
          lm = env.NewObject(lm_class, constructor, 2, 1)
        end

        set_lm = env.GetMethodID(env.GetObjectClass(@native), "setLayoutManager", "(Landroidx/recyclerview/widget/RecyclerView$LayoutManager;)V")
        env.CallVoidMethod(@native, set_lm, lm)
      elsif Native::Platform.ios?
        LibIOS.table_view_set_style(@native, manager.value)
      end
    end

    def on_item_click(&block : Int32 -> Nil)
      @on_item_click = block
    end

    def on_item_long_click(&block : Int32 -> Nil)
      @on_item_long_click = block
    end

    def scroll_to_position(position : Int32, smooth : Bool = false)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0

        if smooth
          smooth_scroll = env.GetMethodID(env.GetObjectClass(@native), "smoothScrollToPosition", "(I)V")
          env.CallVoidMethod(@native, smooth_scroll, position)
        else
          scroll_to = env.GetMethodID(env.GetObjectClass(@native), "scrollToPosition", "(I)V")
          env.CallVoidMethod(@native, scroll_to, position)
        end
      elsif Native::Platform.ios?
        LibIOS.table_view_scroll_to_row(@native, position, smooth)
      end
    end

    def scroll_to_top(smooth : Bool = false)
      scroll_to_position(0, smooth)
    end

    def notify_data_changed
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0

        get_adapter = env.GetMethodID(env.GetObjectClass(@native), "getAdapter", "()Landroidx/recyclerview/widget/RecyclerView$Adapter;")
        adapter_obj = env.CallObjectMethod(@native, get_adapter)

        if adapter_obj
          notify_changed = env.GetMethodID(env.GetObjectClass(adapter_obj), "notifyDataSetChanged", "()V")
          env.CallVoidMethod(adapter_obj, notify_changed)
        end
      elsif Native::Platform.ios?
        LibIOS.table_view_reload_data(@native)
      end
    end

    def notify_item_inserted(position : Int32)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0

        get_adapter = env.GetMethodID(env.GetObjectClass(@native), "getAdapter", "()Landroidx/recyclerview/widget/RecyclerView$Adapter;")
        adapter_obj = env.CallObjectMethod(@native, get_adapter)

        if adapter_obj
          notify_insert = env.GetMethodID(env.GetObjectClass(adapter_obj), "notifyItemInserted", "(I)V")
          env.CallVoidMethod(adapter_obj, notify_insert, position)
        end
      end
    end

    def notify_item_removed(position : Int32)
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0

        get_adapter = env.GetMethodID(env.GetObjectClass(@native), "getAdapter", "()Landroidx/recyclerview/widget/RecyclerView$Adapter;")
        adapter_obj = env.CallObjectMethod(@native, get_adapter)

        if adapter_obj
          notify_remove = env.GetMethodID(env.GetObjectClass(adapter_obj), "notifyItemRemoved", "(I)V")
          env.CallVoidMethod(adapter_obj, notify_remove, position)
        end
      end
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
