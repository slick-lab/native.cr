# src/native/cli/reload.cr

require "../core/process"

def run_reload(entry_file : String)
  config = Native::Process::Config.new
  config.entry_point = entry_file
  
  manager = Native::Process::Manager.new(config)
  manager.start
end

if ARGV.size > 0
  entry = ARGV[0]
  if File.exists?(entry)
    run_reload(entry)
  else
    puts "File not found: #{entry}"
  end
end
