# src/native/cli/build.cr

module Native::CLI
  class BuildCommand
    @entry_point : String = "src/main.cr"
    @platform : String = "android"
    @output : String = "./build"
    @release : Bool = false
    @clean : Bool = false

    def initialize(args : Array(String))
      parse_args(args)
    end

    def parse_args(args : Array(String))
      i = 0
      while i < args.size
        case args[i]
        when "-e", "--entry"
          @entry_point = args[i + 1] if i + 1 < args.size
          i += 2
        when "-o", "--output"
          @output = args[i + 1] if i + 1 < args.size
          i += 2
        when "--release"
          @release = true
          i += 1
        when "--clean"
          @clean = true
          i += 1
        when "android", "ios"
          @platform = args[i]
          i += 1
        when "-h", "--help"
          show_help
          exit(0)
        else
          if File.exists?(args[i])
            @entry_point = args[i]
          end
          i += 1
        end
      end
    end

    def show_help
      puts <<-HELP
      Usage: native.cr build [OPTIONS] [PLATFORM] [ENTRY_FILE]

      Build native.cr app for Android or iOS.

      Options:
        -e, --entry FILE     Entry point file [default: src/main.cr]
        -o, --output DIR     Output directory [default: ./build]
        --release            Build in release mode (optimized)
        --clean              Clean build directory before building
        -h, --help           Show this help

      Platforms:
        android              Build APK for Android
        ios                  iOS support coming soon

      Examples:
        native.cr build android
        native.cr build android --release
        native.cr build android --clean
      HELP
    end

    def run
      if @platform == "ios"
        puts "[native.cr] iOS support is coming soon"
        puts "[native.cr] For now, focus on Android development"
        puts "[native.cr] Follow GitHub for iOS updates"
        return
      end

      puts "[native.cr] Building for Android"
      puts "[native.cr] Entry point: #{@entry_point}"
      puts "[native.cr] Output: #{@output}"
      puts ""

      if @clean && Dir.exists?(@output)
        FileUtils.rm_rf(@output)
        puts "[native.cr] Cleaned output directory"
      end

      Dir.mkdir_p(@output)

      build_android
    end

    private def build_android
      # Check for Android NDK
      ndk = ENV["ANDROID_NDK"]?
      unless ndk && Dir.exists?(ndk)
        puts "[native.cr] Error: ANDROID_NDK environment variable not set"
        puts "[native.cr] Install Android NDK and set ANDROID_NDK to its path"
        puts "[native.cr] Example: export ANDROID_NDK=/home/user/android-ndk-r27c"
        exit(1)
      end

      # Check for Android SDK
      sdk = ENV["ANDROID_HOME"]? || ENV["ANDROID_SDK_ROOT"]?
      unless sdk && Dir.exists?(sdk)
        puts "[native.cr] Error: ANDROID_HOME environment variable not set"
        puts "[native.cr] Install Android SDK and set ANDROID_HOME"
        exit(1)
      end

      # Check for prebuilt libraries from postinstall
      lib_dir = "lib/native"
      engine_so = "#{lib_dir}/libnative_cr_engine.so"
      crystal_so = "#{lib_dir}/libnative_cr.so"

      unless File.exists?(engine_so) && File.exists?(crystal_so)
        puts "[native.cr] Error: Prebuilt Android libraries not found"
        puts "[native.cr] Run 'shards install' first to download them"
        exit(1)
      end

      puts "[native.cr] Found prebuilt libraries in #{lib_dir}/"
      puts "[native.cr] Using NDK at: #{ndk}"
      puts "[native.cr] Using SDK at: #{sdk}"

      # Setup NDK toolchain
      toolchain = "#{ndk}/toolchains/llvm/prebuilt/linux-x86_64"
      clang = "#{toolchain}/bin/aarch64-linux-android24-clang"

      unless File.exists?(clang)
        puts "[native.cr] Error: NDK toolchain not found at #{toolchain}"
        exit(1)
      end

      # Create output directories
      lib_dir_out = "#{@output}/lib/arm64-v8a"
      Dir.mkdir_p(lib_dir_out)

      # Copy prebuilt libraries to output
      FileUtils.cp(engine_so, lib_dir_out)
      FileUtils.cp(crystal_so, lib_dir_out)
      puts "[native.cr] Copied prebuilt libraries to #{lib_dir_out}"

      # Compile user's Crystal code to object file
      puts "[native.cr] Compiling user code..."
      user_o = "#{@output}/user_code.o"
      cmd = "crystal build #{@entry_point} -D android --target aarch64-linux-android -c -o #{user_o}"
      output = `#{cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      # Link user code with prebuilt libraries
      puts "[native.cr] Linking final library..."
      final_so = "#{@output}/lib/arm64-v8a/libuser_app.so"
      link_cmd = "#{clang} -shared -fPIC -o #{final_so} #{user_o} #{lib_dir_out}/libnative_cr_engine.so #{lib_dir_out}/libnative_cr.so"

      link_output = `#{link_cmd} 2>&1`
      unless $?.success?
        puts "[native.cr] Linking failed:"
        puts link_output
        exit(1)
      end

      # Find or create Android project
      android_project = find_android_project
      unless android_project
        puts "[native.cr] No Android project found. Creating one..."
        android_project = create_android_project
      end

      # Copy libraries to Android project
      jni_dir = "#{android_project}/app/src/main/jniLibs/arm64-v8a"
      Dir.mkdir_p(jni_dir)
      FileUtils.cp(final_so, "#{jni_dir}/libnative_cr.so")
      FileUtils.cp(engine_so, jni_dir)
      FileUtils.cp(crystal_so, jni_dir)
      puts "[native.cr] Copied libraries to Android project"

      # Build APK with Gradle
      puts "[native.cr] Building APK with Gradle..."
      gradle_cmd = @release ? "./gradlew assembleRelease" : "./gradlew assembleDebug"

      Dir.cd(android_project) do
        output = `#{gradle_cmd} 2>&1`
        if $?.success?
          puts "[native.cr] APK build successful"
        else
          puts "[native.cr] Gradle build failed:"
          puts output
          exit(1)
        end
      end

      # Find and copy APK
      apk_type = @release ? "release" : "debug"
      apk_dir = "#{android_project}/app/build/outputs/apk/#{apk_type}"
      apk_files = Dir.glob("#{apk_dir}/*.apk")

      if apk_files.any?
        apk_dest = "#{@output}/app-#{apk_type}.apk"
        FileUtils.cp(apk_files.first, apk_dest)
        puts ""
        puts "[native.cr] Build complete!"
        puts "[native.cr] APK: #{apk_dest}"
        puts ""
        puts "Install on device:"
        puts "  adb install #{apk_dest}"
      else
        puts "[native.cr] Warning: APK not found at #{apk_dir}"
      end
    end

    private def find_android_project : String?
      ["android", "../android", "./android"].each do |path|
        if Dir.exists?(path) && File.exists?("#{path}/app/build.gradle")
          return path
        end
      end
      nil
    end

    private def create_android_project : String
      project_name = File.basename(Dir.current)
      android_dir = "android"

      puts "[native.cr] Creating Android project in #{android_dir}/"

      Dir.mkdir_p(android_dir)
      Dir.mkdir_p("#{android_dir}/app/src/main/java/com/nativecr/#{project_name}")
      Dir.mkdir_p("#{android_dir}/app/src/main/jniLibs/arm64-v8a")
      Dir.mkdir_p("#{android_dir}/gradle/wrapper")

      # Create AndroidManifest.xml
      File.write("#{android_dir}/app/src/main/AndroidManifest.xml", <<-XML
        <?xml version="1.0" encoding="utf-8"?>
        <manifest xmlns:android="http://schemas.android.com/apk/res/android"
            package="com.nativecr.#{project_name}">

            <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="34" />

            <application
                android:label="#{project_name}"
                android:hasCode="true"
                android:allowBackup="false">

                <activity
                    android:name=".MainActivity"
                    android:configChanges="orientation|keyboardHidden|screenSize"
                    android:exported="true">

                    <intent-filter>
                        <action android:name="android.intent.action.MAIN" />
                        <category android:name="android.intent.category.LAUNCHER" />
                    </intent-filter>
                </activity>
            </application>
        </manifest>
      XML
      )

      # Create MainActivity.java
      File.write("#{android_dir}/app/src/main/java/com/nativecr/#{project_name}/MainActivity.java", <<-JAVA
        package com.nativecr.#{project_name};

        import android.app.NativeActivity;
        import android.os.Bundle;

        public class MainActivity extends NativeActivity {
            static {
                System.loadLibrary("native_cr");
            }

            @Override
            protected void onCreate(Bundle savedInstanceState) {
                super.onCreate(savedInstanceState);
            }
        }
      JAVA
      )

      # Create build.gradle (project level)
      File.write("#{android_dir}/build.gradle", <<-GRADLE
        buildscript {
            repositories {
                google()
                mavenCentral()
            }
            dependencies {
                classpath 'com.android.tools.build:gradle:8.1.0'
            }
        }

        allprojects {
            repositories {
                google()
                mavenCentral()
            }
        }

        task clean(type: Delete) {
            delete rootProject.buildDir
        }
      GRADLE
      )

      # Create build.gradle (app level)
      File.write("#{android_dir}/app/build.gradle", <<-GRADLE
        plugins {
            id 'com.android.application'
        }

        android {
            namespace 'com.nativecr.#{project_name}'
            compileSdk 34

            defaultConfig {
                applicationId "com.nativecr.#{project_name}"
                minSdk 24
                targetSdk 34
                versionCode 1
                versionName "1.0"
            }

            sourceSets {
                main {
                    jniLibs.srcDirs = ['src/main/jniLibs']
                }
            }
        }
      GRADLE
      )

      # Create settings.gradle
      File.write("#{android_dir}/settings.gradle", <<-GRADLE
        rootProject.name = "#{project_name}"
        include ':app'
      GRADLE
      )

      # Create gradle wrapper properties
      File.write("#{android_dir}/gradle/wrapper/gradle-wrapper.properties", <<-PROPERTIES
        distributionBase=GRADLE_USER_HOME
        distributionPath=wrapper/dists
        distributionUrl=https\\\\://services.gradle.org/distributions/gradle-8.0-bin.zip
        zipStoreBase=GRADLE_USER_HOME
        zipStorePath=wrapper/dists
      PROPERTIES
      )

      # Create gradle.properties
      File.write("#{android_dir}/gradle.properties", <<-PROPERTIES
        org.gradle.jvmargs=-Xmx2048m
        android.useAndroidX=true
      PROPERTIES
      )

      android_dir
    end
  end
end

if ARGV.size > 0 && ARGV[0] == "build"
  args = ARGV[1..-1] || [] of String
  cmd = Native::CLI::BuildCommand.new(args)
  cmd.run
end
