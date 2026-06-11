# spec/network_spec.cr

describe Native::Network::Response do
  it "creates successful response" do
    response = Native::Network::Response.new
    response.status_code = 200
    response.body = "OK"
    response.success = true
    response.ok?.should be_true
    response.success.should be_true
  end

  it "creates client error response" do
    response = Native::Network::Response.new
    response.status_code = 404
    response.body = "Not Found"
    response.success = false
    response.ok?.should be_false
    response.client_error?.should be_true
    response.server_error?.should be_false
  end

  it "creates server error response" do
    response = Native::Network::Response.new
    response.status_code = 500
    response.body = "Internal Error"
    response.success = false
    response.ok?.should be_false
    response.client_error?.should be_false
    response.server_error?.should be_true
  end

  it "parses JSON body" do
    response = Native::Network::Response.new
    response.body = %({"key":"value"})
    response.success = true
    json = response.json
    json.should_not be_nil
    json.try(&.["key"].as_s).should eq("value")
  end
end
