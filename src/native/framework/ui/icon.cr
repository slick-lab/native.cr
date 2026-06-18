# src/native/framework/ui/icon.cr

module Native::UI
  class Icon < TextView
    enum IconSet
      Material
      FontAwesome
      Ionicons
      Custom
    end

    @icon_set : IconSet = IconSet::Material
    @icon_code : String = ""
    @font_family : String = "MaterialIcons"

    def initialize(icon_set : IconSet = IconSet::Material, icon_code : String = "")
      super()
      @icon_set = icon_set
      @icon_code = icon_code

      case @icon_set
      when IconSet::Material
        @font_family = "MaterialIcons"
      when IconSet::FontAwesome
        @font_family = "FontAwesome"
      when IconSet::Ionicons
        @font_family = "Ionicons"
      when IconSet::Custom
        @font_family = "CustomIcons"
      end

      if !icon_code.empty?
        set_icon(icon_code)
      end
    end

    def set_icon(icon_code : String)
      @icon_code = icon_code
      self.text = icon_code

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env && @native != 0

        set_typeface = env.get_method_id(env.get_object_class(@native), "setTypeface", "(Landroid/graphics/Typeface;)V")

        typeface_class = env.find_class("android/graphics/Typeface")
        create_method = env.get_static_method_id(typeface_class, "createFromAsset", "(Landroid/content/res/AssetManager;Ljava/lang/String;)Landroid/graphics/Typeface;")

        asset_manager = env.call_object_method(Native::Android::JNI.activity, env.get_method_id(env.get_object_class(Native::Android::JNI.activity), "getAssets", "()Landroid/content/res/AssetManager;"))
        typeface = env.call_static_object_method(typeface_class, create_method, asset_manager, env.new_string_utf("#{@font_family}.ttf"))

        if typeface
          env.call_void_method(@native, set_typeface, typeface)
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.label_set_font(@native, @font_family.to_utf8)
      {% end %}
    end

    def icon_code : String
      @icon_code
    end

    def icon_set=(value : IconSet)
      @icon_set = value
      case @icon_set
      when IconSet::Material
        @font_family = "MaterialIcons"
      when IconSet::FontAwesome
        @font_family = "FontAwesome"
      when IconSet::Ionicons
        @font_family = "Ionicons"
      when IconSet::Custom
        @font_family = "CustomIcons"
      end
      set_icon(@icon_code) if !@icon_code.empty?
    end

    def icon_set : IconSet
      @icon_set
    end

    def size=(value : Int32)
      self.text_size = value
    end

    def color=(value : Native::Math::Color)
      self.text_color = value
    end
  end

  # Material Icons helper (common icons)
  module MaterialIcons
    def self.home : String
      "\uE88A"
    end

    def self.home_filled : String
      "\uE88A"
    end

    def self.search : String
      "\uE8B6"
    end

    def self.favorite : String
      "\uE87D"
    end

    def self.favorite_filled : String
      "\uE87D"
    end

    def self.settings : String
      "\uE8B8"
    end

    def self.person : String
      "\uE7FD"
    end

    def self.person_filled : String
      "\uE7FD"
    end

    def self.menu : String
      "\uE5D2"
    end

    def self.back : String
      "\uE5C4"
    end

    def self.close : String
      "\uE5CD"
    end

    def self.more_vert : String
      "\uE5D4"
    end

    def self.more_horiz : String
      "\uE5D3"
    end

    def self.add : String
      "\uE145"
    end

    def self.remove : String
      "\uE15B"
    end

    def self.delete : String
      "\uE872"
    end

    def self.edit : String
      "\uE3C9"
    end

    def self.check : String
      "\uE5CA"
    end

    def self.arrow_back : String
      "\uE5C4"
    end

    def self.arrow_forward : String
      "\uE5C8"
    end

    def self.refresh : String
      "\uE5D5"
    end

    def self.share : String
      "\uE80D"
    end

    def self.star : String
      "\uE838"
    end

    def self.star_filled : String
      "\uE838"
    end

    def self.info : String
      "\uE88E"
    end

    def self.warning : String
      "\uE002"
    end

    def self.error : String
      "\uE000"
    end

    def self.check_circle : String
      "\uE86C"
    end

    def self.help : String
      "\uE887"
    end

    def self.lock : String
      "\uE897"
    end

    def self.visibility : String
      "\uE8F4"
    end

    def self.visibility_off : String
      "\uE8F5"
    end

    def self.photo_camera : String
      "\uE412"
    end

    def self.videocam : String
      "\uE04B"
    end

    def self.mic : String
      "\uE029"
    end

    def self.mic_off : String
      "\uE02A"
    end

    def self.volume_up : String
      "\uE050"
    end

    def self.volume_off : String
      "\uE04F"
    end

    def self.play_arrow : String
      "\uE037"
    end

    def self.pause : String
      "\uE034"
    end

    def self.stop : String
      "\uE047"
    end

    def self.cloud : String
      "\uE2BD"
    end

    def self.cloud_upload : String
      "\uE2C3"
    end

    def self.cloud_download : String
      "\uE2C0"
    end
  end

  # Font Awesome Icons helper
  module FontAwesomeIcons
    def self.home : String
      "\uF015"
    end

    def self.user : String
      "\uF007"
    end

    def self.search : String
      "\uF002"
    end

    def self.heart : String
      "\uF004"
    end

    def self.star : String
      "\uF005"
    end

    def self.cog : String
      "\uF013"
    end

    def self.trash : String
      "\uF1F8"
    end

    def self.pencil : String
      "\uF040"
    end

    def self.check : String
      "\uF00C"
    end

    def self.times : String
      "\uF00D"
    end

    def self.plus : String
      "\uF067"
    end

    def self.minus : String
      "\uF068"
    end

    def self.camera : String
      "\uF030"
    end

    def self.video : String
      "\uF03D"
    end

    def self.music : String
      "\uF001"
    end

    def self.envelope : String
      "\uF0E0"
    end

    def self.phone : String
      "\uF095"
    end

    def self.map_marker : String
      "\uF041"
    end

    def self.calendar : String
      "\uF073"
    end
  end
end
