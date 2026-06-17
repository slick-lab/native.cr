# src/native/framework/image_picker.cr

module Native::ImagePicker
  enum ImageSource
    Camera
    Gallery
    Both
  end

  enum ImageQuality
    Low      = 0
    Medium   = 1
    High     = 2
    Original = 3
  end

  struct ImagePickerResult
    property success : Bool
    property path : String?
    property data : Bytes?
    property width : Int32
    property height : Int32
    property mime_type : String
    property error_message : String?

    def initialize(@success = false, @path = nil, @data = nil,
                   @width = 0, @height = 0, @mime_type = "image/jpeg",
                   @error_message = nil)
    end

    def has_image? : Bool
      success && (path || data)
    end
  end

  class ImagePicker
    @@callback : (ImagePickerResult -> Nil)?
    @@picker_ptr : Int64 = 0

    def self.pick(source : ImageSource = ImageSource::Gallery,
                  quality : ImageQuality = ImageQuality::High,
                  max_width : Int32 = 0,
                  max_height : Int32 = 0,
                  &callback : ImagePickerResult -> Nil)
      @@callback = callback

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        picker_class = env.FindClass("com/nativecr/ImagePickerHelper")
        if picker_class == Pointer(Void).null
          callback.call(ImagePickerResult.new(success: false, error_message: "ImagePicker class not found"))
          return
        end

        pick_method = env.GetStaticMethodID(picker_class, "pickImage", "(Landroid/app/Activity;III)V")
        env.CallStaticVoidMethod(picker_class, pick_method, activity, source.value, quality.value, 0)
      {% elsif flag?(:native_ios) %}
        LibIOS.image_picker_pick(source.value, quality.value, max_width, max_height)
      {% else %}
        callback.call(ImagePickerResult.new(success: false, error_message: "Platform not supported"))
      {% end %}
    end

    def self.take_photo(quality : ImageQuality = ImageQuality::High,
                        max_width : Int32 = 0,
                        max_height : Int32 = 0,
                        &callback : ImagePickerResult -> Nil)
      @@callback = callback

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        picker_class = env.FindClass("com/nativecr/ImagePickerHelper")
        if picker_class == Pointer(Void).null
          callback.call(ImagePickerResult.new(success: false, error_message: "ImagePicker class not found"))
          return
        end

        take_method = env.GetStaticMethodID(picker_class, "takePhoto", "(Landroid/app/Activity;III)V")
        env.CallStaticVoidMethod(picker_class, take_method, activity, quality.value, 0)
      {% elsif flag?(:native_ios) %}
        LibIOS.image_picker_take_photo(quality.value, max_width, max_height)
      {% else %}
        callback.call(ImagePickerResult.new(success: false, error_message: "Platform not supported"))
      {% end %}
    end

    def self.pick_multiple(max_count : Int32 = 10,
                           &callback : Array(ImagePickerResult) -> Nil)
      # Multiple image selection not implemented in this version
      callback.call([] of ImagePickerResult)
    end

    def self.handleResult(path : String, data : Bytes?, width : Int32, height : Int32, mime_type : String, success : Bool)
      result = ImagePickerResult.new(
        success: success,
        path: path.empty? ? nil : path,
        data: data,
        width: width,
        height: height,
        mime_type: mime_type,
        error_message: success ? nil : "Failed to pick image"
      )
      @@callback.try &.call(result)
      @@callback = nil
    end
  end

  module ImagePickerAPI
    def self.pick_image(source : ImageSource = ImageSource::Gallery,
                        quality : ImageQuality = ImageQuality::High,
                        &callback : ImagePickerResult -> Nil)
      ImagePicker.pick(source, quality, &callback)
    end

    def self.take_photo(quality : ImageQuality = ImageQuality::High,
                        &callback : ImagePickerResult -> Nil)
      ImagePicker.take_photo(quality, &callback)
    end

    def self.pick_and_resize(source : ImageSource = ImageSource::Gallery,
                             max_width : Int32 = 1024,
                             max_height : Int32 = 1024,
                             &callback : ImagePickerResult -> Nil)
      ImagePicker.pick(source, ImageQuality::Original, max_width, max_height, &callback)
    end
  end
end
