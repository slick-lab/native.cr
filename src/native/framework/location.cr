# src/native/framework/location.cr

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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        location_class = env.FindClass("com/nativecr/LocationHelper")
        if location_class == Pointer(Void).null
          return
        end

        init_method = env.GetStaticMethodID(location_class, "init", "(Landroid/app/Activity;)V")
        env.CallStaticVoidMethod(location_class, init_method, activity)

        setupCallbacks
      end
    end

    def start_updates(accuracy : LocationAccuracy = LocationAccuracy::Balanced,
                      min_distance : Float32 = 0.0f32,
                      min_time : Int64 = 0)
      return if @@is_listening

      @@accuracy = accuracy
      @@min_distance = min_distance
      @@min_time = min_time

      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env

        location_class = env.FindClass("com/nativecr/LocationHelper")
        return if location_class == Pointer(Void).null

        start_method = env.GetStaticMethodID(location_class, "startUpdates", "(IIFJ)V")
        env.CallStaticVoidMethod(location_class, start_method, accuracy.value, 0, min_distance, min_time)
      elsif Native::Platform.ios?
        LibIOS.location_start_updates(accuracy.value, min_distance, min_time)
      end

      @@is_listening = true
    end

    def stop_updates
      return unless @@is_listening

      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env

        location_class = env.FindClass("com/nativecr/LocationHelper")
        return if location_class == Pointer(Void).null

        stop_method = env.GetStaticMethodID(location_class, "stopUpdates", "()V")
        env.CallStaticVoidMethod(location_class, stop_method)
      elsif Native::Platform.ios?
        LibIOS.location_stop_updates
      end

      @@is_listening = false
    end

    def get_last_location : Location?
      if @@last_location
        return @@last_location
      end

      if Native::Platform.android?
        env = Native::Android::JNI.env
        return nil unless env

        location_class = env.FindClass("com/nativecr/LocationHelper")
        return nil if location_class == Pointer(Void).null

        get_method = env.GetStaticMethodID(location_class, "getLastLocation", "()Ljava/lang/String;")
        result = env.CallStaticObjectMethod(location_class, get_method)

        if result
          json = env.GetStringUTFChars(result, nil).to_s
          env.DeleteLocalRef(result)
          parse_location_json(json)
        else
          nil
        end
      elsif Native::Platform.ios?
        ptr = LibIOS.location_get_last
        if ptr
          json = String.new(ptr)
          LibIOS.free_string(ptr)
          parse_location_json(json)
        else
          nil
        end
      else
        nil
      end
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
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env

      callback_class = env.FindClass("com/nativecr/LocationCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      location_class = env.FindClass("com/nativecr/LocationHelper")
      return if location_class == Pointer(Void).null

      set_callback = env.GetStaticMethodID(location_class, "setCallback", "(Lcom/nativecr/LocationCallback;)V")
      env.CallStaticVoidMethod(location_class, set_callback, callback_obj)
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

  module Location
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
