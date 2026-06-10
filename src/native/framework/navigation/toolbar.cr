# src/native/framework/navigation/toolbar.cr

module Native::Navigation
  class Toolbar < UI::View
    @title : String = ""
    @subtitle : String = ""
    @navigation_icon : Int32 = 0
    @menu_items : Array(MenuItem) = [] of MenuItem
    @on_navigation_click : (-> Nil)? = nil
    @on_menu_item_click : (Int32 -> Nil)?

    class MenuItem
      property id : Int32
      property title : String
      property icon : Int32
      property show_as_action : Bool

      def initialize(@id : Int32, @title : String, @icon : Int32 = 0, @show_as_action : Bool = false)
      end
    end

    def initialize
      super()

      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        toolbar_class = env.FindClass("androidx/appcompat/widget/Toolbar")
        constructor = env.GetMethodID(toolbar_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(toolbar_class, constructor, activity).to_i64

        setupNavigation
      elsif Native::Platform.ios?
        ptr = LibIOS.create_navigation_bar
        @native = ptr.to_i64
      end
    end

    def title=(value : String)
      @title = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_title = env.GetMethodID(env.GetObjectClass(@native), "setTitle", "(Ljava/lang/CharSequence;)V")
        env.CallVoidMethod(@native, set_title, env.NewStringUTF(value))
      elsif Native::Platform.ios?
        LibIOS.navigation_bar_set_title(@native, value.to_utf8)
      end
    end

    def title : String
      @title
    end

    def subtitle=(value : String)
      @subtitle = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_subtitle = env.GetMethodID(env.GetObjectClass(@native), "setSubtitle", "(Ljava/lang/CharSequence;)V")
        env.CallVoidMethod(@native, set_subtitle, env.NewStringUTF(value))
      end
    end

    def subtitle : String
      @subtitle
    end

    def navigation_icon=(resource_id : Int32)
      @navigation_icon = resource_id
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        set_nav = env.GetMethodID(env.GetObjectClass(@native), "setNavigationIcon", "(I)V")
        env.CallVoidMethod(@native, set_nav, resource_id)
      end
    end

    def navigation_icon : Int32
      @navigation_icon
    end

    def on_navigation_click(&block : -> Nil)
      @on_navigation_click = block
    end

    def add_menu_item(id : Int32, title : String, icon : Int32 = 0, show_as_action : Bool = false)
      item = MenuItem.new(id, title, icon, show_as_action)
      @menu_items << item

      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0

        menu_class = env.FindClass("android/view/Menu")
        add_method = env.GetMethodID(env.GetObjectClass(@native), "getMenu", "()Landroid/view/Menu;")
        menu = env.CallObjectMethod(@native, add_method)

        add_item = env.GetMethodID(env.GetObjectClass(menu), "add", "(IIII)Landroid/view/MenuItem;")
        menu_item = env.CallObjectMethod(menu, add_item, 0, id, 0, env.NewStringUTF(title))

        if icon != 0 && show_as_action
          set_icon = env.GetMethodID(env.GetObjectClass(menu_item), "setIcon", "(I)Landroid/view/MenuItem;")
          env.CallObjectMethod(menu_item, set_icon, icon)

          set_show = env.GetMethodID(env.GetObjectClass(menu_item), "setShowAsAction", "(I)V")
          env.CallVoidMethod(menu_item, set_show, 2)
        end
      end
    end

    def on_menu_item_click(&block : Int32 -> Nil)
      @on_menu_item_click = block
    end

    def setupWithActivity
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        set_actionbar = env.GetMethodID(env.GetObjectClass(activity), "setSupportActionBar", "(Landroidx/appcompat/widget/Toolbar;)V")
        env.CallVoidMethod(activity, set_actionbar, @native)
      end
    end

    private def setupNavigation
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_class = env.FindClass("com/nativecr/ToolbarCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      set_nav = env.GetMethodID(env.GetObjectClass(@native), "setNavigationOnClickListener", "(Landroid/view/View$OnClickListener;)V")
      env.CallVoidMethod(@native, set_nav, callback_obj)
    end

    def handleNavigationClick
      @on_navigation_click.try &.call
    end

    def handleMenuItemClick(item_id : Int32)
      @on_menu_item_click.try &.call(item_id)
    end
  end
end
