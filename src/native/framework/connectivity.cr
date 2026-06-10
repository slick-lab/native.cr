# src/native/framework/connectivity.cr

module Native::Connectivity
  enum NetworkType
    None
    WiFi
    Cellular
    Ethernet
    Bluetooth
    VPN
    Unknown
  end

  struct NetworkInfo
    property type : NetworkType
    property is_connected : Bool
    property is_metered : Bool
    property is_roaming : Bool
    property ssid : String
    property ip_address : String
    property signal_strength : Int32

    def initialize(@type = NetworkType::Unknown, @is_connected = false,
                   @is_metered = false, @is_roaming = false,
                   @ssid = "", @ip_address = "", @signal_strength = 0)
    end

    def is_wifi? : Bool
      @type == NetworkType::WiFi
    end

    def is_cellular? : Bool
      @type == NetworkType::Cellular
    end
  end

  class ConnectivityManager
    @@instance : ConnectivityManager?
    @@listeners : Array(NetworkInfo -> Nil) = [] of NetworkInfo -> Nil
    @@current_info : NetworkInfo = NetworkInfo.new
    @@is_monitoring : Bool = false

    def self.instance : ConnectivityManager
      @@instance ||= ConnectivityManager.new
      @@instance.not_nil!
    end

    def initialize
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        conn_class = env.FindClass("com/nativecr/ConnectivityHelper")
        if conn_class == Pointer(Void).null
          return
        end

        init_method = env.GetStaticMethodID(conn_class, "init", "(Landroid/app/Activity;)V")
        env.CallStaticVoidMethod(conn_class, init_method, activity)

        setupCallbacks
      elsif Native::Platform.ios?
        @@is_monitoring = true
      end
    end

    def get_network_info : NetworkInfo
      if Native::Platform.android?
        env = Native::Android::JNI.env
        return @@current_info unless env

        conn_class = env.FindClass("com/nativecr/ConnectivityHelper")
        return @@current_info if conn_class == Pointer(Void).null

        get_info = env.GetStaticMethodID(conn_class, "getNetworkInfo", "()Ljava/lang/String;")
        result = env.CallStaticObjectMethod(conn_class, get_info)

        if result
          json = env.GetStringUTFChars(result, nil).to_s
          env.DeleteLocalRef(result)
          parse_network_info_json(json)
        else
          @@current_info
        end
      elsif Native::Platform.ios?
        ptr = LibIOS.connectivity_get_info
        if ptr
          json = String.new(ptr)
          LibIOS.free_string(ptr)
          parse_network_info_json(json)
        else
          @@current_info
        end
      else
        @@current_info
      end
    end

    def is_connected? : Bool
      get_network_info.is_connected
    end

    def is_wifi? : Bool
      get_network_info.is_wifi?
    end

    def is_cellular? : Bool
      get_network_info.is_cellular?
    end

    def start_monitoring(&callback : NetworkInfo -> Nil)
      @@listeners << callback
      return if @@is_monitoring

      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env

        conn_class = env.FindClass("com/nativecr/ConnectivityHelper")
        return if conn_class == Pointer(Void).null

        start_mon = env.GetStaticMethodID(conn_class, "startMonitoring", "()V")
        env.CallStaticVoidMethod(conn_class, start_mon)
      elsif Native::Platform.ios?
        LibIOS.connectivity_start_monitoring
      end

      @@is_monitoring = true
    end

    def stop_monitoring
      return unless @@is_monitoring

      if Native::Platform.android?
        env = Native::Android::JNI.env
        return unless env

        conn_class = env.FindClass("com/nativecr/ConnectivityHelper")
        return if conn_class == Pointer(Void).null

        stop_mon = env.GetStaticMethodID(conn_class, "stopMonitoring", "()V")
        env.CallStaticVoidMethod(conn_class, stop_mon)
      elsif Native::Platform.ios?
        LibIOS.connectivity_stop_monitoring
      end

      @@is_monitoring = false
    end

    def on_network_change(&callback : NetworkInfo -> Nil)
      @@listeners << callback
    end

    private def setupCallbacks
      return unless Native::Platform.android?
      env = Native::Android::JNI.env
      return unless env

      callback_class = env.FindClass("com/nativecr/ConnectivityCallback")
      if callback_class == Pointer(Void).null
        return
      end

      callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

      conn_class = env.FindClass("com/nativecr/ConnectivityHelper")
      return if conn_class == Pointer(Void).null

      set_callback = env.GetStaticMethodID(conn_class, "setCallback", "(Lcom/nativecr/ConnectivityCallback;)V")
      env.CallStaticVoidMethod(conn_class, set_callback, callback_obj)
    end

    private def parse_network_info_json(json : String) : NetworkInfo
      info = NetworkInfo.new
      begin
        data = JSON.parse(json)
        info.type = NetworkType.from_value(data["type"].as_i)
        info.is_connected = data["connected"].as_bool
        info.is_metered = data["metered"].as_bool
        info.is_roaming = data["roaming"].as_bool
        info.ssid = data["ssid"].as_s
        info.ip_address = data["ip"].as_s
        info.signal_strength = data["signal"].as_i
      rescue
      end
      info
    end

    def handleNetworkChange(json : String)
      @@current_info = parse_network_info_json(json)
      @@listeners.each { |listener| listener.call(@@current_info) }
    end
  end

  module Connectivity
    def self.get_network_info : NetworkInfo
      ConnectivityManager.instance.get_network_info
    end

    def self.is_connected? : Bool
      ConnectivityManager.instance.is_connected?
    end

    def self.is_wifi? : Bool
      ConnectivityManager.instance.is_wifi?
    end

    def self.is_cellular? : Bool
      ConnectivityManager.instance.is_cellular?
    end

    def self.start_monitoring(&callback : NetworkInfo -> Nil)
      ConnectivityManager.instance.start_monitoring(&callback)
    end

    def self.stop_monitoring
      ConnectivityManager.instance.stop_monitoring
    end

    def self.on_network_change(&callback : NetworkInfo -> Nil)
      ConnectivityManager.instance.on_network_change(&callback)
    end
  end
end
