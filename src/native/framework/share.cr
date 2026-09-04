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

    # Refactored to use JNIHelpers for automatic local reference cleanup.
    # The old version had never compiled for Android: a `retun` typo, a
    # garbage putExtra signature ("(Ljava/lang/string:...)"), and
    # `activity.class` on a Void* — all in code paths CI never type-checked.
    private def show_android
      JNIHelpers.with_env do |env|
        activity = Native::Android::JNI.activity
        return unless activity

        intent = JNIHelpers.with_class(env, "android/content/Intent") do |intent_class|
          next Pointer(Void).null if intent_class.null?
          ctor = env.get_method_id(intent_class, "<init>", "()V")
          next Pointer(Void).null if ctor.null?
          env.new_object(intent_class, ctor)
        end
        return if intent.null?

        begin
          JNIHelpers.with_jstring(env, "android.intent.action.SEND") do |jaction|
            JNIHelpers.call_object(env, intent.to_i64, "setAction", "(Ljava/lang/String;)Landroid/content/Intent;", jaction)
          end

          unless @options.text.empty?
            JNIHelpers.with_jstring(env, @options.text) do |jtext|
              JNIHelpers.with_jstring(env, "android.intent.extra.TEXT") do |jkey|
                JNIHelpers.call_object(env, intent.to_i64, "putExtra", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;", jkey, jtext)
              end
            end
          end

          unless @options.url.empty?
            JNIHelpers.with_jstring(env, @options.url) do |jurl|
              JNIHelpers.with_jstring(env, "android.intent.extra.TEXT") do |jkey|
                JNIHelpers.call_object(env, intent.to_i64, "putExtra", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;", jkey, jurl)
              end
            end
          end

          JNIHelpers.with_jstring(env, @options.mime_type) do |jtype|
            JNIHelpers.call_object(env, intent.to_i64, "setType", "(Ljava/lang/String;)Landroid/content/Intent;", jtype)
          end

          unless @options.image_path.empty?
            JNIHelpers.with_jstring(env, @options.image_path) do |jpath|
              image_uri = JNIHelpers.call_static_object(env, "android/net/Uri", "parse", "(Ljava/lang/String;)Landroid/net/Uri;", jpath)
              unless image_uri.null?
                begin
                  JNIHelpers.with_jstring(env, "android.intent.extra.STREAM") do |jkey|
                    JNIHelpers.call_object(env, intent.to_i64, "putExtra", "(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;", jkey, image_uri)
                  end
                ensure
                  env.delete_local_ref(image_uri)
                end
              end
            end
          end

          chooser = JNIHelpers.with_jstring(env, @options.title) do |jtitle|
            JNIHelpers.call_static_object(env, "android/content/Intent", "createChooser", "(Landroid/content/Intent;Ljava/lang/CharSequence;)Landroid/content/Intent;", intent, jtitle)
          end

          unless chooser.null?
            begin
              JNIHelpers.call_void(env, activity.to_i64, "startActivity", "(Landroid/content/Intent;)V", chooser)
            ensure
              env.delete_local_ref(chooser)
            end
          end

          @on_complete.try &.call(true)
        ensure
          env.delete_local_ref(intent)
        end
      end
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
