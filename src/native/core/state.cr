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
      klass.from_json(json)
    rescue ex : Exception
      raise DeserializationError.new("Failed to load state: #{ex.message}")
    end

    def self.capture_and_restore(obj : JSON::Serializable, &block)
      saved_state = save(obj)
      result = block.call
      loaded = load(saved_state, obj.class)
      copy_properties(loaded, obj)
      result
    end

    private def self.copy_properties(source : JSON::Serializable, target : JSON::Serializable) : Nil
      source_json = source.to_json
      target.from_json(source_json)
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
