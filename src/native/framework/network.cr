# src/native/framework/network.cr

module Native
  module Network
    enum Method
      GET
      POST
      PUT
      DELETE
      PATCH
      HEAD
    end

    enum ContentType
      JSON
      XML
      Form
      Plain
      HTML
      Binary
    end

    struct Header
      property key : String
      property value : String

      def initialize(@key : String, @value : String)
      end
    end

    struct Request
      property method : Method = Method::GET
      property url : String = ""
      property headers : Array(Header) = [] of Header
      property body : String = ""
      property body_bytes : Bytes? = nil
      property timeout : Float64 = 30.0
      property content_type : ContentType = ContentType::JSON

      def initialize
      end

      def add_header(key : String, value : String) : Nil
        @headers << Header.new(key, value)
      end

      def set_json_body(data : String) : Nil
        @body = data
        @content_type = ContentType::JSON
        add_header("Content-Type", "application/json")
      end

      def set_form_body(params : Hash(String, String)) : Nil
        body = params.map { |k, v| "#{URI.encode(k)}=#{URI.encode(v)}" }.join("&")
        @body = body
        @content_type = ContentType::Form
        add_header("Content-Type", "application/x-www-form-urlencoded")
      end

      def set_binary_body(data : Bytes) : Nil
        @body_bytes = data
        @content_type = ContentType::Binary
      end
    end

    struct Response
      property status_code : Int32 = 0
      property headers : Hash(String, String) = {} of String => String
      property body : String = ""
      property body_bytes : Bytes? = nil
      property success : Bool = false
      property error : String? = nil

      def initialize
      end

      def json : JSON::Any?
        return nil unless success
        JSON.parse(body) rescue nil
      end

      def status_message : String
        case @status_code
        when 200 then "OK"
        when 201 then "Created"
        when 204 then "No Content"
        when 400 then "Bad Request"
        when 401 then "Unauthorized"
        when 403 then "Forbidden"
        when 404 then "Not Found"
        when 500 then "Internal Server Error"
        when 502 then "Bad Gateway"
        when 503 then "Service Unavailable"
        else "Unknown"
        end
      end

      def ok? : Bool
        @status_code >= 200 && @status_code < 300
      end

      def client_error? : Bool
        @status_code >= 400 && @status_code < 500
      end

      def server_error? : Bool
        @status_code >= 500 && @status_code < 600
      end
    end

    class HTTPClient
      @default_headers : Array(Header) = [] of Header
      @base_url : String = ""
      @timeout : Float64 = 30.0

      def initialize(base_url : String = "")
        @base_url = base_url
      end

      def set_base_url(url : String) : Nil
        @base_url = url
      end

      def set_default_header(key : String, value : String) : Nil
        @default_headers << Header.new(key, value)
      end

      def set_timeout(seconds : Float64) : Nil
        @timeout = seconds
      end

      def get(path : String) : Response
        request = Request.new
        request.method = Method::GET
        request.url = build_url(path)
        request.timeout = @timeout
        execute(request)
      end

      def post(path : String, body : String = "") : Response
        request = Request.new
        request.method = Method::POST
        request.url = build_url(path)
        request.body = body
        request.timeout = @timeout
        execute(request)
      end

      def put(path : String, body : String = "") : Response
        request = Request.new
        request.method = Method::PUT
        request.url = build_url(path)
        request.body = body
        request.timeout = @timeout
        execute(request)
      end

      def delete(path : String) : Response
        request = Request.new
        request.method = Method::DELETE
        request.url = build_url(path)
        request.timeout = @timeout
        execute(request)
      end

      def request(request : Request) : Response
        @default_headers.each do |h|
          request.add_header(h.key, h.value)
        end
        execute(request)
      end

      private def build_url(path : String) : String
        if @base_url.empty?
          path
        else
          if path.starts_with?("/")
            @base_url + path
          else
            @base_url + "/" + path
          end
        end
      end

      private def execute(request : Request) : Response
        {% if flag?(:android) }}
          execute_android(request)
        {% elsif flag?(:ios) }}
          execute_ios(request)
        {% else }}
          execute_stub(request)
        {% end }}
      end

      private def execute_android(request : Request) : Response
        url = request.url.to_utf8
        method = request.method.to_s.to_utf8
        
        header_keys = request.headers.map(&.key.to_utf8)
        header_values = request.headers.map(&.value.to_utf8)
        
        body_ptr = request.body.to_utf8
        body_len = request.body.bytesize
        
        response = LibAndroid.http_request(
          url, method,
          header_keys, header_values, request.headers.size,
          body_ptr, body_len,
          request.timeout
        )
        
        parse_response(response)
      end

      private def execute_ios(request : Request) : Response
        url = request.url.to_utf8
        method = request.method.to_s.to_utf8
        
        header_keys = request.headers.map(&.key.to_utf8)
        header_values = request.headers.map(&.value.to_utf8)
        
        body_ptr = request.body.to_utf8
        body_len = request.body.bytesize
        
        response = LibIOS.http_request(
          url, method,
          header_keys, header_values, request.headers.size,
          body_ptr, body_len,
          request.timeout
        )
        
        parse_response(response)
      end

      private def execute_stub(request : Request) : Response
        response = Response.new
        response.success = false
        response.error = "Network not available in stub mode"
        response
      end

      private def parse_response(ptr : Void*) : Response
        response = Response.new
        
        response.status_code = LibNetwork.get_status_code(ptr)
        response.body = String.new(LibNetwork.get_body(ptr))
        response.success = response.ok?
        
        LibNetwork.free_response(ptr)
        response
      end
    end

    module HTTP
      def self.get(url : String) : Response
        client = HTTPClient.new
        client.get(url)
      end

      def self.post(url : String, body : String = "") : Response
        client = HTTPClient.new
        client.post(url, body)
      end

      def self.put(url : String, body : String = "") : Response
        client = HTTPClient.new
        client.put(url, body)
      end

      def self.delete(url : String) : Response
        client = HTTPClient.new
        client.delete(url)
      end

      def self.json(url : String, data : String) : Response
        client = HTTPClient.new
        request = Request.new
        request.method = Method::POST
        request.url = url
        request.set_json_body(data)
        client.request(request)
      end
    end

    class ImageDownloader
      @client : HTTPClient

      def initialize
        @client = HTTPClient.new
      end

      def download(url : String) : Image::ImageData?
        response = @client.get(url)
        return nil unless response.success
        
        data = response.body_bytes
        return nil unless data
        
        content_type = response.headers["Content-Type"]? || ""
        
        if content_type.includes?("png")
          Image::ImageLoader.from_bytes(data, "png")
        elsif content_type.includes?("jpeg") || content_type.includes?("jpg")
          Image::ImageLoader.from_bytes(data, "jpg")
        else
          nil
        end
      end

      def download_async(url : String, &callback : Image::ImageData? -> Nil) : Nil
        spawn do
          result = download(url)
          callback.call(result)
        end
      end
    end

    class WebSocket
      @on_open_callbacks : Array(-> Nil) = [] of -> Nil
      @on_message_callbacks : Array(String -> Nil) = [] of String -> Nil
      @on_error_callbacks : Array(String -> Nil) = [] of String -> Nil
      @on_close_callbacks : Array(Int32, String -> Nil) = [] of Int32, String -> Nil
      
      @socket_ptr : Void*? = nil
      @url : String = ""
      @is_connected : Bool = false

      def initialize(@url : String)
      end

      def connect : Nil
        return if @is_connected
        
        {% if flag?(:android) }}
          connect_android
        {% elsif flag?(:ios) }}
          connect_ios
        {% end }}
      end

      def disconnect : Nil
        return unless @is_connected
        
        {% if flag?(:android) }}
          LibAndroid.websocket_close(@socket_ptr)
        {% elsif flag?(:ios) }}
          LibIOS.websocket_close(@socket_ptr)
        {% end }}
        
        @is_connected = false
        @socket_ptr = nil
      end

      def send(text : String) : Nil
        return unless @is_connected
        
        {% if flag?(:android) }}
          LibAndroid.websocket_send_text(@socket_ptr, text.to_utf8)
        {% elsif flag?(:ios) }}
          LibIOS.websocket_send_text(@socket_ptr, text.to_utf8)
        {% end }}
      end

      def send(data : Bytes) : Nil
        return unless @is_connected
        
        {% if flag?(:android) }}
          LibAndroid.websocket_send_binary(@socket_ptr, data, data.size)
        {% elsif flag?(:ios) }}
          LibIOS.websocket_send_binary(@socket_ptr, data, data.size)
        {% end }}
      end

      def on_open(&block : -> Nil) : Nil
        @on_open_callbacks << block
      end

      def on_message(&block : String -> Nil) : Nil
        @on_message_callbacks << block
      end

      def on_error(&block : String -> Nil) : Nil
        @on_error_callbacks << block
      end

      def on_close(&block : Int32, String -> Nil) : Nil
        @on_close_callbacks << block
      end

      private def connect_android : Nil
        @socket_ptr = LibAndroid.websocket_connect(@url.to_utf8)
        
        if @socket_ptr
          @is_connected = true
          @on_open_callbacks.each(&.call)
          start_listening_android
        else
          @on_error_callbacks.each { |cb| cb.call("Failed to connect") }
        end
      end

      private def start_listening_android : Nil
        spawn do
          while @is_connected && @socket_ptr
            message = LibAndroid.websocket_receive(@socket_ptr)
            if message
              @on_message_callbacks.each { |cb| cb.call(String.new(message)) }
              LibAndroid.free_string(message)
            end
          end
        end
      end

      private def connect_ios : Nil
        @socket_ptr = LibIOS.websocket_connect(@url.to_utf8)
        
        if @socket_ptr
          @is_connected = true
          @on_open_callbacks.each(&.call)
          start_listening_ios
        else
          @on_error_callbacks.each { |cb| cb.call("Failed to connect") }
        end
      end

      private def start_listening_ios : Nil
        spawn do
          while @is_connected && @socket_ptr
            message = LibIOS.websocket_receive(@socket_ptr)
            if message
              @on_message_callbacks.each { |cb| cb.call(String.new(message)) }
              LibIOS.free_string(message)
            end
          end
        end
      end
    end
  end
end
