# spec/preserve_state_spec.cr
#
# The hot-reload state DSL: `@[Preserve]` ivars of an App subclass must
# round-trip through state_to_json / state_from_json without any user
# serialization code.

require "./spec_helper"

# A stand-in app mirroring the documented counter example.
class PreserveSpecApp < Native::App
  @[Preserve]
  property count : Int32 = 0

  @[Preserve]
  property title : String = "untitled"

  @[Preserve]
  property score : Float64 = 0.0

  @[Preserve]
  property active : Bool = false

  @[Preserve]
  property tags : Array(String) = [] of String

  @[Preserve]
  property maybe : String? = nil

  # Deliberately NOT annotated — must never appear in state.
  property transient : Int32 = 99

  def setup : Nil
  end
end

# Second subclass with different state: proves the serializer is
# generated per actual subclass, not shared across App.
class OtherStateApp < Native::App
  @[Preserve]
  property level : Int32 = 1

  def setup : Nil
  end
end

class EmptyStateApp < Native::App
  def setup : Nil
  end
end

describe "hot-reload state DSL" do
  app = PreserveSpecApp.new

  it "serializes annotated ivars only" do
    app.count = 42
    app.title = "Hello"
    app.score = 3.5
    app.active = true
    app.tags = ["a", "b"]
    app.maybe = "set"
    app.transient = 7

    json = app.state_to_json
    parsed = JSON.parse(json).as_h

    parsed.keys.should contain("count")
    parsed.keys.should contain("title")
    parsed.keys.should contain("score")
    parsed.keys.should contain("active")
    parsed.keys.should contain("tags")
    parsed.keys.should contain("maybe")
    # Unannotated state is invisible to the serializer.
    parsed.keys.should_not contain("transient")
    parsed["count"].as_i.should eq(42)
    parsed["title"].as_s.should eq("Hello")
    parsed["score"].as_f.should eq(3.5)
    parsed["active"].as_bool.should be_true
    parsed["tags"].as_a.map(&.as_s).should eq(["a", "b"])
  end

  it "restores state onto a fresh instance" do
    app.count = 42
    app.title = "Hello"
    app.score = 3.5
    app.active = true
    app.tags = ["a", "b"]
    app.maybe = "set"

    fresh = PreserveSpecApp.new
    fresh.state_from_json(app.state_to_json)

    fresh.count.should eq(42)
    fresh.title.should eq("Hello")
    fresh.score.should eq(3.5)
    fresh.active.should be_true
    fresh.tags.should eq(["a", "b"])
    fresh.maybe.should eq("set")
    # Non-preserved ivar keeps its own default.
    fresh.transient.should eq(99)
  end

  it "keeps defaults when keys are missing" do
    fresh = PreserveSpecApp.new
    fresh.state_from_json(%({"count": 7}))

    fresh.count.should eq(7)
    fresh.title.should eq("untitled")
    fresh.score.should eq(0.0)
  end

  it "ignores corrupt state instead of crashing" do
    fresh = PreserveSpecApp.new
    fresh.state_from_json("not json {{{")
    fresh.count.should eq(0)
  end

  it "serializes nil as null and back" do
    app.maybe = nil
    fresh = PreserveSpecApp.new
    fresh.maybe = "temp"
    fresh.state_from_json(app.state_to_json)
    fresh.maybe.should be_nil
  end

  it "generates {} for apps without preserved state" do
    EmptyStateApp.new.state_to_json.should eq("{}")
    OtherStateApp.new.state_to_json.should contain("level")
  end

  it "is per-subclass, not shared" do
    other = OtherStateApp.new
    other.level = 9
    json = other.state_to_json
    json.should contain("level")
    json.should_not contain("count")
  end

  it "Core::State validates JSON strings" do
    Native::Core::State.valid_json?(%({"a": 1})).should be_true
    Native::Core::State.valid_json?("not json").should be_false
  end
end
