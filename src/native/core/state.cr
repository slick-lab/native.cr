# native/cr/src/core/state.cr
# The state management foundation for native.cr
# Handles saving and restoring app state across fast restarts

module NativeCR
  module State
    # Error types for state operations
    class SerializationError < Exception
    end
    
    class DeserializationError < Exception
    end
    
    # Save any object that includes JSON::Serializable
    def self.save(obj : JSON::Serializable) : String
      obj.to_json
    rescue ex : Exception
      raise SerializationError.new("Failed to save state: #{ex.message}")
    end
    
    # Load JSON into an existing object that includes JSON::Serializable
    def self.load(json : String, obj : JSON::Serializable) : Nil
      obj.from_json(json)
    rescue ex : Exception
      raise DeserializationError.new("Failed to load state: #{ex.message}")
    end
    
    # Save + load in one operation (for process restart)
    def self.capture_and_restore(obj : JSON::Serializable, &block) : Nil
      saved_state = save(obj)
      block.call
      load(saved_state, obj)
    end
    
    # Check if a string is valid JSON (simple validation)
    def self.valid_json?(json : String) : Bool
      JSON.parse(json)
      true
    rescue
      false
    end
    
    # Pretty print state for debugging
    def self.pretty(obj : JSON::Serializable) : String
      obj.to_json pretty: true
    end
  end
end
