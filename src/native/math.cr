# src/native/math.cr

module Native
  module Math
    PI         =  3.141592653589793
    TAU        =  6.283185307179586
    HALF_PI    = 1.5707963267948966
    DEG_TO_RAD = PI / 180.0
    RAD_TO_DEG = 180.0 / PI

    def self.clamp(value : T, min : T, max : T) forall T
      return min if value < min
      return max if value > max
      value
    end

    def self.lerp(a : Float64, b : Float64, t : Float64) : Float64
      a + (b - a) * clamp(t, 0.0, 1.0)
    end

    def self.map(value : Float64, from_min : Float64, from_max : Float64, to_min : Float64, to_max : Float64) : Float64
      to_min + (to_max - to_min) * ((value - from_min) / (from_max - from_min))
    end

    def self.random(min : Float64 = 0.0, max : Float64 = 1.0) : Float64
      min + (Random.rand * (max - min))
    end

    def self.random_int(min : Int32, max : Int32) : Int32
      min + Random.rand(max - min + 1)
    end

    def self.deg_to_rad(degrees : Float64) : Float64
      degrees * DEG_TO_RAD
    end

    def self.rad_to_deg(radians : Float64) : Float64
      radians * RAD_TO_DEG
    end

    struct Vector2
      property x : Float64
      property y : Float64

      def initialize(@x = 0.0, @y = 0.0)
      end

      def self.zero : Vector2
        new(0.0, 0.0)
      end

      def self.one : Vector2
        new(1.0, 1.0)
      end

      def self.up : Vector2
        new(0.0, 1.0)
      end

      def self.down : Vector2
        new(0.0, -1.0)
      end

      def self.left : Vector2
        new(-1.0, 0.0)
      end

      def self.right : Vector2
        new(1.0, 0.0)
      end

      def +(other : Vector2) : Vector2
        Vector2.new(@x + other.x, @y + other.y)
      end

      def -(other : Vector2) : Vector2
        Vector2.new(@x - other.x, @y - other.y)
      end

      def *(scalar : Float64) : Vector2
        Vector2.new(@x * scalar, @y * scalar)
      end

      def *(scalar : Int32) : Vector2
        Vector2.new(@x * scalar, @y * scalar)
      end

      def /(scalar : Float64) : Vector2
        Vector2.new(@x / scalar, @y / scalar)
      end

      def /(scalar : Int32) : Vector2
        Vector2.new(@x / scalar, @y / scalar)
      end

      def - : Vector2
        Vector2.new(-@x, -@y)
      end

      def magnitude : Float64
        ::Math.sqrt(@x * @x + @y * @y)
      end

      def magnitude_squared : Float64
        @x * @x + @y * @y
      end

      def normalize : Vector2
        mag = magnitude
        return Vector2.zero if mag == 0
        Vector2.new(@x / mag, @y / mag)
      end

      def normalized : Vector2
        normalize
      end

      def dot(other : Vector2) : Float64
        @x * other.x + @y * other.y
      end

      def cross(other : Vector2) : Float64
        @x * other.y - @y * other.x
      end

      def distance_to(other : Vector2) : Float64
        (self - other).magnitude
      end

      def distance_squared_to(other : Vector2) : Float64
        (self - other).magnitude_squared
      end

      def angle_to(other : Vector2) : Float64
        ::Math.atan2(cross(other), dot(other))
      end

      def angle : Float64
        ::Math.atan2(@y, @x)
      end

      def rotate(radians : Float64) : Vector2
        cos = ::Math.cos(radians)
        sin = ::Math.sin(radians)
        Vector2.new(@x * cos - @y * sin, @x * sin + @y * cos)
      end

      def lerp(to : Vector2, t : Float64) : Vector2
        Vector2.new(
          @x + (to.x - @x) * Native::Math.clamp(t, 0.0, 1.0),
          @y + (to.y - @y) * Native::Math.clamp(t, 0.0, 1.0)
        )
      end

      def clamp(min : Vector2, max : Vector2) : Vector2
        Vector2.new(
          Native::Math.clamp(@x, min.x, max.x),
          Native::Math.clamp(@y, min.y, max.y)
        )
      end

      def ==(other : Vector2) : Bool
        @x == other.x && @y == other.y
      end

      def to_s : String
        "(#{@x}, #{@y})"
      end

      def to_tuple : {Float64, Float64}
        {@x, @y}
      end
    end

    struct Vector3
      property x : Float64
      property y : Float64
      property z : Float64

      def initialize(@x = 0.0, @y = 0.0, @z = 0.0)
      end

      def self.zero : Vector3
        new(0.0, 0.0, 0.0)
      end

      def self.one : Vector3
        new(1.0, 1.0, 1.0)
      end

      def +(other : Vector3) : Vector3
        Vector3.new(@x + other.x, @y + other.y, @z + other.z)
      end

      def -(other : Vector3) : Vector3
        Vector3.new(@x - other.x, @y - other.y, @z - other.z)
      end

      def *(scalar : Float64) : Vector3
        Vector3.new(@x * scalar, @y * scalar, @z * scalar)
      end

      def /(scalar : Float64) : Vector3
        Vector3.new(@x / scalar, @y / scalar, @z / scalar)
      end

      def magnitude : Float64
        ::Math.sqrt(@x * @x + @y * @y + @z * @z)
      end

      def magnitude_squared : Float64
        @x * @x + @y * @y + @z * @z
      end

      def normalize : Vector3
        mag = magnitude
        return Vector3.zero if mag == 0
        Vector3.new(@x / mag, @y / mag, @z / mag)
      end

      def dot(other : Vector3) : Float64
        @x * other.x + @y * other.y + @z * other.z
      end

      def cross(other : Vector3) : Vector3
        Vector3.new(
          @y * other.z - @z * other.y,
          @z * other.x - @x * other.z,
          @x * other.y - @y * other.x
        )
      end

      def ==(other : Vector3) : Bool
        @x == other.x && @y == other.y && @z == other.z
      end

      def to_s : String
        "(#{@x}, #{@y}, #{@z})"
      end
    end

    struct Rect
      property x : Float64
      property y : Float64
      property width : Float64
      property height : Float64

      def initialize(@x = 0.0, @y = 0.0, @width = 0.0, @height = 0.0)
      end

      def left : Float64
        @x
      end

      def right : Float64
        @x + @width
      end

      def top : Float64
        @y
      end

      def bottom : Float64
        @y + @height
      end

      def center_x : Float64
        @x + @width / 2
      end

      def center_y : Float64
        @y + @height / 2
      end

      def center : Vector2
        Vector2.new(center_x, center_y)
      end

      def contains_point(point : Vector2) : Bool
        point.x >= @x && point.x <= @x + @width && point.y >= @y && point.y <= @y + @height
      end

      def intersects(other : Rect) : Bool
        !(other.right < @x || other.left > right || other.bottom < @y || other.top > bottom)
      end

      def intersection(other : Rect) : Rect?
        return nil unless intersects(other)

        new_x = ::Math.max(@x, other.x)
        new_y = ::Math.max(@y, other.y)
        new_w = ::Math.min(right, other.right) - new_x
        new_h = ::Math.min(bottom, other.bottom) - new_y

        Rect.new(new_x, new_y, new_w, new_h)
      end

      def expand(amount : Float64) : Rect
        Rect.new(@x - amount, @y - amount, @width + amount * 2, @height + amount * 2)
      end

      def shrink(amount : Float64) : Rect
        expand(-amount)
      end
    end

    struct Matrix3
      property m : Array(Float64)

      def initialize
        @m = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]
      end

      def self.identity : Matrix3
        Matrix3.new
      end

      def self.translation(x : Float64, y : Float64) : Matrix3
        mat = Matrix3.new
        mat.m[2] = x
        mat.m[5] = y
        mat
      end

      def self.scaling(x : Float64, y : Float64) : Matrix3
        mat = Matrix3.new
        mat.m[0] = x
        mat.m[4] = y
        mat
      end

      def self.rotation(angle : Float64) : Matrix3
        mat = Matrix3.new
        cos = ::Math.cos(angle)
        sin = ::Math.sin(angle)
        mat.m[0] = cos
        mat.m[1] = -sin
        mat.m[3] = sin
        mat.m[4] = cos
        mat
      end

      def *(other : Matrix3) : Matrix3
        result = Matrix3.new
        a = @m
        b = other.m

        result.m[0] = a[0] * b[0] + a[1] * b[3] + a[2] * b[6]
        result.m[1] = a[0] * b[1] + a[1] * b[4] + a[2] * b[7]
        result.m[2] = a[0] * b[2] + a[1] * b[5] + a[2] * b[8]
        result.m[3] = a[3] * b[0] + a[4] * b[3] + a[5] * b[6]
        result.m[4] = a[3] * b[1] + a[4] * b[4] + a[5] * b[7]
        result.m[5] = a[3] * b[2] + a[4] * b[5] + a[5] * b[8]
        result.m[6] = a[6] * b[0] + a[7] * b[3] + a[8] * b[6]
        result.m[7] = a[6] * b[1] + a[7] * b[4] + a[8] * b[7]
        result.m[8] = a[6] * b[2] + a[7] * b[5] + a[8] * b[8]

        result
      end

      def transform(point : Vector2) : Vector2
        x = @m[0] * point.x + @m[1] * point.y + @m[2]
        y = @m[3] * point.x + @m[4] * point.y + @m[5]
        Vector2.new(x, y)
      end
    end

    struct Color
      property r : Float64
      property g : Float64
      property b : Float64
      property a : Float64

      def initialize(@r = 0.0, @g = 0.0, @b = 0.0, @a = 1.0)
      end

      def self.from_rgba(r : Int32, g : Int32, b : Int32, a : Int32 = 255) : Color
        Color.new(r / 255.0, g / 255.0, b / 255.0, a / 255.0)
      end

      def self.from_hex(hex : UInt32) : Color
        r = ((hex >> 16) & 0xFF).to_i32
        g = ((hex >> 8) & 0xFF).to_i32
        b = (hex & 0xFF).to_i32
        a = ((hex >> 24) & 0xFF).to_i32
        from_rgba(r, g, b, a == 0 ? 255 : a)
      end

      def self.white : Color
        new(1.0, 1.0, 1.0, 1.0)
      end

      def self.black : Color
        new(0.0, 0.0, 0.0, 1.0)
      end

      def self.red : Color
        new(1.0, 0.0, 0.0, 1.0)
      end

      def self.green : Color
        new(0.0, 1.0, 0.0, 1.0)
      end

      def self.blue : Color
        new(0.0, 0.0, 1.0, 1.0)
      end

      def self.transparent : Color
        new(0.0, 0.0, 0.0, 0.0)
      end

      def lerp(to : Color, t : Float64) : Color
        Color.new(
          @r + (to.r - @r) * t,
          @g + (to.g - @g) * t,
          @b + (to.b - @b) * t,
          @a + (to.a - @a) * t
        )
      end

      def with_alpha(alpha : Float64) : Color
        Color.new(@r, @g, @b, alpha)
      end

      def to_rgba : {Int32, Int32, Int32, Int32}
        {(@r * 255).to_i, (@g * 255).to_i, (@b * 255).to_i, (@a * 255).to_i}
      end

      def to_hex : UInt32
        r = (@r * 255).to_i
        g = (@g * 255).to_i
        b = (@b * 255).to_i
        a = (@a * 255).to_i
        (a.to_u32 << 24) | (r.to_u32 << 16) | (g.to_u32 << 8) | b.to_u32
      end
    end
  end
end
