require "native"

include Native

class HelloApp < Native::App
  def setup : Nil
    @text = UI::TextView.new("hello world")
    @root = @label
  end
end

Native::App.start(HelloApp)
