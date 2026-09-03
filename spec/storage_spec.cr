# spec/storage_spec.cr
#
# This file sat as spec/storage.cr for ages, which `crystal spec` never picks
# up — its tests were silently skipped. It is enabled now, with the tests
# adjusted to what a desktop (no device) build actually does: Preferences is
# a no-op stub that returns whatever default it is given.

require "./spec_helper"

describe Native::Storage::Preferences do
  it "falls back to the default string on a desktop build" do
    prefs = Native::Storage::Preferences.new
    prefs.set("test_string", "hello") # no-op without an Android/iOS backend
    prefs.get_string("test_string").should eq("")
    prefs.get_string("test_string", "fallback").should eq("fallback")
  end

  it "falls back to the default int on a desktop build" do
    prefs = Native::Storage::Preferences.new
    prefs.set("test_int", 42) # no-op without an Android/iOS backend
    prefs.get_int("test_int").should eq(0)
    prefs.get_int("test_int", 99).should eq(99)
  end

  it "falls back to the default bool on a desktop build" do
    prefs = Native::Storage::Preferences.new
    prefs.set("test_bool", true) # no-op without an Android/iOS backend
    prefs.get_bool("test_bool").should be_false
    prefs.get_bool("test_bool", true).should be_true
  end

  it "returns default when key not found" do
    prefs = Native::Storage::Preferences.new
    prefs.get_string("missing", "default").should eq("default")
    prefs.get_int("missing", 99).should eq(99)
    prefs.get_bool("missing", true).should be_true
  end

  it "deletes key without complaints on a desktop build" do
    prefs = Native::Storage::Preferences.new
    prefs.set("to_delete", "value")
    prefs.delete("to_delete")
    prefs.get_string("to_delete", "").should eq("")
  end

  it "reports no keys on a desktop build" do
    prefs = Native::Storage::Preferences.new
    prefs.set("exists", "yes") # no-op without an Android/iOS backend
    prefs.contains?("exists").should be_false
    prefs.contains?("not_exists").should be_false
    prefs.all_keys.should be_empty
  end
end

describe Native::Storage::FileStorage do
  it "reports unavailable file operations on a desktop build" do
    storage = Native::Storage::FileStorage.new
    storage.write_text("native-cr-spec.txt", "hello").should be_false
    storage.read_text("native-cr-spec.txt").should be_nil
    storage.exists?("native-cr-spec.txt").should be_false
    storage.delete("native-cr-spec.txt").should be_false
    storage.list.should be_empty
  end
end

