# Networking

native.cr provides an HTTP client and a WebSocket client that work on Android, iOS, and the desktop development build. All classes live in the `Native::Network` namespace.

---

## One-liner HTTP requests

The `Native::Network::HTTP` module has convenience methods for simple cases:

```crystal
# GET
response = Native::Network::HTTP.get("https://api.example.com/users")

# POST
response = Native::Network::HTTP.post(
  "https://api.example.com/users",
  body: "{\"name\":\"Alice\"}"
)

# PUT
response = Native::Network::HTTP.put(
  "https://api.example.com/users/1",
  body: "{\"name\":\"Alice Updated\"}"
)

# DELETE
response = Native::Network::HTTP.delete("https://api.example.com/users/1")
```

### Reading the response

```crystal
if response.success
  puts response.status_code   # e.g. 200
  puts response.body          # raw response string

  # Parse JSON automatically
  if data = response.json
    puts data["name"].as_s
  end
else
  puts "Request failed: #{response.error}"
end

# Status code helpers
response.ok?           # true for 200–299
response.client_error? # true for 400–499
response.server_error? # true for 500–599
```

### The `Response` struct at a glance

| Field / Method | Type | Description |
|---|---|---|
| `success` | `Bool` | `true` if the request completed without a network error |
| `status_code` | `Int32` | HTTP status (200, 404, 500…) |
| `body` | `String` | Response body as text |
| `headers` | `Hash(String, String)` | Response headers |
| `error` | `String?` | Error message when `success` is `false` |
| `ok?` | `Bool` | `status_code` in 200–299 |
| `client_error?` | `Bool` | `status_code` in 400–499 |
| `server_error?` | `Bool` | `status_code` in 500–599 |
| `json` | `JSON::Any?` | Parsed JSON, or `nil` if the body is not valid JSON |

---

## HTTPClient — reusable client with a base URL

When all your requests go to the same server, create an `HTTPClient` with a base URL. Paths are then relative to that base.

```crystal
client = Native::Network::HTTPClient.new("https://api.example.com")

# All paths are relative to the base URL
users    = client.get("/users")
profile  = client.get("/users/me")
created  = client.post("/users", body: new_user_json)
updated  = client.put("/users/1", body: update_json)
deleted  = client.delete("/users/1")
```

### Adding request headers

Pass a `Hash(String, String)` as the `headers:` argument:

```crystal
auth_headers = {
  "Authorization" => "Bearer #{@token}",
  "Accept-Language" => "en-US",
}

profile = client.get("/profile", headers: auth_headers)
```

### Building a custom request

For full control, use `Native::Network::Request`:

```crystal
req = Native::Network::Request.new
req.method  = Native::Network::Method::POST
req.url     = "https://api.example.com/upload"
req.timeout = 60.0                               # seconds (default: 30)

# Set body + Content-Type: application/json in one call
req.json = { name: "Alice", age: 30 }.to_json

# Or set form-encoded body
req.form = { "username" => "alice", "password" => "secret" }

# Add individual headers
req.add_header("X-Custom-Header", "my-value")

response = client.request(req)
```

### HTTP methods

```
Native::Network::Method::GET
Native::Network::Method::POST
Native::Network::Method::PUT
Native::Network::Method::DELETE
Native::Network::Method::PATCH
Native::Network::Method::HEAD
```

---

## Streaming responses

Use streaming to process the response as it arrives — ideal for Server-Sent Events, large file downloads, or AI streaming APIs.

```crystal
client = Native::Network::HTTPClient.new("https://api.example.com")

# The block receives each chunk as Bytes
client.get("/events") do |chunk|
  text = String.new(chunk)
  puts "Chunk: #{text}"
end
```

On a `Request` object:

```crystal
req = Native::Network::Request.new
req.method = Native::Network::Method::GET
req.url    = "https://stream.example.com/live"
req.on_chunk do |bytes|
  process_chunk(bytes)
end

client.request(req)
```

---

## WebSockets

`Native::Network::WebSocket` keeps a persistent two-way connection open with a server.

```crystal
ws = Native::Network::WebSocket.new("wss://echo.websocket.org")

# Register handlers BEFORE calling connect
ws.on_open do
  puts "Connected!"
  ws.send("Hello, server!")
end

ws.on_message do |text|
  puts "Server says: #{text}"
end

ws.on_chunk do |bytes|
  puts "Binary frame: #{bytes.size} bytes"
end

ws.on_error do |message|
  puts "WebSocket error: #{message}"
end

ws.on_close do |code, reason|
  puts "Closed — code: #{code}, reason: #{reason}"
end

# Open the connection
ws.connect
```

### Sending data

```crystal
ws.send("Hello!")                          # send a text frame
ws.send_binary(Bytes[0x01, 0x02, 0x03])   # send a binary frame
ws.close                                   # close the connection
```

---

## Running requests in the background

HTTP requests block the calling fiber. To keep the UI responsive, run them in a background fiber and update the UI when done:

```crystal
def load_feed
  spawn do
    response = Native::Network::HTTP.get("https://api.example.com/feed")

    if response.ok?
      posts = response.json.try(&.as_a) || [] of JSON::Any

      # Back on the main thread — update UI
      @list_view.adapter = Native::UI::SimpleAdapter.new(
        posts.map { |p| p["title"].as_s }
      )
    else
      @status_label.text = "Failed to load feed"
    end
  end
end
```

---

## Real-world example — authenticated JSON API

```crystal
class ApiClient
  BASE = "https://api.example.com"

  def initialize(@token : String)
    @client = Native::Network::HTTPClient.new(BASE)
    @headers = { "Authorization" => "Bearer #{@token}" }
  end

  def get_profile : JSON::Any?
    r = @client.get("/profile", headers: @headers)
    r.ok? ? r.json : nil
  end

  def create_post(title : String, body : String) : Bool
    payload = { title: title, body: body }.to_json
    r = @client.post("/posts", body: payload, headers: @headers.merge({
      "Content-Type" => "application/json"
    }))
    r.ok?
  end

  def delete_post(id : Int32) : Bool
    r = @client.delete("/posts/#{id}", headers: @headers)
    r.ok?
  end
end
```

---

## Real-world example — live chat with WebSocket

```crystal
class ChatApp < Native::App
  def setup
    @messages = [] of String

    @list = Native::UI::RecyclerView.new

    @input = Native::UI::EditText.new
    @input.hint = "Type a message…"

    send_btn = Native::UI::Button.new("Send")
    send_btn.on_click { send_message }

    input_row = Native::UI::LinearLayout.new(
      Native::UI::LinearLayout::Orientation::Horizontal
    )
    input_row.addView(@input)
    input_row.addView(send_btn)

    root = Native::UI::LinearLayout.new
    root.orientation = Native::UI::LinearLayout::Orientation::Vertical
    root.addView(@list)
    root.addView(input_row)
    @root = root

    connect_websocket
  end

  def connect_websocket
    @ws = Native::Network::WebSocket.new("wss://chat.example.com/ws")

    @ws.on_open { puts "Connected to chat" }

    @ws.on_message do |text|
      @messages << text
      @list.adapter = Native::UI::SimpleAdapter.new(@messages)
      @list.scroll_to_position(@messages.size - 1, smooth: true)
    end

    @ws.on_error { |err| puts "Chat error: #{err}" }

    @ws.connect
  end

  def send_message
    text = @input.text.strip
    return if text.empty?
    @ws.send(text)
    @input.text = ""
  end

  def on_destroy
    @ws.close
  end
end
```
