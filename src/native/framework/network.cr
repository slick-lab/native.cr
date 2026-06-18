require "http/client"

module Native::Network
  enum Method
    GET
    POST
    PUT
    DELETE
    PATCH
    HEAD
  end

  struct Request
    property method : Method = Method::GET
    property url : String = ""
    property headers : Hash(String, String) = {} of String => String
    property body : String = ""
    property timeout : Float64 = 30.0
    property stream : Bool = false
    property chunk_handler : (Bytes -> Nil)? = nil

    def initialize
    end

    def add_header(key : String, value : String) : Nil
      @headers[key] = value
    end

    def json=(data : String)
      @body = data
      add_header("Content-Type", "application/json")
    end

    def form=(params : Hash(String, String))
      @body = params.map { |k, v| "#{URI.encode(k)}=#{URI.encode(v)}" }.join("&")
      add_header("Content-Type", "application/x-www-form-urlencoded")
    end

    def on_chunk(&block : Bytes -> Nil)
      @stream = true
      @chunk_handler = block
    end
  end

  # src/native/framework/network.cr

  struct Response
    property status_code : Int32 = 0
    property headers : Hash(String, String) = {} of String => String
    property body : String = ""
    property success : Bool = false
    property error : String? = nil

    def initialize
    end

    def ok? : Bool
      status_code >= 200 && status_code < 300
    end

    def client_error? : Bool
      status_code >= 400 && status_code < 500
    end

    def server_error? : Bool
      status_code >= 500 && status_code < 600
    end

    def json
      JSON.parse(body) if success
    end
  end

  class HTTPClient
    def initialize(@base_url : String = "")
    end

    def get(path : String, headers : Hash(String, String)? = nil, &block : Bytes -> Nil) : Response
      request = Request.new
      request.method = Method::GET
      request.url = build_url(path)
      request.headers = headers if headers
      request.stream = true
      request.chunk_handler = block
      execute(request)
    end

    def post(path : String, body : String = "", headers : Hash(String, String)? = nil) : Response
      request = Request.new
      request.method = Method::POST
      request.url = build_url(path)
      request.body = body
      request.headers = headers if headers
      execute(request)
    end

    def put(path : String, body : String = "", headers : Hash(String, String)? = nil) : Response
      request = Request.new
      request.method = Method::PUT
      request.url = build_url(path)
      request.body = body
      request.headers = headers if headers
      execute(request)
    end

    def delete(path : String, headers : Hash(String, String)? = nil) : Response
      request = Request.new
      request.method = Method::DELETE
      request.url = build_url(path)
      request.headers = headers if headers
      execute(request)
    end

    def request(request : Request) : Response
      execute(request)
    end

    private def build_url(path : String) : String
      if @base_url.empty?
        path
      else
        @base_url + (path.starts_with?("/") ? path : "/" + path)
      end
    end

    private def execute(request : Request) : Response
      {% if flag?(:native_android) %}
        execute_android(request)
      {% elsif flag?(:native_ios) %}
        execute_ios(request)
      {% else %}
        execute_desktop(request)
      {% end %}
    end

    private def execute_android(request : Request) : Response
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return Response.new(success: false, error: "JNI not available") unless env && activity

      if request.stream && request.chunk_handler
        execute_android_stream(request, env, activity)
      else
        execute_android_sync(request, env, activity)
      end
    end

    private def execute_android_sync(request : Request, env : Void*, activity : Void*) : Response
      url_string = env.new_string_utf(request.url)
      method_string = env.new_string_utf(request.method.to_s)

      headers_keys = env.new_object_array(request.headers.size, env.find_class("java/lang/String"), nil)
      headers_values = env.new_object_array(request.headers.size, env.find_class("java/lang/String"), nil)

      request.headers.each_with_index do |(key, value), i|
        env.set_object_array_element(headers_keys, i, env.new_string_utf(key))
        env.set_object_array_element(headers_values, i, env.new_string_utf(value))
      end

      body_string = env.new_string_utf(request.body)

      http_client_class = env.find_class("com/nativecr/HTTPClient")
      if http_client_class == Pointer(Void).null
        cleanup_android(env, url_string, method_string, headers_keys, headers_values, body_string)
        return Response.new(success: false, error: "HTTPClient class not found")
      end

      execute_method = env.get_static_method_id(http_client_class, "execute", "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;D)Ljava/lang/String;")
      if execute_method == Pointer(Void).null
        cleanup_android(env, url_string, method_string, headers_keys, headers_values, body_string)
        return Response.new(success: false, error: "execute method not found")
      end

      result = env.call_static_object_method(http_client_class, execute_method, url_string, method_string, headers_keys, headers_values, body_string, request.timeout)

      cleanup_android(env, url_string, method_string, headers_keys, headers_values, body_string)

      if result
        json = env.get_string_utf_chars(result, nil).to_s
        env.delete_local_ref(result)
        parse_response_json(json)
      else
        Response.new(success: false, error: "Request failed")
      end
    end

    private def execute_android_stream(request : Request, env : Void*, activity : Void*) : Response
      url_string = env.new_string_utf(request.url)
      method_string = env.new_string_utf(request.method.to_s)

      headers_keys = env.new_object_array(request.headers.size, env.find_class("java/lang/String"), nil)
      headers_values = env.new_object_array(request.headers.size, env.find_class("java/lang/String"), nil)

      request.headers.each_with_index do |(key, value), i|
        env.set_object_array_element(headers_keys, i, env.new_string_utf(key))
        env.set_object_array_element(headers_values, i, env.new_string_utf(value))
      end

      http_client_class = env.find_class("com/nativecr/HTTPClient")
      if http_client_class == Pointer(Void).null
        cleanup_android(env, url_string, method_string, headers_keys, headers_values)
        return Response.new(success: false, error: "HTTPClient class not found")
      end

      callback_class = env.find_class("com/nativecr/StreamCallback")
      if callback_class == Pointer(Void).null
        cleanup_android(env, url_string, method_string, headers_keys, headers_values)
        return Response.new(success: false, error: "StreamCallback class not found")
      end

      callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "()V"))

      stream_method = env.get_static_method_id(http_client_class, "executeStream", "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;[Ljava/lang/String;Lcom/nativecr/StreamCallback;D)V")
      if stream_method == Pointer(Void).null
        cleanup_android(env, url_string, method_string, headers_keys, headers_values)
        env.delete_local_ref(callback_obj)
        return Response.new(success: false, error: "executeStream method not found")
      end

      env.call_static_void_method(http_client_class, stream_method, url_string, method_string, headers_keys, headers_values, callback_obj, request.timeout)

      cleanup_android(env, url_string, method_string, headers_keys, headers_values)
      env.delete_local_ref(callback_obj)

      Response.new(success: true, status_code: 200)
    end

    private def execute_ios(request : Request) : Response
      if request.stream && request.chunk_handler
        execute_ios_stream(request)
      else
        execute_ios_sync(request)
      end
    end

    private def execute_ios_sync(request : Request) : Response
      headers_json = request.headers.to_json
      ptr = LibIOS.http_request(request.url.to_utf8, request.method.to_s.to_utf8, headers_json.to_utf8, request.body.to_utf8, request.timeout)
      if ptr
        json = String.new(ptr)
        LibIOS.free_string(ptr)
        parse_response_json(json)
      else
        Response.new(success: false, error: "Request failed")
      end
    end

    private def execute_ios_stream(request : Request) : Response
      headers_json = request.headers.to_json
      LibIOS.http_request_stream(request.url.to_utf8, request.method.to_s.to_utf8, headers_json.to_utf8, request.body.to_utf8, request.timeout)
      Response.new(success: true, status_code: 200)
    end

    private def execute_desktop(request : Request) : Response
      if request.stream && request.chunk_handler
        execute_desktop_stream(request)
      else
        execute_desktop_sync(request)
      end
    end

    private def execute_desktop_sync(request : Request) : Response
      begin
        http_method = case request.method
                      when Method::GET    then HTTP::Method::GET
                      when Method::POST   then HTTP::Method::POST
                      when Method::PUT    then HTTP::Method::PUT
                      when Method::DELETE then HTTP::Method::DELETE
                      when Method::PATCH  then HTTP::Method::PATCH
                      when Method::HEAD   then HTTP::Method::HEAD
                      end

        http_response = HTTP::Client.exec(
          method: http_method,
          url: request.url,
          headers: HTTP::Headers.new(request.headers),
          body: request.body
        )

        Response.new(
          status_code: http_response.status_code,
          headers: http_response.headers.to_h,
          body: http_response.body,
          success: true
        )
      rescue ex
        Response.new(success: false, error: ex.message)
      end
    end

    private def execute_desktop_stream(request : Request) : Response
      begin
        http_method = case request.method
                      when Method::GET    then HTTP::Method::GET
                      when Method::POST   then HTTP::Method::POST
                      when Method::PUT    then HTTP::Method::PUT
                      when Method::DELETE then HTTP::Method::DELETE
                      when Method::PATCH  then HTTP::Method::PATCH
                      when Method::HEAD   then HTTP::Method::HEAD
                      end

        HTTP::Client.get(request.url, headers: HTTP::Headers.new(request.headers)) do |response|
          handler = request.chunk_handler
          if handler
            response.body_io.each_byte do |byte|
              handler.call(Bytes[byte])
            end
          end
        end

        Response.new(success: true, status_code: 200)
      rescue ex
        Response.new(success: false, error: ex.message)
      end
    end

    private def cleanup_android(env : Void*, url : Void*, method : Void*, keys : Void*, values : Void*, body : Void*? = nil)
      env.delete_local_ref(url)
      env.delete_local_ref(method)
      env.delete_local_ref(keys)
      env.delete_local_ref(values)
      env.delete_local_ref(body) if body
    end

    private def parse_response_json(json : String) : Response
      begin
        data = JSON.parse(json)
        Response.new(
          status_code: data["status"].as_i,
          body: data["body"].as_s,
          success: data["success"].as_bool
        )
      rescue
        Response.new(success: false, error: "Failed to parse response")
      end
    end
  end

  module HTTP
    def self.get(url : String, &block : Bytes -> Nil) : Response
      HTTPClient.new.get(url, &block)
    end

    def self.get(url : String) : Response
      HTTPClient.new.get(url)
    end

    def self.post(url : String, body : String = "") : Response
      HTTPClient.new.post(url, body)
    end

    def self.put(url : String, body : String = "") : Response
      HTTPClient.new.put(url, body)
    end

    def self.delete(url : String) : Response
      HTTPClient.new.delete(url)
    end
  end

  class WebSocket
    @on_open : -> Nil
    @on_message : String -> Nil
    @on_chunk : Bytes -> Nil
    @on_error : String -> Nil
    @on_close : Int32, String -> Nil

    def initialize(@url : String)
      @on_open = nil
      @on_message = nil
      @on_chunk = nil
      @on_error = nil
      @on_close = nil
    end

    def on_open(&block : -> Nil) : Nil
      @on_open = block
    end

    def on_message(&block : String -> Nil) : Nil
      @on_message = block
    end

    def on_chunk(&block : Bytes -> Nil) : Nil
      @on_chunk = block
    end

    def on_error(&block : String -> Nil) : Nil
      @on_error = block
    end

    def on_close(&block : Int32, String -> Nil) : Nil
      @on_close = block
    end

    def connect : Nil
      {% if flag?(:native_android) %}
        connect_android
      {% elsif flag?(:native_ios) %}
        connect_ios
      {% end %}
    end

    def send(text : String) : Nil
      {% if flag?(:native_android) %}
        send_android(text)
      {% elsif flag?(:native_ios) %}
        send_ios(text)
      {% end %}
    end

    def send_binary(data : Bytes) : Nil
      {% if flag?(:native_android) %}
        send_binary_android(data)
      {% elsif flag?(:native_ios) %}
        send_binary_ios(data)
      {% end %}
    end

    def close : Nil
      {% if flag?(:native_android) %}
        close_android
      {% elsif flag?(:native_ios) %}
        close_ios
      {% end %}
    end

    private def connect_android : Nil
      env = Native::Android::JNI.env
      activity = Native::Android::JNI.activity
      return unless env && activity

      ws_class = env.find_class("com/nativecr/WebSocketClient")
      if ws_class == Pointer(Void).null
        @on_error.try &.call("WebSocket class not found")
        return
      end

      connect_method = env.get_static_method_id(ws_class, "connect", "(Landroid/app/Activity;Ljava/lang/String;)J")
      if connect_method == Pointer(Void).null
        @on_error.try &.call("connect method not found")
        return
      end

      env.call_static_long_method(ws_class, connect_method, activity, env.new_string_utf(@url))
    end

    private def connect_ios : Void
      LibIOS.websocket_connect(@url.to_utf8)
    end

    private def send_android(text : String) : Void
    end

    private def send_ios(text : String) : Void
      LibIOS.websocket_send_text(text.to_utf8)
    end

    private def send_binary_android(data : Bytes) : Void
    end

    private def send_binary_ios(data : Bytes) : Void
      LibIOS.websocket_send_binary(data, data.size)
    end

    private def close_android : Void
    end

    private def close_ios : Void
      LibIOS.websocket_close
    end
  end
end
