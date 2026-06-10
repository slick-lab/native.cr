# src/native/cli/ios.cr

module Native::CLI
  class IOSGenerator
    @project_name : String
    @output_dir : String

    def initialize(project_name : String, output_dir : String)
      @project_name = project_name
      @output_dir = output_dir
    end

    def generate
      puts "[native.cr] Generating iOS project..."
      puts "[native.cr] Project: #{@project_name}"
      puts ""

      ios_dir = "#{@output_dir}/ios"
      app_dir = "#{ios_dir}/#{@project_name}"

      Dir.mkdir_p(app_dir)

      create_app_delegate(app_dir)
      create_view_controller(app_dir)
      create_crystal_view(app_dir)
      create_info_plist(app_dir)
      create_bridging_header(app_dir)
      create_readme(ios_dir)
      create_gitignore(ios_dir)

      puts ""
      puts "[native.cr] iOS source files generated at #{ios_dir}"
      puts ""
      puts "Next steps (requires Mac with Xcode):"
      puts "  1. Open Xcode and create a new iOS App project"
      puts "  2. Name the project: #{@project_name}"
      puts "  3. Add the generated Swift files to your project:"
      puts "     - #{app_dir}/AppDelegate.swift"
      puts "     - #{app_dir}/ViewController.swift"
      puts "     - #{app_dir}/CrystalView.swift"
      puts "  4. Add #{app_dir}/Info.plist to your project"
      puts "  5. Add #{app_dir}/#{@project_name}-Bridging-Header.h to your project"
      puts "  6. Add libnative_cr_ios.a and libnative_cr_engine.a from lib/native/ to your project"
      puts "  7. Build and run on your iOS device"
      puts ""
      puts "See README.md for detailed instructions"
    end

    private def create_app_delegate(app_dir : String)
      File.write("#{app_dir}/AppDelegate.swift", <<-SWIFT
        import UIKit

        @main
        class AppDelegate: UIResponder, UIApplicationDelegate {
            var window: UIWindow?

            func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                window = UIWindow(frame: UIScreen.main.bounds)
                window?.rootViewController = ViewController()
                window?.makeKeyAndVisible()

                crystal_init()
                crystal_start()

                return true
            }
        }
      SWIFT
      )
    end

    private def create_view_controller(app_dir : String)
      File.write("#{app_dir}/ViewController.swift", <<-SWIFT
        import UIKit

        class ViewController: UIViewController {
            private var crystalView: CrystalView!

            override func viewDidLoad() {
                super.viewDidLoad()
                setupCrystalView()
            }

            private func setupCrystalView() {
                crystalView = CrystalView(frame: view.bounds)
                crystalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view.addSubview(crystalView)
            }

            override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
                guard let point = touches.first?.location(in: view) else { return }
                crystal_touch_began(Float(point.x), Float(point.y))
            }

            override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
                guard let point = touches.first?.location(in: view) else { return }
                crystal_touch_moved(Float(point.x), Float(point.y))
            }

            override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
                guard let point = touches.first?.location(in: view) else { return }
                crystal_touch_ended(Float(point.x), Float(point.y))
            }
        }
      SWIFT
      )
    end

    private def create_crystal_view(app_dir : String)
      File.write("#{app_dir}/CrystalView.swift", <<-SWIFT
        import UIKit
        import MetalKit

        final class CrystalView: MTKView {
            private var displayLink: CADisplayLink?

            override init(frame frameRect: CGRect, device: MTLDevice?) {
                super.init(frame: frameRect, device: device ?? MTLCreateSystemDefaultDevice())
                setupDisplayLink()
            }

            required init(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            private func setupDisplayLink() {
                displayLink = CADisplayLink(target: self, selector: #selector(renderFrame))
                displayLink?.add(to: .main, forMode: .common)
            }

            @objc private func renderFrame() {
                crystal_render_frame()
            }
        }
      SWIFT
      )
    end

    private def create_info_plist(app_dir : String)
      File.write("#{app_dir}/Info.plist", <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>en</string>
            <key>CFBundleExecutable</key>
            <string>$(EXECUTABLE_NAME)</string>
            <key>CFBundleIdentifier</key>
            <string>com.nativecr.#{@project_name}</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>#{@project_name}</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundleVersion</key>
            <string>1</string>
            <key>UIRequiredDeviceCapabilities</key>
            <array>
                <string>arm64</string>
            </array>
            <key>UIStatusBarHidden</key>
            <true/>
        </dict>
        </plist>
      XML
      )
    end

    private def create_bridging_header(app_dir : String)
      File.write("#{app_dir}/#{@project_name}-Bridging-Header.h", <<-HEADER
        void crystal_init(void);
        void crystal_start(void);
        void crystal_render_frame(void);
        void crystal_touch_began(float x, float y);
        void crystal_touch_moved(float x, float y);
        void crystal_touch_ended(float x, float y);
      HEADER
      )
    end

    private def create_readme(ios_dir : String)
      File.write("#{ios_dir}/README.md", <<-README
        # iOS Setup for #{@project_name}

        ## Prerequisites
        - Mac with Xcode 14+
        - iOS device or simulator

        ## Setup Instructions

        ### 1. Create Xcode Project
        - Open Xcode
        - File → New → Project
        - iOS → App
        - Product Name: #{@project_name}
        - Interface: Storyboard (delete later)
        - Save to this directory

        ### 2. Add Source Files
        Add these files to your Xcode project:
        - `#{@project_name}/AppDelegate.swift`
        - `#{@project_name}/ViewController.swift`
        - `#{@project_name}/CrystalView.swift`

        ### 3. Configure Bridging Header
        - Add `#{@project_name}/#{@project_name}-Bridging-Header.h` to project
        - In Build Settings, set Objective-C Bridging Header to the file path

        ### 4. Add Info.plist
        - Replace the default Info.plist with `#{@project_name}/Info.plist`

        ### 5. Link Native Libraries
        - The prebuilt libraries are in `lib/native/` (from shards install)
        - Add `lib/native/libnative_cr_ios.a` to your Xcode project
        - Add `lib/native/libnative_cr_engine.a` to your Xcode project

        ### 6. Add Frameworks
        - Metal.framework
        - UIKit.framework
        - QuartzCore.framework

        ### 7. Build and Run
        - Select your device or simulator
        - Press Run

        ## Troubleshooting

        | Issue | Solution |
        |-------|----------|
        | Bridging header not found | Check path in Build Settings |
        | Library not loaded | Ensure .a files are in project and linked |
        | Metal errors | Ensure device supports Metal (iPhone 5s+) |
      README
      )
    end

    private def create_gitignore(ios_dir : String)
      File.write("#{ios_dir}/.gitignore", <<-GITIGNORE
        *.xcworkspace
        *.xcuserstate
        xcuserdata/
        DerivedData/
        .DS_Store
        build/
        *.ipa
        *.dSYM
      GITIGNORE
      )
    end
  end
end
