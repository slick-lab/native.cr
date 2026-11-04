# src/native/core/preserve.cr
#
# The hot-reload state DSL.
#
#   class MyApp < Native::App
#     @[Preserve]
#     property count : Int32 = 0
#   end
#
# `@[Preserve]` marks instance variables whose values should survive a
# hot reload. App#state_to_json / #state_from_json (see app.cr) are
# generated from the annotated variables of the *actual* subclass, so
# state round-trips without writing any serialization code.
#
# Supported types: Bool, Int32, Int64, Float32, Float64, String,
# Array(String), Array(Int32), Array(Float64), JSON::Any, and nilable
# versions thereof. An unsupported annotated type is a compile error —
# a build failure beats silently dropping state.

# Top-level annotation so apps can write the documented bare form:
#
#   @[Preserve] property count : Int32 = 0
#
# inside `class MyApp < Native::App` without a namespace prefix.
annotation Preserve
end

# Namespaced twin for users who prefer explicitness:
#
#   @[Native::Preserve] property count : Int32 = 0
#
module Native
  annotation Preserve
  end

  # Types whose JSON round-trip is defined for @[Preserve] ivars.
  # A plain constant (not a macro) so it can be read from other macros.
  STATE_TYPES = {
    "Bool", "Int32", "Int64", "Float32", "Float64", "String",
    "Array(String)", "Array(Int32)", "Array(Float64)", "JSON::Any",
  }

  # (The type check + extraction logic lives INLINE in app.cr's
  # state_to_json / state_from_json macro bodies: Crystal does not
  # resolve macro calls with arguments from method bodies, so a shared
  # helper macro is unreachable from there. STATE_TYPES above is the
  # single source of truth both sites read.)

  module Core
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
end
