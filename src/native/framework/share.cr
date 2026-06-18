module Native::Share
  struct ShareOptions
    property title : String = ""
    property text : String = ""
    property url : String = ""
    property image_path : String = ""
    property image_data : String = ""
    property mime_type : String = "text/plain"

    def initialize
    end

    def has_content? : Bool
      !text.empty? || !url.empty? || !image_path.empty? || !image_data.empty?
    end
  end

  class ShareSheet
    property options : ShareOptions = ShareOptions.new
    property on_complete : (Bool -> Nil)? = nil

    def initialize(options : ShareOptions = ShareOptions.new)
    end

    def show(&block : Bool -> Nil)
      @on_complete = block
      {% if flag?(:native_android) %}
        show_android
      {% elsif flag?(:native_ios) %}
        show_ios
      {% end %}
    end

    private def show_android
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      retun unless env && activity

      intent_class = env.find_class("android/content/Intent")
      intent_constructor = env.get_method_id(intent_class, "<init>", "()V")
      intent = env.new_object(intent_class, intent_constructor)

      set_action = env.get_method_id(intent_class, "setAction", "(Ljava/lang/String;)Landroid/content/Intent;")
      env.call_object_method(intent, set_action, env.new_string_utf("android.intent.action.SEND"))

      if @options.text && !@options.text.empty?
        put_extra = env.get_method_id(intent_class, "putExtra", "(Ljava/lang/string:ljava/lang/string:)Landroid/content/Intent;")
        env.call_object_method(intent, put_extra, env.new_string_utf("android.intent.extra.TEXT"), env.new_string_utf(@options.text))
      end

      if @options.url && !@options.url.empty?
        put_extra = env.get_method_id(intent_class, "putExtra", "(Ljava/lang/string:ljava/lang/string:)Landroid/content/Intent;")
        env.call_object_method(intent, put_extra, env.new_string_utf("android.intent.extra.TEXT"), env.new_string_utf(@options.url))
      end

      if @options.image_path && !@options.image_path.empty?
        uri_class = env.find_class("android/net/Uri")
        uri_parse = env.get_static_method_id(uri_class, "parse", "(Ljava/lang/String;)Landroid/net/Uri;")
        image_uri = env.call_static_object_method(uri_class, uri_parse, env.new_string_utf(@options.image_path))

        put_extra = env.get_method_id(intent_class, "putExtra", "(Ljava/lang/string:ljava/lang/Object;)Landroid/content/Intent;")
        env.call_object_method(intent, put_extra, env.new_string_utf("android.intent.extra.STREAM"), image_uri)

        set_type = env.get_method_id(intent_class, "setType", "(Ljava/lang/String;)Landroid/content/Intent;")
        env.call_object_method(intent, set_type, env.new_string_utf(@options.mime_type))
      else
        set_type = env.get_method_id(intent_class, "setType", "(Ljava/lang/String;)Landroid/content/Intent;")
        env.call_object_method(intent, set_type, env.new_string_utf(@options.mime_type))
      end

      create_chooser = env.get_static_method_id(intent_class, "createChooser", "(Landroid/content/Intent;Ljava/lang/String;)Landroid/content/Intent;")
      chooser = env.call_static_object_method(intent_class, create_chooser, intent, env.new_string_utf(@options.title))
      start_activity = env.get_method_id(activity.class, "startActivity", "(Landroid/content/Intent;)V")
      env.call_void_method(activity, start_activity, chooser)

      @on_complete.try &.call(true)
    end

    private def show_ios
      LibIOS.share(@options.text.to_utf8, @options.url.to_utf8, @options.title.to_utf8, @options.image_path.to_utf8, @options.image_data.to_utf8, @options.mime_type.to_utf8)
      @on_complete.try &.call(true)
    end
  end

  module Share
    def self.share_text(text : String, title : String = "share", &block : Bool -> Nil)
      options = ShareOptions.new
      options.text = text
      options.title = title
      ShareSheet.new(options).show(&block)
    end

    def self.share_url(url : String, title : String = "share", &block : Bool -> Nil)
      options = ShareOptions.new
      options.url = url
      options.title = title
      ShareSheet.new(options).show(&block)
    end

    def self.share_image(image_path : String, title : String = "share", &block : Bool -> Nil)
      options = ShareOptions.new
      options.image_path = image_path
      options.title = title
      ShareSheet.new(options).show(&block)
    end

    def self.share_text_and_url(text : String, url : String, title : String = "share", &block : Bool -> Nil)
      options = ShareOptions.new
      options.text = text
      options.url = url
      options.title = title
      ShareSheet.new(options).show(&block)
    end

    def self.share(options : ShareOptions, &block : Bool -> Nil)
      ShareSheet.new(options).show(&block)
    end
  end
end
