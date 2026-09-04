# src/native/framework/ui/web_view.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

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
        env.delete_local_ref(webview_class) unless webview_class.null?

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
        JNIHelpers.call_void_string(env, @native, "loadUrl", "(Ljava/lang/String;)V", value)
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
        JNIHelpers.call_void_string(env, @native, "loadDataWithBaseURL", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V", env.new_string_utf(base_url), env.new_string_utf(html), env.new_string_utf("text/html"), env.new_string_utf("UTF-8"), "")
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
        JNIHelpers.call_void(env, settings, "setJavaScriptEnabled", "(Z)V", value)
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
        JNIHelpers.call_void(env, settings, "setDomStorageEnabled", "(Z)V", value)
      {% end %}
    end

    def dom_storage_enabled? : Bool
      @dom_storage_enabled
    end

    def can_go_back? : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env && @native != 0
        JNIHelpers.call_boolean(env, @native, "canGoBack", "()Z")
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
        JNIHelpers.call_boolean(env, @native, "canGoForward", "()Z")
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
        JNIHelpers.call_void(env, @native, "goBack", "()V")
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_go_back(@native)
      {% end %}
    end

    def go_forward
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "goForward", "()V")
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_go_forward(@native)
      {% end %}
    end

    def reload
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "reload", "()V")
      {% elsif flag?(:native_ios) %}
        LibIOS.web_view_reload(@native)
      {% end %}
    end

    def stop_loading
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0
        JNIHelpers.call_void(env, @native, "stopLoading", "()V")
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
      JNIHelpers.call_void(env, settings, "setCacheMode", "(I)V", -1)
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
      env.delete_local_ref(client_class) unless client_class.null?

      JNIHelpers.call_void(env, @native, "setWebViewClient", "(Landroid/webkit/WebViewClient;)V", client_obj)
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
      env.delete_local_ref(chrome_class) unless chrome_class.null?

      JNIHelpers.call_void(env, @native, "setWebChromeClient", "(Landroid/webkit/WebChromeClient;)V", chrome_obj)
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
