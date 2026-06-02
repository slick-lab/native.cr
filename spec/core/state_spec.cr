# spec/core/state_spec.cr

require "../spec_helper"

class TestApp
  include JSON::Serializable
  
  property name : String = ""
  property score : Int32 = 0
  property active : Bool = false
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
    
    it "raises SerializationError on invalid object" do
      expect_raises(Native::Core::State::SerializationError) do
        Native::Core::State.save(Box.new(123))
      end
    end
  end
  
  describe "#load" do
    it "deserializes JSON into object" do
      app = TestApp.new
      json = %({"name":"restored","score":50,"active":true})
      
      Native::Core::State.load(json, app)
      
      app.name.should eq("restored")
      app.score.should eq(50)
      app.active.should eq(true)
    end
    
    it "raises DeserializationError on invalid JSON" do
      app = TestApp.new
      expect_raises(Native::Core::State::DeserializationError) do
        Native::Core::State.load("{invalid json}", app)
      end
    end
  end
  
  describe "#capture_and_restore" do
    it "saves state, runs block, restores state" do
      app = TestApp.new
      app.score = 100
      
      Native::Core::State.capture_and_restore(app) do
        app.score = 200
      end
      
      app.score.should eq(100)
    end
  end
  
  describe "#valid_json?" do
    it "returns true for valid JSON" do
      Native::Core::State.valid_json?('{"key":"value"}').should be_true
    end
    
    it "returns false for invalid JSON" do
      Native::Core::State.valid_json?("not json").should be_false
    end
  end
  
  describe "#pretty" do
    it "returns pretty printed JSON" do
      app = TestApp.new
      app.name = "test"
      
      pretty = Native::Core::State.pretty(app)
      
      pretty.should contain("\n")
      pretty.should contain("  ")
    end
  end
end
