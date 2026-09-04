# src/native/framework/sensors.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.
# Also fixed: two double-comma syntax errors in the JNI calls, misnamed
# enum members (SesnorType::Gytoscope etc.), a wrong callback class path
# (com/native/ instead of com/nativecr/), a `-> NIl` return annotation,
# and delay_us being used without ever being a parameter.

module Native::Sensors
  enum SensorType
    Accelerometer
    Gyroscope
    Magnetometer
    Light
    Proximity
    Pressure
    Temperature
    Humidity
  end

  struct SensorData
    property type : SensorType = SensorType::Accelerometer
    property timestamp : Int64
    property values : Array(Float64)
    property accuracy : Int32

    def initialize(type : SensorType, @timestamp = 0_i64, @values = [] of Float64, @accuracy = 0)
    end

    def x : Float64
      values.size > 0 ? values[0] : 0.0
    end

    def y : Float64
      values.size > 1 ? values[1] : 0.0
    end

    def z : Float64
      values.size > 2 ? values[2] : 0.0
    end
  end

  class SensorManager
    @@instance : SensorManager?
    @@listeners : Hash(SensorType, Array(SensorData -> Nil)) = {} of SensorType => Array(SensorData -> Nil)
    @@active_sensors : Hash(SensorType, Bool) = {} of SensorType => Bool
    @@manager_ptr : Int64 = 0_i64

    def self.instance : SensorManager
      @@instance ||= SensorManager.new
      @@instance.not_nil!
    end

    def initialize
      {% if flag?(:native_android) %}
        init_android
      {% elsif flag?(:native_ios) %}
        init_ios
      {% end %}
    end

    private def init_android
      JNIHelpers.with_env do |env|
        activity = Native::Android::JNI.activity
        return unless activity

        @@manager_ptr = JNIHelpers.with_jstring(env, "sensor") do |jname|
          JNIHelpers.call_object(env, activity.to_i64, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;", jname)
        end.to_i64
      end
    end

    private def init_ios
      @@manager_ptr = LibIOS.sensor_manager_init
    end

    def sensor_available?(type : SensorType) : Bool
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          return false if @@manager_ptr == 0_i64
          sensor = JNIHelpers.call_object(env, @@manager_ptr, "getDefaultSensor", "(I)Landroid/hardware/Sensor;", sensor_type_value(type))
          !sensor.null?
        end
      {% elsif flag?(:native_ios) %}
        LibIOS.sensor_available(type.value)
      {% else %}
        false
      {% end %}
    end

    def start_listening(type : SensorType, delay_us : Int32 = 200000, &callback : SensorData -> Nil)
      @@listeners[type] ||= [] of SensorData -> Nil
      @@listeners[type] << callback

      unless @@active_sensors[type]
        {% if flag?(:native_android) %}
          start_listening_android(type, delay_us)
        {% elsif flag?(:native_ios) %}
          start_listening_ios(type, delay_us)
        {% end %}
        @@active_sensors[type] = true
      end
    end

    private def start_listening_android(type, delay_us : Int32)
      JNIHelpers.with_env do |env|
        return if @@manager_ptr == 0_i64
        sensor = JNIHelpers.call_object(env, @@manager_ptr, "getDefaultSensor", "(I)Landroid/hardware/Sensor;", sensor_type_value(type))
        return if sensor.null?
        begin
          listener = JNIHelpers.with_class(env, "com/nativecr/SensorListener") do |listener_class|
            next Pointer(Void).null if listener_class.null?
            ctor = env.get_method_id(listener_class, "<init>", "(JI)V")
            next Pointer(Void).null if ctor.null?
            env.new_object(listener_class, ctor, 0i64, type.value)
          end
          next if listener.null?
          begin
            JNIHelpers.call_boolean(
              env, @@manager_ptr, "registerListener",
              "(Landroid/hardware/SensorEventListener;Landroid/hardware/Sensor;I)Z",
              listener, sensor, delay_us
            )
          ensure
            env.delete_local_ref(listener)
          end
        ensure
          env.delete_local_ref(sensor)
        end
      end
    end

    private def start_listening_ios(type, delay_us : Int32)
      LibIOS.sensor_start(type.value, delay_us)
    end

    def stop_listening(type : SensorType)
      @@listeners[type] = [] of SensorData -> Nil
      @@active_sensors[type] = false

      {% if flag?(:native_android) %}
        stop_listening_android(type)
      {% elsif flag?(:native_ios) %}
        stop_listening_ios(type)
      {% end %}
    end

    private def stop_listening_android(type)
      JNIHelpers.with_env do |env|
        return if @@manager_ptr == 0_i64
        listener = JNIHelpers.with_class(env, "com/nativecr/SensorListener") do |listener_class|
          next Pointer(Void).null if listener_class.null?
          fid = env.get_static_field_id(listener_class, "instance", "Lcom/nativecr/SensorListener;")
          fid.null? ? Pointer(Void).null : env.get_static_object_field(listener_class, fid)
        end
        return if listener.null?
        begin
          JNIHelpers.call_void(env, @@manager_ptr, "unregisterListener", "(Landroid/hardware/SensorEventListener;)V", listener)
        ensure
          env.delete_local_ref(listener)
        end
      end
    end

    private def stop_listening_ios(type)
      LibIOS.sensor_stop(type.value)
    end

    def stop_all
      @@listeners.each_key do |type|
        stop_listening(type)
      end
      @@listeners.clear
    end

    def on_sensor_data(type : SensorType, values : Array(Float64), timestamp : Int64, accuracy : Int32)
      data = SensorData.new(type, timestamp, values, accuracy)
      if callbacks = @@listeners[type]?
        callbacks.each { |cb| cb.call(data) }
      end
    end

    private def sensor_type_value(type : SensorType) : Int32
      case type
      when SensorType::Accelerometer then 1
      when SensorType::Gyroscope     then 4
      when SensorType::Magnetometer  then 3
      when SensorType::Light         then 5
      when SensorType::Proximity     then 8
      when SensorType::Pressure      then 6
      when SensorType::Temperature   then 7
      when SensorType::Humidity      then 12
      else
        1
      end
    end
  end

  module Sensor
    def self.accelerometer(delay_us : Int32 = 200000, &callback : SensorData -> Nil)
      SensorManager.instance.start_listening(SensorType::Accelerometer, delay_us, &callback)
    end

    def self.gyroscope(delay_us : Int32 = 200000, &callback : SensorData -> Nil)
      SensorManager.instance.start_listening(SensorType::Gyroscope, delay_us, &callback)
    end

    def self.magnetometer(delay_us : Int32 = 200000, &callback : SensorData -> Nil)
      SensorManager.instance.start_listening(SensorType::Magnetometer, delay_us, &callback)
    end

    def self.light(delay_us : Int32 = 20000, &callback : SensorData -> Nil)
      SensorManager.instance.start_listening(SensorType::Light, delay_us, &callback)
    end

    def self.proximity(delay_us : Int32 = 200000, &callback : SensorData -> Nil)
      SensorManager.instance.start_listening(SensorType::Proximity, delay_us, &callback)
    end

    def self.pressure(delay_us : Int32 = 200000, &callback : SensorData -> Nil)
      SensorManager.instance.start_listening(SensorType::Pressure, delay_us, &callback)
    end

    def self.temperature(delay_us : Int32 = 200000, &callback : SensorData -> Nil)
      SensorManager.instance.start_listening(SensorType::Temperature, delay_us, &callback)
    end

    def self.humidity(delay_us : Int32 = 200000, &callback : SensorData -> Nil)
      SensorManager.instance.start_listening(SensorType::Humidity, delay_us, &callback)
    end
  end
end
