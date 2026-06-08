# src/native/cli/apk.cr

module Native::CLI::Apk
  def self.build(android_project : String, release : Bool = false) : String?
    puts "[native.cr] Building APK..."
    puts "[native.cr] Project: #{android_project}"
    puts ""

    unless Dir.exists?(android_project) && File.exists?("#{android_project}/app/build.gradle")
      puts "[native.cr] Error: Invalid Android project at #{android_project}"
      puts ""
      puts "To fix this:"
      puts "  1. Run 'native.cr create my_app --android' to create an Android project"
      return nil
    end

    gradle_cmd = release ? "./gradlew assembleRelease" : "./gradlew assembleDebug"

    Dir.cd(android_project) do
      output = `#{gradle_cmd} 2>&1`
      unless $?.success?
        puts "[native.cr] Gradle build failed:"
        puts output
        return nil
      end
    end

    apk_type = release ? "release" : "debug"
    apk_dir = "#{android_project}/app/build/outputs/apk/#{apk_type}"
    apk_files = Dir.glob("#{apk_dir}/*.apk")

    if apk_files.any?
      apk_path = apk_files.first
      puts "[native.cr] APK created: #{apk_path}"
      return apk_path
    else
      puts "[native.cr] Error: APK not found"
      return nil
    end
  end
end
