# Location

native.cr gives you access to GPS and network-based location services through `Native::Location`.

> **Remember:** You must request the location permission before using any location feature. See the [Permissions guide](./permissions.md).

---

## Quick setup

```crystal
# 1. Request permission first
Native::Permissions::Permissions.location do |status|
  if status == Native::Permissions::PermissionStatus::Granted
    start_location_tracking
  end
end

def start_location_tracking
  Native::Location::Locations.start_updates do |location|
    puts "Lat: #{location.latitude}, Lon: #{location.longitude}"
    puts "Accuracy: #{location.accuracy} metres"
    puts "Speed: #{location.speed} m/s"
  end
end
```

---

## Location accuracy modes

| Mode | Description | Battery usage |
|---|---|---|
| `High` | GPS, most accurate | High |
| `Balanced` | Network + GPS (default) | Medium |
| `Low` | Network only | Low |
| `Passive` | Only receives updates from other apps | Very low |

```crystal
Native::Location::Locations.start_updates(
  accuracy: Native::Location::LocationAccuracy::High
) do |location|
  # ...
end
```

---

## Filtering updates

```crystal
Native::Location::Locations.start_updates(
  accuracy: Native::Location::LocationAccuracy::Balanced,
  min_distance: 10.0_f32,    # only update when moved at least 10 metres
  min_time: 5000_i64         # only update at most every 5 seconds (milliseconds)
) do |location|
  update_map(location)
end
```

---

## Getting the last known location

If you just need the most recent location without subscribing to updates:

```crystal
if loc = Native::Location::Locations.get_last_location
  puts "Last known: #{loc.latitude}, #{loc.longitude}"
else
  puts "No location available yet"
end
```

---

## Stopping updates

Always stop location updates when you no longer need them to save battery:

```crystal
Native::Location::Locations.stop_updates
```

A good pattern is to start in `on_resume` and stop in `on_pause`:

```crystal
def on_resume
  Native::Location::Locations.start_updates { |loc| update_ui(loc) }
end

def on_pause
  Native::Location::Locations.stop_updates
end
```

---

## Handling errors

```crystal
Native::Location::Locations.on_error do |error|
  puts "Location error: #{error}"
end
```

---

## The `Location` struct

Each update delivers a `Native::Location::Location` with these fields:

| Field | Type | Description |
|---|---|---|
| `latitude` | `Float64` | Degrees north/south |
| `longitude` | `Float64` | Degrees east/west |
| `altitude` | `Float64` | Metres above sea level |
| `accuracy` | `Float32` | Horizontal accuracy in metres |
| `bearing` | `Float32` | Direction of travel (degrees, 0 = north) |
| `speed` | `Float32` | Speed in metres/second |
| `timestamp` | `Int64` | Unix timestamp (milliseconds) |
| `provider` | `String` | `"gps"`, `"network"`, etc. |

---

## Calculating distance between two points

```crystal
# Distance in metres between two coordinates
metres = Native::Location::Locations.distance_between(
  lat1: 48.8566, lon1: 2.3522,    # Paris
  lat2: 51.5074, lon2: -0.1278    # London
)
puts "#{(metres / 1000).round(1)} km"
```

You can also call `distance_to` directly on a `Location` struct:

```crystal
paris = Native::Location::Location.new(latitude: 48.8566, longitude: 2.3522)
here  = Native::Location::Location.new(latitude: 51.5074, longitude: -0.1278)
metres = paris.distance_to(here)
```

---

## Check if location is being tracked

```crystal
if Native::Location::Locations.is_listening?
  puts "Already tracking"
end
```
