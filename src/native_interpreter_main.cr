require "./native/interpreter/interpreter"

file = ARGV[0]? || "src/main.cr"
Native::Interpreter::Interpreter.new(file).run
