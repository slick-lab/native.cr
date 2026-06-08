# src/native/cli/ipa.cr

module Native::CLI::Ipa
  def self.build(ios_project : String, release : Bool = false) : String?
    puts "[native.cr] Building IPA..."
    puts "[native.cr] Project: #{ios_project}"
    puts ""

    unless Dir.exists?(ios_project) && File.exists?("#{ios_project}/#{File.basename(ios_project)}.xcodeproj")
      puts "[native.cr] Error: Invalid iOS project at #{ios_project}"
      puts ""
      puts "To fix this:"
      puts "  1. Run 'native.cr create my_app --ios' to create an iOS project"
      puts "  2. Then run 'native.cr build ios' again"
      return nil
    end

    if !system("xcodebuild -version")
      puts "[native.cr] Error: Xcode not found"
      puts ""
      puts "To fix this:"
      puts "  1. Install Xcode from the Mac App Store"
      puts "  2. Open Xcode once to accept the license"
      puts "  3. Run 'sudo xcode-select --reset'"
      return nil
    end

    scheme = File.basename(ios_project)
    configuration = release ? "Release" : "Debug"

    puts "[native.cr] Building with Xcode..."
    puts "[native.cr] Scheme: #{scheme}"
    puts "[native.cr] Configuration: #{configuration}"
    puts ""

    Dir.cd(ios_project) do
      build_cmd = "xcodebuild -project #{scheme}.xcodeproj -scheme #{scheme} -configuration #{configuration} build"
      output = `#{build_cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Xcode build failed:"
        puts output
        return nil
      end

      archive_cmd = "xcodebuild -project #{scheme}.xcodeproj -scheme #{scheme} -configuration #{configuration} archive -archivePath ./build/#{scheme}.xcarchive"
      output = `#{archive_cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Archive failed:"
        puts output
        return nil
      end

      export_plist = <<-PLIST
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>method</key>
            <string>development</string>
            <key>teamID</key>
            <string>#{ENV["APPLE_TEAM_ID"]? || ""}</string>
            <key>provisioningProfiles</key>
            <dict>
                <key>#{scheme}</key>
                <string>#{ENV["PROVISIONING_PROFILE"]? || ""}</string>
            </dict>
        </dict>
        </plist>
      PLIST

      File.write("exportOptions.plist", export_plist)

      export_cmd = "xcodebuild -exportArchive -archivePath ./build/#{scheme}.xcarchive -exportPath ./build/#{scheme} -exportOptionsPlist exportOptions.plist"
      output = `#{export_cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Export failed:"
        puts output
        return nil
      end

      ipa_path = "./build/#{scheme}/#{scheme}.ipa"
      if File.exists?(ipa_path)
        puts "[native.cr] IPA created: #{ipa_path}"
        return ipa_path
      else
        puts "[native.cr] Error: IPA not found"
        return nil
      end
    end
  end
end
