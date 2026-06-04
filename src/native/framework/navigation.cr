# src/native/framework/navigation.cr

module Native
  module Navigation
    enum TransitionType
      Slide
      Fade
      Scale
      None
    end

    struct TransitionConfig
      property type : TransitionType = TransitionType::Slide
      property duration : Float64 = 0.3
      property curve : Animation::Curve = Animation::Curve::EaseInOut

      def initialize
      end
    end

    class Route
      property name : String
      property view : UI::View
      property transition : TransitionConfig
      property data : Hash(String, String)?

      def initialize(@name : String, @view : UI::View,
                     @transition : TransitionConfig = TransitionConfig.new,
                     @data = nil)
      end
    end

    class Navigator
      @stack : Array(Route) = [] of Route
      @container : UI::View
      @current_view : UI::View?
      @transitioning : Bool = false
      @on_navigate : (String, Hash(String, String)? -> Nil)?
      @on_back : (String, Hash(String, String)? -> Nil)?

      def initialize(container : UI::View)
        @container = container
      end

      def push(route : Route) : Nil
        return if @transitioning

        @stack << route

        if @current_view
          transition_to(route, forward: true)
        else
          show_route(route)
        end

        @on_navigate.try &.call(route.name, route.data)
      end

      def push(name : String, view : UI::View, data : Hash(String, String)? = nil) : Nil
        config = TransitionConfig.new
        push(Route.new(name, view, config, data))
      end

      def pop : Nil
        return if @transitioning || @stack.size <= 1

        old_route = @stack.pop
        new_route = @stack.last

        transition_to(new_route, forward: false)

        @on_back.try &.call(old_route.name, old_route.data)
      end

      def pop_to_root : Nil
        return if @transitioning || @stack.size <= 1

        while @stack.size > 1
          @stack.pop
        end

        root_route = @stack.first
        transition_to(root_route, forward: false)
      end

      def replace(route : Route) : Nil
        return if @transitioning

        @stack.pop if @stack.any?
        @stack << route
        show_route(route)
      end

      def current_route : Route?
        @stack.last
      end

      def can_go_back? : Bool
        @stack.size > 1
      end

      def on_navigate(&block : String, Hash(String, String)? -> Nil) : Nil
        @on_navigate = block
      end

      def on_back(&block : String, Hash(String, String)? -> Nil) : Nil
        @on_back = block
      end

      private def show_route(route : Route) : Nil
        @container.add_child(route.view)
        route.view.layout(0, 0, @container.width, @container.height)
        @current_view = route.view
      end

      private def transition_to(route : Route, forward : Bool) : Nil
        @transitioning = true

        old_view = @current_view
        new_view = route.view

        @container.add_child(new_view)
        new_view.layout(0, 0, @container.width, @container.height)

        setup_transition_views(old_view, new_view, forward)

        animate_transition(old_view, new_view, forward) do
          complete_transition(old_view, new_view, route)
        end
      end

      private def setup_transition_views(old_view : UI::View?, new_view : UI::View, forward : Bool) : Nil
        case route.transition.type
        when TransitionType::Slide
          offset = @container.width
          if forward
            new_view.x = offset
            new_view.alpha = 1.0
          else
            new_view.x = -offset
            new_view.alpha = 1.0
          end

          if old_view
            if forward
              old_view.alpha = 1.0
            else
              old_view.alpha = 1.0
            end
          end
        when TransitionType::Fade
          new_view.alpha = 0.0
          new_view.x = 0
        when TransitionType::Scale
          new_view.alpha = 0.0
          new_view.scale = 0.9
          new_view.x = 0
        when TransitionType::None
          new_view.alpha = 1.0
          new_view.x = 0
          new_view.scale = 1.0
        end
      end

      private def animate_transition(old_view : UI::View?, new_view : UI::View,
                                     forward : Bool, &complete : -> Nil) : Nil
        duration = route.transition.duration

        case route.transition.type
        when TransitionType::Slide
          offset = @container.width

          animate(duration: duration) do
            new_view.animate.x(forward ? 0 : -offset)
            if old_view
              old_view.animate.x(forward ? -offset : offset)
              old_view.animate.alpha(forward ? 0.0 : 1.0)
            end
            new_view.animate.alpha(1.0)
          end

          after(duration) { complete.call }
        when TransitionType::Fade
          animate(duration: duration) do
            new_view.animate.alpha(1.0)
            old_view.try(&.animate.alpha(0.0))
          end

          after(duration) { complete.call }
        when TransitionType::Scale
          animate(duration: duration) do
            new_view.animate.alpha(1.0)
            new_view.animate.scale(1.0)
            old_view.try(&.animate.alpha(0.0))
            old_view.try(&.animate.scale(1.1))
          end

          after(duration) { complete.call }
        when TransitionType::None
          complete.call
        end
      end

      private def complete_transition(old_view : UI::View?, new_view : UI::View, route : Route) : Nil
        old_view.try { |v| @container.remove_child(v) }

        new_view.x = 0
        new_view.y = 0
        new_view.alpha = 1.0
        new_view.scale = 1.0

        @current_view = new_view
        @transitioning = false
      end
    end

    class NavigationStack
      @navigator : Navigator
      @back_button : UI::Button?
      @title_view : UI::Text?
      @header : UI::View?
      @show_header : Bool = true
      @header_height : Int32 = 56

      def initialize(container : UI::View, show_header : Bool = true)
        @show_header = show_header

        if @show_header
          setup_header
          @navigator = Navigator.new(header_container)
          @header.add_child(header_container)
          container.add_child(@header)
          container.add_child(@navigator.container)
        else
          @navigator = Navigator.new(container)
        end

        setup_navigation_callbacks
      end

      def push(route : Route) : Nil
        @navigator.push(route)
      end

      def push(name : String, view : UI::View, data : Hash(String, String)? = nil) : Nil
        @navigator.push(name, view, data)
      end

      def pop : Nil
        @navigator.pop
      end

      def pop_to_root : Nil
        @navigator.pop_to_root
      end

      def replace(route : Route) : Nil
        @navigator.replace(route)
      end

      def navigator : Navigator
        @navigator
      end

      def set_title(title : String) : Nil
        @title_view.try &.text = title
      end

      def show_back_button(show : Bool) : Nil
        @back_button.try &.visible = show
      end

      def header_height=(height : Int32)
        @header_height = height
        @header.try &.height = height
      end

      private def setup_header : Nil
        @header = UI::View.new
        @header.height = @header_height
        @header.background_color = Styling::Theme.primary_color
        @header.y = 0

        @back_button = UI::Button.new
        @back_button.text = "< Back"
        @back_button.text_color = Styling::Color.white
        @back_button.background_color = Styling::Color.transparent
        @back_button.width = 80
        @back_button.height = @header_height
        @back_button.x = 8
        @back_button.on_click = -> { @navigator.pop }
        @back_button.visible = false

        @title_view = UI::Text.new
        @title_view.text = ""
        @title_view.text_size = 18
        @title_view.color = Styling::Color.white
        @title_view.text_alignment = TextAlignment::Center

        @header.add_child(@back_button)
        @header.add_child(@title_view)
      end

      private def header_container : UI::View
        container = UI::View.new
        container.y = @header_height
        container.height = @container.height - @header_height
        container
      end

      private def setup_navigation_callbacks : Nil
        @navigator.on_navigate do |name, data|
          set_title(name)
          show_back_button(@navigator.can_go_back?)
        end

        @navigator.on_back do |name, data|
          if @navigator.can_go_back?
            show_back_button(true)
            if current = @navigator.current_route
              set_title(current.name)
            end
          else
            show_back_button(false)
            set_title("")
          end
        end
      end
    end

    module NavigationDSL
      def navigate_to(name : String, view : UI::View, data : Hash(String, String)? = nil) : Nil
        @navigator.try &.push(name, view, data)
      end

      def go_back : Nil
        @navigator.try &.pop
      end

      def go_to_root : Nil
        @navigator.try &.pop_to_root
      end
    end
  end
end
