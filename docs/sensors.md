# Sensors

native.cr gives you access to hardware sensors on the device through `Native::Sensors`.

---

## Available sensors

| Sensor | What it measures |
|---|---|
| Accelerometer | Linear acceleration (movement, tilt) — x, y, z in m/s² |
| Gyroscope | Rotation rate — x, y, z in radians/second |
| Magnetometer | Magnetic field strength — x, y, z in μT |
| Light | Ambient light level in lux |
| Proximity | Distance to nearby object (near/far) |
| Pressure | Atmospheric pressure in hPa |
| Temperature | Ambient temperature in °C |
| Humidity | Relative humidity in % |

---

## Listening to a sensor

Use the shortcut methods in `Native::Sensors::Sensor`:

```crystal
# Accelerometer — fires every 200ms by default
Native::Sensors::Sensor.accelerometer do |data|
  puts "X: #{data.x}  Y: #{data.y}  Z: #{data.z}"
end

# Gyroscope
Native::Sensors::Sensor.gyroscope do |data|
  puts "Rotation X: #{data.x}"
end

# Magnetometer
Native::Sensors::Sensor.magnetometer do |data|
  puts "Magnetic X: #{data.x}"
end

# Light sensor
Native::Sensors::Sensor.light do |data|
  puts "Light: #{data.values[0]} lux"
end

# Proximity
Native::Sensors::Sensor.proximity do |data|
  puts "Near: #{data.values[0] < 5}"
end

# Pressure
Native::Sensors::Sensor.pressure do |data|
  puts "Pressure: #{data.values[0]} hPa"
end

# Temperature
Native::Sensors::Sensor.temperature do |data|
  puts "Temp: #{data.values[0]} °C"
end

# Humidity
Native::Sensors::Sensor.humidity do |data|
  puts "Humidity: #{data.values[0]}%"
end
```

---

## Controlling the update rate

The `delay_us` parameter controls how often you get updates, in **microseconds**:

```crystal
# 50,000 µs = 50ms ≈ 20 times per second (good for games)
Native::Sensors::Sensor.accelerometer(delay_us: 50_000) do |data|
  update_game_physics(data.x, data.y, data.z)
end

# 500,000 µs = 500ms = 2 times per second (good for battery saving)
Native::Sensors::Sensor.accelerometer(delay_us: 500_000) do |data|
  detect_shake(data)
end
```

Default is 200,000 µs (5 times per second).

---

## The `SensorData` struct

Each sensor callback receives a `Native::Sensors::SensorData`:

| Field | Type | Description |
|---|---|---|
| `type` | `SensorType` | Which sensor fired |
| `timestamp` | `Int64` | When the reading was taken (nanoseconds) |
| `values` | `Array(Float64)` | Raw sensor values |
| `accuracy` | `Int32` | Accuracy level (0 = unreliable, 3 = high) |
| `x` | `Float64` | Shortcut for `values[0]` |
| `y` | `Float64` | Shortcut for `values[1]` |
| `z` | `Float64` | Shortcut for `values[2]` |

---

## Using `SensorManager` directly

For more control (e.g. checking availability, stopping individual sensors):

```crystal
manager = Native::Sensors::SensorManager.instance

# Check if the sensor exists on this device
if manager.sensor_available?(Native::Sensors::SensorType::Gyroscope)
  manager.start_listening(Native::Sensors::SensorType::Gyroscope) do |data|
    puts "Gyro: #{data.x}, #{data.y}, #{data.z}"
  end
end

# Stop a specific sensor
manager.stop_listening(Native::Sensors::SensorType::Gyroscope)

# Stop all sensors
manager.stop_all
```

---

## Practical example — shake detection

```crystal
class MyApp < Native::App
  SHAKE_THRESHOLD = 15.0

  def setup
    Native::Sensors::Sensor.accelerometer(delay_us: 100_000) do |data|
      magnitude = Math.sqrt(data.x**2 + data.y**2 + data.z**2) - 9.8
      if magnitude > SHAKE_THRESHOLD
        on_shake_detected
      end
    end
  end

  def on_shake_detected
    puts "Shake!"
    # reset score, shuffle items, etc.
  end
end
```

---

## Battery tip

Sensors run continuously and drain the battery. Stop them when the app goes into the background:

```crystal
def on_pause
  Native::Sensors::SensorManager.instance.stop_all
end

def on_resume
  Native::Sensors::Sensor.accelerometer { |data| handle_data(data) }
end
```
