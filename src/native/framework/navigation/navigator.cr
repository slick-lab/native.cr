# src/native/framework/navigation/navigator.cr
#
# A stack-based screen navigator.
#
# Create one inside your App.setup, push your first screen, and the
# Navigator takes care of calling App#root= so the UI is displayed.
#
# Example:
#
#   class MyApp < Native::App
#     def setup
#       @nav = Native::Navigation::Navigator.new(self)
#       @nav.push(HomeScreen.new)
#     end
#
#     def on_back
#       @nav.back
#     end
#   end

module Native::Navigation
  class Navigator
    # The app this navigator belongs to. Navigator calls app.root= whenever
    # the active screen changes.
    getter app : Native::App

    # The current navigation stack (bottom → top). The last element is the
    # screen the user sees.
    getter stack : Array(Screen)

    def initialize(@app : Native::App)
      @stack = [] of Screen
    end

    # ── Core navigation ───────────────────────────────────────────────────

    # Push *screen* on top of the stack and display it.
    # The previously visible screen receives `on_disappear`.
    def push(screen : Screen) : Nil
      if prev = @stack.last?
        prev.on_disappear
      end

      screen.navigator = self
      @stack << screen
      screen.on_appear
      show(screen)
    end

    # Pop the top screen and return to the previous one.
    # Returns `true` if a pop happened, `false` if the stack only has one screen.
    def pop : Bool
      return false if @stack.size <= 1

      @stack.last.on_disappear
      @stack.last.navigator = nil
      @stack.pop

      prev = @stack.last
      prev.on_appear
      show(prev)
      true
    end

    # Replace the top screen with *screen* (no new stack entry).
    def replace(screen : Screen) : Nil
      if top = @stack.last?
        top.on_disappear
        top.navigator = nil
        @stack.pop
      end

      screen.navigator = self
      @stack << screen
      screen.on_appear
      show(screen)
    end

    # Pop all screens back to the root and show it again.
    def pop_to_root : Nil
      return if @stack.size <= 1

      @stack.last.on_disappear

      # Detach all intermediate screens
      (@stack.size - 1).downto(1) do |i|
        @stack[i].navigator = nil
        @stack.delete_at(i)
      end

      root = @stack.first
      root.on_appear
      show(root)
    end

    # Handle the device back button. Returns `true` if handled.
    # Call this from App#on_key_pressed or a back-button listener.
    def back : Bool
      # Give the top screen a chance to consume the event first.
      if (top = @stack.last?) && top.on_back
        return true
      end
      pop
    end

    # ── Convenience ───────────────────────────────────────────────────────

    # The screen currently on top (visible to the user).
    def current : Screen?
      @stack.last?
    end

    # Number of screens in the stack.
    def depth : Int32
      @stack.size
    end

    # ── Private ───────────────────────────────────────────────────────────

    # Tell the app to display this screen's view as the root content view.
    private def show(screen : Screen) : Nil
      @app.root = screen.view
    end
  end
end
