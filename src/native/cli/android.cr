# src/native/cli/android.cr
require "system"

module Native::CLI
  class AndroidGenerator
    @project_name : String
    @output_dir : String
    @package_name : String

    def initialize(project_name : String, output_dir : String)
      @project_name = project_name
      @output_dir = output_dir
      @package_name = "com.nativecr.#{project_name.downcase.gsub(/[^a-zA-Z0-9]/, "")}"
    end

    def generate
      puts "[native.cr] Generating Android project..."
      puts "[native.cr] Project: #{@project_name}"
      puts ""

      android_dir = "#{@output_dir}/android"
      app_dir = "#{android_dir}/app"
      main_dir = "#{app_dir}/src/main"
      java_dir = "#{main_dir}/java/#{@package_name.gsub(".", "/")}"
      jni_dir = "#{main_dir}/jniLibs/arm64-v8a"

      Dir.mkdir_p(java_dir)
      Dir.mkdir_p(jni_dir)
      Dir.mkdir_p("#{android_dir}/gradle/wrapper")

      create_settings_gradle(android_dir)
      create_build_gradle(android_dir)
      create_app_build_gradle(app_dir)
      create_android_manifest(main_dir)
      create_main_activity(java_dir)
      create_gradle_properties(android_dir)
      create_gradle_wrapper(android_dir)
      create_gitignore(android_dir)
      download_gradle_jar(android_dir)

      puts "[native.cr] Android project generated at #{android_dir}"
      puts "[native.cr] Build APK: cd #{android_dir} && ./gradlew assembleDebug"
    end

    private def create_settings_gradle(android_dir : String)
      File.write("#{android_dir}/settings.gradle", <<-GRADLE
        rootProject.name = "#{@project_name}"
        include ':app'
      GRADLE
      )
    end

    private def create_build_gradle(android_dir : String)
      File.write("#{android_dir}/build.gradle", <<-GRADLE
        buildscript {
            repositories {
                google()
                mavenCentral()
            }
            dependencies {
                classpath 'com.android.tools.build:gradle:9.1.0'
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
    end

    private def create_app_build_gradle(app_dir : String)
      File.write("#{app_dir}/build.gradle", <<-GRADLE
        plugins {
            id 'com.android.application'
        }

        android {
            namespace = '#{@package_name}'
            compileSdk = 34

            defaultConfig {
                applicationId ='#{@package_name}'
                minSdk = 24
                targetSdk = 34
                versionCode = 1
                versionName = '1.0'
            }

            sourceSets {
                main {
                    jniLibs.srcDirs = ['src/main/jniLibs']
                }
            }
        }

        dependencies {
            // Required by NotificationHelper / NotificationCompat (local notifications).
            implementation 'androidx.core:core:1.12.0'

            // To enable FCM remote push, uncomment and add google-services.json:
            // implementation 'com.google.firebase:firebase-messaging:23.4.0'
        }
      GRADLE
      )
    end

    private def create_android_manifest(main_dir : String)
      File.write("#{main_dir}/AndroidManifest.xml", <<-XML
       <?xml version="1.0" encoding="utf-8"?>
       <manifest xmlns:android="http://schemas.android.com/apk/res/android"
        package="#{@package_name}">

        <!-- Camera / microphone / location are requested at runtime -->
        <!-- POST_NOTIFICATIONS is required on Android 13+ (API 33+) -->
        <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
        <!-- SCHEDULE_EXACT_ALARM lets NotificationHelper deliver on time in Doze mode -->
        <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
        <!-- RECEIVE_BOOT_COMPLETED restores scheduled alarms after a reboot -->
        <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

        <application
            android:label="#{@project_name}"
            android:hasCode="true"
            android:allowBackup="false">

            <activity
                android:name=".MainActivity"
                android:configChanges="orientation|keyboardHidden|screenSize"
                android:exported="true">

                <meta-data
                    android:name="android.app.lib_name"
                    android:value="native_app" />

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

    private def create_main_activity(java_dir : String)
      File.write("#{java_dir}/MainActivity.java", <<-JAVA
        package #{@package_name};

        import android.app.NativeActivity;
        import android.os.Bundle;

        public class MainActivity extends NativeActivity {
            static {
                System.loadLibrary("native_app");
            }

            @Override
            protected void onCreate(Bundle savedInstanceState) {
                super.onCreate(savedInstanceState);
            }
        }
      JAVA
      )
    end

    private def create_gradle_properties(android_dir : String)
      File.write("#{android_dir}/gradle.properties", <<-PROPERTIES
        org.gradle.jvmargs=-Xmx2048m
        android.useAndroidX=true
      PROPERTIES
      )
    end

    private def create_gradle_wrapper(android_dir : String)
      File.write("#{android_dir}/gradle/wrapper/gradle-wrapper.properties", <<-PROPERTIES
        distributionBase=GRADLE_USER_HOME
        distributionPath=wrapper/dists
        distributionUrl=https\\://services.gradle.org/distributions/gradle-9.3.1-bin.zip
        zipStoreBase=GRADLE_USER_HOME
        zipStorePath=wrapper/dists
      PROPERTIES
      )

      # Fixed CLASSPATH string interpolation and class name spelling
      File.write("#{android_dir}/gradlew", <<-'SCRIPT'
        #!/bin/sh
        APP_HOME=$(cd "$(dirname "$0")" && pwd)
        CLASSPATH="$APP_HOME/gradle/wrapper/gradle-wrapper.jar"
        exec java -cp "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
        SCRIPT
      )
      File.chmod("#{android_dir}/gradlew", 0o755)

      # Fixed missing percentage symbols and class name casing
      File.write("#{android_dir}/gradlew.bat", <<-'BAT'
        @echo off
        set APP_HOME=%~dp0
        set CLASSPATH=%APP_HOME%gradle\wrapper\gradle-wrapper.jar
        java -cp "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*
        BAT
      )
    end

    private def create_gitignore(android_dir : String)
      File.write("#{android_dir}/.gitignore", <<-GITIGNORE
        .gradle/
        build/
        local.properties
        .idea/
        *.iml
        .DS_Store
      GITIGNORE
      )
    end

    private def download_gradle_jar(android_dir : String)
      jar_dir = "#{android_dir}/gradle/wrapper"
      jar_path = "#{jar_dir}/gradle-wrapper.jar"
      tmp_path = "#{jar_path}.part"

      Dir.mkdir_p(jar_dir)
      version = Native::VERSION
      url = "https://github.com/slick-lab/native.cr/releases/download/v#{version}/gradle-wrapper.jar"

      # Download to a .part file first so a failed or interrupted transfer
      # never leaves a broken jar at the final path.
      # -f : fail on HTTP errors instead of saving the error page as the jar
      # -sS: no progress meter, but keep error messages
      # -L : follow redirects (GitHub release assets redirect to CDN)
      # -w : print the final HTTP status code so failures are explainable
      # Only `success?` is used on the process result — stream accessors
      # differ between crystal versions.
      http_code_out = IO::Memory.new
      result = Process.run(
        "curl",
        args: ["-fsSL", "--retry", "3", "--retry-delay", "2", "--connect-timeout", "15", "--max-time", "300", "-w", "%{http_code}", "-o", tmp_path, url],
        output: http_code_out,
        error: Process::Redirect::Inherit
      )
      http_code = http_code_out.to_s.strip

      if result.success? && JarUtil.valid_jar?(tmp_path)
        File.rename(tmp_path, jar_path)
        puts "[native.cr] gradle-wrapper.jar downloaded and verified (#{File.size(jar_path)} bytes)"
        return
      end

      # Something went wrong — say exactly what instead of failing silently.
      File.delete(tmp_path) if File.exists?(tmp_path)
      code = http_code.to_i?
      reason =
        if code && code >= 400
          "HTTP #{code} fetching #{url} (no release asset for v#{version}?)"
        elsif code && code >= 200 && code < 400
          "downloaded file is not a valid jar (expected a zip archive)"
        elsif code == 0 || http_code.empty?
          "network error reaching #{url} (offline, timeout, or DNS failure)"
        else
          "curl could not complete the download (see curl error above)"
        end

      puts "[native.cr] ERROR: could not download gradle-wrapper.jar: #{reason}"
      puts "[native.cr] The android build cannot work without this jar."
      puts "[native.cr] Download it manually from https://github.com/slick-lab/native.cr/releases"
      puts "[native.cr] and place it at: #{jar_path}"
      exit 1
    end

  end

  # Jar integrity helpers for the CLI download logic.
  # Kept module-level so specs can exercise them without a device.
  module JarUtil
    # A jar is a zip: it must start with the "PK\x03\x04" magic bytes.
    # An HTML error page or truncated body will not.
    def self.valid_jar?(path : String) : Bool
      return false unless File.exists?(path) && File.size(path) >= 4
      header = Bytes.new(4)
      File.open(path, "rb") do |file|
        file.read_fully(header)
      end
      header[0] == 0x50 && header[1] == 0x4B && header[2] == 0x03 && header[3] == 0x04
    end
  end
end
