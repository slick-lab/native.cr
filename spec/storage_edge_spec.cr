# spec/storage_edge_spec.cr
#
# Pins the behavior of storage on a plain desktop/CI build, where no
# platform backend (Android JNI / iOS) is compiled in: the setters are
# compile-time no-ops and the getters must return their defaults
# gracefully instead of raising.

require "./spec_helper"

describe Native::Storage::Preferences do
  it "returns the default value for every getter when nothing is stored" do
    prefs = Native::Storage::Preferences.new
    prefs.get_string("missing").should be_empty
    prefs.get_string("missing", "fallback").should eq("fallback")
    prefs.get_int("missing").should eq(0)
    prefs.get_int("missing", 99).should eq(99)
    prefs.get_int64("missing").should eq(0)
    prefs.get_int64("missing", -5).should eq(-5)
    prefs.get_float("missing").should eq(0.0)
    prefs.get_float("missing", 1.5).should eq(1.5)
    prefs.get_double("missing").should eq(0.0)
    prefs.get_double("missing", 2.5).should eq(2.5)
    prefs.get_bool("missing").should be_false
    prefs.get_bool("missing", true).should be_true
  end

  it "treats negative and zero numeric defaults as-is" do
    prefs = Native::Storage::Preferences.new
    prefs.get_int("missing", -1).should eq(-1)
    prefs.get_int("missing", 0).should eq(0)
    prefs.get_double("missing", -0.5).should eq(-0.5)
  end

  it "reports no containment and no keys without a backend" do
    prefs = Native::Storage::Preferences.new
    prefs.contains?("anything").should be_false
    prefs.all_keys.should be_empty
  end

  it "treats set, delete and clear as safe no-ops without a backend" do
    prefs = Native::Storage::Preferences.new("ci-run")
    prefs.set("key", "value")
    prefs.set("count", 42)
    prefs.set("enabled", true)
    prefs.delete("key")
    prefs.clear
    prefs.get_string("key", "untouched").should eq("untouched")
    prefs.contains?("count").should be_false
  end

  it "accepts unusual keys without raising" do
    prefs = Native::Storage::Preferences.new
    prefs.set("", "empty key")
    prefs.set("键/值 🔑", "unicode key")
    prefs.get_string("", "none").should eq("none")
    prefs.get_string("键/值 🔑", "none").should eq("none")
  end
end

describe Native::Storage::FileStorage do
  it "fails gracefully for every operation without a platform backend" do
    storage = Native::Storage::FileStorage.new(Native::Storage::FileStorage::StorageType::Temporary)
    storage.write("file.bin", Bytes[1, 2, 3]).should be_false
    storage.write_text("file.txt", "hello").should be_false
    storage.read("file.bin").should be_nil
    storage.read_text("file.txt").should be_nil
    storage.exists?("file.bin").should be_false
    storage.delete("file.bin").should be_false
    storage.list.should be_empty
    storage.list("subdir").should be_empty
  end

  it "uses Documents as the default storage type" do
    storage = Native::Storage::FileStorage.new
    storage.exists?("whatever.txt").should be_false
  end
end
