# spec/network_edge_spec.cr
#
# Edge cases and failure paths for the network request/response models.
# Pure logic only — no sockets, no device.

require "./spec_helper"
require "json"

describe Native::Network::Request do
  it "defaults to a plain GET with no url, body or streaming" do
    request = Native::Network::Request.new
    request.method.should eq(Native::Network::Method::GET)
    request.url.should be_empty
    request.body.should be_empty
    request.timeout.should eq(30.0)
    request.stream.should be_false
    request.chunk_handler.should be_nil
    request.headers.should be_empty
  end

  it "exposes all six HTTP methods" do
    Native::Network::Method.values.size.should eq(6)
    Native::Network::Method::HEAD.should_not be_nil
  end

  it "replaces a header when the same key is added twice" do
    request = Native::Network::Request.new
    request.add_header("Authorization", "Bearer old")
    request.add_header("Authorization", "Bearer new")
    request.headers["Authorization"].should eq("Bearer new")
    request.headers.size.should eq(1)
  end

  it "keeps multiple distinct headers" do
    request = Native::Network::Request.new
    request.add_header("Accept", "application/json")
    request.add_header("X-Custom", "1")
    request.headers.size.should eq(2)
  end

  it "sets a json body and the matching content type" do
    request = Native::Network::Request.new
    request.json = %({"a": 1})
    request.body.should eq(%({"a": 1}))
    request.headers["Content-Type"].should eq("application/json")
  end

  it "replaces a previous json body and content type when form encoding is used" do
    request = Native::Network::Request.new
    request.json = %({"a": 1})
    request.form = {"name" => "hello world"}
    request.headers["Content-Type"].should eq("application/x-www-form-urlencoded")
    request.body.should eq("name=hello%20world")
  end

  it "leaves reserved characters unescaped in form bodies (documents current behavior)" do
    request = Native::Network::Request.new
    request.form = {"query" => "a&b=c"}
    # URI.encode keeps & and = as-is, so values containing reserved
    # characters currently produce an ambiguous form body. Pinning the
    # behavior here — switching to URI.encode_www_form would be a fix.
    request.body.should eq("query=a&b=c")
  end

  it "percent-encodes unicode in form bodies" do
    request = Native::Network::Request.new
    request.form = {"q" => "café"}
    request.body.should eq("q=caf%C3%A9")
  end

  it "enables streaming and stores the chunk handler" do
    request = Native::Network::Request.new
    received = [] of Bytes
    request.on_chunk { |bytes| received << bytes }
    request.stream.should be_true
    request.chunk_handler.should_not be_nil
  end
end

describe Native::Network::Response do
  it "starts as a failed empty response" do
    response = Native::Network::Response.new
    response.status_code.should eq(0)
    response.success.should be_false
    response.ok?.should be_false
    response.client_error?.should be_false
    response.server_error?.should be_false
    response.error.should be_nil
  end

  it "classifies the 2xx boundary exactly" do
    failed = Native::Network::Response.new
    failed.status_code = 199
    failed.ok?.should be_false

    first_ok = Native::Network::Response.new
    first_ok.status_code = 200
    first_ok.ok?.should be_true

    last_ok = Native::Network::Response.new
    last_ok.status_code = 299
    last_ok.ok?.should be_true

    redirect = Native::Network::Response.new
    redirect.status_code = 300
    redirect.ok?.should be_false
  end

  it "classifies the 4xx boundary exactly" do
    not_error = Native::Network::Response.new
    not_error.status_code = 399
    not_error.client_error?.should be_false

    first_client = Native::Network::Response.new
    first_client.status_code = 400
    first_client.client_error?.should be_true

    teapot = Native::Network::Response.new
    teapot.status_code = 418
    teapot.client_error?.should be_true

    last_client = Native::Network::Response.new
    last_client.status_code = 499
    last_client.client_error?.should be_true

    first_server = Native::Network::Response.new
    first_server.status_code = 500
    first_server.client_error?.should be_false
  end

  it "classifies the 5xx boundary exactly" do
    first_server = Native::Network::Response.new
    first_server.status_code = 500
    first_server.server_error?.should be_true

    last_server = Native::Network::Response.new
    last_server.status_code = 599
    last_server.server_error?.should be_true

    beyond = Native::Network::Response.new
    beyond.status_code = 600
    beyond.server_error?.should be_false
  end

  it "classifies a 301 redirect as neither ok, client error nor server error" do
    response = Native::Network::Response.new
    response.status_code = 301
    response.ok?.should be_false
    response.client_error?.should be_false
    response.server_error?.should be_false
  end

  it "returns nil json when the request failed, even with a parseable body" do
    response = Native::Network::Response.new
    response.success = false
    response.body = %({"key": "value"})
    response.json.should be_nil
  end

  it "raises on a malformed json body of a successful response (documents current behavior)" do
    response = Native::Network::Response.new
    response.success = true
    response.body = "{not valid json"
    expect_raises(JSON::ParseException) { response.json }
  end

  it "raises on an empty json body of a successful response (documents current behavior)" do
    response = Native::Network::Response.new
    response.success = true
    response.body = ""
    expect_raises(JSON::ParseException) { response.json }
  end

  it "parses a top-level json array body" do
    response = Native::Network::Response.new
    response.success = true
    response.body = "[1, 2, 3]"
    response.json.try(&.as_a.size).should eq(3)
  end

  it "parses nested json structures" do
    response = Native::Network::Response.new
    response.success = true
    response.body = %({"a": {"b": [1, 2]}, "count": 42})
    json = response.json
    json.should_not be_nil
    json.try(&.["a"]["b"].as_a.size).should eq(2)
    json.try(&.["count"].as_i).should eq(42)
  end

  it "keeps response headers accessible" do
    response = Native::Network::Response.new
    response.headers["Content-Type"] = "application/json"
    response.headers["Content-Type"].should eq("application/json")
  end
end
