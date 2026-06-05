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
