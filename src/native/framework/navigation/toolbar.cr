# src/native/framework/navigation/toolbar.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

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

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        toolbar_class = env.find_class("androidx/appcompat/widget/Toolbar")
        constructor = env.get_method_id(toolbar_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(toolbar_class, constructor, activity).to_i64
        env.delete_local_ref(toolbar_class) unless toolbar_class.null?

        setupNavigation
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_navigation_bar
        @native = ptr.to_i64
      {% end %}
    end

    def title=(value : String)
      @title = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void_string(env, @native, "setTitle", "(Ljava/lang/CharSequence;)V", value)
      {% elsif flag?(:native_ios) %}
        LibIOS.navigation_bar_set_title(@native, value.to_utf8)
      {% end %}
    end

    def title : String
      @title
    end

    def subtitle=(value : String)
      @subtitle = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void_string(env, @native, "setSubtitle", "(Ljava/lang/CharSequence;)V", value)
      {% end %}
    end

    def subtitle : String
      @subtitle
    end

    def navigation_icon=(resource_id : Int32)
      @navigation_icon = resource_id
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "setNavigationIcon", "(I)V", resource_id)
      {% end %}
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

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        menu_class = env.find_class("android/view/Menu")
        add_method = env.get_method_id(env.get_object_class(@native), "getMenu", "()Landroid/view/Menu;")
        menu = env.call_object_method(@native, add_method)

        add_item = env.get_method_id(env.get_object_class(menu), "add", "(IIII)Landroid/view/MenuItem;")
        menu_item = env.call_object_method(menu, add_item, 0, id, 0, env.new_string_utf(title))

        if icon != 0 && show_as_action
          JNIHelpers.call_object(env, menu_item, "setIcon", "(I)Landroid/view/MenuItem;", icon)

          JNIHelpers.call_void(env, menu_item, "setShowAsAction", "(I)V", 2)
        end
      {% end %}
    end

    def on_menu_item_click(&block : Int32 -> Nil)
      @on_menu_item_click = block
    end

    def setupWithActivity
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        JNIHelpers.call_void(env, activity, "setSupportActionBar", "(Landroidx/appcompat/widget/Toolbar;)V", @native)
      {% end %}
    end

    private def setupNavigation
      {% unless flag?(:native_android) %}
        return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @native != 0

      callback_class = env.find_class("com/nativecr/ToolbarCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(J)V"), 0i64)
      env.delete_local_ref(callback_class) unless callback_class.null?

      JNIHelpers.call_void(env, @native, "setNavigationOnClickListener", "(Landroid/view/View$OnClickListener;)V", callback_obj)
    end

    def handleNavigationClick
      @on_navigation_click.try &.call
    end

    def handleMenuItemClick(item_id : Int32)
      @on_menu_item_click.try &.call(item_id)
    end
  end
end
