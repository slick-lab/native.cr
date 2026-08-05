# src/native/framework/navigation/screen.cr
#
# A Screen represents a single page in your app.
# Subclass it, implement `build` to return the root view for this page,
# and push it onto a Navigator to display it.
#
# Example:
#
#   class HomeScreen < Native::Navigation::Screen
#     def build : Native::UI::View
#       layout = Native::UI::LinearLayout.new
#       label  = Native::UI::TextView.new("Home")
#       layout.addView(label)
#       layout
#     end
#   end

module Native::Navigation
  abstract class Screen
    @cached_view : UI::View? = nil
    @navigator : Navigator? = nil

    # Build and return the root view for this screen.
    # Called once; the result is cached. If you need to force a rebuild
    # (e.g. after data changes), call `invalidate` then let Navigator show
    # the screen again.
    abstract def build : UI::View

    # Returns the view for this screen, building it on the first call.
    def view : UI::View
      @cached_view ||= build
    end

    # Discard the cached view so the next call to `view` rebuilds it.
    def invalidate : Nil
      @cached_view = nil
    end

    # Called every time this screen becomes the top of the Navigator stack.
    def on_appear : Nil; end

    # Called every time this screen is no longer the top of the stack
    # (either popped or covered by a new screen).
    def on_disappear : Nil; end

    # Called when the hardware/system back button is pressed while this
    # screen is on top. Return `true` to consume the event (preventing the
    # default pop behaviour), or `false` to let the Navigator handle it.
    def on_back : Bool
      false
    end

    # The Navigator that owns this screen (set automatically on push).
    def navigator : Navigator?
      @navigator
    end

    # :nodoc:
    def navigator=(nav : Navigator?)
      @navigator = nav
    end

    # Convenience: push a new screen from within this screen.
    def push(screen : Screen) : Nil
      @navigator.try &.push(screen)
    end

    # Convenience: pop this screen from within itself.
    def pop : Bool
      @navigator.try(&.pop) || false
    end
  end
end
