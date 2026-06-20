# Networking

native.cr provides an HTTP client and WebSocket support that work on Android, iOS, and desktop.

---

## Quick HTTP requests

The simplest way to make requests is through the `Native::Network::HTTP` module:

```crystal
# GET
response = Native::Network::HTTP.get("https://api.example.com/posts")

# POST
response = Native::Network::HTTP.post(
  "https://api.example.com/posts",
  body: "{\"title\":\"Hello\"}"
)

# PUT
response = Native::Network::HTTP.put("https://api.example.com/posts/1", body: "...")

# DELETE
response = Native::Network::HTTP.delete("https://api.example.com/posts/1")
```

### Checking the response

```crystal
if response.ok?
  puts response.body          # raw string body
  data = response.json        # parsed JSON (returns JSON::Any)
  puts data["title"].as_s
elsif response.client_error?
  puts "Bad request: #{response.status_code}"
elsif response.server_error?
  puts "Server error: #{response.status_code}"
end

puts response.success         # true if the request itself succeeded (no network error)
puts response.error           # error message if success == false
```

| Method | Returns | Description |
|---|---|---|
| `ok?` | `Bool` | Status 200–299 |
| `client_error?` | `Bool` | Status 400–499 |
| `server_error?` | `Bool` | Status 500–599 |
| `status_code` | `Int32` | Raw HTTP status code |
| `body` | `String` | Response body as text |
| `json` | `JSON::Any?` | Parsed JSON (nil if body is not JSON) |

---

## HTTPClient — reusable client with a base URL

When all your requests go to the same server, use `HTTPClient` with a base URL:

```crystal
client = Native::Network::HTTPClient.new("https://api.example.com")

# Now paths are relative to the base URL
response = client.get("/users")
response = client.post("/users", body: user_json)
response = client.put("/users/1", body: updated_json)
response = client.delete("/users/1")
```

### Adding headers

```crystal
response = client.get("/profile", headers: {
  "Authorization" => "Bearer my-token",
  "Accept-Language" => "en"
})
```

### Building a custom request

For more control, create a `Request` struct:

```crystal
request = Native::Network::Request.new
request.method = Native::Network::Method::POST
request.url = "https://api.example.com/upload"
request.add_header("Authorization", "Bearer my-token")
request.json = { name: "Alice" }.to_json  # sets body + Content-Type header
request.timeout = 60.0                    # seconds (default is 30)

response = client.request(request)
```

Setting `request.json=` automatically adds the `Content-Type: application/json` header.

For form data:

```crystal
request.form = { "username" => "alice", "password" => "secret" }
```

---

## Streaming responses

Use streaming when you want to process the response as it arrives, e.g. for Server-Sent Events or large downloads:

```crystal
client = Native::Network::HTTPClient.new("https://api.example.com")

client.get("/stream") do |chunk|
  text = String.new(chunk)
  puts "Received chunk: #{text}"
end
```

---

## WebSockets

WebSockets let you keep an open, two-way connection to a server.

```crystal
ws = Native::Network::WebSocket.new("wss://echo.websocket.org")

# Set up event handlers BEFORE calling connect
ws.on_open do
  puts "Connected!"
  ws.send("Hello server")
end

ws.on_message do |text|
  puts "Server says: #{text}"
end

ws.on_chunk do |bytes|
  puts "Received binary data: #{bytes.size} bytes"
end

ws.on_error do |error|
  puts "Error: #{error}"
end

ws.on_close do |code, reason|
  puts "Closed: #{code} #{reason}"
end

# Now connect
ws.connect
```

### Sending data

```crystal
ws.send("Hello")                    # send text
ws.send_binary(Bytes[1, 2, 3])     # send binary data
ws.close                            # disconnect
```

---

## A real-world example — fetching and displaying a list

```crystal
class PostsApp < Native::App
  def setup
    @list = UI::RecyclerView.new

    Native::Network::HTTP.get("https://jsonplaceholder.typicode.com/posts") do |response|
      if response.ok?
        posts = response.json.as_a
        @list.items = posts.map { |p| p["title"].as_s }
      end
    end

    @root = @list
  end
end
```

> **Tip:** HTTP requests are blocking by default. For a smooth UI, run them in a background fiber:
> ```crystal
> spawn do
>   response = Native::Network::HTTP.get(url)
>   # update UI on main thread
> end
> ```
