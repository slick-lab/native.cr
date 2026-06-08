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
      xcodeproj_dir = "#{ios_dir}/#{@project_name}.xcodeproj"

      Dir.mkdir_p(app_dir)
      Dir.mkdir_p("#{xcodeproj_dir}/xcuserdata")
      Dir.mkdir_p("#{xcodeproj_dir}/project.xcworkspace")

      create_app_delegate(app_dir)
      create_view_controller(app_dir)
      create_crystal_view(app_dir)
      create_info_plist(app_dir)
      create_bridging_header(app_dir)
      create_project_pbxproj(xcodeproj_dir)
      create_gitignore(ios_dir)

      puts "[native.cr] iOS project generated at #{ios_dir}"
      puts "[native.cr] Run: open #{ios_dir}/#{@project_name}.xcodeproj"
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

    private def create_project_pbxproj(xcodeproj_dir : String)
      File.write("#{xcodeproj_dir}/project.pbxproj", <<-PBXPROJ
        // !$*UTF8*$!
        {
            archiveVersion = 1;
            classes = {
            };
            objectVersion = 56;
            objects = {
                PBXFileReference = {
                    _rootObject = {isa = PBXFileReference; lastKnownFileType = wrapper.pb-project; path = "#{@project_name}.xcodeproj"; sourceTree = "<group>"; };
                };
            };
            rootObject = _rootObject;
        }
      PBXPROJ
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
