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
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return unless env && activity

      sensor_class = env.FindClass("android/hardware/Sensor")
      get_service = env.GetMethodID(env.GetObjectClass(activity), "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;")
      @@manager_ptr = env.CallObjectMethod(activity, get_service, env.NewStringUTF("sensor")).to_i64
    end

    private def init_ios
      @@manager_ptr = LibIOS.sensor_manager_init
    end

    def sensor_available?(type : SensorType) : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env && @@manager_ptr != 0_i64
        sensor_type = sensor_type_value(type)
        sensor_class = env.FindClass("android/hardware/Sensor")
        get_default_sensor = env.GetMethodID(env.GetObjectClass(@@manager_ptr), "getDefaultSensor", "(I)Landroid/hardware/Sensor;")
        sensor = env.CallObjectMethod(@@manager_ptr, get_default_sensor, sensor_type)
        return sensor != Pointer(Void).null
      {% elsif flag?(:native_ios) %}
        return LibIOS.sensor_available(type.value)
      {% else %}
        false
      {% end %}
    end

    def start_listening(type : SensorType, &callback : SensorData -> Nil)
      @@listeners[type] ||= [] of SensorData -> Nil
      @@listeners[type] << callback

      unless @@active_sensors[type]
        {% if flag?(:native_android) %}
          start_listening_android(type)
        {% elsif flag?(:native_ios) %}
          start_listening_ios(type)
        {% end %}
        @@active_sensors[type] = true
      end
    end

    private def start_listening_android(type)
      env = Native::Android::JNI.env
      return unless env && @@manager_ptr != 0_i64
      sensor_type = sensor_type_value(type)
      get_default = env.GetMethodID(env.GetObjectClass(@@manager_ptr), "getDefaultSensor", "(I)Landroid/hardware/Sensor;")
      sensor = env.CallObjectMethod(@@manager_ptr, get_default, sensor_type)
      if sensor != Pointer(Void).null
        listener_class = env.FindClass("com/nativecr/SensorListener")
        if listener_class != Pointer(Void).null
          callback_obj = env.NewObject(listener_class, env.GetMethodID(listener_class, "<init>", "(JI)V"), Pointer(Void).address.to_i64, type.value)
          register = env.GetMethodID(env.GetObjectClass(@@manager_ptr), "registerListener", "(Landroid/hardware/SensorEventListener;Landroid/hardware/Sensor;I)Z")
          env.CallBooleanMethod(@@manager_ptr, register, callback_obj, sensor, delay_us)
        end
      end
    end

    private def start_listening_ios(type)
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
      env = Native::Android::JNI.env
      return unless env && @@manager_ptr != 0_i64
      sensor_type = sensor_type_value(type)
      listener_class = env.FindClass("com/native/SensorListener")
      if listener_class != Pointer(Void).null
        callback_obj = env.GetStaticObjectField(listener_class, env.GetStaticFieldID(listener_class, "instance", "Lcom/native/SensorListener;"))
        unregister = env.GetMethodID(env.GetObjectClass(@@manager_ptr), "unregisterListener", "(Landroid/hardware/SensorEventListener;)V")
        env.CallVoidMethod(@@manager_ptr, unregister, callback_obj)
      end
    end

    private def stop_listening_ios(type)
      LibIOS.sensor_stop(type.value)
    end

    def stop_all
      @@listeners.each do |type|
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
      when SesnorType::Gytoscope     then 4
      when SensorType::Magnometer    then 3
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
      SensorManager.instance.start_listening(SensorType::Acclerometer, delay_us, &callback)
    end

    def self.gyroscope(delay_us : Int32 = 200000, &callback : SensorData -> Nil)
      SensorManager.instance.start_listening(SensorType::Gyroscope, delay_us, &callback)
    end

    def self.magnetometer(delay_us : Int32 = 200000, &callback : SensorData -> Nil)
      SensorManager.instance.start_listening(SensorType::Magnetometer, delay_us, &callback)
    end

    def self.light(delay_us : Int32 = 20000, &callback : SensorData -> NIl)
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
