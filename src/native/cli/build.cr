# src/native/cli/build.cr

require "./apk"
require "./ipa"

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
      Usage: native.cr build [OPTIONS] [PLATFORM]

      Build native.cr app for Android or iOS.

      Options:
        -e, --entry FILE     Entry point file [default: src/main.cr]
        -o, --output DIR     Output directory [default: ./build]
        --release            Build in release mode (optimized)
        --clean              Clean build directory before building
        -h, --help           Show this help

      Platforms:
        android              Build APK for Android
        ios                  Build IPA for iOS (requires Mac and Xcode)

      Examples:
        native.cr build android
        native.cr build android --release
        native.cr build ios
      HELP
    end

    def mac?
      uname = `uname`.chomp
      uname == "Darwin"
    rescue
      false
    end

    def run
      if @platform == "ios"
        if mac?
          puts "[native.cr] Error: iOS builds can only be performed on macOS."
          puts "[native.cr] To build for iOS, you need a Mac with Xcode installed."
          exit(1)
        end
        build_ios
      else
        build_android
      end
    end

    # Build a minimal GC stub library for Android arm64.
    # Crystal's compiler driver adds -lgc to the linker command regardless
    # of -D without_gc. The host Crystal installation's libgc.a is built for
    # x86_64 and is incompatible with the aarch64-linux-android target.
    # This stub provides the GC symbols as no-ops so linking succeeds.
    #
    # CRITICAL: Boehm GC zeroes allocated memory, which Crystal relies on
    # for object initialization. The stub MUST use calloc (not malloc) to
    # match this behaviour, otherwise unset pointers contain garbage and
    # the runtime crashes with SIGSEGV.
    private def ensure_gc_stub_android(toolchain : String) : String
      gc_dir = "#{@output}/gc-android-arm64"
      stub_a = "#{gc_dir}/libgc.a"

      if File.exists?(stub_a)
        puts "[native.cr] GC stub already built."
        return gc_dir
      end

      puts "[native.cr] Building GC stub for Android arm64..."
      Dir.mkdir_p(gc_dir)

      clang = "#{toolchain}/bin/aarch64-linux-android24-clang"
      llvm_ar = "#{toolchain}/bin/llvm-ar"

      gc_stub_c = "#{gc_dir}/gc_stub.c"
      File.write(gc_stub_c, <<~C
        #include <stdlib.h>
        #include <stddef.h>
        #include <string.h>
        typedef void (*GC_finalization_proc)(void *, void *);
        typedef int GC_bool;

        static void *gc_alloc(size_t size) {
            void *p = calloc(1, size);
            return p;
        }

        void GC_init(void) {}
        void *GC_malloc(size_t size) { return gc_alloc(size); }
        void *GC_malloc_atomic(size_t size) { return gc_alloc(size); }
        void *GC_malloc_uncollectable(size_t size) { return gc_alloc(size); }
        void GC_free(void *ptr) { free(ptr); }
        void *GC_realloc(void *ptr, size_t size) {
            void *p = realloc(ptr, size);
            if (p && ptr != p) memset(p, 0, size);
            return p;
        }
        void GC_gcollect(void) {}
        void GC_enable(void) {}
        void GC_disable(void) {}
        GC_bool GC_is_disabled(void) { return 0; }
        void *GC_base(void *ptr) { return NULL; }
        void GC_register_finalizer_no_order(void *obj, GC_finalization_proc fn, void *cd, GC_finalization_proc *ofn, void **ocd) {}
        int GC_register_disappearing_link(void **link) { return 0; }
        int GC_unregister_disappearing_link(void **link) { return 0; }
        size_t GC_get_heap_size(void) { return 0; }
        size_t GC_get_free_bytes(void) { return 0; }
        size_t GC_get_unmapped_bytes(void) { return 0; }
        size_t GC_get_bytes_since_gc(void) { return 0; }
        size_t GC_get_total_bytes(void) { return 0; }
        void GC_set_max_heap_size(size_t n) {}
        int GC_invoke_finalizers(void) { return 0; }
        void GC_atfork_prepare(void) {}
        void GC_atfork_parent(void) {}
        void GC_atfork_child(void) {}
        C
      )

      stub_o = "#{gc_dir}/gc_stub.o"
      `#{clang} -c #{gc_stub_c} -o #{stub_o}`
      `#{llvm_ar} rcs #{stub_a} #{stub_o}`

      unless File.exists?(stub_a)
        puts "[native.cr] Error: Failed to build GC stub."
        exit(1)
      end

      puts "[native.cr] GC stub built."
      gc_dir
    end

    # Build PCRE2 for Android arm64 from source.
    # Crystal's stdlib requires libpcre2-8 at link time. When targeting
    # aarch64-linux-android the NDK linker cannot use the host x86_64 PCRE2.
    private def ensure_pcre2_android(toolchain : String) : String
      pcre2_dir = "/tmp/pcre2-android"
      pcre2_lib = "#{pcre2_dir}/lib/libpcre2-8.a"

      if File.exists?(pcre2_lib)
        puts "[native.cr] PCRE2 for Android already built."
        return "#{pcre2_dir}/lib"
      end

      puts "[native.cr] Building PCRE2 for Android arm64..."

      pcre2_version = "10.42"
      pcre2_tar = "#{@output}/pcre2-#{pcre2_version}.tar.gz"
      pcre2_src = "#{@output}/pcre2-#{pcre2_version}"

      unless File.exists?(pcre2_tar)
        url = "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-#{pcre2_version}/pcre2-#{pcre2_version}.tar.gz"
        puts "[native.cr] Downloading PCRE2 #{pcre2_version}..."
        system("wget -q -O #{pcre2_tar} #{url}")
        unless File.exists?(pcre2_tar) && File.size(pcre2_tar) > 0
          puts "[native.cr] Error: Failed to download PCRE2."
          exit(1)
        end
      end

      unless Dir.exists?(pcre2_src)
        system("tar xzf #{pcre2_tar} -C #{@output}")
      end

      clang = "#{toolchain}/bin/aarch64-linux-android24-clang"
      clangxx = "#{toolchain}/bin/aarch64-linux-android24-clang++"
      llvm_ar = "#{toolchain}/bin/llvm-ar"
      llvm_ranlib = "#{toolchain}/bin/llvm-ranlib"

      configure_cmd = <<~CMD
        cd #{pcre2_src} && \
        ./configure \
          --host=aarch64-linux-android \
          --prefix=#{pcre2_dir} \
          --enable-static \
          --disable-shared \
          --disable-jit \
          CC="#{clang}" \
          CXX="#{clangxx}" \
          AR="#{llvm_ar}" \
          RANLIB="#{llvm_ranlib}" \
          > #{@output}/pcre2-configure.log 2>&1
      CMD

      puts "[native.cr] Configuring PCRE2..."
      system(configure_cmd)

      puts "[native.cr] Compiling PCRE2..."
      make_cmd = "cd #{pcre2_src} && make -j$(nproc) > #{@output}/pcre2-build.log 2>&1"
      system(make_cmd)

      puts "[native.cr] Installing PCRE2..."
      install_cmd = "cd #{pcre2_src} && make install > #{@output}/pcre2-install.log 2>&1"
      system(install_cmd)

      unless File.exists?(pcre2_lib)
        puts "[native.cr] Error: Failed to build PCRE2 for Android."
        puts "[native.cr] Check #{@output}/pcre2-*.log for details."
        exit(1)
      end

      puts "[native.cr] PCRE2 built for Android arm64."
      "#{pcre2_dir}/lib"
    end

    private def build_android
      puts "[native.cr] Building for Android"
      puts "[native.cr] Entry point: #{@entry_point}"
      puts "[native.cr] Output: #{@output}"
      puts "[native.cr] Release mode: #{@release ? "yes" : "no"}"
      puts ""

      if @clean && Dir.exists?(@output)
        FileUtils.rm_rf(@output)
        puts "[native.cr] Cleaned output directory"
      end

      Dir.mkdir_p(@output)

      ndk = ENV["ANDROID_NDK"]?
      unless ndk && Dir.exists?(ndk)
        puts "[native.cr] Error: ANDROID_NDK not set"
        puts "[native.cr] Install Android NDK and set ANDROID_NDK environment variable"
        exit(1)
      end

      android_project = find_android_project
      unless android_project
        puts "[native.cr] Error: Android project not found."
        puts "[native.cr] Run 'native.cr create my_app --android' first."
        exit(1)
      end

      lib_dir = "lib/native"

      unless File.exists?("#{lib_dir}/native_engine.o")
        puts "[native.cr] Error: Prebuilt engine object not found."
        puts "[native.cr] Run 'shards install' first to download native_engine.o"
        exit(1)
      end

      unless File.exists?("#{lib_dir}/libnative_cr_android.jar")
        puts "[native.cr] Error: Prebuilt Java library not found."
        puts "[native.cr] Run 'shards install' first to download libnative_cr_android.jar"
        exit(1)
      end
      op = os
      toolchain = "#{ndk}/toolchains/llvm/prebuilt/#{op}"
      clang = "#{toolchain}/bin/aarch64-linux-android24-clang"

      unless File.exists?(clang)
        puts "[native.cr] Error: NDK toolchain not found at #{toolchain}"
        exit(1)
      end

      lib_dir_out = "#{@output}/lib/arm64-v8a"
      Dir.mkdir_p(lib_dir_out)

      # Build GC stub and PCRE2 for Android arm64 cross-compilation.
      # Crystal's compiler driver adds -lgc regardless of -D without_gc,
      # so we need an aarch64-compatible libgc.a stub. PCRE2 is also
      # required by Crystal's stdlib regex support.
      gc_lib_dir = ensure_gc_stub_android(toolchain)
      pcre2_lib_dir = ensure_pcre2_android(toolchain)

      puts "[native.cr] Compiling user code with framework..."
      user_o = "#{@output}/user_code.o"
      # -Dwithout_gc: use gc/null.cr instead of gc/boehm.cr to avoid
      # Boehm GC compatibility issues with Android's bionic libc.
      cmd = "crystal build #{@entry_point} -Dnative_android -Dwithout_gc --target aarch64-linux-android --cross-compile -o #{user_o}"
      cmd += " --release" if @release
      output = `#{cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      puts "[native.cr] Linking final library..."
      final_so = "#{@output}/lib/arm64-v8a/libnative_app.so"
      link_cmd = "#{clang} -shared -fPIC -Wl,-soname,libnative_app.so -o #{final_so} #{user_o} #{lib_dir}/native_engine.o -L#{gc_lib_dir} -L#{pcre2_lib_dir} -lgc -lpcre2-8 -landroid -llog"
      link_output = `#{link_cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Linking failed:"
        puts link_output
        exit(1)
      end

      jni_dir = "#{android_project}/app/src/main/jniLibs/arm64-v8a"
      libs_dir = "#{android_project}/app/libs"
      Dir.mkdir_p(jni_dir)
      Dir.mkdir_p(libs_dir)

      FileUtils.cp(final_so, "#{jni_dir}/libnative_app.so")
      FileUtils.cp("#{lib_dir}/libnative_cr_android.jar", libs_dir)

      apk_path = Native::CLI::Apk.build(android_project, @release)

      if apk_path
        puts "\n[native.cr] Build complete! APK: #{apk_path}"
      else
        puts "[native.cr] APK build failed"
        exit(1)
      end
    end

    private def build_ios
      puts "[native.cr] Building for iOS"
      puts "[native.cr] Entry point: #{@entry_point}"
      puts "[native.cr] Output: #{@output}"
      puts "[native.cr] Release mode: #{@release ? "yes" : "no"}"
      puts ""

      if @clean && Dir.exists?(@output)
        FileUtils.rm_rf(@output)
        puts "[native.cr] Cleaned output directory"
      end

      Dir.mkdir_p(@output)

      ios_project = find_ios_project
      unless ios_project
        puts "[native.cr] Error: iOS project not found."
        puts "[native.cr] Run 'native.cr create my_app --ios' first."
        exit(1)
      end

      lib_dir = "lib/native"

      unless File.exists?("#{lib_dir}/libnative_cr_engine.a")
        puts "[native.cr] Error: Prebuilt engine library not found."
        puts "[native.cr] Run 'shards install' first to download libnative_cr_engine.a"
        exit(1)
      end

      frameworks_dir = "#{ios_project}/Frameworks"
      Dir.mkdir_p(frameworks_dir)
      FileUtils.cp("#{lib_dir}/libnative_cr_engine.a", frameworks_dir)

      puts "[native.cr] Compiling user code with framework..."
      user_o = "#{@output}/user_code.o"
      cmd = "crystal build #{@entry_point} -D ios --target aarch64-apple-darwin --cross-compile -o #{user_o}"
      cmd += " --release" if @release
      output = `#{cmd} 2>&1`

      unless $?.success?
        puts "[native.cr] Compilation failed:"
        puts output
        exit(1)
      end

      puts "[native.cr] Creating static library..."
      final_a = "#{@output}/libuser_app.a"
      `ar rcs #{final_a} #{user_o}`

      FileUtils.cp(final_a, frameworks_dir)

      ipa_path = Native::CLI::Ipa.build(ios_project, @release)

      if ipa_path
        puts "\n[native.cr] Build complete! IPA: #{ipa_path}"
      else
        puts "[native.cr] IPA build failed"
        exit(1)
      end
    end

    private def find_android_project : String?
      ["android", "../android", "./android"].each do |path|
        return path if Dir.exists?(path) && File.exists?("#{path}/app/build.gradle")
      end
      nil
    end

    private def find_ios_project : String?
      ["ios", "../ios", "./ios"].each do |path|
        return path if Dir.exists?(path) && Dir.glob("#{path}/*.xcodeproj").any?
      end
      nil
    end

    private def os : String
      host_os = `uname -s`.chomp.downcase
      host_arch = `uname -m`.chomp.downcase
      os_name = case host_os
                when "darwin"            then "darwin"
                when "linux"             then "linux"
                when /mingw|msys|cygwin/ then "windows"
                else                          "linux"
                end
      os_arch = case host_arch
                when /x86_64/        then "x86_64"
                when /aarch64|arm64/ then "aarch64"
                else                      "x86_64"
                end

      "#{os_name}-#{os_arch}"
    end
  end
end

if ARGV.size > 0 && ARGV[0] == "build"
  args = ARGV[1..-1] || [] of String
  cmd = Native::CLI::BuildCommand.new(args)
  cmd.run
end
