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

    def self.load(json : String, obj : JSON::Serializable) : Nil
      temp = obj.class.from_json(json)
      copy_properties(temp, obj)
    rescue ex : Exception
      raise DeserializationError.new("Failed to load state: #{ex.message}")
    end

    def self.copy_properties(source : JSON::Serializable, target : JSON::Serializable) : Nil
      source_json = source.to_json
      target.from_json(source_json)
    rescue ex : Exception
      raise DeserializationError.new("Failed to copy properties: #{ex.message}")
    end

    def self.capture_and_restore(obj : JSON::Serializable, &block) : Nil
      saved_state = save(obj)
      block.call
      load(saved_state, obj)
    end

    def self.valid_json?(json : String) : Bool
      JSON.parse(json)
      true
    rescue
      false
    end

    def self.pretty(obj : JSON::Serializable) : String
      obj.to_json(pretty: true)
    end
  end
end
