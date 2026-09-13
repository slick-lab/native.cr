# src/native/cli/ios.cr

require "digest"
#
# Generates a complete, buildable Xcode project for an iOS app:
#   - AppDelegate / ViewController / CrystalView (render + touch bridge)
#   - the full native.cr Swift runtime (src/native/engine/ios/swift/)
#   - Info.plist with launch screen, orientations and usage descriptions
#   - bridging header for the crystal_* entry points
#   - project.pbxproj wiring everything, including the two static libraries
#     (libuser_app.a from `native build ios`, libnative_cr_engine.a from
#     shards install)
#
# The project opens in Xcode and builds with no manual steps; on a Mac with
# Xcode, `native build ios` goes all the way to an IPA.

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
      Dir.mkdir_p("#{ios_dir}/#{@project_name}.xcodeproj")

      create_app_delegate(app_dir)
      create_view_controller(app_dir)
      create_crystal_view(app_dir)
      copy_swift_runtime(app_dir)
      create_info_plist(app_dir)
      create_bridging_header(app_dir)
      create_xcode_project(ios_dir)
      create_readme(ios_dir)
      create_gitignore(ios_dir)

      puts ""
      puts "[native.cr] iOS project generated at #{ios_dir}"
      puts ""
      puts "Next steps (requires a Mac with Xcode):"
      puts "  1. native.cr build ios          # cross-compile + xcodebuild to IPA"
      puts "  2. or open #{ios_dir}/#{@project_name}.xcodeproj directly in Xcode"
      puts ""
      puts "Signing: set APPLE_TEAM_ID in the environment for device IPAs;"
      puts "without it the build falls back to an unsigned simulator IPA."
      puts ""
      puts "See README.md for details"
    end

    # ── Swift app files ──────────────────────────────────────────────────────

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
                super.init(coder: coder)
                setupDisplayLink()
            }

            private func setupDisplayLink() {
                enableSetNeedsDisplay = false
                isPaused = false
                preferredFramesPerSecond = 60
                displayLink = CADisplayLink(target: self, selector: #selector(step))
                displayLink?.add(to: .main, forMode: .common)
            }

            @objc private func step() {
                crystal_render_frame()
            }
        }
      SWIFT
      )
    end

    # ── Swift runtime (LibIOS implementation) ────────────────────────────────

    private def copy_swift_runtime(app_dir : String)
      runtime_dir = "#{__DIR__}/../engine/ios/swift"
      Dir.glob("#{runtime_dir}/*.swift").each do |src|
        dest = "#{app_dir}/#{File.basename(src)}"
        FileUtils.cp(src, dest)
        puts "[native.cr]   + runtime #{File.basename(src)}"
      end
    rescue e
      puts "[native.cr] Warning: could not copy Swift runtime (#{e.message})"
      puts "[native.cr]   expected at #{runtime_dir}"
    end

    private def create_info_plist(app_dir : String)
      File.write("#{app_dir}/Info.plist", <<-PLIST
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>en</string>
            <key>CFBundleExecutable</key>
            <string>$(EXECUTABLE_NAME)</string>
            <key>CFBundleIdentifier</key>
            <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
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
            <key>UILaunchScreen</key>
            <dict/>
            <key>UISupportedInterfaceOrientations</key>
            <array>
                <string>UIInterfaceOrientationPortrait</string>
                <string>UIInterfaceOrientationLandscapeLeft</string>
                <string>UIInterfaceOrientationLandscapeRight</string>
            </array>
            <key>NSCameraUsageDescription</key>
            <string>This app uses the camera to take photos.</string>
            <key>NSPhotoLibraryUsageDescription</key>
            <string>This app lets you pick images from your library.</string>
            <key>NSLocationWhenInUseUsageDescription</key>
            <string>This app uses your location when active.</string>
            <key>NSMotionUsageDescription</key>
            <string>This app uses motion sensors.</string>
            <key>NSFaceIDUsageDescription</key>
            <string>This app uses Face ID to authenticate.</string>
        </dict>
        </plist>
      PLIST
      )
    end

    private def create_bridging_header(app_dir : String)
      File.write("#{app_dir}/#{@project_name}-Bridging-Header.h", <<-HEADER
        // Bridging header — exposes the Crystal entry points to Swift.
        // The LibIOS functions Swift exports (@_cdecl) need no declaration:
        // Crystal links them directly from the static library.

        #ifndef #{@project_name.upcase}_BRIDGING_HEADER_H
        #define #{@project_name.upcase}_BRIDGING_HEADER_H

        void crystal_init(void);
        void crystal_start(void);
        void crystal_render_frame(void);
        void crystal_touch_began(float x, float y);
        void crystal_touch_moved(float x, float y);
        void crystal_touch_ended(float x, float y);

        #endif
      HEADER
      )
    end

    # ── Xcode project (project.pbxproj) ──────────────────────────────────────

    private def uuid(name : String) : String
      # Deterministic 24-hex UUIDs so regeneration is stable in git.
      digest = Digest::SHA1.hexdigest("nativecr-ios-#{@project_name}-#{name}")[0, 24].upcase
      digest
    end

    private def create_xcode_project(ios_dir : String)
      proj_name = @project_name
      id = ->(name : String) { uuid(name) }

      swift_files = [
        "AppDelegate.swift", "ViewController.swift", "CrystalView.swift",
        "NativeRuntime.swift", "NativeMedia.swift", "NativeServices.swift",
      ]

      file_refs = swift_files.map { |f| {ref: id.call("fileref-#{f}"), name: f} }
      build_files = swift_files.map { |f| {build: id.call("build-#{f}"), file: id.call("fileref-#{f}"), name: f} }
      lib_engine_ref = id.call("fileref-libengine")
      lib_user_ref = id.call("fileref-libuser")
      lib_engine_build = id.call("build-libengine")
      lib_user_build = id.call("build-libuser")
      plist_ref = id.call("fileref-infoplist")
      header_ref = id.call("fileref-header")
      main_group = id.call("group-main")
      products_group = id.call("group-products")
      sources_phase = id.call("phase-sources")
      frameworks_phase = id.call("phase-frameworks")
      target_ref = id.call("native-target")
      project_ref = id.call("pbx-project")
      cfg_list_project = id.call("cfglist-project")
      cfg_list_target = id.call("cfglist-target")
      cfg_proj_dbg = id.call("cfg-proj-debug")
      cfg_proj_rel = id.call("cfg-proj-release")
      cfg_tgt_dbg = id.call("cfg-tgt-debug")
      cfg_tgt_rel = id.call("cfg-tgt-release")
      product_ref = id.call("fileref-product")
      products_build = id.call("build-product")

      swift_file_refs = file_refs.map do |r|
        "\t\t#{r[:ref]} /* #{r[:name]} */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = #{r[:name]}; sourceTree = \"<group>\"; };"
      end.join("\n")

      swift_build_files = build_files.map do |b|
        "\t\t#{b[:build]} /* #{b[:name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{b[:file]} /* #{b[:name]} */; };"
      end.join("\n")

      swift_sources = build_files.map do |b|
        "\t\t\t\t#{b[:build]} /* #{b[:name]} in Sources */,"
      end.join("\n")

      File.write("#{ios_dir}/#{proj_name}.xcodeproj/project.pbxproj", <<-PBX
        // !$*UTF8*$!
        {
        \tarchiveVersion = 1;
        \tclasses = {
        \t};
        \tobjectVersion = 56;
        \tobjects = {

        /* Begin PBXBuildFile section */
        #{swift_build_files}
        \t\t#{lib_engine_build} /* libnative_cr_engine.a in Frameworks */ = {isa = PBXBuildFile; fileRef = #{lib_engine_ref} /* libnative_cr_engine.a */; };
        \t\t#{lib_user_build} /* libuser_app.a in Frameworks */ = {isa = PBXBuildFile; fileRef = #{lib_user_ref} /* libuser_app.a */; };
        \t\t#{products_build} /* #{proj_name}.app in Frameworks */ = {isa = PBXBuildFile; fileRef = #{product_ref} /* #{proj_name}.app */; settings = {ATTRIBUTES = (Weak, ); }; };
        /* End PBXBuildFile section */

        /* Begin PBXFileReference section */
        #{swift_file_refs}
        \t\t#{plist_ref} /* Info.plist */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
        \t\t#{header_ref} /* Bridging-Header.h */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; name = "#{proj_name}-Bridging-Header.h"; path = "#{proj_name}/#{proj_name}-Bridging-Header.h"; sourceTree = "<group>"; };
        \t\t#{lib_engine_ref} /* libnative_cr_engine.a */ = {isa = PBXFileReference; lastKnownFileType = archive.ar; name = libnative_cr_engine.a; path = Frameworks/libnative_cr_engine.a; sourceTree = "<group>"; };
        \t\t#{lib_user_ref} /* libuser_app.a */ = {isa = PBXFileReference; lastKnownFileType = archive.ar; name = libuser_app.a; path = Frameworks/libuser_app.a; sourceTree = "<group>"; };
        \t\t#{product_ref} /* #{proj_name}.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "#{proj_name}.app"; sourceTree = BUILT_PRODUCTS_DIR; };
        /* End PBXFileReference section */

        /* Begin PBXFrameworksBuildPhase section */
        \t\t#{frameworks_phase} /* Frameworks */ = {
        \t\t\tisa = PBXFrameworksBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        \t\t\t\t#{lib_engine_build} /* libnative_cr_engine.a in Frameworks */,
        \t\t\t\t#{lib_user_build} /* libuser_app.a in Frameworks */,
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXFrameworksBuildPhase section */

        /* Begin PBXGroup section */
        \t\t#{main_group} = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\t#{products_group} /* Products */,
        \t\t\t\t#{plist_ref} /* Info.plist */,
        \t\t\t\t#{header_ref} /* Bridging-Header.h */,
        \t\t\t\t#{lib_engine_ref} /* libnative_cr_engine.a */,
        \t\t\t\t#{lib_user_ref} /* libuser_app.a */,
        \t\t\t\t#{file_refs.map { |r| "#{r[:ref]} /* #{r[:name]} */" }.join(",\n\t\t\t\t")},
        \t\t\t);
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\t#{products_group} /* Products */ = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\t#{product_ref} /* #{proj_name}.app */,
        \t\t\t);
        \t\t\tname = Products;
        \t\t\tsourceTree = "<group>";
        \t\t};
        /* End PBXGroup section */

        /* Begin PBXNativeTarget section */
        \t\t#{target_ref} /* #{proj_name} */ = {
        \t\t\tisa = PBXNativeTarget;
        \t\t\tbuildConfigurationList = #{cfg_list_target};
        \t\t\tbuildPhases = (
        \t\t\t\t#{sources_phase} /* Sources */,
        \t\t\t\t#{frameworks_phase} /* Frameworks */,
        \t\t\t);
        \t\t\tbuildRules = (
        \t\t\t);
        \t\t\tdependencies = (
        \t\t\t);
        \t\t\tname = #{proj_name};
        \t\t\tproductName = #{proj_name};
        \t\t\tproductReference = #{product_ref} /* #{proj_name}.app */;
        \t\t\tproductType = "com.apple.product-type.application";
        \t\t};
        /* End PBXNativeTarget section */

        /* Begin PBXProject section */
        \t\t#{project_ref} /* Project object */ = {
        \t\t\tisa = PBXProject;
        \t\t\tattributes = {
        \t\t\t\tLastSwiftUpdateCheck = 1400;
        \t\t\t\tLastUpgradeCheck = 1400;
        \t\t\t\tTargetAttributes = {
        \t\t\t\t\t#{target_ref} = {
        \t\t\t\t\t\tCreatedOnToolsVersion = 14.0;
        \t\t\t\t\t};
        \t\t\t\t};
        \t\t\t};
        \t\t\tbuildConfigurationList = #{cfg_list_project};
        \t\t\tcompatibilityVersion = "Xcode 14.0";
        \t\t\tdevelopmentRegion = en;
        \t\t\thasScannedForEncodings = 0;
        \t\t\tknownRegions = (
        \t\t\t\ten,
        \t\t\t\tBase,
        \t\t\t);
        \t\t\tmainGroup = #{main_group};
        \t\t\tproductRefGroup = #{products_group} /* Products */;
        \t\t\tprojectDirPath = "";
        \t\t\tprojectRoot = "";
        \t\t\ttargets = (
        \t\t\t\t#{target_ref} /* #{proj_name} */,
        \t\t\t);
        \t\t};
        /* End PBXProject section */

        /* Begin PBXSourcesBuildPhase section */
        \t\t#{sources_phase} /* Sources */ = {
        \t\t\tisa = PBXSourcesBuildPhase;
        \t\t\tbuildActionMask = 2147483647;
        \t\t\tfiles = (
        #{swift_sources}
        \t\t\t);
        \t\t\trunOnlyForDeploymentPostprocessing = 0;
        \t\t};
        /* End PBXSourcesBuildPhase section */

        /* Begin XCBuildConfiguration section */
        \t\t#{cfg_proj_dbg} /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
        \t\t\t\tCLANG_ENABLE_MODULES = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 12.0;
        \t\t\t\tSDKROOT = iphoneos;
        \t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\t#{cfg_proj_rel} /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
        \t\t\t\tCLANG_ENABLE_MODULES = YES;
        \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 12.0;
        \t\t\t\tSDKROOT = iphoneos;
        \t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
        \t\t\t\tVALIDATE_PRODUCT = YES;
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        \t\t#{cfg_tgt_dbg} /* Debug */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tENABLE_BITCODE = NO;
        \t\t\t\tINFOPLIST_FILE = "#{proj_name}/Info.plist";
        \t\t\t\tLD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
        \t\t\t\tLIBRARY_SEARCH_PATHS = "$(PROJECT_DIR)/Frameworks";
        \t\t\t\tOTHER_LDFLAGS = "-lc++";
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.nativecr.#{proj_name.downcase.gsub(/[^a-z0-9]/, "")};
        \t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
        \t\t\t\tSWIFT_OBJC_BRIDGING_HEADER = "#{proj_name}/#{proj_name}-Bridging-Header.h";
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t};
        \t\t\tname = Debug;
        \t\t};
        \t\t#{cfg_tgt_rel} /* Release */ = {
        \t\t\tisa = XCBuildConfiguration;
        \t\t\tbuildSettings = {
        \t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        \t\t\t\tCODE_SIGN_STYLE = Automatic;
        \t\t\t\tENABLE_BITCODE = NO;
        \t\t\t\tINFOPLIST_FILE = "#{proj_name}/Info.plist";
        \t\t\t\tLD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
        \t\t\t\tLIBRARY_SEARCH_PATHS = "$(PROJECT_DIR)/Frameworks";
        \t\t\t\tOTHER_LDFLAGS = "-lc++";
        \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.nativecr.#{proj_name.downcase.gsub(/[^a-z0-9]/, "")};
        \t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
        \t\t\t\tSWIFT_OBJC_BRIDGING_HEADER = "#{proj_name}/#{proj_name}-Bridging-Header.h";
        \t\t\t\tSWIFT_VERSION = 5.0;
        \t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
        \t\t\t};
        \t\t\tname = Release;
        \t\t};
        /* End XCBuildConfiguration section */

        /* Begin XCConfigurationList section */
        \t\t#{cfg_list_project} /* Build configuration list for PBXProject "#{proj_name}" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\t#{cfg_proj_dbg} /* Debug */,
        \t\t\t\t#{cfg_proj_rel} /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        \t\t#{cfg_list_target} /* Build configuration list for PBXNativeTarget "#{proj_name}" */ = {
        \t\t\tisa = XCConfigurationList;
        \t\t\tbuildConfigurations = (
        \t\t\t\t#{cfg_tgt_dbg} /* Debug */,
        \t\t\t\t#{cfg_tgt_rel} /* Release */,
        \t\t\t);
        \t\t\tdefaultConfigurationIsVisible = 0;
        \t\t\tdefaultConfigurationName = Release;
        \t\t};
        /* End XCConfigurationList section */
        };
        \trootObject = #{project_ref} /* Project object */;
        }
      PBX
      )
    end

    private def create_readme(ios_dir : String)
      File.write("#{ios_dir}/README.md", <<-README
        # #{@project_name} — iOS

        Generated by native.cr. The Xcode project is complete and buildable:
        it already includes the Swift runtime (LibIOS implementation), the
        bridging header and the two static libraries it links.

        ## Build

        ```bash
        # From the project root (on a Mac with Xcode):
        native.cr build ios
        ```

        - Without `APPLE_TEAM_ID` set: builds for the iOS Simulator and
          packages an unsigned `#{proj_name_placeholder}.ipa` (runs in any simulator).
        - With `APPLE_TEAM_ID=<team id>`: archives for device and exports a
          signed IPA via `development` method (override with
          `EXPORT_METHOD=app-store` and `PROVISIONING_PROFILE=<uuid>`).

        ## Frameworks linked

        - UIKit, WebKit, AVFoundation, UserNotifications, LocalAuthentication,
          CoreLocation, CoreMotion, StoreKit, AudioToolbox (via the Swift runtime)
        - QuartzCore / Metal (via MTKView)

        ## Troubleshooting

        | Issue | Solution |
        |-------|----------|
        | Library not loaded | Ensure `Frameworks/libuser_app.a` exists (run `native.cr build ios`) |
        | Undefined crystal_* symbols | `native.cr build ios` cross-compiles with `-Dnative_ios` — never plain `-D ios` |
        | Signing errors | Set `APPLE_TEAM_ID` or build for simulator (default without it) |
      README
      )
    end

    private def proj_name_placeholder
      @project_name
    end

    private def create_gitignore(ios_dir : String)
      File.write("#{ios_dir}/.gitignore", <<-GITIGNORE
        *.xcuserstate
        xcuserdata/
        DerivedData/
        .DS_Store
        build/
        *.ipa
        *.dSYM
        Frameworks/
      GITIGNORE
      )
    end
  end
end
