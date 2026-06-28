require "./spec_helper"

describe Native::Interpreter do
  describe Native::Interpreter::UINode do
    it "starts with no children" do
      node = Native::Interpreter::TextViewNode.new("n1", "hello")
      node.children.should be_empty
    end

    it "adds children" do
      parent = Native::Interpreter::LinearLayoutNode.new("layout1")
      child  = Native::Interpreter::TextViewNode.new("tv1", "hi")
      parent.add_child(child)
      parent.children.size.should eq(1)
      parent.children.first.should be(child)
    end

    it "adds multiple children in order" do
      layout = Native::Interpreter::LinearLayoutNode.new("l1")
      3.times { |i| layout.add_child(Native::Interpreter::TextViewNode.new("tv#{i}", "text#{i}")) }
      layout.children.size.should eq(3)
    end

    it "is visible by default" do
      node = Native::Interpreter::ButtonNode.new("b1", "Click")
      node.visible.should be_true
    end

    it "can be hidden" do
      node = Native::Interpreter::TextViewNode.new("tv1", "text")
      node.visible = false
      node.visible.should be_false
    end
  end

  describe Native::Interpreter::TextViewNode do
    it "stores text" do
      node = Native::Interpreter::TextViewNode.new("tv1", "Hello World")
      node.text.should eq("Hello World")
    end

    it "has default text size 14" do
      node = Native::Interpreter::TextViewNode.new("tv1", "text")
      node.text_size.should eq(14)
    end

    it "allows setting text size" do
      node = Native::Interpreter::TextViewNode.new("tv1", "text")
      node.text_size = 24
      node.text_size.should eq(24)
    end

    it "defaults to white color" do
      node = Native::Interpreter::TextViewNode.new("tv1", "text")
      r, g, b = node.color
      r.should eq(1.0f32)
      g.should eq(1.0f32)
      b.should eq(1.0f32)
    end

    it "is not bold by default" do
      node = Native::Interpreter::TextViewNode.new("tv1", "text")
      node.bold.should be_false
    end

    it "can be set bold" do
      node = Native::Interpreter::TextViewNode.new("tv1", "text")
      node.bold = true
      node.bold.should be_true
    end
  end

  describe Native::Interpreter::ButtonNode do
    it "stores label" do
      node = Native::Interpreter::ButtonNode.new("b1", "Submit")
      node.label.should eq("Submit")
    end

    it "is enabled by default" do
      node = Native::Interpreter::ButtonNode.new("b1", "OK")
      node.enabled.should be_true
    end

    it "has empty on_click_body by default" do
      node = Native::Interpreter::ButtonNode.new("b1", "OK")
      node.on_click_body.should be_empty
    end

    it "stores on_click body" do
      node = Native::Interpreter::ButtonNode.new("b1", "OK")
      node.on_click_body = "puts \"clicked\""
      node.on_click_body.should eq("puts \"clicked\"")
    end
  end

  describe Native::Interpreter::EditTextNode do
    it "stores placeholder" do
      node = Native::Interpreter::EditTextNode.new("et1", "Enter name...")
      node.placeholder.should eq("Enter name...")
    end

    it "has empty value by default" do
      node = Native::Interpreter::EditTextNode.new("et1", "hint")
      node.value.should be_empty
    end

    it "is not multiline by default" do
      node = Native::Interpreter::EditTextNode.new("et1", "hint")
      node.multiline.should be_false
    end
  end

  describe Native::Interpreter::CheckboxNode do
    it "stores label" do
      node = Native::Interpreter::CheckboxNode.new("cb1", "Remember me")
      node.label.should eq("Remember me")
    end

    it "is unchecked by default" do
      node = Native::Interpreter::CheckboxNode.new("cb1", "Option")
      node.checked.should be_false
    end

    it "can be checked" do
      node = Native::Interpreter::CheckboxNode.new("cb1", "Option")
      node.checked = true
      node.checked.should be_true
    end
  end

  describe Native::Interpreter::SliderNode do
    it "stores label, min, max" do
      node = Native::Interpreter::SliderNode.new("s1", "Volume", 0.0f32, 1.0f32)
      node.label.should eq("Volume")
      node.min.should eq(0.0f32)
      node.max.should eq(1.0f32)
    end

    it "has default value 0" do
      node = Native::Interpreter::SliderNode.new("s1", "Speed", 0.0f32, 100.0f32)
      node.value.should eq(0.0f32)
    end

    it "can set value" do
      node = Native::Interpreter::SliderNode.new("s1", "Brightness", 0.0f32, 1.0f32)
      node.value = 0.75f32
      node.value.should eq(0.75f32)
    end
  end

  describe Native::Interpreter::LinearLayoutNode do
    it "defaults to vertical orientation" do
      node = Native::Interpreter::LinearLayoutNode.new("l1")
      node.orientation.should eq(Native::Interpreter::Orientation::Vertical)
    end

    it "can be horizontal" do
      node = Native::Interpreter::LinearLayoutNode.new("l1", Native::Interpreter::Orientation::Horizontal)
      node.orientation.should eq(Native::Interpreter::Orientation::Horizontal)
    end

    it "nests layouts" do
      outer = Native::Interpreter::LinearLayoutNode.new("outer")
      inner = Native::Interpreter::LinearLayoutNode.new("inner")
      outer.add_child(inner)
      outer.children.first.should be(inner)
    end
  end

  describe Native::Interpreter::CardViewNode do
    it "has empty title by default" do
      node = Native::Interpreter::CardViewNode.new("c1")
      node.title.should be_empty
    end
  end

  describe Native::Interpreter::SeparatorNode do
    it "creates with an id" do
      node = Native::Interpreter::SeparatorNode.new("sep1")
      node.id.should eq("sep1")
      node.children.should be_empty
    end
  end

  describe Native::Interpreter::SpacerNode do
    it "has default height of 8" do
      node = Native::Interpreter::SpacerNode.new("spacer1")
      node.height.should eq(8)
    end

    it "accepts custom height" do
      node = Native::Interpreter::SpacerNode.new("spacer1", 24)
      node.height.should eq(24)
    end
  end

  describe Native::Interpreter::ProgressBarNode do
    it "has default value 0" do
      node = Native::Interpreter::ProgressBarNode.new("pb1")
      node.value.should eq(0.0f32)
    end

    it "stores value" do
      node = Native::Interpreter::ProgressBarNode.new("pb1")
      node.value = 0.5f32
      node.value.should eq(0.5f32)
    end
  end

  describe Native::Interpreter::ImageViewNode do
    it "has empty src by default" do
      node = Native::Interpreter::ImageViewNode.new("img1")
      node.src.should be_empty
    end

    it "stores src" do
      node = Native::Interpreter::ImageViewNode.new("img1", "avatar.png")
      node.src.should eq("avatar.png")
    end
  end

  describe Native::Interpreter::AppNode do
    it "has no root by default" do
      app = Native::Interpreter::AppNode.new
      app.root.should be_nil
    end

    it "has no error by default" do
      app = Native::Interpreter::AppNode.new
      app.error_message.should be_nil
    end

    it "stores class name" do
      app = Native::Interpreter::AppNode.new("MyApp")
      app.class_name.should eq("MyApp")
    end

    it "has default title" do
      app = Native::Interpreter::AppNode.new
      app.title.should eq("native.cr Preview")
    end
  end
end
