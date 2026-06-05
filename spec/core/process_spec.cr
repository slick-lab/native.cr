# spec/core/process_spec.cr

require "../spec_helper"
require "file_utils"

describe Native::Core::Process do
  describe Native::Core::Process::Config do
    it "has default values" do
      config = Native::Core::Process::Config.new

      config.entry_point.should eq("src/main.cr")
      config.watch_paths.should eq(["./src"])
      config.build_output.should eq("./.native_cache/app")
      config.state_file.should eq("./.native_cache/state.json")
    end

    it "allows overriding values" do
      config = Native::Core::Process::Config.new
      config.entry_point = "app.cr"
      config.watch_paths = ["src", "lib"]

      config.entry_point.should eq("app.cr")
      config.watch_paths.should eq(["src", "lib"])
    end
  end

  describe Watcher do
    it "detects file changes" do
      Dir.mkdir_p("test_spec/src")
      File.write("test_spec/src/test.cr", "puts 'hello'")

      changed = false
      watcher = Native::Core::Process::Watcher.new(["test_spec/src"]) do |file|
        changed = true
      end

      watcher.check.should be_false

      File.write("test_spec/src/test.cr", "puts 'world'")
      watcher.check.should be_true

      FileUtils.rm_rf("test_spec")
    end

    it "calls callback on change" do
      Dir.mkdir_p("test_spec/src")
      File.write("test_spec/src/test.cr", "puts 'hello'")

      callback_called = false
      watcher = Native::Core::Process::Watcher.new(["test_spec/src"]) do |file|
        callback_called = true
        file.should contain("test.cr")
      end

      File.write("test_spec/src/test.cr", "puts 'world'")
      watcher.check

      callback_called.should be_true

      FileUtils.rm_rf("test_spec")
    end
  end

  describe Manager do
    it "creates cache directory" do
      config = Native::Core::Process::Config.new
      config.build_output = "./test_cache/app"
      config.state_file = "./test_cache/state.json"

      manager = Native::Core::Process::Manager.new(config)

      Dir.exists?("./test_cache").should be_true

      FileUtils.rm_rf("./test_cache")
    end
  end
end
