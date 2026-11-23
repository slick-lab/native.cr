# src/native/framework/app.cr

module Native
  abstract class App
    @@current : App?
    # Nilable until the user registers their subclass; starting without a
    # registration used to fall through to instantiating the abstract
    # Native::App itself, because the non-nilable default made the
    # "if registered" check always true. (Note: `App.class?` does not
    # parse — metaclass nilability needs the explicit `| Nil` union.)
    @@registered_subclass : App.class | Nil

    def self.current : App
      @@current.not_nil!
    end

    def self.current=(app : App)
      @@current = app
    end

    # The app subclass registered by the user for Android builds.
    # Set this in your main.cr instead of calling App.start directly:
    #
    #   class MyApp < Native::App
    #     def setup; end
    #   end
    #   Native::App.registered_subclass = MyApp
    #
    # On desktop you can continue to call Native::App.start(MyApp) as before.
    def self.registered_subclass : App.class | Nil
      @@registered_subclass
    end

    def self.registered_subclass=(klass : App.class)
      @@registered_subclass = klass
    end

    def self.start(app_class : App.class)
      app = app_class.new
      @@current = app
      app.load_saved_state
      app.setup
      app.run
    end

    # Used by the Android bridge (crystal_android_main) to start the
    # user's app when the entry-point main.cr doesn't run.
    def self.start_registered : Nil
      if subclass = @@registered_subclass
        start(subclass)
      elsif app = @@current
        app.load_saved_state
        app.setup
        app.android_attach_root
        app.run
      else
        raise "No app registered. Set Native::App.registered_subclass = MyApp in your entry point."
      end
    end

    # ── instance ─────────────────────────────────────────────────────────────

    # The root view that will be displayed on screen.
    # Set this at the end of setup (or use a Navigator which sets it for you).
    # Assigning it on Android immediately schedules setContentView on the UI
    # thread, so you can also reassign it later to swap entire screen layouts.
    @root : UI::View? = nil

    def initialize
      @renderer = Pointer(Void).null
      setup_signal_handlers
    end

    # Assign a view as the root content view.
    # On Android this calls setContentView on the UI thread automatically.
    def root=(view : UI::View)
      @root = view
      android_attach_root
      apply_pending_background(view)
    end

    # Expose the current root view (read).
    def root : UI::View?
      @root
    end

    private def setup_signal_handlers
      Signal::USR1.trap { save_state }
      Signal::TERM.trap { save_state; exit(0) }
    end

    private def save_state
      state_file = ENV["NATIVE_CR_STATE_FILE"]?
      return unless state_file
      File.write(state_file, state_to_json)
    rescue
    end

    def load_saved_state
      state_file = ENV["NATIVE_CR_STATE_FILE"]?
      return unless state_file && File.exists?(state_file)
      json = File.read(state_file)
      state_from_json(json)
      File.delete(state_file)
    rescue
    end

    # ── Hot-reload state (the @[Preserve] DSL) ────────────────────────────────
    #
    # Both methods are macro-generated from the ACTUAL subclass's
    # @[Preserve]-annotated instance variables (see core/preserve.cr), so
    # `count` in the docs' counter example round-trips through a reload
    # with zero serialization code in user land.
    #
    # Unsupported annotated types fail at compile time. Everything else
    # (unannotated ivars) is deliberately skipped — only marked state
    # survives a reload.
    #
    # Overriding either method in a subclass is still supported: call
    # `super` first and merge your own keys if you need extra data.

    def state_to_json : String
      {% begin %}
        {% ivars = @type.instance_vars.select { |iv|
            iv.annotation(::Preserve) || iv.annotation(Native::Preserve)
          } %}
        {% if ivars.empty? %}
          "{}"
        {% else %}
          String.build do |io|
            io << "{"
            {% for i in 0...ivars.size %}
              {% ivar = ivars[i] %}
              {% ut = ivar.type.union_types %}
              {% non_nil = ut.reject { |t| t == Nil } %}
              {% unless non_nil.size == 1 && (ut.size == 1 || ut.size == 2) && (non_nil[0] == Bool || non_nil[0] == Int32 || non_nil[0] == Int64 || non_nil[0] == Float32 || non_nil[0] == Float64 || non_nil[0] == String || non_nil[0] == Array(String) || non_nil[0] == Array(Int32) || non_nil[0] == Array(Float64) || non_nil[0] == JSON::Any) %}
                {% raise "Unsupported @[Preserve] type #{ivar.type} for #{ivar.name} — " \
                         "use Bool, Int32, Int64, Float32, Float64, String, Array(String), " \
                         "Array(Int32), Array(Float64), JSON::Any or a nilable variant" %}
              {% end %}
              {% unless i == 0 %} io << "," {% end %}
              {{ivar.name.stringify}}.to_json(io)
              io << ":"
              @{{ivar.name.id}}.to_json(io)
            {% end %}
            io << "}"
          end
        {% end %}
      {% end %}
    end

    def state_from_json(json : String) : Nil
      {% begin %}
        {% ivars = @type.instance_vars.select { |iv|
            iv.annotation(::Preserve) || iv.annotation(Native::Preserve)
          } %}
        {% if !ivars.empty? %}
          doc = JSON.parse(json)
          hash = doc.as_h?
          return unless hash
          {% for ivar in ivars %}
            {% ut = ivar.type.union_types %}
            {% non_nil = ut.reject { |t| t == Nil } %}
            {% unless non_nil.size == 1 && (ut.size == 1 || ut.size == 2) %}
              {% raise "Unsupported @[Preserve] type #{ivar.type} for #{ivar.name} — " \
                       "use Bool, Int32, Int64, Float32, Float64, String, Array(String), " \
                       "Array(Int32), Array(Float64), JSON::Any or a nilable variant" %}
            {% end %}
            {% t = non_nil[0] %}
            {% nilable = ut.size == 2 %}
            if value = hash[{{ivar.name.stringify}}]?
              {% if t == Bool %}
                @{{ivar.name.id}} = value.{{ nilable ? "as_bool?".id : "as_bool".id }}
              {% elsif t == Int32 %}
                @{{ivar.name.id}} = value.{{ nilable ? "as_i?.try &.to_i32".id : "as_i.to_i32".id }}
              {% elsif t == Int64 %}
                @{{ivar.name.id}} = value.{{ nilable ? "as_i64?".id : "as_i64".id }}
              {% elsif t == Float32 %}
                @{{ivar.name.id}} = value.{{ nilable ? "as_f?.try &.to_f32".id : "as_f.to_f32".id }}
              {% elsif t == Float64 %}
                @{{ivar.name.id}} = value.{{ nilable ? "as_f?".id : "as_f".id }}
              {% elsif t == String %}
                @{{ivar.name.id}} = value.{{ nilable ? "as_s?".id : "as_s".id }}
              {% elsif t == Array(String) %}
                @{{ivar.name.id}} = value.{{ nilable ? "as_a?.try &.map(&.as_s)".id : "as_a.map &.as_s".id }}
              {% elsif t == Array(Int32) %}
                @{{ivar.name.id}} = value.{{ nilable ? "as_a?.try &.map { |v| v.as_i.to_i32 }".id : "as_a.map { |v| v.as_i.to_i32 }".id }}
              {% elsif t == Array(Float64) %}
                @{{ivar.name.id}} = value.{{ nilable ? "as_a?.try &.map(&.as_f)".id : "as_a.map &.as_f".id }}
              {% elsif t == JSON::Any %}
                @{{ivar.name.id}} = value
              {% else %}
                raise "BUG: unsupported preserved type reached runtime"
              {% end %}
            end
          {% end %}
        {% end %}
      {% end %}
    rescue ex : JSON::ParseException
      # Corrupt or foreign state file — keep defaults rather than crash
      # the freshly reloaded app.
      Log.debug { "state_from_json ignored bad state: #{ex.message}" }
    end

    # ── Window background ─────────────────────────────────────────────────────
    #
    # Docs and examples have always shown `set_background_color(r, g, b)`
    # in setup — implemented here for real:
    #   Android: window background (via decor view), posted to the UI thread
    #   iOS:     root view background color
    #   desktop: stored, applied to the next assigned root view

    def set_background_color(r : Int32, g : Int32, b : Int32, alpha : Int32 = 255) : Nil
      {% if flag?(:native_android) %}
        JNIHelpers.with_env do |env|
          activity = Native::Android::JNI.activity
          return unless activity
          window = JNIHelpers.call_object(env, activity.address.to_i64, "getWindow", "()Landroid/view/Window;")
          decor = JNIHelpers.call_object(env, window.address.to_i64, "getDecorView", "()Landroid/view/View;")
          JNIHelpers.call_void(env, decor.address.to_i64, "setBackgroundColor", "(I)V",
            ((alpha & 0xFF) << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF))
        end
      {% elsif flag?(:native_ios) %}
        color = Native::Math::Color.from_rgba(r, g, b, alpha)
        if root_view = @root
          LibIOS.view_set_background_color(root_view.native_ptr,
            color.r.to_f32, color.g.to_f32, color.b.to_f32, color.a.to_f32)
        else
          @pending_background = color
        end
      {% else %}
        @pending_background = Native::Math::Color.from_rgba(r, g, b, alpha)
      {% end %}
    end

    @pending_background : Native::Math::Color? = nil

    # Called by root= (desktop/iOS) to apply a set_background_color that
    # happened before any root view existed.
    private def apply_pending_background(view : UI::View) : Nil
      if color = @pending_background
        view.background_color = color
        @pending_background = nil
      end
    end

    abstract def setup : Nil

    def run : Nil
      loop do
        sleep 0.016.seconds
      end
    end

    # ── Android root-view attachment ─────────────────────────────────────────
    #
    # Called automatically after setup (and whenever root= is assigned).
    # Uses NativeHelper.setContentView which posts to the UI thread, so it is
    # safe to call from the Crystal background thread.

    def android_attach_root : Nil
      {% if flag?(:native_android) %}
        root_view = @root
        return unless root_view && root_view.native_ptr != 0

        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && !activity.null?

        # com.nativecr.NativeHelper.setContentView(Activity, View)
        helper_class = env.find_class("com/nativecr/NativeHelper")
        return if helper_class.null?

        set_cv = env.get_static_method_id(
          helper_class,
          "setContentView",
          "(Landroid/app/Activity;Landroid/view/View;)V"
        )
        return if set_cv.null?

        view_ptr = Pointer(Void).new(root_view.native_ptr.to_u64)
        env.call_static_void_method(helper_class, set_cv, activity, view_ptr)
      {% end %}
    end

    # ── Optional callbacks (stub methods) ────────────────────────────────────

    def on_touch_began(x : Float32, y : Float32) : Nil; end

    def on_touch_moved(x : Float32, y : Float32) : Nil; end

    def on_touch_ended(x : Float32, y : Float32) : Nil; end

    def on_key_pressed(key : Int32) : Nil; end

    def on_key_released(key : Int32) : Nil; end

    def on_pause : Nil; end

    def on_resume : Nil; end

    def on_destroy : Nil; end

    property renderer : Void*
  end
end
