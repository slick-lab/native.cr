# Location

native.cr gives you access to the device GPS and network location through `Native::Location`. You can get one-time location fixes, subscribe to a continuous stream of updates, and calculate distances.

> **Always request permission first.** See the [Permissions guide](./permissions.md). Without permission the API returns nothing.

---

## Requesting permission

```crystal
Native::Permissions::Permissions.location do |status|
  if status == Native::Permissions::PermissionStatus::Granted
    start_tracking
  else
    show_alert("Location access is required for this feature.")
  end
end
```

---

## Subscribing to live updates

`Native::Location::Locations.start_updates` starts the GPS receiver and fires your block each time a new position is available.

```crystal
Native::Location::Locations.start_updates do |location|
  puts "Lat: #{location.latitude}"
  puts "Lon: #{location.longitude}"
  puts "Accuracy: #{location.accuracy} metres"
  puts "Speed: #{location.speed} m/s"
  puts "Bearing: #{location.bearing}°"
  puts "Provider: #{location.provider}"   # "gps", "network", etc.
end
```

### Accuracy modes

```crystal
Native::Location::Locations.start_updates(
  accuracy: Native::Location::LocationAccuracy::High      # GPS, most accurate
) { |loc| update_map(loc) }

Native::Location::Locations.start_updates(
  accuracy: Native::Location::LocationAccuracy::Balanced  # GPS + network (default)
) { |loc| update_map(loc) }

Native::Location::Locations.start_updates(
  accuracy: Native::Location::LocationAccuracy::Low       # network only, battery-saving
) { |loc| update_map(loc) }

Native::Location::Locations.start_updates(
  accuracy: Native::Location::LocationAccuracy::Passive   # piggyback on other apps
) { |loc| update_map(loc) }
```

| Mode | Source | Accuracy | Battery cost |
|---|---|---|---|
| `High` | GPS | 1–10 m | High |
| `Balanced` | GPS + network | 10–100 m | Medium |
| `Low` | Network / Wi-Fi | 100–1000 m | Low |
| `Passive` | Other apps | Varies | None |

### Filtering updates

Avoid getting flooded with updates by setting minimum thresholds:

```crystal
Native::Location::Locations.start_updates(
  accuracy:     Native::Location::LocationAccuracy::High,
  min_distance: 10.0_f32,    # only fire when moved ≥ 10 metres
  min_time:     5000_i64     # only fire at most once every 5 seconds (ms)
) do |location|
  update_map(location)
end
```

---

## Stopping updates

Always stop location updates when you no longer need them — GPS is one of the biggest battery drains on mobile.

```crystal
Native::Location::Locations.stop_updates
```

Best practice — start in `on_resume`, stop in `on_pause`:

```crystal
def on_resume
  Native::Location::Locations.start_updates { |loc| update_ui(loc) }
end

def on_pause
  Native::Location::Locations.stop_updates
end
```

---

## Getting the last known location (no subscription)

If you only need a one-time fix and are OK with a slightly stale result, use `get_last_location`. It returns the most recent location the device has cached — this is instant and uses no additional battery.

```crystal
if loc = Native::Location::Locations.get_last_location
  puts "Last known position: #{loc.latitude}, #{loc.longitude}"
  puts "As of: #{Time.unix_ms(loc.timestamp)}"
else
  puts "No cached location available — start tracking first"
end
```

---

## Handling errors

```crystal
Native::Location::Locations.on_error do |message|
  puts "Location error: #{message}"
  # Common causes:
  # - Permission denied
  # - GPS hardware off
  # - Device indoors with no signal
end
```

---

## Checking if tracking is active

```crystal
if Native::Location::Locations.is_listening?
  puts "Currently tracking"
end
```

---

## The `Location` struct

Each update delivers a `Native::Location::Location` value:

| Field | Type | Description |
|---|---|---|
| `latitude` | `Float64` | Degrees north (+) / south (−) |
| `longitude` | `Float64` | Degrees east (+) / west (−) |
| `altitude` | `Float64` | Metres above sea level |
| `accuracy` | `Float32` | Horizontal accuracy radius in metres (lower = better) |
| `bearing` | `Float32` | Direction of travel in degrees (0 = north, 90 = east) |
| `speed` | `Float32` | Speed in metres per second |
| `timestamp` | `Int64` | Unix timestamp in milliseconds |
| `provider` | `String` | `"gps"`, `"network"`, `"passive"`, etc. |

---

## Calculating distances

### Between two `Location` values

```crystal
here  = get_current_location
there = Native::Location::Location.new(
  latitude: 48.8566, longitude: 2.3522  # Paris
)

metres = here.distance_to(there)
km     = metres / 1000
puts "#{km.round(1)} km away"
```

### Between raw coordinates

```crystal
metres = Native::Location::Locations.distance_between(
  lat1: 48.8566, lon1: 2.3522,    # Paris
  lat2: 51.5074, lon2: -0.1278    # London
)

puts "Paris → London: #{(metres / 1000).round} km"
```

Both methods use the Haversine formula (great-circle distance, accurate to within ~0.3%).

---

## Real example — delivery tracker

```crystal
class DeliveryApp < Native::App
  @[Preserve]
  property destination : String = "Eiffel Tower, Paris"

  def setup
    set_background_color(255, 255, 255)

    @status  = Native::UI::TextView.new("Waiting for GPS…")
    @status.text_size = 16

    @distance = Native::UI::TextView.new("—")
    @distance.text_size = 28

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.addView(@status)
    layout.addView(@distance)
    @root = layout

    start_tracking_if_permitted
  end

  def start_tracking_if_permitted
    Native::Permissions::Permissions.location do |status|
      if status == Native::Permissions::PermissionStatus::Granted
        Native::Location::Locations.start_updates(
          accuracy:     Native::Location::LocationAccuracy::High,
          min_distance: 20.0_f32
        ) do |loc|
          on_location_update(loc)
        end

        Native::Location::Locations.on_error do |err|
          @status.text = "GPS error: #{err}"
        end
      else
        @status.text = "Location permission required"
      end
    end
  end

  def on_location_update(loc : Native::Location::Location)
    # Distance to destination (hardcoded for this example)
    dest = Native::Location::Location.new(
      latitude:  48.8584,
      longitude: 2.2945
    )
    metres = loc.distance_to(dest)

    if metres < 100
      @status.text   = "You have arrived!"
      @distance.text = "< 100 m"
    elsif metres < 1000
      @status.text   = "Almost there…"
      @distance.text = "#{metres.round} m"
    else
      @status.text   = "En route to #{@destination}"
      @distance.text = "#{(metres / 1000).round(1)} km"
    end
  end

  def on_pause
    Native::Location::Locations.stop_updates
  end

  def on_resume
    start_tracking_if_permitted
  end
end
```
