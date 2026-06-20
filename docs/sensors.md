# Sensors

native.cr exposes the device's hardware sensors through `Native::Sensors`. You subscribe to a sensor and receive readings in a block.

---

## Available sensors

| Sensor type | Constant | What it measures |
|---|---|---|
| Accelerometer | `SensorType::Accelerometer` | Linear acceleration in m/s² (x, y, z) |
| Gyroscope | `SensorType::Gyroscope` | Angular rotation in rad/s (x, y, z) |
| Magnetometer | `SensorType::Magnetometer` | Magnetic field strength in µT (x, y, z) |
| Light | `SensorType::Light` | Ambient light level in lux |
| Proximity | `SensorType::Proximity` | Distance to nearest object in cm |
| Pressure | `SensorType::Pressure` | Atmospheric pressure in hPa |
| Temperature | `SensorType::Temperature` | Ambient temperature in °C |
| Humidity | `SensorType::Humidity` | Relative humidity in % |

---

## Quick start — `Native::Sensors::Sensor`

The `Sensor` module has one-liner shortcuts for every sensor type:

```crystal
# Accelerometer — fires every 200ms by default
Native::Sensors::Sensor.accelerometer do |data|
  puts "X: #{data.x}  Y: #{data.y}  Z: #{data.z}"
end

# Gyroscope
Native::Sensors::Sensor.gyroscope do |data|
  puts "Rotation X: #{data.x.round(3)} rad/s"
end

# Magnetometer
Native::Sensors::Sensor.magnetometer do |data|
  puts "Magnetic field — X: #{data.x}, Y: #{data.y}, Z: #{data.z}"
end

# Light
Native::Sensors::Sensor.light do |data|
  lux = data.values[0]
  puts "Ambient light: #{lux} lux"
end

# Proximity
Native::Sensors::Sensor.proximity do |data|
  near = data.values[0] < 5.0
  puts near ? "Something is close!" : "Nothing nearby"
end

# Pressure
Native::Sensors::Sensor.pressure do |data|
  puts "Pressure: #{data.values[0]} hPa"
end

# Temperature
Native::Sensors::Sensor.temperature do |data|
  puts "Temperature: #{data.values[0]} °C"
end

# Humidity
Native::Sensors::Sensor.humidity do |data|
  puts "Humidity: #{data.values[0]}%"
end
```

---

## Controlling the update rate

The `delay_us` parameter sets the minimum interval between readings in **microseconds**. Shorter intervals = more readings = more battery used.

```crystal
# 50,000 µs = 50 ms = 20 readings/second — good for games, physics
Native::Sensors::Sensor.accelerometer(delay_us: 50_000) do |data|
  update_physics(data.x, data.y, data.z)
end

# 200,000 µs = 200 ms = 5 readings/second (default)
Native::Sensors::Sensor.accelerometer do |data|
  detect_orientation(data)
end

# 1,000,000 µs = 1 second — for environmental sensors where fast updates waste power
Native::Sensors::Sensor.temperature(delay_us: 1_000_000) do |data|
  @temperature_label.text = "#{data.values[0].round(1)} °C"
end
```

---

## The `SensorData` struct

Every callback receives a `Native::Sensors::SensorData`:

| Field | Type | Description |
|---|---|---|
| `type` | `SensorType` | Which sensor fired |
| `timestamp` | `Int64` | Time of reading in nanoseconds since boot |
| `values` | `Array(Float64)` | Raw sensor values (meaning depends on sensor) |
| `accuracy` | `Int32` | 0 = unreliable, 1 = low, 2 = medium, 3 = high |
| `x` | `Float64` | Shortcut for `values[0]` |
| `y` | `Float64` | Shortcut for `values[1]` |
| `z` | `Float64` | Shortcut for `values[2]` |

### Values by sensor type

| Sensor | `values[0]` | `values[1]` | `values[2]` |
|---|---|---|---|
| Accelerometer | x axis (m/s²) | y axis (m/s²) | z axis (m/s²) |
| Gyroscope | x rotation (rad/s) | y rotation | z rotation |
| Magnetometer | x field (µT) | y field | z field |
| Light | lux | — | — |
| Proximity | distance (cm) | — | — |
| Pressure | hPa | — | — |
| Temperature | °C | — | — |
| Humidity | % | — | — |

---

## Using `SensorManager` for full control

```crystal
manager = Native::Sensors::SensorManager.instance

# Check if the sensor hardware exists on this device
if manager.sensor_available?(Native::Sensors::SensorType::Gyroscope)
  manager.start_listening(Native::Sensors::SensorType::Gyroscope) do |data|
    puts "Gyro: #{data.x.round(4)}, #{data.y.round(4)}, #{data.z.round(4)}"
  end
else
  puts "This device has no gyroscope"
end

# Stop a specific sensor
manager.stop_listening(Native::Sensors::SensorType::Gyroscope)

# Stop all active sensors at once
manager.stop_all
```

---

## Stopping sensors in lifecycle callbacks

Sensors run continuously and drain battery. Always stop them when your app goes to the background:

```crystal
def on_pause
  Native::Sensors::SensorManager.instance.stop_all
end

def on_resume
  # restart only the sensors you need
  Native::Sensors::Sensor.accelerometer { |data| handle_accel(data) }
end

def on_destroy
  Native::Sensors::SensorManager.instance.stop_all
end
```

---

## Real examples

### Shake detection

```crystal
class ShakeApp < Native::App
  SHAKE_THRESHOLD = 15.0   # m/s² — tune to taste
  GRAVITY         = 9.81

  def setup
    @label = Native::UI::TextView.new("Shake the phone!")
    @label.text_size = 22
    @label.center

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(@label)
    @root = layout

    Native::Sensors::Sensor.accelerometer(delay_us: 100_000) do |data|
      # Remove gravity to get user acceleration only
      net = Math.sqrt(data.x**2 + data.y**2 + data.z**2) - GRAVITY
      on_shake if net > SHAKE_THRESHOLD
    end
  end

  def on_shake
    @label.text = "Shake detected! 🎉"
    spawn { sleep 1.5; @label.text = "Shake the phone!" }
  end
end
```

### Tilt-based UI

```crystal
class TiltApp < Native::App
  def setup
    @tilt_label = Native::UI::TextView.new("Tilt: —")
    @tilt_label.text_size = 18
    @tilt_label.center

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(@tilt_label)
    @root = layout

    Native::Sensors::Sensor.accelerometer(delay_us: 100_000) do |data|
      # x < 0 = tilted left, x > 0 = tilted right
      direction = if data.x < -3.0
                    "← Left"
                  elsif data.x > 3.0
                    "→ Right"
                  elsif data.y > 5.0
                    "↑ Up"
                  elsif data.y < -5.0
                    "↓ Down"
                  else
                    "• Flat"
                  end
      @tilt_label.text = "Tilt: #{direction}"
    end
  end

  def on_pause
    Native::Sensors::SensorManager.instance.stop_all
  end
end
```

### Step counter using accelerometer

```crystal
class StepCounter < Native::App
  @[Preserve]
  property steps : Int32 = 0

  STEP_THRESHOLD = 12.0
  @last_peak : Bool = false

  def setup
    @steps_label = Native::UI::TextView.new("Steps: 0")
    @steps_label.text_size = 36
    @steps_label.center

    layout = Native::UI::LinearLayout.new
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(@steps_label)
    @root = layout

    Native::Sensors::Sensor.accelerometer(delay_us: 100_000) do |data|
      magnitude = Math.sqrt(data.x**2 + data.y**2 + data.z**2)

      if magnitude > STEP_THRESHOLD && !@last_peak
        @steps += 1
        @steps_label.text = "Steps: #{@steps}"
        @last_peak = true
      elsif magnitude < 9.0
        @last_peak = false
      end
    end
  end
end
```
