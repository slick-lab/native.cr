
abstract class NativeApp
  include JSON::Serializable
  
  macro preserve
    {% preserve_vars = @type.instance_vars.select { |var| var.has_annotation! Preserve } %}
    
    def to_json : String
      {
        {% for var in preserve_vars %}
          {{var.name.stringify}}: @{{var.name}},
        {% end %}
      }.to_json
    end
    
    def from_json(json : String) : Nil
      data = JSON.parse(json)
      {% for var in preserve_vars %}
        if data.has_key?({{var.name.stringify}})
          @{{var.name}} = data[{{var.name.stringify}}].as({{var.type}})
        end
      {% end %}
    end
  end
  
  annotation Preserve; end
  
  def initialize
    setup_signal_handlers
  end
  
  private def setup_signal_handlers
    Signal::USR1.trap do
      save_state
    end
    
    Signal::TERM.trap do
      save_state
      exit(0)
    end
  end
  
  private def save_state
    state_file = ENV["NATIVE_CR_STATE_FILE"]?
    
    if state_file
      begin
        json = to_json
        File.write(state_file, json)
        STDERR.puts "[native.cr] State saved to #{state_file}"
      rescue ex
        STDERR.puts "[native.cr] Failed to save state: #{ex.message}"
      end
    end
  end
  
  protected def load_saved_state
    state_file = ENV["NATIVE_CR_STATE_FILE"]?
    
    if state_file && File.exists?(state_file)
      begin
        json = File.read(state_file)
        from_json(json)
        STDERR.puts "[native.cr] State loaded from #{state_file}"
        File.delete(state_file)
      rescue ex
        STDERR.puts "[native.cr] Failed to load state: #{ex.message}"
      end
    end
  end
  
  abstract def render : String
  abstract def run : Nil
  
  def self.start
    app = new
    app.load_saved_state
    app.run
  end
end
