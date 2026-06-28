module Native::Interpreter
  enum Orientation
    Vertical
    Horizontal
  end

  abstract class UINode
    property id : String
    property visible : Bool = true
    property children : Array(UINode) = [] of UINode

    def initialize(@id : String)
    end

    def add_child(node : UINode)
      @children << node
    end
  end

  class TextViewNode < UINode
    property text : String
    property text_size : Int32 = 14
    property bold : Bool = false
    property color : Tuple(Float32, Float32, Float32) = {1.0f32, 1.0f32, 1.0f32}

    def initialize(id : String, @text : String)
      super(id)
    end
  end

  class ButtonNode < UINode
    property label : String
    property on_click_body : String = ""
    property enabled : Bool = true

    def initialize(id : String, @label : String)
      super(id)
    end
  end

  class EditTextNode < UINode
    property placeholder : String
    property value : String = ""
    property multiline : Bool = false

    def initialize(id : String, @placeholder : String)
      super(id)
    end
  end

  class CheckboxNode < UINode
    property label : String
    property checked : Bool = false

    def initialize(id : String, @label : String)
      super(id)
    end
  end

  class SliderNode < UINode
    property label : String
    property value : Float32 = 0.0f32
    property min : Float32 = 0.0f32
    property max : Float32 = 1.0f32

    def initialize(id : String, @label : String, @min : Float32, @max : Float32)
      super(id)
    end
  end

  class LinearLayoutNode < UINode
    property orientation : Orientation

    def initialize(id : String, @orientation : Orientation = Orientation::Vertical)
      super(id)
    end
  end

  class CardViewNode < UINode
    property title : String = ""

    def initialize(id : String)
      super(id)
    end
  end

  class SeparatorNode < UINode
    def initialize(id : String)
      super(id)
    end
  end

  class SpacerNode < UINode
    property height : Int32 = 8

    def initialize(id : String, @height : Int32 = 8)
      super(id)
    end
  end

  class ImageViewNode < UINode
    property src : String = ""

    def initialize(id : String, @src : String = "")
      super(id)
    end
  end

  class ProgressBarNode < UINode
    property value : Float32 = 0.0f32
    property label : String = ""

    def initialize(id : String)
      super(id)
    end
  end

  class ScrollViewNode < UINode
    def initialize(id : String)
      super(id)
    end
  end

  class AppNode
    property class_name : String = "App"
    property title : String = "native.cr Preview"
    property root : UINode?
    property state_vars : Hash(String, String) = {} of String => String
    property error_message : String? = nil

    def initialize(@class_name : String = "App")
    end
  end
end
