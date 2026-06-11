# spec/storage_spec.cr

require "./spec_helper"

describe Native::Storage::Preferences do
  it "sets and gets string" do
    prefs = Native::Storage::Preferences.new
    prefs.set("test_string", "hello")
    prefs.get_string("test_string").should eq("hello")
  end

  it "sets and gets integer" do
    prefs = Native::Storage::Preferences.new
    prefs.set("test_int", 42)
    prefs.get_int("test_int").should eq(42)
  end

  it "sets and gets boolean" do
    prefs = Native::Storage::Preferences.new
    prefs.set("test_bool", true)
    prefs.get_bool("test_bool").should be_true
  end

  it "returns default when key not found" do
    prefs = Native::Storage::Preferences.new
    prefs.get_string("missing", "default").should eq("default")
    prefs.get_int("missing", 99).should eq(99)
    prefs.get_bool("missing", true).should be_true
  end

  it "deletes key" do
    prefs = Native::Storage::Preferences.new
    prefs.set("to_delete", "value")
    prefs.delete("to_delete")
    prefs.get_string("to_delete", "").should eq("")
  end

  it "checks if key exists" do
    prefs = Native::Storage::Preferences.new
    prefs.set("exists", "yes")
    prefs.contains?("exists").should be_true
    prefs.contains?("not_exists").should be_false
  end
end
