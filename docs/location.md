# Location

GPS and network location tracking.

---

## Request Permission

```crystal
Native::Permissions::Permissions.location do |status|
  if status == Native::Permissions::PermissionStatus::Granted
    start_tracking
  end
end
```

---

## Start Updates

```crystal
Native::Location::Locations.start_updates do |loc|
  puts "Lat: #{loc.latitude}"
  puts "Lon: #{loc.longitude}"
  puts "Accuracy: #{loc.accuracy}m"
end
```

### Accuracy Modes

```crystal
Native::Location::Locations.start_updates(
  accuracy: Native::Location::LocationAccuracy::High
)
```

| Mode | Source | Battery |
|------|--------|---------|
| High | GPS | High |
| Balanced | GPS + network | Medium |
| Low | Network | Low |

### Filter Updates

```crystal
Native::Location::Locations.start_updates(
  accuracy: Native::Location::LocationAccuracy::High,
  min_distance: 10.0_f32,
  min_time: 5000_i64
)
```

---

## Stop Updates

```crystal
Native::Location::Locations.stop_updates
```

Stop in `on_pause`:

```crystal
def on_pause
  Native::Location::Locations.stop_updates
end

def on_resume
  Native::Location::Locations.start_updates { |loc| update_ui(loc) }
end
```

---

## Last Known Location

```crystal
if loc = Native::Location::Locations.get_last_location
  puts "#{loc.latitude}, #{loc.longitude}"
end
```

---

## Distance Calculation

```crystal
here = Native::Location::Location.new(latitude: 48.8, longitude: 2.3)
there = Native::Location::Location.new(latitude: 51.5, longitude: -0.1)

distance = here.distance_to(there)  # meters
km = distance / 1000
```

---

## Location Fields

| Field | Type | Description |
|-------|------|-------------|
| latitude | Float64 | North/South |
| longitude | Float64 | East/West |
| altitude | Float64 | Meters above sea |
| accuracy | Float32 | Accuracy in meters |
| speed | Float32 | m/s |
| bearing | Float32 | Direction degrees |

---

## Example: Distance Tracker

```crystal
class TrackerApp < Native::App
  def setup
    @label = Native::UI::TextView.new("Waiting for GPS...")
    @root = @label
    
    Native::Permissions::Permissions.location do |status|
      if status == Native::Permissions::PermissionStatus::Granted
        Native::Location::Locations.start_updates(
          accuracy: Native::Location::LocationAccuracy::High
        ) { |loc| update_distance(loc) }
      end
    end
  end

  def update_distance(loc)
    destination = Native::Location::Location.new(
      latitude: 48.86, longitude: 2.30
    )
    meters = loc.distance_to(destination)
    @label.text = "#{(meters / 1000).round(1)} km away"
  end

  def on_pause
    Native::Location::Locations.stop_updates
  end
end
```
