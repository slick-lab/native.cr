# src/native/cli/create.cr

module Native::CLI
  class CreateCommand
    @project_name : String = ""
    @path : String = ""
    @platform : String = "both"
    @template : String = "app"

    def initialize(args : Array(String))
      parse_args(args)
    end

    def parse_args(args : Array(String))
      i = 0
      while i < args.size
        case args[i]
        when "-p", "--path"
          @path = args[i + 1] if i + 1 < args.size
          i += 2
        when "--android"
          @platform = "android"
          i += 1
        when "--ios"
          @platform = "ios"
          i += 1
        when "-t", "--template"
          @template = args[i + 1] if i + 1 < args.size
          i += 2
        when "-h", "--help"
          show_help
          exit(0)
        else
          if @project_name.empty?
            @project_name = args[i]
          end
          i += 1
        end
      end

      if @project_name.empty?
        puts "Error: Project name required"
        show_help
        exit(1)
      end

      if @path.empty?
        @path = @project_name
      end
    end

    def show_help
      puts <<-HELP
      Usage: native.cr create [OPTIONS] PROJECT_NAME

      Create a new native.cr project.

      Options:
        -p, --path DIR       Project directory path [default: ./PROJECT_NAME]
        --android            Generate Android only project
        --ios                Generate iOS only project
        -t, --template TYPE  Template type [app, game, library] [default: app]
        -h, --help           Show this help

      Examples:
        native.cr create my_app
        native.cr create my_app --android
        native.cr create my_app --ios
        native.cr create projects/my_app -p ./projects
      HELP
    end

    def run
      puts "[native.cr] Creating project: #{@project_name}"
      puts "[native.cr] Location: #{@path}"
      puts "[native.cr] Platform: #{@platform}"
      puts ""

      Dir.mkdir_p(@path)
      Dir.mkdir_p("#{@path}/src")
      Dir.mkdir_p("#{@path}/assets")

      create_main_cr
      create_shard_yml

      if @platform == "android" || @platform == "both"
        create_android_project
      end

      if @platform == "ios" || @platform == "both"
        create_ios_project
      end

      create_gitignore

      puts ""
      puts "[native.cr] Project created successfully!"
      puts ""
      puts "Next steps:"
      puts "  cd #{@path}"
      puts "  native.cr build #{@platform}"
      puts ""

      if @platform == "android" || @platform == "both"
        puts "Android:"
        puts "  cd #{@path}/android && ./gradlew assembleRelease"
        puts "  APK: #{@path}/android/app/build/outputs/apk/release/"
        puts ""
      end

      if @platform == "ios" || @platform == "both"
        puts "iOS:"
        puts "  open #{@path}/ios/NativeCr.xcodeproj"
        puts "  Build with Xcode"
        puts ""
      end
    end

    private def create_main_cr
      if @template == "game"
        create_game_template
      else
        create_app_template
      end
    end

    private def create_app_template
      File.write("#{@path}/src/main.cr", <<-CR
        require "native"
        class MyApp < Native::App
          @[Preserve]
          property count : Int32 = 0

          def setup : Nil
            @label = UI::Text.new
            @label.text = "Tap: 0"
            @label.text_size = 24

            button = UI::Button.new
            button.text = "Tap Me"
            button.width = 120
            button.height = 44
            button.on_click = ->{ increment }

            column = UI::Column.new
            column.spacing = 20
            column.add_child(@label)
            column.add_child(button)

            @root = column
          end

          def increment
            @count += 1
            @label.text = "Tap: \#{@count}"
          end

          def draw : Nil
            @root.draw(renderer)
          end
        end

        Native::App.start(MyApp)
      CR
      )
    end

    private def create_game_template
      File.write("#{@path}/src/main.cr", <<-CR
        class MyGame < Native::App
          include Native::GameLoop::GameLoopDSL

          @player_x : Float64 = 0.0
          @player_y : Float64 = 0.0
          @player_size : Int32 = 50
          @score : Int32 = 0

          def setup
            set_background_color(50, 50, 80)
            game_loop(target_fps: 60, mode: Native::GameLoop::LoopMode::Adaptive)
          end

          def game_start
            Native::Dialog.toast("Game Started!")
          end

          def game_update(delta_time : Float64)
          end

          def game_fixed_update(delta_time : Float64)
          end

          def game_render(alpha : Float64)
            draw_rect(renderer, @player_x.to_i, @player_y.to_i, @player_size, @player_size, 255, 100, 100, 255)
            draw_text(renderer, "Score: \#{@score}", 20, 60, 24, 255, 255, 255)
          end

          def on_touch_began(x : Float32, y : Float32)
            @player_x = x.to_f64 - @player_size // 2
            @player_y = y.to_f64 - @player_size // 2
            @score += 1
            Native::Platform::HapticFeedback.light
          end

          def draw
          end
        end

        Native::App.start(MyGame)
      CR
      )
    end

    private def create_shard_yml
      File.write("#{@path}/shard.yml", <<-YAML
        name: #{@project_name}
        version: 0.1.0

        authors:
          - Your Name <you@example.com>

        dependencies:
          native.cr:
            github: slick-lab/native.cr
            version: ~> 0.0.97

        crystal: ">= 1.20.0"

        license: MIT
      YAML
      )
    end

    private def create_android_project
      puts "[native.cr] Generating Android project..."

      android_dir = "#{@path}/android"
      Dir.mkdir_p(android_dir)
      Dir.mkdir_p("#{android_dir}/app/src/main/java/com/nativecr/#{@project_name}")
      Dir.mkdir_p("#{android_dir}/app/src/main/jniLibs/arm64-v8a")
      Dir.mkdir_p("#{android_dir}/gradle/wrapper")

      create_android_manifest(android_dir)
      create_android_main_activity(android_dir)
      create_android_build_gradle(android_dir)
      create_android_settings_gradle(android_dir)
      create_android_gradle_wrapper(android_dir)
      create_android_gradle_properties(android_dir)

      puts "[native.cr] Android project generated at #{android_dir}"
    end

    private def create_android_manifest(android_dir : String)
      File.write("#{android_dir}/app/src/main/AndroidManifest.xml", <<-XML
        <?xml version="1.0" encoding="utf-8"?>
        <manifest xmlns:android="http://schemas.android.com/apk/res/android"
            package="com.nativecr.#{@project_name}">

            <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="34" />

            <application
                android:label="#{@project_name}"
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
    end

    private def create_android_main_activity(android_dir : String)
      File.write("#{android_dir}/app/src/main/java/com/nativecr/#{@project_name}/MainActivity.java", <<-JAVA
        package com.nativecr.#{@project_name};

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
    end

    private def create_android_build_gradle(android_dir : String)
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

      File.write("#{android_dir}/app/build.gradle", <<-GRADLE
        plugins {
            id 'com.android.application'
        }

        android {
            namespace 'com.nativecr.#{@project_name}'
            compileSdk 34

            defaultConfig {
                applicationId "com.nativecr.#{@project_name}"
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
    end

    private def create_android_settings_gradle(android_dir : String)
      File.write("#{android_dir}/settings.gradle", <<-GRADLE
        rootProject.name = "#{@project_name}"
        include ':app'
      GRADLE
      )
    end

    private def create_android_gradle_wrapper(android_dir : String)
      File.write("#{android_dir}/gradle/wrapper/gradle-wrapper.properties", <<-PROPERTIES
        distributionBase=GRADLE_USER_HOME
        distributionPath=wrapper/dists
        distributionUrl=https\\://services.gradle.org/distributions/gradle-8.0-bin.zip
        zipStoreBase=GRADLE_USER_HOME
        zipStorePath=wrapper/dists
      PROPERTIES
      )
    end

    private def create_android_gradle_properties(android_dir : String)
      File.write("#{android_dir}/gradle.properties", <<-PROPERTIES
        org.gradle.jvmargs=-Xmx2048m
        android.useAndroidX=true
      PROPERTIES
      )
    end

    private def create_ios_project
      puts "[native.cr] Generating iOS project..."

      ios_dir = "#{@path}/ios"
      Dir.mkdir_p(ios_dir)
      Dir.mkdir_p("#{ios_dir}/NativeCr.xcodeproj")
      Dir.mkdir_p("#{ios_dir}/Base.lproj")

      create_ios_pbxproj(ios_dir)
      create_ios_main_storyboard(ios_dir)

      puts "[native.cr] iOS project generated at #{ios_dir}"
    end

    private def create_ios_pbxproj(ios_dir : String)
      File.write("#{ios_dir}/NativeCr.xcodeproj/project.pbxproj", <<-PBXPROJ
        // !$*UTF8*$!
        {
            archiveVersion = 1;
            classes = {
            };
            objectVersion = 56;
            objects = {
            };
            rootObject = 1;
        }
      PBXPROJ
      )
      puts "[native.cr] Note: iOS Xcode project requires manual setup in v0.1"
      puts "[native.cr] Run: xcodebuild -create-xcodeproj or use Flutter's template approach"
    end

    private def create_ios_main_storyboard(ios_dir : String)
      File.write("#{ios_dir}/Base.lproj/Main.storyboard", <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="21701" targetRuntime="iOS.CocoaTouch">
            <scenes>
                <scene sceneID="home">
                    <objects>
                        <viewController id="main" storyboardIdentifier="Main" sceneMemberID="viewController"/>
                        <placeholder placeholderIdentifier="IBFirstResponder" id="firstResponder" sceneMemberID="firstResponder"/>
                    </objects>
                </scene>
            </scenes>
        </document>
      XML
      )
    end

    private def create_gitignore
      File.write("#{@path}/.gitignore", <<-GITIGNORE
        /.native_cache/
        /lib/
        /bin/
        /shard.lock
        /android/.gradle/
        /android/build/
        /android/local.properties
        /ios/Pods/
        /ios/build/
        .DS_Store
      GITIGNORE
      )
    end
  end
end

if ARGV.size > 0 && ARGV[0] == "create"
  args = ARGV[1..-1] || [] of String
  cmd = Native::CLI::CreateCommand.new(args)
  cmd.run
end
