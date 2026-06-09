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

      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        webview_class = env.FindClass("android/webkit/WebView")
        constructor = env.GetMethodID(webview_class, "<init>", "(Landroid/content/Context;)V")
        @native = env.NewObject(webview_class, constructor, activity).to_i64

        setupWebView
        setupWebViewClient
        setupWebChromeClient
      elsif Native::Platform.ios?
        ptr = LibIOS.create_web_view
        @native = ptr.to_i64
      end
    end

    def url=(value : String)
      @url = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        load_url = env.GetMethodID(env.GetObjectClass(@native), "loadUrl", "(Ljava/lang/String;)V")
        env.CallVoidMethod(@native, load_url, env.NewStringUTF(value))
      elsif Native::Platform.ios?
        LibIOS.web_view_load_url(@native, value.to_utf8)
      end
    end

    def url : String
      @url
    end

    def load_html(html : String, base_url : String = "")
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        load_data = env.GetMethodID(env.GetObjectClass(@native), "loadDataWithBaseURL", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
        env.CallVoidMethod(@native, load_data, env.NewStringUTF(base_url), env.NewStringUTF(html), env.NewStringUTF("text/html"), env.NewStringUTF("UTF-8"), env.NewStringUTF(""))
      elsif Native::Platform.ios?
        LibIOS.web_view_load_html(@native, html.to_utf8, base_url.to_utf8)
      end
    end

    def java_script_enabled=(value : Bool)
      @java_script_enabled = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        settings = env.CallObjectMethod(@native, env.GetMethodID(env.GetObjectClass(@native), "getSettings", "()Landroid/webkit/WebSettings;"))
        set_js = env.GetMethodID(env.GetObjectClass(settings), "setJavaScriptEnabled", "(Z)V")
        env.CallVoidMethod(settings, set_js, value)
      elsif Native::Platform.ios?
        LibIOS.web_view_set_js_enabled(@native, value)
      end
    end

    def java_script_enabled? : Bool
      @java_script_enabled
    end

    def dom_storage_enabled=(value : Bool)
      @dom_storage_enabled = value
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        settings = env.CallObjectMethod(@native, env.GetMethodID(env.GetObjectClass(@native), "getSettings", "()Landroid/webkit/WebSettings;"))
        set_dom = env.GetMethodID(env.GetObjectClass(settings), "setDomStorageEnabled", "(Z)V")
        env.CallVoidMethod(settings, set_dom, value)
      end
    end

    def dom_storage_enabled? : Bool
      @dom_storage_enabled
    end

    def can_go_back? : Bool
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return false unless env && @native != 0
        can_go = env.GetMethodID(env.GetObjectClass(@native), "canGoBack", "()Z")
        env.CallBooleanMethod(@native, can_go)
      elsif Native::Platform.ios?
        LibIOS.web_view_can_go_back(@native)
      else
        false
      end
    end

    def can_go_forward? : Bool
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return false unless env && @native != 0
        can_go = env.GetMethodID(env.GetObjectClass(@native), "canGoForward", "()Z")
        env.CallBooleanMethod(@native, can_go)
      elsif Native::Platform.ios?
        LibIOS.web_view_can_go_forward(@native)
      else
        false
      end
    end

    def go_back
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        go = env.GetMethodID(env.GetObjectClass(@native), "goBack", "()V")
        env.CallVoidMethod(@native, go)
      elsif Native::Platform.ios?
        LibIOS.web_view_go_back(@native)
      end
    end

    def go_forward
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        go = env.GetMethodID(env.GetObjectClass(@native), "goForward", "()V")
        env.CallVoidMethod(@native, go)
      elsif Native::Platform.ios?
        LibIOS.web_view_go_forward(@native)
      end
    end

    def reload
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        reload = env.GetMethodID(env.GetObjectClass(@native), "reload", "()V")
        env.CallVoidMethod(@native, reload)
      elsif Native::Platform.ios?
        LibIOS.web_view_reload(@native)
      end
    end

    def stop_loading
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env && @native != 0
        stop = env.GetMethodID(env.GetObjectClass(@native), "stopLoading", "()V")
        env.CallVoidMethod(@native, stop)
      elsif Native::Platform.ios?
        LibIOS.web_view_stop_loading(@native)
      end
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
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env && @native != 0

      settings = env.CallObjectMethod(@native, env.GetMethodID(env.GetObjectClass(@native), "getSettings", "()Landroid/webkit/WebSettings;"))
      set_cache = env.GetMethodID(env.GetObjectClass(settings), "setCacheMode", "(I)V")
      env.CallVoidMethod(settings, set_cache, -1)
    end

    private def setupWebViewClient
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env && @native != 0

      client_class = env.FindClass("com/nativecr/WebViewClientCallback")
      if client_class == Pointer(Void).null
        return
      end

      client_obj = env.NewObject(client_class, env.GetMethodID(client_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      set_client = env.GetMethodID(env.GetObjectClass(@native), "setWebViewClient", "(Landroid/webkit/WebViewClient;)V")
      env.CallVoidMethod(@native, set_client, client_obj)
    end

    private def setupWebChromeClient
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env && @native != 0

      chrome_class = env.FindClass("com/nativecr/WebChromeClientCallback")
      if chrome_class == Pointer(Void).null
        return
      end

      chrome_obj = env.NewObject(chrome_class, env.GetMethodID(chrome_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      set_chrome = env.GetMethodID(env.GetObjectClass(@native), "setWebChromeClient", "(Landroid/webkit/WebChromeClient;)V")
      env.CallVoidMethod(@native, set_chrome, chrome_obj)
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
