module Native::Storage
  class Preferences
    def initialize(@name : String = "default")
    end

    def set(key : String, value : String) : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        jkey = env.new_string_utf(key)
        jvalue = env.new_string_utf(value)

        get_prefs = env.get_method_id(env.get_object_class(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.call_object_method(activity, get_prefs, env.new_string_utf(@name), 0)

        edit = env.get_method_id(env.get_object_class(prefs), "edit", "()Landroid/content/SharedPreferences$Editor;")
        editor = env.call_object_method(prefs, edit)

        put_string = env.get_method_id(env.get_object_class(editor), "putString", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;")
        env.call_object_method(editor, put_string, jkey, jvalue)

        apply = env.get_method_id(env.get_object_class(editor), "apply", "()V")
        env.call_void_method(editor, apply)

        env.delete_local_ref(jkey)
        env.delete_local_ref(jvalue)
        env.delete_local_ref(prefs)
        env.delete_local_ref(editor)
      {% elsif flag?(:native_ios) %}
        LibIOS.user_defaults_set(key.to_utf8, value.to_utf8)
      {% end %}
    end

    def set(key : String, value : Int32) : Nil
      set(key, value.to_s)
    end

    def set(key : String, value : Int64) : Nil
      set(key, value.to_s)
    end

    def set(key : String, value : Float32) : Nil
      set(key, value.to_s)
    end

    def set(key : String, value : Float64) : Nil
      set(key, value.to_s)
    end

    def set(key : String, value : Bool) : Nil
      set(key, value.to_s)
    end

    def get_string(key : String, default : String = "") : String
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return default unless env && activity

        jkey = env.new_string_utf(key)
        jdefault = env.new_string_utf(default)

        get_prefs = env.get_method_id(env.get_object_class(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.call_object_method(activity, get_prefs, env.new_string_utf(@name), 0)

        get_string = env.get_method_id(env.get_object_class(prefs), "getString", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;")
        result = env.call_object_method(prefs, get_string, jkey, jdefault)

        value = if result
                  env.get_string_utf_chars(result, nil).to_s
                else
                  default
                end

        env.delete_local_ref(jkey)
        env.delete_local_ref(jdefault)
        env.delete_local_ref(prefs)
        env.delete_local_ref(result) if result

        value
      {% elsif flag?(:native_ios) %}
        ptr = LibIOS.user_defaults_get(key.to_utf8)
        if ptr
          result = String.new(ptr)
          LibIOS.free_string(ptr)
          result
        else
          default
        end
      {% else %}
        default
      {% end %}
    end

    def get_int(key : String, default : Int32 = 0) : Int32
      get_string(key, default.to_s).to_i
    end

    def get_int64(key : String, default : Int64 = 0) : Int64
      get_string(key, default.to_s).to_i64
    end

    def get_float(key : String, default : Float32 = 0.0) : Float32
      get_string(key, default.to_s).to_f32
    end

    def get_double(key : String, default : Float64 = 0.0) : Float64
      get_string(key, default.to_s).to_f64
    end

    def get_bool(key : String, default : Bool = false) : Bool
      get_string(key, default.to_s) == "true"
    end

    def contains?(key : String) : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        jkey = env.new_string_utf(key)

        get_prefs = env.get_method_id(env.get_object_class(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.call_object_method(activity, get_prefs, env.new_string_utf(@name), 0)

        contains = env.get_method_id(env.get_object_class(prefs), "contains", "(Ljava/lang/String;)Z")
        result = env.call_boolean_method(prefs, contains, jkey)

        env.delete_local_ref(jkey)
        env.delete_local_ref(prefs)

        result
      {% elsif flag?(:native_ios) %}
        LibIOS.user_defaults_contains(key.to_utf8)
      {% else %}
        false
      {% end %}
    end

    def delete(key : String) : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        jkey = env.new_string_utf(key)

        get_prefs = env.get_method_id(env.get_object_class(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.call_object_method(activity, get_prefs, env.new_string_utf(@name), 0)

        edit = env.get_method_id(env.get_object_class(prefs), "edit", "()Landroid/content/SharedPreferences$Editor;")
        editor = env.call_object_method(prefs, edit)

        remove = env.get_method_id(env.get_object_class(editor), "remove", "(Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;")
        env.call_object_method(editor, remove, jkey)

        apply = env.get_method_id(env.get_object_class(editor), "apply", "()V")
        env.call_void_method(editor, apply)

        env.delete_local_ref(jkey)
        env.delete_local_ref(prefs)
        env.delete_local_ref(editor)
      {% elsif flag?(:native_ios) %}
        LibIOS.user_defaults_delete(key.to_utf8)
      {% end %}
    end

    def clear : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        get_prefs = env.get_method_id(env.get_object_class(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.call_object_method(activity, get_prefs, env.new_string_utf(@name), 0)

        edit = env.get_method_id(env.get_object_class(prefs), "edit", "()Landroid/content/SharedPreferences$Editor;")
        editor = env.call_object_method(prefs, edit)

        clr = env.get_method_id(env.get_object_class(editor), "clear", "()Landroid/content/SharedPreferences$Editor;")
        env.call_object_method(editor, clr)

        apply = env.get_method_id(env.get_object_class(editor), "apply", "()V")
        env.call_void_method(editor, apply)

        env.delete_local_ref(prefs)
        env.delete_local_ref(editor)
      {% elsif flag?(:native_ios) %}
        LibIOS.user_defaults_clear
      {% end %}
    end

    def all_keys : Array(String)
      {% if flag?(:native_android) %}
        keys = [] of String
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return keys unless env && activity

        get_prefs = env.get_method_id(env.get_object_class(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.call_object_method(activity, get_prefs, env.new_string_utf(@name), 0)

        get_all = env.get_method_id(env.get_object_class(prefs), "getAll", "()Ljava/util/Map;")
        map = env.call_object_method(prefs, get_all)

        key_set = env.call_object_method(map, env.get_method_id(env.get_object_class(map), "keySet", "()Ljava/util/Set;"))
        iterator = env.call_object_method(key_set, env.get_method_id(env.get_object_class(key_set), "iterator", "()Ljava/util/Iterator;"))

        while env.call_boolean_method(iterator, env.get_method_id(env.get_object_class(iterator), "hasNext", "()Z"))
          jkey = env.call_object_method(iterator, env.get_method_id(env.get_object_class(iterator), "next", "()Ljava/lang/Object;"))
          keys << env.get_string_utf_chars(jkey, nil).to_s
          env.delete_local_ref(jkey)
        end

        env.delete_local_ref(prefs)
        env.delete_local_ref(map)
        env.delete_local_ref(key_set)
        env.delete_local_ref(iterator)

        keys
      {% elsif flag?(:native_ios) %}
        ptr_array = LibIOS.user_defaults_all_keys
        keys = [] of String
        if ptr_array
          i = 0
          while true
            ptr = ptr_array[i]
            break if ptr.null?
            keys << String.new(ptr)
            i += 1
          end
          LibIOS.free_string_array(ptr_array)
        end
        keys
      {% else %}
        [] of String
      {% end %}
    end
  end

  class FileStorage
    enum StorageType
      Documents
      Cache
      Temporary
    end

    def initialize(@type : StorageType = StorageType::Documents)
    end

    def write(filename : String, data : Bytes) : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        method_name = case @type
                      when StorageType::Documents then "getFilesDir"
                      when StorageType::Cache     then "getCacheDir"
                      when StorageType::Temporary then "getCacheDir"
                      end

        get_dir = env.get_method_id(env.get_object_class(activity), method_name, "()Ljava/io/File;")
        dir = env.call_object_method(activity, get_dir)

        get_path = env.get_method_id(env.get_object_class(dir), "getPath", "()Ljava/lang/String;")
        path = env.call_object_method(dir, get_path)

        full_path = "#{env.get_string_utf_chars(path, nil).to_s}/#{filename}"
        env.delete_local_ref(dir)
        env.delete_local_ref(path)

        file_class = env.find_class("java/io/File")
        file_constructor = env.get_method_id(file_class, "<init>", "(Ljava/lang/String;)V")
        file = env.new_object(file_class, file_constructor, env.new_string_utf(full_path))

        fos_class = env.find_class("java/io/FileOutputStream")
        fos_constructor = env.get_method_id(fos_class, "<init>", "(Ljava/io/File;)V")
        fos = env.new_object(fos_class, fos_constructor, file)

        write_method = env.get_method_id(fos_class, "write", "([B)V")
        byte_array = env.new_byte_array(data.size)
        env.set_byte_array_region(byte_array, 0, data.size, data)
        env.call_void_method(fos, write_method, byte_array)

        close_method = env.get_method_id(fos_class, "close", "()V")
        env.call_void_method(fos, close_method)

        env.delete_local_ref(file)
        env.delete_local_ref(fos)
        env.delete_local_ref(byte_array)

        true
      {% elsif flag?(:native_ios) %}
        LibIOS.file_write(filename.to_utf8, data, data.size, @type.value)
      {% else %}
        false
      {% end %}
    end

    def write_text(filename : String, content : String) : Bool
      write(filename, content.to_slice)
    end

    def read(filename : String) : Bytes?
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return nil unless env && activity

        method_name = case @type
                      when StorageType::Documents then "getFilesDir"
                      when StorageType::Cache     then "getCacheDir"
                      when StorageType::Temporary then "getCacheDir"
                      end

        get_dir = env.get_method_id(env.get_object_class(activity), method_name, "()Ljava/io/File;")
        dir = env.call_object_method(activity, get_dir)

        get_path = env.get_method_id(env.get_object_class(dir), "getPath", "()Ljava/lang/String;")
        path = env.call_object_method(dir, get_path)

        full_path = "#{env.get_string_utf_chars(path, nil).to_s}/#{filename}"
        env.delete_local_ref(dir)
        env.delete_local_ref(path)

        file_class = env.find_class("java/io/File")
        file_constructor = env.get_method_id(file_class, "<init>", "(Ljava/lang/String;)V")
        file = env.new_object(file_class, file_constructor, env.new_string_utf(full_path))

        fis_class = env.find_class("java/io/FileInputStream")
        fis_constructor = env.get_method_id(fis_class, "<init>", "(Ljava/io/File;)V")
        fis = env.new_object(fis_class, fis_constructor, file)

        available = env.get_method_id(fis_class, "available", "()I")
        size = env.call_int_method(fis, available)

        if size <= 0
          env.delete_local_ref(file)
          env.delete_local_ref(fis)
          return nil
        end

        byte_array = env.new_byte_array(size)
        read_method = env.get_method_id(fis_class, "read", "([B)I")
        env.call_int_method(fis, read_method, byte_array)

        close_method = env.get_method_id(fis_class, "close", "()V")
        env.call_void_method(fis, close_method)

        data = Bytes.new(size)
        env.get_byte_array_region(byte_array, 0, size, data)

        env.delete_local_ref(file)
        env.delete_local_ref(fis)
        env.delete_local_ref(byte_array)

        data
      {% elsif flag?(:native_ios) %}
        size_ptr = Pointer(Int32).malloc(1)
        data_ptr = LibIOS.file_read(filename.to_utf8, size_ptr, @type.value)
        if data_ptr && size_ptr.value > 0
          data = Bytes.new(size_ptr.value) { |i| data_ptr[i] }
          LibIOS.free(data_ptr)
          data
        else
          nil
        end
      {% else %}
        nil
      {% end %}
    end

    def read_text(filename : String) : String?
      data = read(filename)
      data ? String.new(data) : nil
    end

    def exists?(filename : String) : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        method_name = case @type
                      when StorageType::Documents then "getFilesDir"
                      when StorageType::Cache     then "getCacheDir"
                      when StorageType::Temporary then "getCacheDir"
                      end

        get_dir = env.get_method_id(env.get_object_class(activity), method_name, "()Ljava/io/File;")
        dir = env.call_object_method(activity, get_dir)

        get_path = env.get_method_id(env.get_object_class(dir), "getPath", "()Ljava/lang/String;")
        path = env.call_object_method(dir, get_path)

        full_path = "#{env.get_string_utf_chars(path, nil).to_s}/#{filename}"
        env.delete_local_ref(dir)
        env.delete_local_ref(path)

        file_class = env.find_class("java/io/File")
        file_constructor = env.get_method_id(file_class, "<init>", "(Ljava/lang/String;)V")
        file = env.new_object(file_class, file_constructor, env.new_string_utf(full_path))

        exists_method = env.get_method_id(file_class, "exists", "()Z")
        result = env.call_boolean_method(file, exists_method)

        env.delete_local_ref(file)

        result
      {% elsif flag?(:native_ios) %}
        LibIOS.file_exists(filename.to_utf8, @type.value)
      {% else %}
        false
      {% end %}
    end

    def delete(filename : String) : Bool
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        method_name = case @type
                      when StorageType::Documents then "getFilesDir"
                      when StorageType::Cache     then "getCacheDir"
                      when StorageType::Temporary then "getCacheDir"
                      end

        get_dir = env.get_method_id(env.get_object_class(activity), method_name, "()Ljava/io/File;")
        dir = env.call_object_method(activity, get_dir)

        get_path = env.get_method_id(env.get_object_class(dir), "getPath", "()Ljava/lang/String;")
        path = env.call_object_method(dir, get_path)

        full_path = "#{env.get_string_utf_chars(path, nil).to_s}/#{filename}"
        env.delete_local_ref(dir)
        env.delete_local_ref(path)

        file_class = env.find_class("java/io/File")
        file_constructor = env.get_method_id(file_class, "<init>", "(Ljava/lang/String;)V")
        file = env.new_object(file_class, file_constructor, env.new_string_utf(full_path))

        delete_method = env.get_method_id(file_class, "delete", "()Z")
        result = env.call_boolean_method(file, delete_method)

        env.delete_local_ref(file)

        result
      {% elsif flag?(:native_ios) %}
        LibIOS.file_delete(filename.to_utf8, @type.value)
      {% else %}
        false
      {% end %}
    end

    def list(directory : String = "") : Array(String)
      {% if flag?(:native_android) %}
        files = [] of String
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return files unless env && activity

        method_name = case @type
                      when StorageType::Documents then "getFilesDir"
                      when StorageType::Cache     then "getCacheDir"
                      when StorageType::Temporary then "getCacheDir"
                      end

        get_dir = env.get_method_id(env.get_object_class(activity), method_name, "()Ljava/io/File;")
        dir = env.call_object_method(activity, get_dir)

        get_path = env.get_method_id(env.get_object_class(dir), "getPath", "()Ljava/lang/String;")
        path = env.call_object_method(dir, get_path)

        full_path = env.get_string_utf_chars(path, nil).to_s
        if !directory.empty?
          full_path = "#{full_path}/#{directory}"
        end
        env.delete_local_ref(dir)
        env.delete_local_ref(path)

        file_class = env.find_class("java/io/File")
        file_constructor = env.get_method_id(file_class, "<init>", "(Ljava/lang/String;)V")
        file = env.new_object(file_class, file_constructor, env.new_string_utf(full_path))

        list_method = env.get_method_id(file_class, "list", "()[Ljava/lang/String;")
        array = env.call_object_method(file, list_method)

        if array
          length = env.get_array_length(array.as(Void*))
          length.times do |i|
            jfile = env.get_object_array_element(array, i)
            filename = env.get_string_utf_chars(jfile, nil).to_s
            files << filename
            env.delete_local_ref(jfile)
          end
          env.delete_local_ref(array)
        end

        env.delete_local_ref(file)

        files
      {% elsif flag?(:native_ios) %}
        ptr_array = LibIOS.file_list(directory.to_utf8, @type.value)
        files = [] of String
        if ptr_array
          i = 0
          while true
            ptr = ptr_array[i]
            break if ptr.null?
            files << String.new(ptr)
            i += 1
          end
          LibIOS.free_string_array(ptr_array)
        end
        files
      {% else %}
        [] of String
      {% end %}
    end
  end
end
