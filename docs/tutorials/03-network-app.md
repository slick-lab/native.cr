# Tutorial 3 — Talking to the Network

Fetch JSON, parse it, handle failure, and send form data. Uses the
synchronous `Native::Network::HTTP` helpers plus `Request` for control.

---

## 1. The two ways to call out

**Simple one-liners:**

```crystal
response = Native::Network::HTTP.get("https://api.example.com/ping")
if response.success
  puts response.body
else
  puts "failed: #{response.status_code}"
end
```

**Full control with `Request`:**

```crystal
request = Native::Network::Request.new
request.url = "https://api.example.com/session"
request.method = "POST"
request.json = %({"user": "ada", "token": "secret"})
request.timeout = 10
response = request.execute
```

A `Response` carries `status_code`, `body`, and `success`. `success` is true
for 2xx. Body strings parse with `JSON.parse`.

> Requests are synchronous. Call them from `spawn` when you do not want to
> block the caller, and keep UI updates on the main flow.

---

## 2. The app: a tiny client dashboard

```crystal
require "native"

class NetworkApp < Native::App
  @[Preserve]
  property status : String = "idle"

  def setup
    @status_label = Native::UI::TextView.new("Status: idle")
    @status_label.text_size = 18

    fetch_btn = Native::UI::Button.new("Fetch /ping")
    fetch_btn.on_click { spawn { fetch_ping } }

    form_btn = Native::UI::Button.new("Send form")
    form_btn.on_click { spawn { send_form } }

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.padding = 16
    layout.gravity = Native::UI::LinearLayout::Gravity::Center

    layout.addView(@status_label)
    layout.addView(fetch_btn)
    layout.addView(form_btn)
    @root = layout
  end

  private def fetch_ping
    set_status("fetching…")
    response = Native::Network::HTTP.get("https://httpbin.org/json")
    if response.success
      data = JSON.parse(response.body)
      title = data.dig?("slideshow", "title").try(&.as_s?) || "(no title)"
      set_status("200 OK — #{title}")
    else
      set_status("request failed (#{response.status_code})")
    end
  end

  private def send_form
    set_status("sending…")
    request = Native::Network::Request.new
    request.url = "https://httpbin.org/post"
    request.method = "POST"
    request.form = {"user" => "ada", "note" => "a&b=c is safe now"}
    response = request.execute
    set_status(response.success ? "form sent (#{response.status_code})" : "form failed")
  end

  private def set_status(text : String)
    @status = text
    @status_label.text = "Status: #{text}"
  end
end

Native::App.registered_subclas = NetworkApp
```

### Points worth noticing

- **`request.form = {...}`** percent-encodes reserved characters, so values
  like `a&b=c` cannot corrupt the body — no manual escaping, ever.
- **`request.json = ...`** sets the body *and* the `Content-Type:
  application/json` header; setting `form=` afterwards replaces both.
- **`JSON.parse`** returns `JSON::Any`; `dig?` chains fail soft, `.try`
  keeps the UI code flat.
- Failures are values, not exceptions — branch on `response.success`.

---

## 3. Streaming large payloads

For big bodies, register a chunk handler instead of buffering everything:

```crystal
request = Native::Network::Request.new
request.url = "https://example.com/big-file"
request.on_chunk do |bytes|
  total += bytes.size
end
request.stream = true
request.execute
```

---

## 4. Exercises

1. Add a `Native::UI::ProgressView` you advance from `on_chunk`.
2. POST JSON with `request.json =` and print the echoed body.
3. Store the last successful fetch time with
   `Native::Storage::Preferences`.

Next: [Tutorial 4 — A Touch-Driven Game](04-game.md)
