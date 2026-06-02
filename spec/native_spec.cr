# spec/native_spec.cr

require "./spec_helper"

describe Native do
  it "has a version" do
    Native::VERSION.should be_a(String)
    Native::VERSION.should_not be_empty
  end
end
