# Math

Vectors, colors, rects, and utility functions.

---

## Constants

```crystal
Native::Math::PI         # 3.14159...
Native::Math::TAU        # 2 * PI
Native::Math::HALF_PI    # PI / 2
Native::Math::DEG_TO_RAD # PI / 180
Native::Math::RAD_TO_DEG # 180 / PI
```

---

## Utilities

```crystal
Native::Math.clamp(value, min, max)
Native::Math.lerp(a, b, t)           # Linear interpolation
Native::Math.map(value, from_min, from_max, to_min, to_max)
Native::Math.random(min, max)        # Float between min and max
Native::Math.random_int(min, max)    # Int between min and max
Native::Math.deg_to_rad(degrees)
Native::Math.rad_to_deg(radians)
```

---

## Vector2

2D vector operations:

```crystal
v = Native::Math::Vector2.new(3.0, 4.0)
v.magnitude       # => 5.0
v.normalize       # => Vector2(0.6, 0.8)
v.angle           # => radians

# Static directions
Vector2.zero
Vector2.one
Vector2.up
Vector2.down
Vector2.left
Vector2.right
```

Operations:

```crystal
a + b       # Add
a - b       # Subtract
a * 2.0     # Scale
a / 2.0     # Divide
-a          # Negate

a.dot(b)       # Dot product
a.cross(b)     # 2D cross (scalar)
a.distance_to(b)
a.angle_to(b)
a.rotate(radians)
a.lerp(b, 0.5) # Interpolate
```

---

## Vector3

3D vector operations:

```crystal
v = Native::Math::Vector3.new(1.0, 2.0, 3.0)
v.magnitude
v.normalize

Vector3.zero
Vector3.one
```

Operations:

```crystal
a + b
a - b
a * scalar
a.dot(b)
a.cross(b)  # Returns Vector3
```

---

## Rect

Rectangle bounds:

```crystal
rect = Native::Math::Rect.new(10, 20, 100, 50)

rect.left      # => 10
rect.right     # => 110
rect.top       # => 20
rect.bottom    # => 70
rect.center    # => Vector2(60, 45)

rect.contains_point(Vector2.new(50, 30))  # => true
rect.intersects(other_rect)               # => true
rect.intersection(other)                  # => Rect or nil
rect.expand(10)
rect.shrink(5)
```

---

## Matrix3

3x3 transformation matrix:

```crystal
m = Native::Math::Matrix3.identity

# Factory methods
Matrix3.translation(100, 50)
Matrix3.scaling(2.0, 2.0)
Matrix3.rotation(Math.pi / 4)

# Combine
transform = Matrix3.translation(100, 0) * Matrix3.rotation(angle)
transform.transform(Vector2.new(10, 20))
```

---

## Color

RGBA color handling:

```crystal
# Factory methods
Native::Math::Color.white
Native::Math::Color.black
Native::Math::Color.red
Native::Math::Color.green
Native::Math::Color.blue
Native::Math::Color.gray(128)
Native::Math::Color.transparent

# From values
Color.from_rgba(255, 128, 0, 255)  # Orange
Color.from_hex(0xFF8855FF)         # ARGB hex
```

Operations:

```crystal
color.lerp(other, 0.5)    # Blend
color.with_alpha(0.5)     # New color with alpha
color.lighten(0.2)       # Brighten
color.darken(0.2)        # Darken

color.to_rgba  # => {255, 128, 0, 255}
color.to_hex   # => 0xFF8855FF
```

---

## Example: Movement

```crystal
class MovingApp < Native::App
  def setup
    @pos = Native::Math::Vector2.new(100, 100)
    @vel = Native::Math::Vector2.new(50, 30)
  end

  def update(dt)
    @pos = @pos + @vel * dt
    bounce if hit_edge?
  end

  def bounce
    @vel.x = -@vel.x if @pos.x < 0 || @pos.x > screen_width
    @vel.y = -@vel.y if @pos.y < 0 || @pos.y > screen_height
  end
end
```

---

## Example: Collision

```crystal
def check_collision
  player_rect = Native::Math::Rect.new(@player_x, @player_y, 50, 50)
  enemy_rect = Native::Math::Rect.new(@enemy_x, @enemy_y, 50, 50)

  if player_rect.intersects(enemy_rect)
    handle_collision
  end
end
```
