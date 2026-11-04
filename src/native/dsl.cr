# src/native/dsl.cr
#
# Top-level DSL shortcuts. The examples and the getting-started docs write
#
#   class MyApp < Native::App
#     @label = UI::TextView.new("hi")
#     @label.color = Color.from_hex(0x333333)
#
# with bare `UI` / `Color` / `Alignment` / `CornerRadius` names. These
# aliases resolve in BOTH type and expression positions (plain constant
# assignment only works in expressions — `alias` is a real type).
#
# Users who dislike the top-level names can keep using the fully
# qualified forms (`Native::UI::TextView`, `Native::Math::Color`) — both
# styles resolve to the same types.

alias UI        = Native::UI
alias Color     = Native::Math::Color
alias Alignment = Native::UI::Alignment
alias CornerRadius = Native::UI::CornerRadius
