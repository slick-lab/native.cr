# src/native/core/state.cr

module Native::Core
  module State
    class SerializationError < Exception
    end

    class DeserializationError < Exception
    end

    def self.save(obj : JSON::Serializable) : String
      obj.to_json
    rescue ex : Exception
      raise SerializationError.new("Failed to save state: #{ex.message}")
    end
def self.load(json : String, klass : JSON::Serializable.class) : JSON::Serializable
  data = JSON.parse(json)
  
  # Create default instance first
  default = klass.new
  
  # Merge JSON into default
  merged = default.to_json
  parsed_merged = JSON.parse(merged)
  
  data.each do |key, value|
    parsed_merged[key] = value
  end
  
  klass.from_json(parsed_merged.to_json)
end

    def self.capture_and_restore(obj : JSON::Serializable, &block) : JSON::Serializable
      saved_state = save(obj)
      block.call
      load(saved_state, obj.class)
    end

    def self.valid_json?(json : String) : Bool
      JSON.parse(json)
      true
    rescue
      false
    end
  end
end
