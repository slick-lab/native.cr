# spec/review_fixes_spec.cr
#
# Regression coverage for the v0.1.10 external-review fixes:
# storage path traversal, the HTTP stream registry, the response
# envelope parser, and the named-arg Response constructor that used to
# be unreachable (hence never compiled, hence silently broken).

require "./spec_helper"

describe "Native::Storage.valid_filename?" do
  it "accepts plain filenames" do
    Native::Storage.valid_filename?("notes.txt").should be_true
    Native::Storage.valid_filename?("archive.tar.gz").should be_true
    Native::Storage.valid_filename?(".hidden").should be_true
    Native::Storage.valid_filename?("a file with spaces.bin").should be_true
  end

  it "rejects traversal attempts" do
    Native::Storage.valid_filename?("../secrets").should be_false
    Native::Storage.valid_filename?("..").should be_false
    Native::Storage.valid_filename?(".").should be_false
    Native::Storage.valid_filename?("a/b").should be_false
    Native::Storage.valid_filename?("a\\b").should be_false
    Native::Storage.valid_filename?("/etc/passwd").should be_false
    Native::Storage.valid_filename?("").should be_false
  end

  it "rejects NUL-injected names" do
    Native::Storage.valid_filename?("bad\u0000name").should be_false
  end
end

describe "Native::Storage.valid_subdirectory?" do
  it "accepts the root and plain relative paths" do
    Native::Storage.valid_subdirectory?("").should be_true
    Native::Storage.valid_subdirectory?("docs").should be_true
    Native::Storage.valid_subdirectory?("docs/2026").should be_true
  end

  it "rejects traversal and absolute paths" do
    Native::Storage.valid_subdirectory?("../up").should be_false
    Native::Storage.valid_subdirectory?("/abs").should be_false
    Native::Storage.valid_subdirectory?("a//b").should be_false
    Native::Storage.valid_subdirectory?("a/./b").should be_false
  end
end

describe "FileStorage traversal guards" do
  storage = Native::Storage::FileStorage.new

  it "refuses malicious names on every operation" do
    storage.write("../evil", Bytes[1]).should be_false
    storage.write_text("../evil.txt", "data").should be_false
    storage.read("a/b/c").should be_nil
    storage.read_text("..").should be_nil
    storage.exists?("../../etc/passwd").should be_false
    storage.delete("../evil").should be_false
    storage.list("../outside").should be_empty
  end
end

describe "Native::Network::Response" do
  it "constructs with named args" do
    response = Native::Network::Response.new(
      status_code: 404,
      headers: {"x-trace" => "abc"},
      body: "missing",
      success: false,
      error: "not found"
    )
    response.status_code.should eq(404)
    response.headers["x-trace"].should eq("abc")
    response.body.should eq("missing")
    response.success.should be_false
    response.error.should eq("not found")
    response.ok?.should be_false
    response.client_error?.should be_true
  end

  it "parses the mobile backend envelope including headers" do
    json = %q({"status":201,"headers":{"location":"/things/17","content-type":"application/json"},"body":"{\"id\":17}","success":true})
    response = Native::Network::Response.from_json(json)
    response.status_code.should eq(201)
    response.headers["location"].should eq("/things/17")
    response.headers["content-type"].should eq("application/json")
    response.body.should eq(%q({"id":17}))
    response.success.should be_true
    response.ok?.should be_true
  end

  it "parses the error envelope" do
    json = %q({"status":0,"headers":{},"body":"","success":false,"error":"request failed"})
    response = Native::Network::Response.from_json(json)
    response.success.should be_false
    response.error.should eq("request failed")
    response.headers.should be_empty
  end

  it "falls back to a parse failure response instead of raising" do
    response = Native::Network::Response.from_json("not json at all{")
    response.success.should be_false
    response.error.should eq("Failed to parse response")
  end
end

describe "Native::Network::HTTPClient stream registry" do
  it "delivers chunks, completion and errors to a registered request" do
    received = [] of Bytes
    completed = [] of Int32
    errored = [] of String

    request = Native::Network::Request.new
    request.on_chunk { |bytes| received << bytes }
    request.on_complete = ->(status : Int32) { completed << status; nil }
    request.on_error = ->(message : String) { errored << message; nil }

    handle = Native::Network::HTTPClient.register_stream(request)

    Native::Network::HTTPClient.dispatch_stream_chunk(handle, Bytes[1, 2, 3])
    Native::Network::HTTPClient.dispatch_stream_chunk(handle, Bytes[4, 5])
    received.should eq([Bytes[1, 2, 3], Bytes[4, 5]])

    Native::Network::HTTPClient.dispatch_stream_complete(handle, 201)
    completed.should eq([201])

    # Completion unregisters: a late chunk finds no handler and must
    # not raise.
    Native::Network::HTTPClient.dispatch_stream_chunk(handle, Bytes[9])
    received.size.should eq(2)

    Native::Network::HTTPClient.dispatch_stream_error(handle, "late failure")
    errored.should be_empty
  end

  it "delivers errors and unregisters" do
    errored = [] of String
    request = Native::Network::Request.new
    request.on_error = ->(message : String) { errored << message; nil }
    handle = Native::Network::HTTPClient.register_stream(request)

    Native::Network::HTTPClient.dispatch_stream_error(handle, "connection reset")
    errored.should eq(["connection reset"])

    Native::Network::HTTPClient.dispatch_stream_error(handle, "again")
    errored.size.should eq(1)
  end
end

describe "Native::Network::Request" do
  it "exposes the streaming completion hooks" do
    request = Native::Network::Request.new
    request.on_complete.should be_nil
    request.on_error.should be_nil

    fired = [] of Int32
    request.on_complete = ->(status : Int32) { fired << status; nil }
    request.on_complete.try(&.call(200))
    fired.should eq([200])
  end
end

describe "Native::Network::HTTPClient (desktop reachability)" do
  it "keeps the synchronous request path type-checked" do
    # HTTPClient#get without a block did not exist until 0.1.10, and the
    # execute path was unreachable by any spec — Crystal never compiled
    # it. Capturing the method in a proc forces the whole chain
    # (get -> execute -> execute_desktop_*) through semantic analysis
    # without performing any network I/O.
    client = Native::Network::HTTPClient.new("http://127.0.0.1:1")
    get_probe = ->(path : String) { client.get(path) }
    stream_probe = ->(path : String) { client.get(path) { |chunk| chunk.size } }
    post_probe = ->(path : String, body : String) { client.post(path, body) }

    get_probe.should_not be_nil
    stream_probe.should_not be_nil
    post_probe.should_not be_nil
  end
end
