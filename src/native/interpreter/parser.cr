module Native::Interpreter
  class Parser
    @source : String
    @lines : Array(String)
    @counter : Int32 = 0

    def initialize(@source : String)
      @lines = @source.split('\n')
    end

    def parse : AppNode
      app = AppNode.new
      app.error_message = nil

      begin
        class_name = extract_class_name
        app.class_name = class_name if class_name
        app.title = "#{class_name || "App"} — native.cr Preview"

        setup_body = extract_setup_body
        if setup_body.nil?
          app.error_message = "No 'def setup' method found"
          return app
        end

        vars = build_variable_table(setup_body)
        root = build_tree(setup_body, vars)
        app.root = root
        app.state_vars = extract_preserve_vars(@source)
      rescue e
        app.error_message = "Parse error: #{e.message}"
      end

      app
    end

    private def next_id(prefix : String = "node") : String
      @counter += 1
      "#{prefix}_#{@counter}"
    end

    private def extract_class_name : String?
      @lines.each do |line|
        if m = line.match(/class\s+(\w+)\s*<\s*(?:Native::)?App/)
          return m[1]
        end
      end
      nil
    end

    private def extract_setup_body : String?
      in_setup = false
      found_setup = false
      depth = 0
      body_lines = [] of String

      @lines.each do |line|
        stripped = line.strip

        if !in_setup && stripped =~ /def\s+setup\b/
          in_setup = true
          found_setup = true
          depth = 1
          next
        end

        if in_setup
          depth += stripped.scan(/\b(do|begin|if|unless|case|while|until|for|def|class|module|loop)\b/).size
          depth += stripped.scan(/\bdo\s*(\|[^|]*\|)?\s*$/).size
          depth += (stripped == "{" ? 1 : 0)
          depth -= stripped.scan(/\bend\b/).size
          depth -= (stripped == "}" ? 1 : 0)

          break if depth <= 0

          body_lines << line
        end
      end

      return nil unless found_setup
      body_lines.join('\n')
    end

    private def build_variable_table(body : String) : Hash(String, UINode)
      vars = {} of String => UINode
      body.split('\n').each do |line|
        stripped = line.strip
        next if stripped.starts_with?('#')

        if m = stripped.match(/^(\w+)\s*=\s*(.+)$/)
          var_name = m[1]
          rhs = m[2].strip
          node = parse_widget(rhs)
          vars[var_name] = node if node
        end
      end
      vars
    end

    private def build_tree(body : String, vars : Hash(String, UINode)) : UINode
      lines = body.split('\n').map(&.strip).reject { |l| l.empty? || l.starts_with?('#') }

      add_relationships(lines, vars)

      top_level = find_top_level_nodes(lines, vars)

      if top_level.size == 1
        return top_level.first
      end

      root_layout = LinearLayoutNode.new(next_id("root_layout"), Orientation::Vertical)

      if top_level.empty?
        vars.values.each { |v| root_layout.add_child(v) }
      else
        top_level.each { |n| root_layout.add_child(n) }
      end

      root_layout
    end

    private def add_relationships(lines : Array(String), vars : Hash(String, UINode))
      lines.each do |line|
        if m = line.match(/^(\w+)\.add(?:_child|_view)?\((\w+)(?:,.*?)?\)/)
          parent_name = m[1]
          child_name = m[2]
          parent = vars[parent_name]?
          child = vars[child_name]?
          parent.add_child(child) if parent && child
        end

        apply_property(line, vars)
      end
    end

    private def apply_property(line : String, vars : Hash(String, UINode))
      if m = line.match(/^(\w+)\.text\s*=\s*["'](.+?)["']/)
        node = vars[m[1]]?
        if node.is_a?(TextViewNode)
          node.text = m[2]
        end
      end

      if m = line.match(/^(\w+)\.text_size\s*=\s*(\d+)/)
        node = vars[m[1]]?
        if node.is_a?(TextViewNode)
          node.text_size = m[2].to_i
        end
      end

      if m = line.match(/^(\w+)\.placeholder\s*=\s*["'](.+?)["']/)
        node = vars[m[1]]?
        if node.is_a?(EditTextNode)
          node.placeholder = m[2]
        end
      end

      if m = line.match(/^(\w+)\.checked\s*=\s*(true|false)/)
        node = vars[m[1]]?
        if node.is_a?(CheckboxNode)
          node.checked = m[2] == "true"
        end
      end

      if m = line.match(/^(\w+)\.on_click\s*\{(.+?)\}/)
        node = vars[m[1]]?
        if node.is_a?(ButtonNode)
          node.on_click_body = m[2].strip
        end
      end

      if m = line.match(/^(\w+)\.value\s*=\s*([\d.]+)/)
        node = vars[m[1]]?
        if node.is_a?(SliderNode)
          node.value = m[2].to_f32
        elsif node.is_a?(ProgressBarNode)
          node.value = m[2].to_f32
        end
      end
    end

    private def find_top_level_nodes(lines : Array(String), vars : Hash(String, UINode)) : Array(UINode)
      children_names = Set(String).new

      lines.each do |line|
        if m = line.match(/^(\w+)\.add(?:_child|_view)?\((\w+)/)
          children_names.add(m[2])
        end
      end

      top = [] of UINode
      lines.each do |line|
        if m = line.match(/^(\w+)\s*=\s*/)
          var_name = m[1]
          node = vars[var_name]?
          top << node if node && !children_names.includes?(var_name)
        end
      end

      top
    end

    private def parse_widget(expr : String) : UINode?
      case expr
      when /^(?:Native::UI::)?TextView\.new\(["'](.+?)["']\)/
        TextViewNode.new(next_id("tv"), $~[1])
      when /^(?:Native::UI::)?TextView\.new\(\)/
        TextViewNode.new(next_id("tv"), "")
      when /^(?:Native::UI::)?Button\.new\(["'](.+?)["']\)/
        ButtonNode.new(next_id("btn"), $~[1])
      when /^(?:Native::UI::)?Button\.new\(\)/
        ButtonNode.new(next_id("btn"), "Button")
      when /^(?:Native::UI::)?EditText\.new\(["'](.+?)["']\)/
        EditTextNode.new(next_id("et"), $~[1])
      when /^(?:Native::UI::)?EditText\.new\(\)/
        EditTextNode.new(next_id("et"), "Enter text...")
      when /^(?:Native::UI::)?CheckBox\.new\(["'](.+?)["']\)/
        CheckboxNode.new(next_id("cb"), $~[1])
      when /^(?:Native::UI::)?CheckBox\.new\(\)/
        CheckboxNode.new(next_id("cb"), "Option")
      when /^(?:Native::UI::)?LinearLayout\.new\(:vertical\)/
        LinearLayoutNode.new(next_id("layout"), Orientation::Vertical)
      when /^(?:Native::UI::)?LinearLayout\.new\(:horizontal\)/
        LinearLayoutNode.new(next_id("layout"), Orientation::Horizontal)
      when /^(?:Native::UI::)?LinearLayout\.new\(\)/
        LinearLayoutNode.new(next_id("layout"), Orientation::Vertical)
      when /^(?:Native::UI::)?CardView\.new\(\)/
        CardViewNode.new(next_id("card"))
      when /^(?:Native::UI::)?ScrollView\.new\(\)/
        ScrollViewNode.new(next_id("scroll"))
      when /^(?:Native::UI::)?ProgressBar\.new\(\)/
        ProgressBarNode.new(next_id("pb"))
      when /^(?:Native::UI::)?SeekBar\.new\((.+?),\s*(.+?),\s*(.+?)\)/
        min = $~[1].to_f32
        max = $~[2].to_f32
        label = $~[3].gsub(/["']/, "")
        SliderNode.new(next_id("slider"), label, min, max)
      when /^(?:Native::UI::)?SeekBar\.new\(\)/
        SliderNode.new(next_id("slider"), "Value", 0.0f32, 1.0f32)
      when /^(?:Native::UI::)?ImageView\.new\(["']?(.+?)["']?\)/
        ImageViewNode.new(next_id("img"), $~[1])
      when /^(?:Native::UI::)?ImageView\.new\(\)/
        ImageViewNode.new(next_id("img"))
      else
        nil
      end
    end

    private def extract_preserve_vars(source : String) : Hash(String, String)
      result = {} of String => String
      source.scan(/@\[Preserve\]\s*\n\s*@(\w+)\s*[:=]\s*(.+)/) do |m|
        result[m[1]] = m[2].strip
      end
      result
    end
  end
end
