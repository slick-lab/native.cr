# spec/game_loop_spec.cr

require "./spec_helper"

describe Native::GameLoop::LoopConfig do
  it "has default values" do
    config = Native::GameLoop::LoopConfig.new
    config.mode.should eq(Native::GameLoop::LoopMode::Adaptive)
    config.target_fps.should eq(60)
    config.fixed_update_rate.should eq(1.0 / 60.0)
    config.max_frame_time.should eq(0.25)
  end

  it "allows custom configuration" do
    config = Native::GameLoop::LoopConfig.new
    config.mode = Native::GameLoop::LoopMode::Fixed
    config.target_fps = 30
    config.fixed_update_rate = 1.0 / 30.0
    config.max_frame_time = 0.1
    config.mode.should eq(Native::GameLoop::LoopMode::Fixed)
    config.target_fps.should eq(30)
    config.fixed_update_rate.should eq(1.0 / 30.0)
    config.max_frame_time.should eq(0.1)
  end
end

describe Native::GameLoop::GameLoop do
  it "creates game loop with default config" do
    loop = Native::GameLoop::GameLoop.new
    loop.is_running?.should be_false
  end

  it "starts and stops" do
    loop = Native::GameLoop::GameLoop.new
    loop.start
    sleep 0.1
    loop.is_running?.should be_true
    loop.stop
    loop.is_running?.should be_false
  end

  it "triggers on_start callback" do
    started = false
    loop = Native::GameLoop::GameLoop.new
    loop.on_start { started = true }
    loop.start
    sleep 0.1
    started.should be_true
    loop.stop
  end

  it "triggers on_update callback" do
    updated = false
    loop = Native::GameLoop::GameLoop.new
    loop.on_update { |delta| updated = true }
    loop.start
    sleep 0.1
    updated.should be_true
    loop.stop
  end

  it "returns FPS after running" do
    loop = Native::GameLoop::GameLoop.new
    loop.start
    sleep 1.0
    loop.fps.should be > 0
    loop.stop
  end

  it "pauses and resumes" do
    updated = 0
    loop = Native::GameLoop::GameLoop.new
    loop.on_update { |delta| updated += 1 }
    loop.start
    sleep 0.1
    loop.pause
    count_after_pause = updated
    sleep 0.1
    updated.should eq(count_after_pause)
    loop.resume
    sleep 0.1
    updated.should be > count_after_pause
    loop.stop
  end
end

describe Native::GameLoop::FixedGameLoop do
  it "creates fixed timestep loop" do
    loop = Native::GameLoop::FixedGameLoop.new(60)
    loop.target_fps = 60
    loop.start
    sleep 0.1
    loop.is_running?.should be_true
    loop.stop
  end
end

describe Native::GameLoop::VariableGameLoop do
  it "creates variable timestep loop" do
    loop = Native::GameLoop::VariableGameLoop.new(60)
    loop.start
    sleep 0.1
    loop.is_running?.should be_true
    loop.stop
  end
end
