# src/native/cli/android.cr

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
    end

    private def create_app_build_gradle(app_dir : String)
      File.write("#{app_dir}/build.gradle", <<-GRADLE
        plugins {
            id 'com.android.application'
        }

        android {
            namespace '#{@package_name}'
            compileSdk 34

            defaultConfig {
                applicationId '#{@package_name}'
                minSdk 24
                targetSdk 34
                versionCode 1
                versionName '1.0'
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

    private def create_android_manifest(main_dir : String)
      File.write("#{main_dir}/AndroidManifest.xml", <<-XML
        <?xml version="1.0" encoding="utf-8"?>
        <manifest xmlns:android="http://schemas.android.com/apk/res/android"
            package="#{@package_name}">

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

    private def create_main_activity(java_dir : String)
      File.write("#{java_dir}/MainActivity.java", <<-JAVA
        package #{@package_name};

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
        distributionUrl=https\\\\://services.gradle.org/distributions/gradle-8.0-bin.zip
        zipStoreBase=GRADLE_USER_HOME
        zipStorePath=wrapper/dists
      PROPERTIES
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
  end
end
