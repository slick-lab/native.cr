# src/native/framework/location.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::Location
  enum LocationAccuracy
    High
    Balanced
    Low
    Passive
  end

  struct Location
    property latitude : Float64
    property longitude : Float64
    property altitude : Float64
    property accuracy : Float32
    property bearing : Float32
    property speed : Float32
    property timestamp : Int64
    property provider : String

    def initialize(@latitude = 0.0, @longitude = 0.0, @altitude = 0.0,
                   @accuracy = 0.0f32, @bearing = 0.0f32, @speed = 0.0f32,
                   @timestamp = 0_i64, @provider = "")
    end

    def distance_to(other : Location) : Float64
      rad_lat1 = latitude * Math::PI / 180
      rad_lat2 = other.latitude * Math::PI / 180
      delta_lat = (other.latitude - latitude) * Math::PI / 180
      delta_lon = (other.longitude - longitude) * Math::PI / 180

      a = Math.sin(delta_lat / 2) * Math.sin(delta_lat / 2) +
          Math.cos(rad_lat1) * Math.cos(rad_lat2) *
          Math.sin(delta_lon / 2) * Math.sin(delta_lon / 2)
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

      6371000 * c
    end
  end

  class LocationManager
    @@instance : LocationManager?
    @@listeners : Array(Location -> Nil) = [] of Location -> Nil
    @@error_listeners : Array(String -> Nil) = [] of String -> Nil
    @@is_listening : Bool = false
    @@last_location : Location?
    @@accuracy : LocationAccuracy = LocationAccuracy::Balanced
    @@min_distance : Float32 = 0.0f32
    @@min_time : Int64 = 0

    def self.instance : LocationManager
      @@instance ||= LocationManager.new
      @@instance.not_nil!
    end

    def initialize
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        location_class = env.find_class("com/nativecr/LocationHelper")
        if location_class == Pointer(Void).null
          return
        end

        init_method = env.get_static_method_id(location_class, "init", "(Landroid/app/Activity;)V")
        env.call_static_void_method(location_class, init_method, activity)
        env.delete_local_ref(location_class) unless location_class.null?

        setupCallbacks
      {% end %}
    end

    def start_updates(accuracy : LocationAccuracy = LocationAccuracy::Balanced,
                      min_distance : Float32 = 0.0f32,
                      min_time : Int64 = 0)
      return if @@is_listening

      @@accuracy = accuracy
      @@min_distance = min_distance
      @@min_time = min_time

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        location_class = env.find_class("com/nativecr/LocationHelper")
        return if location_class == Pointer(Void).null

        start_method = env.get_static_method_id(location_class, "startUpdates", "(IIFJ)V")
        env.call_static_void_method(location_class, start_method, accuracy.value, 0, min_distance, min_time)
        env.delete_local_ref(location_class) unless location_class.null?
      {% elsif flag?(:native_ios) %}
        LibIOS.location_start_updates(accuracy.value, min_distance, min_time)
      {% end %}

      @@is_listening = true
    end

    def stop_updates
      return unless @@is_listening

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        location_class = env.find_class("com/nativecr/LocationHelper")
        return if location_class == Pointer(Void).null

        stop_method = env.get_static_method_id(location_class, "stopUpdates", "()V")
        env.call_static_void_method(location_class, stop_method)
        env.delete_local_ref(location_class) unless location_class.null?
      {% elsif flag?(:native_ios) %}
        LibIOS.location_stop_updates
      {% end %}

      @@is_listening = false
    end

    def get_last_location : Location?
      if @@last_location
        return @@last_location
      end

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return nil unless env

        location_class = env.find_class("com/nativecr/LocationHelper")
        return nil if location_class == Pointer(Void).null

        get_method = env.get_static_method_id(location_class, "getLastLocation", "()Ljava/lang/String;")
        result = env.call_static_object_method(location_class, get_method)
        env.delete_local_ref(location_class) unless location_class.null?

        if result
          json = env.get_string_utf_chars(result, nil).to_s
          env.delete_local_ref(result)
          parse_location_json(json)
        else
          nil
        end
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.location_get_last
        if ptr
          json = String.new(ptr)
          LibIOS.free_string(ptr)
          parse_location_json(json)
        else
          nil
        end
      {% else %}
        nil
      {% end %}
    end

    def is_listening? : Bool
      @@is_listening
    end

    def on_location(&block : Location -> Nil)
      @@listeners << block
    end

    def on_error(&block : String -> Nil)
      @@error_listeners << block
    end

    private def setupCallbacks
      {% unless flag?(:native_android) %}
        return
      {% end %}
      JNIHelpers.with_env do |env|
        callback_obj = JNIHelpers.new_callback(env, "com/nativecr/LocationCallback", 0i64)
        return if callback_obj.null?

        begin
          JNIHelpers.call_static_void(env, "com/nativecr/LocationHelper", "setCallback", "(Lcom/nativecr/LocationCallback;)V", callback_obj)
        ensure
          env.delete_local_ref(callback_obj)
        end
      end
    end

    private def parse_location_json(json : String) : Location?
      begin
        data = JSON.parse(json)
        location = Location.new
        location.latitude = data["latitude"].as_f
        location.longitude = data["longitude"].as_f
        location.altitude = data["altitude"].as_f
        location.accuracy = data["accuracy"].as_f.to_f32
        location.bearing = data["bearing"].as_f.to_f32
        location.speed = data["speed"].as_f.to_f32
        location.timestamp = data["timestamp"].as_i
        location.provider = data["provider"].as_s
        location
      rescue
        nil
      end
    end

    def handleLocationUpdate(json : String)
      if loc = parse_location_json(json)
        @@last_location = loc
        @@listeners.each { |listener| listener.call(loc) }
      end
    end

    def handleError(error : String)
      @@error_listeners.each { |listener| listener.call(error) }
    end
  end

  module Locations
    def self.start_updates(accuracy : LocationAccuracy = LocationAccuracy::Balanced,
                           min_distance : Float32 = 0.0f32,
                           min_time : Int64 = 0,
                           &callback : Location -> Nil)
      LocationManager.instance.on_location(&callback)
      LocationManager.instance.start_updates(accuracy, min_distance, min_time)
    end

    def self.stop_updates
      LocationManager.instance.stop_updates
    end

    def self.get_last_location : Location?
      LocationManager.instance.get_last_location
    end

    def self.is_listening? : Bool
      LocationManager.instance.is_listening?
    end

    def self.on_error(&block : String -> Nil)
      LocationManager.instance.on_error(&block)
    end

    def self.distance_between(lat1 : Float64, lon1 : Float64, lat2 : Float64, lon2 : Float64) : Float64
      rad_lat1 = lat1 * Math::PI / 180
      rad_lat2 = lat2 * Math::PI / 180
      delta_lat = (lat2 - lat1) * Math::PI / 180
      delta_lon = (lon2 - lon1) * Math::PI / 180

      a = Math.sin(delta_lat / 2) * Math.sin(delta_lat / 2) +
          Math.cos(rad_lat1) * Math.cos(rad_lat2) *
          Math.sin(delta_lon / 2) * Math.sin(delta_lon / 2)
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

      6371000 * c
    end
  end
end
