require "./spec_helper"

private def parse(source : String) : Native::Interpreter::AppNode
  Native::Interpreter::Parser.new(source).parse
end

private def find_node(root : Native::Interpreter::UINode?, type : T.class) : T? forall T
  return nil unless root
  return root.as(T) if root.is_a?(T)
  root.children.each do |child|
    found = find_node(child, type)
    return found if found
  end
  nil
end

private def all_nodes(root : Native::Interpreter::UINode?) : Array(Native::Interpreter::UINode)
  return [] of Native::Interpreter::UINode unless root
  [root] + root.children.flat_map { |c| all_nodes(c) }
end

describe Native::Interpreter::Parser do
  describe "class name extraction" do
    it "extracts simple class name" do
      source = <<-CR
        class MyApp < Native::App
          def setup
          end
        end
      CR
      app = parse(source)
      app.class_name.should eq("MyApp")
    end

    it "extracts class name without module prefix" do
      source = <<-CR
        class CounterApp < App
          def setup
          end
        end
      CR
      app = parse(source)
      app.class_name.should eq("CounterApp")
    end

    it "defaults class name when no class found" do
      source = "def setup\nend"
      app = parse(source)
      app.class_name.should eq("App")
    end

    it "sets title from class name" do
      source = <<-CR
        class WeatherApp < Native::App
          def setup
          end
        end
      CR
      app = parse(source)
      app.title.should contain("WeatherApp")
    end
  end

  describe "setup body extraction" do
    it "returns error when no setup method" do
      source = <<-CR
        class MyApp < Native::App
          def run
          end
        end
      CR
      app = parse(source)
      app.error_message.should_not be_nil
    end

    it "parses empty setup without error" do
      source = <<-CR
        class MyApp < Native::App
          def setup
          end
        end
      CR
      app = parse(source)
      app.error_message.should be_nil
    end
  end

  describe "widget parsing — TextView" do
    it "parses TextView with string argument" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            label = TextView.new("Hello World")
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::TextViewNode)
      node.should_not be_nil
      node.not_nil!.text.should eq("Hello World")
    end

    it "parses Native::UI::TextView" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            t = Native::UI::TextView.new("Scoped")
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::TextViewNode)
      node.should_not be_nil
      node.not_nil!.text.should eq("Scoped")
    end

    it "parses empty TextView" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            spacer = TextView.new()
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::TextViewNode)
      node.should_not be_nil
    end
  end

  describe "widget parsing — Button" do
    it "parses Button with label" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            btn = Button.new("Submit")
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::ButtonNode)
      node.should_not be_nil
      node.not_nil!.label.should eq("Submit")
    end

    it "captures on_click body" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            btn = Button.new("Go")
            btn.on_click { puts "clicked" }
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::ButtonNode)
      node.should_not be_nil
      node.not_nil!.on_click_body.should eq("puts \"clicked\"")
    end
  end

  describe "widget parsing — EditText" do
    it "parses EditText with placeholder" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            input = EditText.new("Enter your name")
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::EditTextNode)
      node.should_not be_nil
      node.not_nil!.placeholder.should eq("Enter your name")
    end

    it "parses EditText without args" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            field = EditText.new()
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::EditTextNode)
      node.should_not be_nil
    end
  end

  describe "widget parsing — CheckBox" do
    it "parses CheckBox with label" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            cb = CheckBox.new("Remember me")
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::CheckboxNode)
      node.should_not be_nil
      node.not_nil!.label.should eq("Remember me")
    end

    it "applies checked property" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            cb = CheckBox.new("Agree")
            cb.checked = true
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::CheckboxNode)
      node.should_not be_nil
      node.not_nil!.checked.should be_true
    end
  end

  describe "widget parsing — LinearLayout" do
    it "parses vertical layout" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            layout = LinearLayout.new(:vertical)
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::LinearLayoutNode)
      node.should_not be_nil
      node.not_nil!.orientation.should eq(Native::Interpreter::Orientation::Vertical)
    end

    it "parses horizontal layout" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            row = LinearLayout.new(:horizontal)
          end
        end
      CR
      app = parse(source)
      nodes = all_nodes(app.root).select { |n| n.is_a?(Native::Interpreter::LinearLayoutNode) }
      h_nodes = nodes.select { |n| n.as(Native::Interpreter::LinearLayoutNode).orientation == Native::Interpreter::Orientation::Horizontal }
      h_nodes.should_not be_empty
    end

    it "parses layout without args as vertical" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            l = LinearLayout.new()
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::LinearLayoutNode)
      node.should_not be_nil
      node.not_nil!.orientation.should eq(Native::Interpreter::Orientation::Vertical)
    end
  end

  describe "widget parsing — CardView" do
    it "parses CardView" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            card = CardView.new()
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::CardViewNode)
      node.should_not be_nil
    end
  end

  describe "widget parsing — ProgressBar" do
    it "parses ProgressBar" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            bar = ProgressBar.new()
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::ProgressBarNode)
      node.should_not be_nil
    end

    it "applies value property" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            bar = ProgressBar.new()
            bar.value = 0.75
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::ProgressBarNode)
      node.should_not be_nil
      node.not_nil!.value.should be_close(0.75f32, 0.01f32)
    end
  end

  describe "widget parsing — ImageView" do
    it "parses ImageView with src" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            img = ImageView.new("avatar.png")
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::ImageViewNode)
      node.should_not be_nil
      node.not_nil!.src.should eq("avatar.png")
    end
  end

  describe "property setters" do
    it "applies text= to TextView" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            label = TextView.new("original")
            label.text = "updated"
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::TextViewNode)
      node.not_nil!.text.should eq("updated")
    end

    it "applies text_size= to TextView" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            title = TextView.new("Title")
            title.text_size = 28
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::TextViewNode)
      node.not_nil!.text_size.should eq(28)
    end

    it "applies placeholder= to EditText" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            field = EditText.new()
            field.placeholder = "Type here..."
          end
        end
      CR
      app = parse(source)
      node = find_node(app.root, Native::Interpreter::EditTextNode)
      node.not_nil!.placeholder.should eq("Type here...")
    end
  end

  describe "layout relationships" do
    it "wires children via .add()" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            layout = LinearLayout.new(:vertical)
            title  = TextView.new("Welcome")
            btn    = Button.new("Start")
            layout.add(title)
            layout.add(btn)
          end
        end
      CR
      app = parse(source)
      layout = find_node(app.root, Native::Interpreter::LinearLayoutNode)
      layout.should_not be_nil
      layout.not_nil!.children.size.should eq(2)
      layout.not_nil!.children[0].should be_a(Native::Interpreter::TextViewNode)
      layout.not_nil!.children[1].should be_a(Native::Interpreter::ButtonNode)
    end

    it "nests layouts" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            outer = LinearLayout.new(:vertical)
            row   = LinearLayout.new(:horizontal)
            btn1  = Button.new("A")
            btn2  = Button.new("B")
            row.add(btn1)
            row.add(btn2)
            outer.add(row)
          end
        end
      CR
      app = parse(source)
      nodes = all_nodes(app.root)
      layouts = nodes.select { |n| n.is_a?(Native::Interpreter::LinearLayoutNode) }
      layouts.size.should be >= 2

      h_layout = layouts.find { |n| n.as(Native::Interpreter::LinearLayoutNode).orientation == Native::Interpreter::Orientation::Horizontal }
      h_layout.should_not be_nil
      h_layout.not_nil!.children.size.should eq(2)
    end

    it "does not add a node as its own child" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            layout = LinearLayout.new(:vertical)
            label  = TextView.new("hi")
            layout.add(label)
          end
        end
      CR
      app = parse(source)
      layout = find_node(app.root, Native::Interpreter::LinearLayoutNode)
      layout.not_nil!.children.none? { |c| c == layout }.should be_true
    end

    it "wires children via .add_child()" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            card  = CardView.new()
            label = TextView.new("Card content")
            card.add_child(label)
          end
        end
      CR
      app = parse(source)
      card = find_node(app.root, Native::Interpreter::CardViewNode)
      card.should_not be_nil
      card.not_nil!.children.size.should eq(1)
    end
  end

  describe "multiple widgets" do
    it "parses a full typical screen" do
      source = <<-CR
        class LoginApp < Native::App
          def setup
            layout   = LinearLayout.new(:vertical)
            title    = TextView.new("Sign In")
            email    = EditText.new("Email")
            password = EditText.new("Password")
            remember = CheckBox.new("Remember me")
            submit   = Button.new("Login")
            layout.add(title)
            layout.add(email)
            layout.add(password)
            layout.add(remember)
            layout.add(submit)
          end
        end
      CR
      app = parse(source)
      app.error_message.should be_nil
      app.class_name.should eq("LoginApp")

      layout = find_node(app.root, Native::Interpreter::LinearLayoutNode)
      layout.should_not be_nil
      layout.not_nil!.children.size.should eq(5)

      nodes = all_nodes(app.root)
      nodes.any? { |n| n.is_a?(Native::Interpreter::TextViewNode) }.should be_true
      nodes.any? { |n| n.is_a?(Native::Interpreter::EditTextNode) }.should be_true
      nodes.any? { |n| n.is_a?(Native::Interpreter::CheckboxNode) }.should be_true
      nodes.any? { |n| n.is_a?(Native::Interpreter::ButtonNode) }.should be_true
    end

    it "handles multiple top-level widgets gracefully" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            label = TextView.new("one")
            btn   = Button.new("two")
          end
        end
      CR
      app = parse(source)
      app.error_message.should be_nil
      nodes = all_nodes(app.root)
      nodes.any? { |n| n.is_a?(Native::Interpreter::TextViewNode) }.should be_true
      nodes.any? { |n| n.is_a?(Native::Interpreter::ButtonNode) }.should be_true
    end
  end

  describe "error handling" do
    it "returns an app node even for empty source" do
      app = parse("")
      app.should_not be_nil
    end

    it "returns error for completely empty setup" do
      source = "class A < Native::App\ndef setup\nend\nend"
      app = parse(source)
      app.should_not be_nil
    end

    it "ignores comment lines" do
      source = <<-CR
        class MyApp < Native::App
          def setup
            # This is a comment
            label = TextView.new("Real")
            # btn = Button.new("Commented out")
          end
        end
      CR
      app = parse(source)
      nodes = all_nodes(app.root)
      text_nodes = nodes.select { |n| n.is_a?(Native::Interpreter::TextViewNode) }
      text_nodes.size.should eq(1)
    end
  end
end
