# spec/core/state_spec.cr

require "../spec_helper"

class TestApp
  JSON.mapping(
    name: String,
    score: Int32,
    active: Bool
  )
  def initialize(@name = "", @score = 0, @active = false)
  end
end
class GameState
  include JSON::Serializable
  
  property level : Int32
  property health : Int32
  property items : Array(String)

  def initialize(@level = 1, @health = 100, @items = [] of String)
  end
end

class UserProfile
  include JSON::Serializable
  
  property username : String
  property email : String
  property age : Int32?
  property premium : Bool

  def initialize(@username = "", @email = "", @age = nil, @premium = false)
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
    
    it "serializes GameState with array" do
      game = GameState.new
      game.level = 5
      game.health = 75
      game.items = ["sword", "shield", "potion"]
      
      json = Native::Core::State.save(game)
      
      json.should contain("\"level\":5")
      json.should contain("\"health\":75")
      json.should contain("\"items\":[\"sword\",\"shield\",\"potion\"]")
    end
    
    it "serializes empty object" do
      app = TestApp.new
      json = Native::Core::State.save(app)
      
      json.should contain("\"name\":\"\"")
      json.should contain("\"score\":0")
      json.should contain("\"active\":false")
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
    
    it "deserializes GameState with array" do
      game = GameState.new
      json = %({"level":10,"health":50,"items":["axe","bow"]})
      
      Native::Core::State.load(json, game)
      
      game.level.should eq(10)
      game.health.should eq(50)
      game.items.should eq(["axe", "bow"])
    end
    
    it "deserializes UserProfile with optional age" do
      profile = UserProfile.new
      json = %({"username":"john","email":"john@example.com","age":25,"premium":true})
      
      Native::Core::State.load(json, profile)
      
      profile.username.should eq("john")
      profile.email.should eq("john@example.com")
      profile.age.should eq(25)
      profile.premium.should eq(true)
    end
    
    it "deserializes UserProfile without optional field" do
      profile = UserProfile.new
      json = %({"username":"jane","email":"jane@example.com","premium":false})
      
      Native::Core::State.load(json, profile)
      
      profile.username.should eq("jane")
      profile.email.should eq("jane@example.com")
      profile.age.should be_nil
      profile.premium.should eq(false)
    end
    
    it "preserves existing values for missing JSON fields" do
      app = TestApp.new
      app.name = "existing"
      app.score = 999
      json = %({"active":true})
      
      Native::Core::State.load(json, app)
      
      app.name.should eq("existing")
      app.score.should eq(999)
      app.active.should eq(true)
    end
    
    it "raises DeserializationError on invalid JSON" do
      app = TestApp.new
      expect_raises(Native::Core::State::DeserializationError) do
        Native::Core::State.load("{invalid json}", app)
      end
    end
    
    it "raises DeserializationError on empty string" do
      app = TestApp.new
      expect_raises(Native::Core::State::DeserializationError) do
        Native::Core::State.load("", app)
      end
    end
  end
  
  describe "#capture_and_restore" do
    it "saves state, runs block, restores state" do
      app = TestApp.new
      app.score = 100
      app.name = "original"
      
      Native::Core::State.capture_and_restore(app) do
        app.score = 200
        app.name = "changed"
      end
      
      app.score.should eq(100)
      app.name.should eq("original")
    end
    
    it "restores state even if block raises error" do
      app = TestApp.new
      app.score = 100
      
      begin
        Native::Core::State.capture_and_restore(app) do
          app.score = 200
          raise "Something went wrong"
        end
      rescue
      end
      
      app.score.should eq(100)
    end
    
    it "works with GameState" do
      game = GameState.new
      game.level = 5
      game.health = 100
      game.items = ["sword"]
      
      Native::Core::State.capture_and_restore(game) do
        game.level = 10
        game.health = 50
        game.items = ["axe", "bow"]
      end
      
      game.level.should eq(5)
      game.health.should eq(100)
      game.items.should eq(["sword"])
    end
  end
  
  describe "#valid_json?" do
    it "returns true for valid JSON object" do
      Native::Core::State.valid_json?("{\"key\":\"value\"}").should be_true
    end
    
    it "returns true for valid JSON array" do
      Native::Core::State.valid_json?("[1,2,3]").should be_true
    end
    
    it "returns true for valid JSON string" do
      Native::Core::State.valid_json?("\"hello\"").should be_true
    end
    
    it "returns true for valid JSON number" do
      Native::Core::State.valid_json?("123").should be_true
    end
    
    it "returns true for valid JSON boolean" do
      Native::Core::State.valid_json?("true").should be_true
    end
    
    it "returns true for valid JSON null" do
      Native::Core::State.valid_json?("null").should be_true
    end
    
    it "returns false for invalid JSON" do
      Native::Core::State.valid_json?("not json").should be_false
    end
    
    it "returns false for empty string" do
      Native::Core::State.valid_json?("").should be_false
    end
    
    it "returns false for malformed JSON" do
      Native::Core::State.valid_json?("{\"key\":}").should be_false
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
    
    it "indents nested objects" do
      user = UserProfile.new
      user.username = "nested"
      user.email = "nested@example.com"
      
      pretty = Native::Core::State.pretty(user)
      
      pretty.should contain("\n")
      pretty.lines.size.should be > 1
    end
  end
end
