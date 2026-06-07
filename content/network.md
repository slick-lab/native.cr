
---
title: Networking
---

# Networking

Most mobile apps need to communicate with the internet. You might fetch data from an API, upload images to a server, or establish a real-time connection with a WebSocket. Native.cr provides a complete networking stack that handles HTTP requests, WebSocket connections, and image downloading.

## HTTP Basics

HTTP (Hypertext Transfer Protocol) is the foundation of data communication on the web. Your app acts as a client that sends requests to servers. Servers send back responses containing the data you asked for.

An HTTP request consists of several parts:

- **Method** - What action you want to perform (GET to retrieve, POST to create, PUT to update, DELETE to remove)
- **URL** - The address of the server and the specific resource you want
- **Headers** - Metadata about the request (content type, authentication tokens, etc.)
- **Body** - Data you are sending to the server (for POST and PUT requests)

An HTTP response contains:

- **Status code** - A number indicating success (200), redirection (300s), client error (400s), or server error (500s)
- **Headers** - Metadata about the response
- **Body** - The actual data returned by the server

## Making HTTP Requests

Native.cr provides two ways to make HTTP requests: simple one-off requests using the `HTTP` module, or persistent clients using the `HTTPClient` class.

### Simple GET Requests

The simplest way to fetch data is using `HTTP.get`. This is perfect for one-time requests where you do not need to maintain session state.

```crystal
response = Network::HTTP.get("https://api.example.com/users")

if response.ok?
  data = response.json
  puts "Got #{data["users"].size} users"
else
  puts "Error: #{response.status_code} - #{response.status_message}"
end
```

The get method takes a URL string and returns a Response object immediately. However, the request happens synchronously. Your app freezes until the response arrives. For network requests, this is rarely what you want.

### Asynchronous Requests

Network requests take time. The server could be across the ocean. The user could be on a slow cellular connection. If you make a synchronous request, your app becomes unresponsive until the request completes. Users will think your app crashed.

Always make network requests asynchronously. Native.cr provides several patterns for asynchronous work.

Using spawn (simple):

```crystal
spawn do
  response = Network::HTTP.get("https://api.example.com/data")
  
  # Update UI on main thread
  DispatchQueue.main.async do
    if response.ok?
      update_ui_with_data(response.json)
    else
      show_error("Failed to load data")
    end
  end
end
```

### Using callbacks:

```crystal
def fetch_user_data(user_id : String, &callback : Network::Response -> Nil)
  spawn do
    response = Network::HTTP.get("https://api.example.com/users/#{user_id}")
    DispatchQueue.main.async { callback.call(response) }
  end
end

# Usage
fetch_user_data("123") do |response|
  if response.ok?
    display_user(response.json)
  end
end
```

## Response Object

The Response object contains everything the server sent back.

Status information:

```crystal
response.status_code     # 200, 404, 500, etc.
response.status_message  # "OK", "Not Found", etc.
response.success?        # true if status is 200-299
response.ok?             # same as success?
response.client_error?   # true if status is 400-499
response.server_error?   # true if status is 500-599
```

Accessing the body:

```crystal
response.body            # Raw string body
response.body_bytes      # Raw bytes body
response.json            # Parsed JSON as a Crystal object
```

Headers:

```crystal
content_type = response.headers["Content-Type"]
all_headers = response.headers
```

### Parsing JSON Responses

Most modern APIs return JSON. The response.json method parses the JSON for you.

```crystal
response = Network::HTTP.get("https://api.example.com/posts/1")

if response.ok?
  post = response.json
  title = post["title"].as_s
  body = post["body"].as_s
  puts "Title: #{title}"
end
```

The json method returns a JSON::Any object. You need to convert values to the correct type using .as_s, .as_i, .as_f, or .as_bool.

### Type conversion example:

```crystal
data = response.json
name = data["name"].as_s               # String
age = data["age"].as_i                 # Int32
score = data["score"].as_f             # Float64
active = data["active"].as_bool        # Bool
items = data["items"].as_a             # Array(JSON::Any)
first_item = items[0].as_s
```

## POST Requests

Use POST to send data to the server, such as creating a new user or submitting a form.

Simple POST with form data:

```crystal
response = Network::HTTP.post("https://api.example.com/users", "name=John&email=john@example.com")
```

### POST with JSON body:

```crystal
client = Network::HTTPClient.new
request = Network::Request.new
request.method = Network::Method::POST
request.url = "https://api.example.com/users"
request.set_json_body(%({"name":"John","email":"john@example.com"}))

response = client.request(request)
```

Using the HTTP module for JSON POST:

```crystal
response = Network::HTTP.json("https://api.example.com/users", %({"name":"John"}))
```

PUT and DELETE Requests

PUT updates an existing resource. DELETE removes a resource.

```crystal
# PUT request
response = Network::HTTP.put("https://api.example.com/users/1", %({"name":"Updated Name"}))

# DELETE request
response = Network::HTTP.delete("https://api.example.com/users/1")
```

## HTTP Client

For apps that make many requests to the same API, using an HTTPClient is more efficient. The client maintains a base URL, default headers, and connection pooling.

Creating a Client

```crystal
client = Network::HTTPClient.new("https://api.example.com")
```

All subsequent requests using this client will have the base URL prepended automatically.

Setting Default Headers

```crystal
client.set_default_header("Authorization", "Bearer your_token_here")
client.set_default_header("Accept", "application/json")
```

These headers are added to every request made with this client.

Setting Timeout

```crystal
client.set_timeout(15.0)  # 15 seconds timeout
```

## Making Requests with Client

```crystal
# GET (relative path)
response = client.get("/users")

# POST with body
response = client.post("/users", "name=John")

# PUT
response = client.put("/users/1", "name=Updated")

# DELETE
response = client.delete("/users/1")
```

## Custom Requests

For full control, build a Request object manually.

```crystal
request = Network::Request.new
request.method = Network::Method::POST
request.url = "https://api.example.com/upload"
request.set_binary_body(file_data)
request.add_header("X-Custom-Header", "custom-value")
request.timeout = 30.0

response = client.request(request)
```

## Handling Errors

Network requests can fail for many reasons. Your app must handle these failures gracefully.

### Common Error Types

- No internet connection - The device is offline
- Timeout - The server did not respond in time
- HTTP error - Server returned 4xx or 5xx status code
- Parsing error - The response was not valid JSON

Complete Error Handling Example

```crystal
def fetch_data(url : String, &callback : (Network::Response?, String?) -> Nil)
  spawn do
    begin
      response = Network::HTTP.get(url)
      DispatchQueue.main.async { callback.call(response, nil) }
    rescue ex : Socket::Error
      DispatchQueue.main.async { callback.call(nil, "No internet connection") }
    rescue ex : IO::TimeoutError
      DispatchQueue.main.async { callback.call(nil, "Request timed out") }
    rescue ex
      DispatchQueue.main.async { callback.call(nil, "Network error: #{ex.message}") }
    end
  end
end

# Usage
fetch_data("https://api.example.com/data") do |response, error|
  if error
    show_error(error)
  elsif response && response.ok?
    process_data(response.json)
  elsif response
    show_error("Server error: #{response.status_code}")
  end
end
```

## Image Downloading

Downloading and displaying images from the internet is a common task. Native.cr provides an ImageDownloader class that handles the complexity.

Basic Image Download

```crystal
downloader = Network::ImageDownloader.new

spawn do
  if image_data = downloader.download("https://example.com/photo.jpg")
    DispatchQueue.main.async do
      @image_view.image = image_data
    end
  end
end
```

Asynchronous Image Download

```crystal
downloader.download_async("https://example.com/photo.jpg") do |image_data|
  if image_data
    @image_view.image = image_data
  else
    @image_view.image = default_placeholder
  end
end
```

## Caching Images

The ImageDownloader does not automatically cache images. You can implement your own cache using Storage::FileStorage.

```crystal
class CachedImageDownloader
  def initialize
    @cache = Storage::FileStorage.new(StorageType::Cache)
    @downloader = Network::ImageDownloader.new
  end
  
  def download(url : String, &callback : Image::ImageData? -> Nil)
    # Generate cache key from URL
    cache_key = url.to_sha256
    
    # Check cache first
    if @cache.exists?(cache_key)
      if data = @cache.read(cache_key)
        if image = Image::ImageLoader.from_bytes(data, "jpg")
          callback.call(image)
          return
        end
      end
    end
    
    # Download and cache
    @downloader.download_async(url) do |image|
      if image
        # Save to cache
        rgba = image.to_rgba
        @cache.write(cache_key, rgba.pixels)
      end
      callback.call(image)
    end
  end
end
```

## WebSocket Connections

WebSockets provide persistent, bidirectional communication between your app and a server. Unlike HTTP where the client requests and the server responds, WebSockets allow either side to send messages at any time. This is perfect for chat apps, live scores, gaming, and real-time dashboards.

How WebSockets Differ from HTTP

Feature HTTP WebSocket
Connection Opens, request, closes Persistent open connection
Direction Client requests, server responds Bidirectional
Overhead Headers on every request Minimal after handshake
Use case Fetching data Real-time updates

Creating a WebSocket Connection

```crystal
ws = Network::WebSocket.new("wss://echo.websocket.org")
```

Use wss:// for secure WebSockets (encrypted) or ws:// for unencrypted. Most production servers use wss://.

## Setting Up Event Handlers

Before connecting, set up your event handlers.

```crystal
ws.on_open do
  puts "Connected to server"
end

ws.on_message do |message|
  puts "Received: #{message}"
end

ws.on_error do |error|
  puts "Error: #{error}"
end

ws.on_close do |code, reason|
  puts "Disconnected: #{reason} (code: #{code})"
end
```

## Connecting and Sending Messages

```crystal
# Connect to the server
ws.connect

# Send a text message
ws.send("Hello, server!")

# Send binary data
bytes = "Binary data".to_slice
ws.send(bytes)
```

## Complete WebSocket Chat Example

```crystal
class ChatApp < Native::App
  def setup
    setup_ui
    connect_to_chat
  end
  
  def setup_ui
    @message_input = UI::TextInput.new
    @message_input.placeholder = "Type a message..."
    @message_input.width = 250
    
    @send_button = UI::Button.new
    @send_button.text = "Send"
    @send_button.on_click = ->{ send_message }
    
    @chat_display = UI::Text.new
    @chat_display.text = ""
    @chat_display.width = 300
    @chat_display.height = 400
    
    row = UI::Row.new
    row.add_child(@message_input)
    row.add_child(@send_button)
    
    column = UI::Column.new
    column.add_child(@chat_display)
    column.add_child(row)
    
    @root = column
  end
  
  def connect_to_chat
    @ws = Network::WebSocket.new("wss://chat.example.com/room/123")
    
    @ws.on_open do
      append_message("Connected to chat!")
    end
    
    @ws.on_message do |message|
      append_message(message)
    end
    
    @ws.on_error do |error|
      append_message("Error: #{error}")
    end
    
    @ws.on_close do |code, reason|
      append_message("Disconnected: #{reason}")
    end
    
    @ws.connect
  end
  
  def send_message
    text = @message_input.text
    return if text.empty?
    
    @ws.send(text)
    @message_input.clear
    append_message("You: #{text}")
  end
  
  def append_message(text : String)
    @chat_display.text += text + "\n"
  end
  
  def draw
    @root.draw(renderer)
  end
end
```

## Reconnecting on Disconnect

WebSocket connections can drop due to network changes or server issues. Implement reconnection logic for robust apps.

```crystal
class ReconnectingWebSocket
  @should_reconnect = true
  @reconnect_delay = 1.0
  @max_reconnect_delay = 30.0
  
  def initialize(url : String)
    @url = url
    connect
  end
  
  def connect
    @ws = Network::WebSocket.new(@url)
    
    @ws.on_close do |code, reason|
      if @should_reconnect
        schedule_reconnect
      end
    end
    
    @ws.connect
  end
  
  def schedule_reconnect
    spawn do
      sleep @reconnect_delay
      @reconnect_delay = [@reconnect_delay * 2, @max_reconnect_delay].min
      connect
    end
  end
  
  def disconnect
    @should_reconnect = false
    @ws.disconnect
  end
end
```

## Practical Examples

Fetching and Displaying a List of Posts

```crystal
class BlogApp < Native::App
  def setup
    @list = UI::ListView.new(item_height: 80)
    @list.on_item_click do |index|
      show_post_detail(@posts[index])
    end
    
    @loading = UI::Text.new
    @loading.text = "Loading..."
    
    @root = @loading
    
    load_posts
  end
  
  def load_posts
    spawn do
      response = Network::HTTP.get("https://jsonplaceholder.typicode.com/posts")
      
      DispatchQueue.main.async do
        if response.ok?
          @posts = response.json.as_a
          display_posts
        else
          show_error("Failed to load posts")
        end
      end
    end
  end
  
  def display_posts
    adapter = List::DataListAdapter(JSON::Any).new(@posts) do |post, index|
      create_post_item(post)
    end
    
    @list.set_adapter(adapter)
    @root = @list
  end
  
  def create_post_item(post : JSON::Any) : UI::View
    view = UI::View.new
    view.background_color = index % 2 == 0 ? Color.white : Color.gray(245)
    
    title = UI::Text.new
    title.text = post["title"].as_s
    title.text_size = 16
    title.font = Font.bold(16)
    title.x = 16
    title.y = 10
    
    body = UI::Text.new
    body.text = post["body"].as_s
    body.text_size = 14
    body.color = Color.gray(100)
    body.x = 16
    body.y = 40
    
    view.add_child(title)
    view.add_child(body)
    view
  end
  
  def draw
    @root.draw(renderer)
  end
end
```

## Uploading an Image

```crystal
def upload_image(image_data : Image::ImageData)
  # Convert image to JPEG bytes
  jpeg_bytes = image_data.to_jpeg(quality: 85)
  
  # Create multipart form request
  boundary = "----#{Random.rand(1000000)}"
  body = build_multipart_body(boundary, jpeg_bytes)
  
  request = Network::Request.new
  request.method = Network::Method::POST
  request.url = "https://api.example.com/upload"
  request.set_binary_body(body)
  request.add_header("Content-Type", "multipart/form-data; boundary=#{boundary}")
  
  client = Network::HTTPClient.new
  response = client.request(request)
  
  if response.ok?
    puts "Upload successful!"
  else
    puts "Upload failed: #{response.status_code}"
  end
end

def build_multipart_body(boundary : String, image_data : Bytes) : Bytes
  body = String.build do |io|
    io << "--#{boundary}\r\n"
    io << "Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n"
    io << "Content-Type: image/jpeg\r\n\r\n"
  end.to_slice
  
  body + image_data + "\r\n--#{boundary}--\r\n".to_slice
end
```

## Best Practices

Always handle errors - Network requests fail. Design your app to handle failures gracefully. Show user-friendly error messages, not technical details.

Show loading indicators - Users need to know something is happening. Show a spinner or progress indicator during network requests.

Use timeouts - Set reasonable timeouts. Fifteen seconds is typical for mobile networks. Do not let requests hang indefinitely.

Cancel requests when not needed - If the user navigates away from a screen, cancel pending requests. Do not waste battery and bandwidth.

Cache responses - Reduce network usage by caching responses. Use Storage::FileStorage to save data for offline access.

Respect the main thread - Never perform network operations on the main thread. Always use spawn for network calls and DispatchQueue.main.async for UI updates.

Use HTTPS in production - Always use HTTPS (not HTTP) in production. Encrypt your users' data. Never send passwords or tokens over unencrypted connections.

## Next Steps

Now that you understand networking, learn about:

- Storage - Save data locally
- Camera - Capture photos and video
- Platform APIs - Device features like battery and sensors
