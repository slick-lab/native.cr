# Networking

HTTP client and WebSocket support for Android, iOS, and desktop.

---

## Quick HTTP

```crystal
# GET
response = Native::Network::HTTP.get("https://api.example.com/users")

# POST
response = Native::Network::HTTP.post(
  "https://api.example.com/users",
  body: "{\"name\":\"Alice\"}"
)

# PUT
response = Native::Network::HTTP.put(url, body: data)

# DELETE
response = Native::Network::HTTP.delete(url)
```

---

## Response

```crystal
if response.success
  puts response.status_code
  puts response.body
  
  if data = response.json
    puts data["name"].as_s
  end
end

# Helpers
response.ok?           # 200–299
response.client_error?  # 400–499
response.server_error?  # 500–599
```

---

## HTTPClient — Base URL

```crystal
client = Native::Network::HTTPClient.new("https://api.example.com")

users = client.get("/users")
profile = client.get("/profile", headers: auth_headers)
created = client.post("/users", body: json_data)
```

---

## Headers

```crystal
headers = {
  "Authorization" => "Bearer #{@token}",
  "Content-Type" => "application/json"
}
response = client.get("/profile", headers: headers)
```

---

## WebSockets

```crystal
ws = Native::Network::WebSocket.new("wss://chat.example.com")

ws.on_open { ws.send("Hello!") }

ws.on_message { |text| puts "Received: #{text}" }

ws.on_error { |msg| puts "Error: #{msg}" }

ws.on_close { |code, reason| puts "Closed: #{code}" }

ws.connect
```

---

## Background Requests

Run in a fiber to keep UI responsive:

```crystal
def load_data
  spawn do
    response = Native::Network::HTTP.get("https://api.example.com/data")
    if response.ok?
      update_ui(response.json)
    end
  end
end
```

---

## Example: API Client

```crystal
class ApiClient
  def initialize(@token : String)
    @client = Native::Network::HTTPClient.new("https://api.example.com")
    @headers = {"Authorization" => "Bearer #{@token}"}
  end

  def get_profile
    response = @client.get("/profile", headers: @headers)
    response.ok? ? response.json : nil
  end

  def create_post(title, body)
    @client.post("/posts", 
      body: {title: title, body: body}.to_json,
      headers: @headers.merge({"Content-Type" => "application/json"})
    )
  end
end
```
