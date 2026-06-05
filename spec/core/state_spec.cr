# spec/core/state_spec.cr

require "../spec_helper"

class TestApp
  include JSON::Serializable
  
  property name : String
  property score : Int32
  property active : Bool

  def initialize(@name = "", @score = 0, @active = false)
  end
end

describe Native::Core::State do
  describe "#save" do
    it "serializes object to JSON" do
      app = TestApp.new
      app.name = "test"
      app.score = 100
      
      json = Native::Core::State.save(app)
      
      json.should contain("\"name\":\"test\"")
      json.should contain("\"score\":100")
    end
    
    it "serializes object with multiple property types" do
      app = TestApp.new
      app.name = "complex"
      app.score = 42
      app.active = true
      
      json = Native::Core::State.save(app)
      
      json.should contain("\"name\":\"complex\"")
      json.should contain("\"score\":42")
      json.should contain("\"active\":true")
    end
  end
  
  describe "#load" do
    it "deserializes JSON into object" do
      json = %({"name":"restored","score":50,"active":true})
      app = Native::Core::State.load(json, TestApp)
      
      app.name.should eq("restored")
      app.score.should eq(50)
      app.active.should eq(true)
    end
    
    it "preserves existing values for missing JSON fields" do
      json = %({"active":true})
      app = Native::Core::State.load(json, TestApp)
      
      app.name.should eq("")
      app.score.should eq(0)
      app.active.should eq(true)
    end
  end
  
  describe "#capture_and_restore" do
    it "saves state, runs block, restores state" do
      app = TestApp.new
      app.score = 100
      app.name = "original"
      
      result = Native::Core::State.capture_and_restore(app) do
        app.score = 200
        app.name = "changed"
        "result"
      end
      
      app.score.should eq(100)
      app.name.should eq("original")
      result.should eq("result")
    end
  end
  
  describe "#valid_json?" do
    it "returns true for valid JSON object" do
      Native::Core::State.valid_json?("{\"key\":\"value\"}").should be_true
    end
    
    it "returns false for invalid JSON" do
      Native::Core::State.valid_json?("not json").should be_false
    end
  end
  
  describe "#pretty" do
    it "returns pretty printed JSON" do
      app = TestApp.new
      app.name = "pretty"
      app.score = 123
      
      pretty = Native::Core::State.pretty(app)
      
      pretty.should contain("\n")
      pretty.should contain("  ")
    end
  end
end
