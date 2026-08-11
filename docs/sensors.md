# Sensors

Device hardware sensors: accelerometer, gyroscope, magnetometer, light, proximity, etc.

---

## Available Sensors

| Sensor | What it measures |
|--------|------------------|
| Accelerometer | m/s² (x, y, z) |
| Gyroscope | rad/s rotation |
| Magnetometer | µT magnetic field |
| Light | lux |
| Proximity | cm distance |
| Pressure | hPa |
| Temperature | °C |
| Humidity | % |

---

## Quick Start

```crystal
Native::Sensors::Sensor.accelerometer do |data|
  puts "X: #{data.x}, Y: #{data.y}, Z: #{data.z}"
end

Native::Sensors::Sensor.gyroscope { |d| puts d.x }
Native::Sensors::Sensor.light { |d| puts d.values[0] }
Native::Sensors::Sensor.proximity { |d| puts d.values[0] }
```

---

## Update Rate

Control via `delay_us` (microseconds):

```crystal
# 20 updates/second (fast for games)
Native::Sensors::Sensor.accelerometer(delay_us: 50_000) { |d| update(d) }

# 1 update/second (slow for temperature)
Native::Sensors::Sensor.temperature(delay_us: 1_000_000) { |d| show(d) }
```

---

## SensorData

Every callback receives `SensorData`:

| Field | Type | Description |
|-------|------|-------------|
| `x`, `y`, `z` | Float64 | Axis values |
| `values` | Array | All readings |
| `accuracy` | Int32 | 0-3 quality |
| `timestamp` | Int64 | Nanoseconds |

---

## SensorManager

```crystal
manager = Native::Sensors::SensorManager.instance

if manager.sensor_available?(Native::Sensors::SensorType::Gyroscope)
  manager.start_listening(Native::Sensors::SensorType::Gyroscope) { |d| use(d) }
end

manager.stop_all
```

---

## Lifecycle

Stop sensors to save battery:

```crystal
def on_pause
  Native::Sensors::SensorManager.instance.stop_all
end

def on_resume
  Native::Sensors::Sensor.accelerometer { |d| handle(d) }
end
```

---

## Example: Shake Detection

```crystal
class ShakeApp < Native::App
  THRESHOLD = 15.0

  def setup
    @label = Native::UI::TextView.new("Shake me!")
    @root = @label

    Native::Sensors::Sensor.accelerometer(delay_us: 100_000) do |d|
      net = Math.sqrt(d.x**2 + d.y**2 + d.z**2) - 9.81
      shake if net > THRESHOLD
    end
  end

  def shake
    @label.text = "Shake detected!"
  end

  def on_pause
    Native::Sensors::SensorManager.instance.stop_all
  end
end
```

---

## Example: Step Counter

```crystal
class StepApp < Native::App
  @[Preserve]
  property steps : Int32 = 0

  def setup
    @label = Native::UI::TextView.new("Steps: 0")
    @root = @label

    Native::Sensors::Sensor.accelerometer(delay_us: 100_000) do |d|
      mag = Math.sqrt(d.x**2 + d.y**2 + d.z**2)
      if mag > 12.0 && !@peak
        @steps += 1
        @label.text = "Steps: #{@steps}"
        @peak = true
      elsif mag < 9.0
        @peak = false
      end
    end
  end
end
```
