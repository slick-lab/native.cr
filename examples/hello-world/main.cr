require "native"

include Native

class HelloApp < Native::App
	def setup : Nil
		@label = UI::TextView.new("hello world")
		@label.text_size = 24
	end
end

Native::App.start(HelloApp)
