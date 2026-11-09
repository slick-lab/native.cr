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
    # Optional completion/error hooks for streaming requests. Chunks arrive
    # via chunk_handler; the final status via on_complete, transport errors
    # via on_error. Only meaningful together with stream = true.
    property on_complete : (Int32 -> Nil)? = nil
    property on_error : (String -> Nil)? = nil

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
      @body = params.map { |k, v| "#{URI.encode_www_form(k)}=#{URI.encode_www_form(v)}" }.join("&")
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

    # Named-arg constructor: every execute_* error path builds a Response
    # with named args. Those call sites were never compiled before
    # (Crystal only type-checks reachable code, and no spec or example
    # reached them) — an empty initialize would have rejected them.
    def initialize(*, status_code : Int32 = 0,
                   headers : Hash(String, String)? = nil,
                   body : String = "",
                   success : Bool = false,
                   error : String? = nil)
      @status_code = status_code
      @headers = headers || {} of String => String
      @body = body
      @success = success
      @error = error
    end

    # Parses the JSON envelope produced by the mobile backends
    # (HTTPClient.java / NativeServices.swift):
    # {"status":int,"headers":{str:str},"body":str,"success":bool,"error":str?}
    def self.from_json(json : String) : Response
      data = JSON.parse(json)
      headers = {} of String => String
      if raw = data["headers"]?.try(&.as_h?)
        raw.each { |key, value| headers[key] = value.as_s }
      end
      Response.new(
        status_code: data["status"]?.try(&.as_i?) || 0,
        headers: headers,
        body: data["body"]?.try(&.as_s?) || "",
        success: data["success"]?.try(&.as_bool?) || false,
        error: data["error"]?.try(&.as_s?)
      )
    rescue
      Response.new(success: false, error: "Failed to parse response")
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

    # ── Streaming registry ────────────────────────────────────────────────────
    # Streaming requests are asynchronous: the platform backends deliver
    # chunks/status/errors through dispatch_stream_* with the handle
    # returned by register_stream. The same registry serves the Android
    # JNI dispatch funs, the iOS trampolines and the desktop path.
    @@streams = {} of Int64 => Request
    # iOS hands the handle to Swift inside a Box; the box must stay
    # heap-reachable for as long as the stream is in flight.
    @@stream_boxes = {} of Int64 => Void*
    @@next_handle = Atomic(Int64).new(0)
    # Registry access happens on the Crystal thread and, on Android,
    # the Java stream dispatcher thread. A spinlock is enough (sections
    # are a handful of instructions) and user callbacks always run
    # OUTSIDE it, so handlers may perform their own requests.
    @@streams_lock = Atomic(Int32).new(0)

    private def self.lock_streams : Nil
      until @@streams_lock.compare_and_set(0, 1)[1]
      end
    end

    private def self.unlock_streams : Nil
      @@streams_lock.set(0)
    end

    def self.register_stream(request : Request) : Int64
      handle = @@next_handle.add(1).to_i64
      lock_streams
      begin
        @@streams[handle] = request
      ensure
        unlock_streams
      end
      handle
    end

    # Roots the box carrying `handle` into Swift so the GC keeps it alive
    # for as long as the stream is registered.
    def self.root_stream_box(handle : Int64, box : Void*) : Nil
      lock_streams
      begin
        @@stream_boxes[handle] = box if @@streams.has_key?(handle)
      ensure
        unlock_streams
      end
    end

    def self.unregister_stream(handle : Int64) : Nil
      lock_streams
      begin
        @@streams.delete(handle)
        @@stream_boxes.delete(handle)
      ensure
        unlock_streams
      end
    end

    def self.dispatch_stream_chunk(handle : Int64, data : Bytes) : Nil
      handler = nil
      lock_streams
      begin
        request = @@streams[handle]?
        handler = request.chunk_handler if request
      ensure
        unlock_streams
      end
      handler.try(&.call(data))
    end

    def self.dispatch_stream_complete(handle : Int64, status : Int32) : Nil
      handler = nil
      lock_streams
      begin
        request = @@streams[handle]?
        handler = request.on_complete if request
        @@streams.delete(handle)
        @@stream_boxes.delete(handle)
      ensure
        unlock_streams
      end
      handler.try(&.call(status))
    end

    def self.dispatch_stream_error(handle : Int64, error : String) : Nil
      handler = nil
      lock_streams
      begin
        request = @@streams[handle]?
        handler = request.on_error if request
        @@streams.delete(handle)
        @@stream_boxes.delete(handle)
      ensure
        unlock_streams
      end
      handler.try(&.call(error))
    end

    def get(path : String, headers : Hash(String, String)? = nil) : Response
      request = Request.new
      request.method = Method::GET
      request.url = build_url(path)
      request.headers = headers if headers
      execute(request)
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

    private def execute_android_sync(request : Request, env : Native::Android::JNIEnvWrapper, activity : Void*) : Response
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
      env.delete_local_ref(http_client_class) unless http_client_class.null?

      # cleanup_android already released url/method/body and both header
      # arrays — deleting them again would be a stale-reference free.
      cleanup_android(env, url_string, method_string, headers_keys, headers_values, body_string)

      if result
        json = env.get_string_utf_chars(result, nil).to_s
        env.delete_local_ref(result)
        Response.from_json(json)
      else
        Response.new(success: false, error: "Request failed")
      end
    end

    private def execute_android_stream(request : Request, env : Native::Android::JNIEnvWrapper, activity : Void*) : Response
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

      # StreamCallback is a concrete class taking a native handle in its
      # constructor: new StreamCallback(J). The handle keys the handler
      # registry the native dispatch funs below read from; the stale-check
      # there drops events from an already-finished stream.
      callback_ctor = env.get_method_id(callback_class, "<init>", "(J)V")
      if callback_ctor == Pointer(Void).null
        env.delete_local_ref(callback_class)
        cleanup_android(env, url_string, method_string, headers_keys, headers_values)
        return Response.new(success: false, error: "StreamCallback constructor not found")
      end

      handle = HTTPClient.register_stream(request)
      callback_obj = env.new_object(callback_class, callback_ctor, handle)
      env.delete_local_ref(callback_class) unless callback_class.null?

      if callback_obj.null?
        HTTPClient.unregister_stream(handle)
        cleanup_android(env, url_string, method_string, headers_keys, headers_values)
        return Response.new(success: false, error: "StreamCallback allocation failed")
      end

      stream_method = env.get_static_method_id(http_client_class, "executeStream", "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;[Ljava/lang/String;Lcom/nativecr/StreamCallback;D)V")
      if stream_method == Pointer(Void).null
        HTTPClient.unregister_stream(handle)
        cleanup_android(env, url_string, method_string, headers_keys, headers_values)
        env.delete_local_ref(callback_obj)
        return Response.new(success: false, error: "executeStream method not found")
      end

      env.call_static_void_method(http_client_class, stream_method, url_string, method_string, headers_keys, headers_values, callback_obj, request.timeout)
      env.delete_local_ref(http_client_class) unless http_client_class.null?

      # cleanup_android already released the strings and arrays; the
      # callback_obj local ref goes separately (it is not part of it).
      cleanup_android(env, url_string, method_string, headers_keys, headers_values)
      env.delete_local_ref(callback_obj)

      # Asynchronous semantics (matching the iOS stream path): the request
      # is now in flight on the Java side; chunks/status/errors arrive via
      # the dispatch funs below. 0 = "pending, no status yet".
      Response.new(success: true, status_code: 0)
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
        Response.from_json(json)
      else
        Response.new(success: false, error: "Request failed")
      end
    end

    private def execute_ios_stream(request : Request) : Response
      headers_json = request.headers.to_json

      # The Swift runtime delivers every stream event on the iOS main
      # queue — the thread the Crystal runtime lives on (see
      # NativeRuntime.swift's threading note) — so the trampolines
      # below run on a GC-registered thread and may allocate freely.
      on_chunk = ->(ctx : Void*, data : UInt8*, size : Int32) {
        stream_handle = Box(Int64).unbox(ctx)
        bytes = size > 0 ? Slice.new(data, size) : Bytes.empty
        HTTPClient.dispatch_stream_chunk(stream_handle, bytes)
      }
      on_complete = ->(ctx : Void*, status : Int32) {
        HTTPClient.dispatch_stream_complete(Box(Int64).unbox(ctx), status)
      }
      on_error = ->(ctx : Void*, message : UInt8*) {
        HTTPClient.dispatch_stream_error(Box(Int64).unbox(ctx), String.new(message))
      }

      handle = HTTPClient.register_stream(request)
      context = Box.box(handle)
      HTTPClient.root_stream_box(handle, context)
      LibIOS.http_request_stream(request.url.to_utf8, request.method.to_s.to_utf8,
        headers_json.to_utf8, request.body.to_utf8, request.timeout,
        context, on_chunk, on_complete, on_error)

      # Asynchronous semantics, matching the Android stream path: the
      # request is now in flight; chunks/status/errors arrive via the
      # trampolines. 0 = "pending, no status yet".
      Response.new(success: true, status_code: 0)
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
        client = build_desktop_client(request)
        http_request = build_desktop_request(request)

        http_response = client.exec(http_request)

        response_headers = {} of String => String
        http_response.headers.each do |key, values|
          response_headers[key] = values.first? || ""
        end

        Response.new(
          status_code: http_response.status_code,
          headers: response_headers,
          body: http_response.body,
          # success used to be hardcoded true — a 404 or 500 was reported
          # as a successful response with an error page as its body.
          success: http_response.success?
        )
      rescue ex
        Response.new(success: false, error: ex.message)
      end
    end

    private def execute_desktop_stream(request : Request) : Response
      begin
        client = build_desktop_client(request)
        http_request = build_desktop_request(request)
        handler = request.chunk_handler

        # The stream path used to ignore the request method entirely and
        # always issue a GET; it also called the handler once per byte and
        # hardcoded success/200 regardless of the actual status.
        final_status = 0
        client.exec(http_request) do |http_response|
          final_status = http_response.status_code
          if handler && (body_io = http_response.body_io)
            buffer = Bytes.new(65536)
            while (read = body_io.read(buffer)) > 0
              handler.call(buffer[0, read])
            end
          end
        end

        request.on_complete.try(&.call(final_status))

        Response.new(
          success: final_status >= 200 && final_status < 300,
          status_code: final_status
        )
      rescue ex
        request.on_error.try(&.call(ex.message.to_s))
        Response.new(success: false, error: ex.message)
      end
    end

    # Shared desktop client: honours request.timeout (connect, read and
    # DNS) — timeouts used to be silently ignored. Note the ::HTTP
    # prefixes: inside Native::Network a bare HTTP resolves to
    # Native::Network::HTTP (the convenience module below).
    private def build_desktop_client(request : Request) : ::HTTP::Client
      client = ::HTTP::Client.new(URI.parse(request.url))
      client.connect_timeout = request.timeout.seconds
      client.read_timeout = request.timeout.seconds
      client.dns_timeout = request.timeout.seconds
      client
    end

    private def build_desktop_request(request : Request) : ::HTTP::Request
      headers = ::HTTP::Headers.new
      request.headers.each do |key, value|
        headers[key] = value
      end
      # GET/HEAD carry no body — sending an empty one made some servers
      # respond 400.
      body = (request.method == Method::GET || request.method == Method::HEAD) ? nil : request.body
      ::HTTP::Request.new(request.method.to_s, URI.parse(request.url).request_target, headers, body)
    end

    private def cleanup_android(env : Native::Android::JNIEnvWrapper, url : Void*, method : Void*, keys : Void*, values : Void*, body : Void*? = nil)
      env.delete_local_ref(url)
      env.delete_local_ref(method)
      env.delete_local_ref(keys)
      env.delete_local_ref(values)
      env.delete_local_ref(body) if body
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
      env.delete_local_ref(ws_class) unless ws_class.null?
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

{% if flag?(:native_android) %}
  # ── Android JNI dispatch funs ──────────────────────────────────────────────
  # ART resolves StreamCallback.java's native methods against these
  # exported symbols (short-name lookup).
  #
  # HTTPClient.java delivers every stream event from a dedicated
  # single-thread executor, so all three funs run on ONE known thread.
  # That thread is foreign to the Crystal runtime, so it must be
  # registered with the Boehm GC before it can allocate (Bytes.new /
  # handler code) — done once, guarded by an atomic flag.
  lib LibGCAndroid
    struct StackBase
      mem_base : Void*
    end

    fun GC_get_stack_base = GC_get_stack_base(base : StackBase*) : Int32
    fun GC_register_my_thread = GC_register_my_thread(base : StackBase*) : Int32
  end

  module Native::Network
    @@jni_dispatcher_registered : Atomic(Bool) = Atomic(Bool).new(false)

    def self.ensure_jni_dispatcher_registered : Nil
      return if @@jni_dispatcher_registered.get
      base = LibGCAndroid::StackBase.new(mem_base: Pointer(Void).null)
      if LibGCAndroid.GC_get_stack_base(pointerof(base)) == 0
        LibGCAndroid.GC_register_my_thread(pointerof(base))
      end
      @@jni_dispatcher_registered.set(true)
    end
  end

  fun java_stream_chunk = Java_com_nativecr_StreamCallback_nativeStreamChunk(env : Void*, clazz : Void*, handle : Int64, data : Void*) : Void
    Native::Network.ensure_jni_dispatcher_registered
    vtable = env.as(LibJNI::JNINativeInterface**).value
    length = vtable.value.get_array_length.call(env, data)
    return if length < 0
    bytes = Bytes.new(length)
    vtable.value.get_byte_array_region.call(env, data, 0, length, bytes.to_unsafe) if length > 0
    Native::Network::HTTPClient.dispatch_stream_chunk(handle, bytes)
  end

  fun java_stream_complete = Java_com_nativecr_StreamCallback_nativeStreamComplete(env : Void*, clazz : Void*, handle : Int64, status : Int32) : Void
    Native::Network.ensure_jni_dispatcher_registered
    Native::Network::HTTPClient.dispatch_stream_complete(handle, status)
  end

  fun java_stream_error = Java_com_nativecr_StreamCallback_nativeStreamError(env : Void*, clazz : Void*, handle : Int64, message : Void*) : Void
    Native::Network.ensure_jni_dispatcher_registered
    vtable = env.as(LibJNI::JNINativeInterface**).value
    length = vtable.value.get_array_length.call(env, message)
    error = "stream failed"
    if length > 0
      bytes = Bytes.new(length)
      vtable.value.get_byte_array_region.call(env, message, 0, length, bytes.to_unsafe)
      error = String.new(bytes)
    end
    Native::Network::HTTPClient.dispatch_stream_error(handle, error)
  end
{% end %}
