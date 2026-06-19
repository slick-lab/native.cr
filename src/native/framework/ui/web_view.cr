# src/native/framework/ui/web_view.cr

module Native::UI
  class WebView < View
    @url : String = ""
    @on_page_started : (String -> Nil)?
    @on_page_finished : (String -> Nil)?
    @on_error : (String -> Nil)?
    @java_script_enabled : Bool = false
    @dom_storage_enabled : Bool = false

    def initialize
      super()

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        webview_class = env.find_class("android/webkit/WebView")
        constructor = env.get_method_id(webview_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.new_object(webview_class, constructor, activity).to_i64

        setupWebView
        setupWebViewClient
        setupWebChromeClient
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.create_web_view
        @native = ptr.to_i64
      {% end %}
    end

    def url=(value : String)
      @url = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        load_url = env.get_method_id(env.get_object_class(@native), "loadUrl", "(Ljava/lang/String;)V")
        env.call_void_method(@native, load_url, env.new_string_utf(value))
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_load_url(@native, value.to_utf8)
      {% end %}
    end

    def url : String
      @url
    end

    def load_html(html : String, base_url : String = "")
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        load_data = env.get_method_id(env.get_object_class(@native), "loadDataWithBaseURL", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
        env.call_void_method(@native, load_data, env.new_string_utf(base_url), env.new_string_utf(html), env.new_string_utf("text/html"), env.new_string_utf("UTF-8"), env.new_string_utf(""))
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_load_html(@native, html.to_utf8, base_url.to_utf8)
      {% end %}
    end

    def java_script_enabled=(value : Bool)
      @java_script_enabled = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        settings = env.call_object_method(@native, env.get_method_id(env.get_object_class(@native), "getSettings", "()Landroid/webkit/WebSettings;"))
        set_js = env.get_method_id(env.get_object_class(settings), "setJavaScriptEnabled", "(Z)V")
        env.call_void_method(settings, set_js, value)
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_set_js_enabled(@native, value)
      {% end %}
    end

    def java_script_enabled? : Bool
      @java_script_enabled
    end

    def dom_storage_enabled=(value : Bool)
      @dom_storage_enabled = value
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        settings = env.call_object_method(@native, env.get_method_id(env.get_object_class(@native), "getSettings", "()Landroid/webkit/WebSettings;"))
        set_dom = env.get_method_id(env.get_object_class(settings), "setDomStorageEnabled", "(Z)V")
        env.call_void_method(settings, set_dom, value)
      {% end %}
    end

    def dom_storage_enabled? : Bool
      @dom_storage_enabled
    end

    def can_go_back? : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env && @native != 0
        can_go = env.get_method_id(env.get_object_class(@native), "canGoBack", "()Z")
        env.call_boolean_method(@native, can_go)
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_can_go_back(@native)
      {% else %}
        false
      {% end %}
    end

    def can_go_forward? : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env && @native != 0
        can_go = env.get_method_id(env.get_object_class(@native), "canGoForward", "()Z")
        env.call_boolean_method(@native, can_go)
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_can_go_forward(@native)
      {% else %}
        false
      {% end %}
    end

    def go_back
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        go = env.get_method_id(env.get_object_class(@native), "goBack", "()V")
        env.call_void_method(@native, go)
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_go_back(@native)
      {% end %}
    end

    def go_forward
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        go = env.get_method_id(env.get_object_class(@native), "goForward", "()V")
        env.call_void_method(@native, go)
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_go_forward(@native)
      {% end %}
    end

    def reload
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        reload = env.get_method_id(env.get_object_class(@native), "reload", "()V")
        env.call_void_method(@native, reload)
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_reload(@native)
      {% end %}
    end

    def stop_loading
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        stop = env.get_method_id(env.get_object_class(@native), "stopLoading", "()V")
        env.call_void_method(@native, stop)
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_stop_loading(@native)
      {% end %}
    end

    def on_page_started(&block : String -> Nil)
      @on_page_started = block
    end

    def on_page_finished(&block : String -> Nil)
      @on_page_finished = block
    end

    def on_error(&block : String -> Nil)
      @on_error = block
    end

    private def setupWebView
      {% unless flag?(:native_android) %}
        return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @native != 0

      settings = env.call_object_method(@native, env.get_method_id(env.get_object_class(@native), "getSettings", "()Landroid/webkit/WebSettings;"))
      set_cache = env.get_method_id(env.get_object_class(settings), "setCacheMode", "(I)V")
      env.call_void_method(settings, set_cache, -1)
    end

    private def setupWebViewClient
      {% unless flag?(:native_android) %}
        return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @native != 0

      client_class = env.find_class("com/nativecr/WebViewClientCallback")
      if client_class == Pointer(Void).null
        return
      end

      client_obj = env.new_object(client_class, env.get_method_id(client_class, "<init>", "(J)V"), 0i64)

      set_client = env.get_method_id(env.get_object_class(@native), "setWebViewClient", "(Landroid/webkit/WebViewClient;)V")
      env.call_void_method(@native, set_client, client_obj)
    end

    private def setupWebChromeClient
      {% unless flag?(:native_android) %}
        return
      {% end %}
      env = Native::Android::JNI.env
      return unless env && @native != 0

      chrome_class = env.find_class("com/nativecr/WebChromeClientCallback")
      if chrome_class == Pointer(Void).null
        return
      end

      chrome_obj = env.new_object(chrome_class, env.get_method_id(chrome_class, "<init>", "(J)V"), 0i64)

      set_chrome = env.get_method_id(env.get_object_class(@native), "setWebChromeClient", "(Landroid/webkit/WebChromeClient;)V")
      env.call_void_method(@native, set_chrome, chrome_obj)
    end

    def handlePageStarted(url : String)
      @on_page_started.try &.call(url)
    end

    def handlePageFinished(url : String)
      @on_page_finished.try &.call(url)
    end

    def handleError(error : String)
      @on_error.try &.call(error)
    end
  end
end
