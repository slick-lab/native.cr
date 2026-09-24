# src/native/cli/ipa.cr
#
# Packages an iOS app:
#   - With APPLE_TEAM_ID set: archive for device + export a signed IPA
#     (method from EXPORT_METHOD, default "development").
#   - Without it: build for the iOS Simulator and package the .app into an
#     unsigned Payload/ IPA — enough to run in any simulator and to hand the
#     pipeline a real artifact without certs.

module Native::CLI::Ipa
  def self.build(ios_project : String, release : Bool = false) : String?
    puts "[native.cr] Building IPA..."
    puts "[native.cr] Project: #{ios_project}"
    puts ""

    proj_file = Dir.glob("#{ios_project}/*.xcodeproj").first?
    unless proj_file
      puts "[native.cr] Error: no .xcodeproj found in #{ios_project}"
      puts ""
      puts "To fix this:"
      puts "  1. Run 'native.cr create my_app --ios' to create an iOS project"
      puts "  2. Then run 'native.cr build ios' again"
      return nil
    end
    scheme = File.basename(proj_file, ".xcodeproj")
    configuration = release ? "Release" : "Debug"

    unless xcode_available?
      puts "[native.cr] Error: Xcode not found"
      puts ""
      puts "To fix this:"
      puts "  1. Install Xcode from the Mac App Store"
      puts "  2. Open Xcode once to accept the license"
      return nil
    end

    team_id = ENV["APPLE_TEAM_ID"]?
    if team_id.nil? || team_id.strip.empty?
      return build_simulator_ipa(ios_project, proj_file, scheme, configuration)
    end

    build_device_ipa(ios_project, proj_file, scheme, configuration, team_id)
  end

  private def self.xcode_available? : Bool
    r = Process.run("xcodebuild", args: ["-version"], output: Process::Redirect::Close, error: Process::Redirect::Close)
    r.success?
  end

  # ── Device path: archive + export ──────────────────────────────────────────

  private def self.build_device_ipa(ios_project, proj_file, scheme, configuration, team_id) : String?
    Dir.cd(ios_project) do
      archive_path = "./build/#{scheme}.xcarchive"

      ok = run_xcode([
        "-project", File.basename(proj_file), "-scheme", scheme,
        "-configuration", configuration, "-sdk", "iphoneos",
        "-destination", "generic/platform=iOS",
        "archive", "-archivePath", archive_path,
        "CODE_SIGN_IDENTITY=iPhone Developer",
        "DEVELOPMENT_TEAM=#{team_id}",
      ])
      unless ok
        puts "[native.cr] Archive failed"
        return nil
      end

      method = ENV["EXPORT_METHOD"]? || "development"
      export_path = "./build/#{scheme}"
      Dir.mkdir_p(export_path)
      File.write("exportOptions.plist", export_options_plist(method, team_id))

      ok = run_xcode([
        "-exportArchive", "-archivePath", archive_path,
        "-exportPath", export_path,
        "-exportOptionsPlist", "exportOptions.plist",
      ])
      unless ok
        puts "[native.cr] Export failed"
        return nil
      end

      ipa_path = "#{export_path}/#{scheme}.ipa"
      if File.exists?(ipa_path)
        puts "[native.cr] IPA created: #{File.expand_path(ipa_path)}"
        return ipa_path
      end
      puts "[native.cr] Error: IPA not found after export"
      nil
    end
  end

  # ── Simulator path: no certs required ──────────────────────────────────────

  private def self.build_simulator_ipa(ios_project, proj_file, scheme, configuration) : String?
    puts "[native.cr] APPLE_TEAM_ID not set — building unsigned simulator IPA"
    Dir.cd(ios_project) do
      build_dir = "./build"
      ok = run_xcode([
        "-project", File.basename(proj_file), "-scheme", scheme,
        "-configuration", configuration, "-sdk", "iphonesimulator",
        "-destination", "generic/platform=iOS Simulator",
        "-derivedDataPath", build_dir, "build",
      ])
      unless ok
        puts "[native.cr] Simulator build failed"
        return nil
      end

      app = Dir.glob("#{build_dir}/Build/Products/#{configuration}-iphonesimulator/*.app").first?
      unless app
        puts "[native.cr] Error: built .app not found"
        return nil
      end

      # Package Payload/<App>.app into an unsigned IPA.
      ipa_path = "./build/#{scheme}.ipa"
      payload = "./build/Payload"
      FileUtils.rm_rf(payload)
      Dir.mkdir_p(payload)
      FileUtils.cp_r(app, "#{payload}/#{File.basename(app)}")

      File.delete(ipa_path) if File.exists?(ipa_path)
      zip = Process.run("zip", args: ["-qr", File.basename(ipa_path), "Payload"],
                        output: Process::Redirect::Close, error: Process::Redirect::Inherit)
      unless zip.success?
        puts "[native.cr] Error: zip failed while packaging IPA"
        return nil
      end

      puts "[native.cr] IPA created (unsigned, simulator): #{File.expand_path(ipa_path)}"
      ipa_path
    end
  end

  private def self.export_options_plist(method : String, team_id : String) : String
    <<-PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>method</key>
          <string>#{method}</string>
          <key>teamID</key>
          <string>#{team_id}</string>
          <key>signingStyle</key>
          <string>automatic</string>
          <key>provisioningProfiles</key>
          <dict>
          </dict>
      </dict>
      </plist>
    PLIST
  end

  private def self.run_xcode(args : Array(String)) : Bool
    puts "  xcodebuild #{args.join(" ")}"
    r = Process.run("xcodebuild", args: args, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
    r.success?
  end
end
