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

end
