# Data and Networking

Fetch data from APIs, handle authentication, and manage caching.

---

## HTTP Client

### GET Request

```crystal
# Simple GET
response = Native::Network::HTTPClient.get("https://api.example.com/users")
if response.success
  users = Array(User).from_json(response.body)
end

# With callback (non-blocking)
Native::Network::HTTPClient.get("https://api.example.com/users") do |response|
  if response.success
    users = Array(User).from_json(response.body)
    update_ui(users)
  end
end
```

### POST Request

```crystal
response = Native::Network::HTTPClient.post(
  "https://api.example.com/users",
  headers: {"Content-Type" => "application/json"},
  body: user.to_json
)
```

### Custom Client

```crystal
client = Native::Network::HTTPClient.new("https://api.example.com")
client.headers["Authorization"] = "Bearer #{@token}"
client.headers["Content-Type"] = "application/json"

response = client.get("/users")
response = client.post("/users", body: data.to_json)
response = client.put("/users/1", body: data.to_json)
response = client.delete("/users/1")
```

---

## Response Object

```crystal
response.success?       # True if 2xx status
response.status_code     # Integer (200, 404, etc.)
response.body            # Response body string
response.headers         # Hash of response headers
response.error_message   # Error description if failed
response.json?           # Parse as JSON (returns JSON::Any?)
```

---

## Error Handling

```crystal
def fetch_users
  response = Native::Network::HTTPClient.get("https://api.example.com/users")

  case response.status_code
  when 200
    Array(User).from_json(response.body)
  when 401
    handle_auth_error
    [] of User
  when 404
    [] of User
  when 500..599
    raise "Server error: #{response.status_code}"
  else
    raise "Unexpected status: #{response.status_code}"
  end
rescue ex : JSON::ParseException
  raise "Invalid JSON response"
rescue ex : Exception
  raise "Network error: #{ex.message}"
end
```

---

## Async Operations

Network requests should run in background fibers:

```crystal
def load_data
  @loading = true
  update_ui

  spawn do
    begin
      response = Native::Network::HTTPClient.get(@api_url)
      if response.success?
        @data = parse_response(response.body)
        schedule_on_main { show_data(@data) }
      else
        schedule_on_main { show_error(response.error_message) }
      end
    rescue ex
      schedule_on_main { show_error(ex.message) }
    ensure
      schedule_on_main do
        @loading = false
        update_ui
      end
    end
  end
end
```

The framework provides `schedule_on_main` to run code on the UI thread.

---

## WebSocket

Real-time bidirectional communication:

```crystal
def connect_websocket
  @ws = Native::Network::WebSocket.new("wss://api.example.com/ws")

  @ws.on_open do
    puts "Connected!"
    @ws.send("Hello server")
  end

  @ws.on_message do |message|
    handle_message(message)
  end

  @ws.on_error do |error|
    puts "WebSocket error: #{error}"
  end

  @ws.on_close do
    puts "Disconnected"
    # Reconnect after delay
    spawn do
      sleep 3.seconds
      connect_websocket
    end
  end

  @ws.connect
end

def send_message(text : String)
  @ws.send(text) if @ws && @ws.connected?
end

def disconnect
  @ws.close if @ws
end
```

---

## Building an API Client

Create a dedicated module for API interactions:

```crystal
module APIClient
  BASE_URL = "https://api.example.com"

  class Client
    @http : Native::Network::HTTPClient
    @token : String?

    def initialize(@token : String? = nil)
      @http = Native::Network::HTTPClient.new(BASE_URL)
      @http.headers["Content-Type"] = "application/json"
      @http.headers["Accept"] = "application/json"

      if @token
        @http.headers["Authorization"] = "Bearer #{@token}"
      end
    end

    def login(email : String, password : String) : AuthResult
      response = @http.post("/auth/login", body: {
        email: email,
        password: password
      }.to_json)

      if response.success?
        AuthResult.from_json(response.body)
      else
        raise APIError.new(response.status_code, response.error_message || "Login failed")
      end
    end

    def get_users : Array(User)
      response = @http.get("/users")
      if response.success?
        Array(User).from_json(response.body)
      else
        raise APIError.new(response.status_code, response.error_message || "Failed to fetch users")
      end
    end

    def get_user(id : String) : User
      response = @http.get("/users/#{id}")
      if response.success?
        User.from_json(response.body)
      else
        raise APIError.new(response.status_code, response.error_message || "Failed to fetch user")
      end
    end

    def create_user(user : User) : User
      response = @http.post("/users", body: user.to_json)
      if response.success?
        User.from_json(response.body)
      else
        raise APIError.new(response.status_code, response.error_message || "Failed to create user")
      end
    end

    def update_user(user : User) : User
      response = @http.put("/users/#{user.id}", body: user.to_json)
      if response.success?
        User.from_json(response.body)
      else
        raise APIError.new(response.status_code, response.error_message || "Failed to update user")
      end
    end

    def delete_user(id : String) : Bool
      response = @http.delete("/users/#{id}")
      response.success?
    end
  end

  class APIError < Exception
    property status_code : Int32

    def initialize(@status_code : Int32, message : String)
      super(message)
    end
  end
end
```

---

## Data Models

Define models with JSON serialization:

```crystal
struct User
  include JSON::Serializable

  property id : String
  property email : String
  property name : String
  property avatar_url : String?
  property created_at : String

  @[JSON::Field(converter: Time::Format.new("%Y-%m-%dT%H:%M:%S%z"))]
  property updated_at : Time
end

struct AuthResult
  include JSON::Serializable

  property token : String
  property user : User
  property expires_at : String
end
```

---

## Caching

### In-Memory Cache

```crystal
class Cache(T)
  @data = {} of String => CacheEntry(T)

  struct CacheEntry(T)
    property data : T
    property expires_at : Time

    def initialize(@data : T, ttl : Time::Span)
      @expires_at = Time.utc + ttl
    end

    def expired? : Bool
      Time.utc > @expires_at
    end
  end

  def get(key : String) : T?
    entry = @data[key]?
    return nil unless entry
    return nil if entry.expired?
    entry.data
  end

  def set(key : String, value : T, ttl : Time::Span = 5.minutes)
    @data[key] = CacheEntry.new(value, ttl)
  end

  def invalidate(key : String)
    @data.delete(key)
  end

  def clear
    @data.clear
  end
end
```

Usage:

```crystal
class MyApp < Native::App
  @users_cache = Cache(Array(User)).new

  def fetch_users(force_refresh : Bool = false) : Array(User)
    cached = @users_cache.get("users")
    return cached if cached && !force_refresh

    response = APIClient::Client.new.get_users
    @users_cache.set("users", response, 5.minutes)
    response
  end
end
```

### Persistent Cache

Save cached data to preferences:

```crystal
class PersistentCache
  def self.get(key : String) : String?
    prefs = Native::Storage::Preferences.new

    # Check expiration
    expires = prefs.get_int64("#{key}_expires", 0)
    return nil if Time.utc.to_unix > expires

    prefs.get_string(key)
  end

  def self.set(key : String, value : String, ttl : Time::Span)
    prefs = Native::Storage::Preferences.new
    prefs.set(key, value)
    prefs.set("#{key}_expires", (Time.utc + ttl).to_unix)
  end

  def self.get_json(key : String, type : T.class) : T? forall T
    json = get(key)
    return nil unless json
    T.from_json(json)
  end

  def self.set_json(key : String, value, ttl : Time::Span = 1.hour)
    set(key, value.to_json, ttl)
  end
end
```

---

## Offline Support

Queue requests when offline:

```crystal
class OfflineQueue
  @queue = [] of QueuedRequest
  @processing = false

  struct QueuedRequest
    property id : String
    property method : String
    property url : String
    property body : String?
    property created_at : Time
  end

  def add(method : String, url : String, body : String? = nil)
    request = QueuedRequest.new(
      id: UUID.random.to_s,
      method: method,
      url: url,
      body: body,
      created_at: Time.utc
    )
    @queue << request
    save_queue
    process if Native::Connectivity.is_connected?
  end

  def process
    return if @processing
    return if @queue.empty?
    return unless Native::Connectivity.is_connected?

    @processing = true

    while !@queue.empty? && Native::Connectivity.is_connected?
      request = @queue.shift
      execute(request)
      save_queue
    end

    @processing = false
  end

  private def execute(request : QueuedRequest)
    case request.method
    when "POST"
      Native::Network::HTTPClient.post(request.url, body: request.body)
    when "PUT"
      Native::Network::HTTPClient.put(request.url, body: request.body)
    when "DELETE"
      Native::Network::HTTPClient.delete(request.url)
    end
  end

  private def save_queue
    prefs = Native::Storage::Preferences.new
    prefs.set("offline_queue", @queue.to_json)
  end

  def load_queue
    prefs = Native::Storage::Preferences.new
    json = prefs.get_string("offline_queue")
    @queue = if json && !json.empty?
      Array(QueuedRequest).from_json(json)
    else
      [] of QueuedRequest
    end
  end
end
```

---

## Best Practices

1. **Always handle errors**: Network requests can fail
2. **Show loading states**: Users need feedback during requests
3. **Cache aggressively**: Reduce unnecessary network calls
4. **Cancel on unmount**: Don't update UI for dead screens
5. **Timeout requests**: Don't wait forever

---

## Next Steps

- [State Management](state-management.md) — Integrate API data with state
- [Tutorial: Data App](tutorial-data-app.md) — Build an app with API integration
