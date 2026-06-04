# src/native/framework/image.cr

module Native
  module Image
    enum ImageFormat
      RGBA
      RGB
      Grayscale
    end

    struct Size
      property width : Int32
      property height : Int32

      def initialize(@width = 0, @height = 0)
      end
    end

    class ImageData
      property width : Int32
      property height : Int32
      property format : ImageFormat
      property pixels : Bytes

      def initialize(@width : Int32, @height : Int32, @format : ImageFormat = ImageFormat::RGBA)
        channels = format_channels
        @pixels = Bytes.new(width * height * channels, 0)
      end

      def initialize(@width : Int32, @height : Int32, @pixels : Bytes, @format : ImageFormat = ImageFormat::RGBA)
      end

      def channels : Int32
        format_channels
      end

      def size : Size
        Size.new(@width, @height)
      end

      def pixel(x : Int32, y : Int32) : {UInt8, UInt8, UInt8, UInt8}
        return {0, 0, 0, 0} if x < 0 || x >= @width || y < 0 || y >= @height
        
        idx = (y * @width + x) * channels
        r = @pixels[idx]
        g = @pixels[idx + 1]
        b = @pixels[idx + 2]
        a = @format == ImageFormat::RGBA ? @pixels[idx + 3] : 255_u8
        {r, g, b, a}
      end

      def set_pixel(x : Int32, y : Int32, r : UInt8, g : UInt8, b : UInt8, a : UInt8 = 255) : Nil
        return if x < 0 || x >= @width || y < 0 || y >= @height
        
        idx = (y * @width + x) * channels
        @pixels[idx] = r
        @pixels[idx + 1] = g
        @pixels[idx + 2] = b
        @pixels[idx + 3] = a if @format == ImageFormat::RGBA
      end

      def fill(r : UInt8, g : UInt8, b : UInt8, a : UInt8 = 255) : Nil
        channels = self.channels
        stride = @width * channels
        
        @height.times do |y|
          row_start = y * stride
          @width.times do |x|
            idx = row_start + x * channels
            @pixels[idx] = r
            @pixels[idx + 1] = g
            @pixels[idx + 2] = b
            @pixels[idx + 3] = a if channels == 4
          end
        end
      end

      def resize(new_width : Int32, new_height : Int32) : ImageData
        result = ImageData.new(new_width, new_height, @format)
        
        x_ratio = @width.to_f / new_width
        y_ratio = @height.to_f / new_height
        
        new_height.times do |y|
          new_width.times do |x|
            src_x = (x * x_ratio).to_i
            src_y = (y * y_ratio).to_i
            r, g, b, a = pixel(src_x, src_y)
            result.set_pixel(x, y, r, g, b, a)
          end
        end
        
        result
      end

      def crop(x : Int32, y : Int32, width : Int32, height : Int32) : ImageData
        result = ImageData.new(width, height, @format)
        
        height.times do |dy|
          width.times do |dx|
            r, g, b, a = pixel(x + dx, y + dy)
            result.set_pixel(dx, dy, r, g, b, a)
          end
        end
        
        result
      end

      def to_rgba : ImageData
        return self if @format == ImageFormat::RGBA
        
        result = ImageData.new(@width, @height, ImageFormat::RGBA)
        
        @height.times do |y|
          @width.times do |x|
            r, g, b, a = pixel(x, y)
            result.set_pixel(x, y, r, g, b, a)
          end
        end
        
        result
      end

      private def format_channels : Int32
        case @format
        when ImageFormat::RGBA then 4
        when ImageFormat::RGB then 3
        when ImageFormat::Grayscale then 1
        end
      end
    end

    class ImageLoader
      def self.from_file(path : String) : ImageData?
        return nil unless File.exists?(path)
        
        ext = File.extname(path).downcase
        
        case ext
        when ".png"
          load_png(path)
        when ".jpg", ".jpeg"
          load_jpeg(path)
        else
          nil
        end
      end

      def self.from_bytes(data : Bytes, format : String) : ImageData?
        case format.downcase
        when "png"
          load_png_from_memory(data)
        when "jpg", "jpeg"
          load_jpeg_from_memory(data)
        else
          nil
        end
      end

      def self.load_png(path : String) : ImageData?
        {% if flag?(:android) %}
          load_png_android(path)
        {% elsif flag?(:ios) %}
          load_png_ios(path)
        {% else %}
          load_png_stub(path)
        {% end %}
      end

      def self.load_jpeg(path : String) : ImageData?
        {% if flag?(:android) %}
          load_jpeg_android(path)
        {% elsif flag?(:ios) %}
          load_jpeg_ios(path)
        {% else %}
          load_jpeg_stub(path)
        {% end %}
      end

      private def self.load_png_android(path : String) : ImageData?
        width = LibAndroid.load_image_width(path.to_utf8)
        height = LibAndroid.load_image_height(path.to_utf8)
        
        return nil if width <= 0 || height <= 0
        
        pixels = Bytes.new(width * height * 4)
        success = LibAndroid.load_image_png(path.to_utf8, pixels, width, height)
        
        return nil unless success
        
        ImageData.new(width, height, pixels, ImageFormat::RGBA)
      end

      private def self.load_jpeg_android(path : String) : ImageData?
        width = LibAndroid.load_image_width(path.to_utf8)
        height = LibAndroid.load_image_height(path.to_utf8)
        
        return nil if width <= 0 || height <= 0
        
        pixels = Bytes.new(width * height * 4)
        success = LibAndroid.load_image_jpeg(path.to_utf8, pixels, width, height)
        
        return nil unless success
        
        ImageData.new(width, height, pixels, ImageFormat::RGBA)
      end

      private def self.load_png_ios(path : String) : ImageData?
        width = LibIOS.load_image_width(path.to_utf8)
        height = LibIOS.load_image_height(path.to_utf8)
        
        return nil if width <= 0 || height <= 0
        
        pixels = Bytes.new(width * height * 4)
        success = LibIOS.load_image_png(path.to_utf8, pixels, width, height)
        
        return nil unless success
        
        ImageData.new(width, height, pixels, ImageFormat::RGBA)
      end

      private def self.load_jpeg_ios(path : String) : ImageData?
        width = LibIOS.load_image_width(path.to_utf8)
        height = LibIOS.load_image_height(path.to_utf8)
        
        return nil if width <= 0 || height <= 0
        
        pixels = Bytes.new(width * height * 4)
        success = LibIOS.load_image_jpeg(path.to_utf8, pixels, width, height)
        
        return nil unless success
        
        ImageData.new(width, height, pixels, ImageFormat::RGBA)
      end

      private def self.load_png_from_memory(data : Bytes) : ImageData?
        {% if flag?(:android) %}
          load_png_memory_android(data)
        {% elsif flag?(:ios) %}
          load_png_memory_ios(data)
        {% else %}
          nil
        {% end %}
      end

      private def self.load_jpeg_from_memory(data : Bytes) : ImageData?
        {% if flag?(:android) %}
          load_jpeg_memory_android(data)
        {% elsif flag?(:ios) %}
          load_jpeg_memory_ios(data)
        {% else %}
          nil
        {% end %}
      end

      private def self.load_png_stub(path : String) : ImageData?
        nil
      end

      private def self.load_jpeg_stub(path : String) : ImageData?
        nil
      end
    end

    class UIImage < UI::View
      property image : ImageData?
      property scale_mode : ScaleMode = ScaleMode::AspectFit
      property tint_color : Styling::Color?

      enum ScaleMode
        Fill
        AspectFit
        AspectFill
        Stretch
      end

      def initialize
        super
        @width = 100
        @height = 100
      end

      def load(path : String) : Bool
        image_data = ImageLoader.from_file(path)
        if image_data
          @image = image_data
          true
        else
          false
        end
      end

      def load(data : Bytes, format : String) : Bool
        image_data = ImageLoader.from_bytes(data, format)
        if image_data
          @image = image_data
          true
        else
          false
        end
      end

      def draw(renderer : Void*) : Nil
        return unless @visible && @alpha > 0
        draw_background(renderer)
        
        if img = @image
          draw_image(renderer, img)
        end
      end

      private def draw_image(renderer : Void*, img : ImageData) : Nil
        src_w = img.width
        src_h = img.height
        dst_w = @width
        dst_h = @height
        
        x = absolute_x
        y = absolute_y
        
        case @scale_mode
        when ScaleMode::Fill
          draw_scaled(renderer, img, x, y, dst_w, dst_h)
          
        when ScaleMode::AspectFit
          ratio = [dst_w.to_f / src_w, dst_h.to_f / src_h].min
          draw_w = (src_w * ratio).to_i
          draw_h = (src_h * ratio).to_i
          draw_x = x + (dst_w - draw_w) // 2
          draw_y = y + (dst_h - draw_h) // 2
          draw_scaled(renderer, img, draw_x, draw_y, draw_w, draw_h)
          
        when ScaleMode::AspectFill
          ratio = [dst_w.to_f / src_w, dst_h.to_f / src_h].max
          draw_w = (src_w * ratio).to_i
          draw_h = (src_h * ratio).to_i
          draw_x = x + (dst_w - draw_w) // 2
          draw_y = y + (dst_h - draw_h) // 2
          draw_scaled(renderer, img, draw_x, draw_y, draw_w, draw_h)
          
        when ScaleMode::Stretch
          draw_scaled(renderer, img, x, y, dst_w, dst_h)
        end
      end

      private def draw_scaled(renderer : Void*, img : ImageData, x : Int32, y : Int32, w : Int32, h : Int32) : Nil
        rgba = img.to_rgba
        
        {% if flag?(:android) %}
          LibAndroid.draw_image(renderer, rgba.pixels, rgba.width, rgba.height, x, y, w, h)
        {% elsif flag?(:ios) %}
          LibIOS.draw_image(renderer, rgba.pixels, rgba.width, rgba.height, x, y, w, h)
        {% end %}
      end

      def measure(max_width : Int32, max_height : Int32) : {Int32, Int32}
        if img = @image
          {[@width, max_width].min, [@height, max_height].min}
        else
          {[@width, max_width].min, [@height, max_height].min}
        end
      end
    end

    module ImageUtils
      def self.create_checkerboard(size : Int32, cell_size : Int32 = 8) : ImageData
        img = ImageData.new(size, size, ImageFormat::RGBA)
        
        size.times do |y|
          size.times do |x|
            cell_x = x // cell_size
            cell_y = y // cell_size
            is_light = (cell_x + cell_y) % 2 == 0
            
            if is_light
              img.set_pixel(x, y, 200, 200, 200, 255)
            else
              img.set_pixel(x, y, 100, 100, 100, 255)
            end
          end
        end
        
        img
      end

      def self.create_gradient(width : Int32, height : Int32, 
                                start_r : UInt8, start_g : UInt8, start_b : UInt8,
                                end_r : UInt8, end_g : UInt8, end_b : UInt8,
                                horizontal : Bool = true) : ImageData
        img = ImageData.new(width, height, ImageFormat::RGBA)
        
        height.times do |y|
          width.times do |x|
            t = horizontal ? x.to_f / width : y.to_f / height
            
            r = (start_r + (end_r - start_r) * t).to_u8
            g = (start_g + (end_g - start_g) * t).to_u8
            b = (start_b + (end_b - start_b) * t).to_u8
            
            img.set_pixel(x, y, r, g, b, 255)
          end
        end
        
        img
      end

      def self.create_circle(radius : Int32, color : Styling::Color) : ImageData
        size = radius * 2
        img = ImageData.new(size, size, ImageFormat::RGBA)
        
        size.times do |y|
          size.times do |x|
            dx = x - radius
            dy = y - radius
            dist = Math.sqrt(dx * dx + dy * dy)
            
            if dist <= radius
              a = ((1.0 - dist / radius) * 255).to_u8
              img.set_pixel(x, y, color.r, color.g, color.b, a)
            else
              img.set_pixel(x, y, 0, 0, 0, 0)
            end
          end
        end
        
        img
      end
    end
  end
end
