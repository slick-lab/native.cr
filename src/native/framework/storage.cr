module Native::Storage
  class Preferences
    def initialize(@name : String = "default")
    end

    def set(key : String, value : String) : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        jkey = env.NewStringUTF(key)
        jvalue = env.NewStringUTF(value)

        get_prefs = env.GetMethodID(env.GetObjectClass(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.CallObjectMethod(activity, get_prefs, env.NewStringUTF(@name), 0)

        edit = env.GetMethodID(env.GetObjectClass(prefs), "edit", "()Landroid/content/SharedPreferences$Editor;")
        editor = env.CallObjectMethod(prefs, edit)

        put_string = env.GetMethodID(env.GetObjectClass(editor), "putString", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;")
        env.CallObjectMethod(editor, put_string, jkey, jvalue)

        apply = env.GetMethodID(env.GetObjectClass(editor), "apply", "()V")
        env.CallVoidMethod(editor, apply)

        env.DeleteLocalRef(jkey)
        env.DeleteLocalRef(jvalue)
        env.DeleteLocalRef(prefs)
        env.DeleteLocalRef(editor)
      elsif Native::Platform.ios?
        LibIOS.user_defaults_set(key.to_utf8, value.to_utf8)
      end
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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return default unless env && activity

        jkey = env.NewStringUTF(key)
        jdefault = env.NewStringUTF(default)

        get_prefs = env.GetMethodID(env.GetObjectClass(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.CallObjectMethod(activity, get_prefs, env.NewStringUTF(@name), 0)

        get_string = env.GetMethodID(env.GetObjectClass(prefs), "getString", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;")
        result = env.CallObjectMethod(prefs, get_string, jkey, jdefault)

        value = if result
                  env.GetStringUTFChars(result, nil).to_s
                else
                  default
                end

        env.DeleteLocalRef(jkey)
        env.DeleteLocalRef(jdefault)
        env.DeleteLocalRef(prefs)
        env.DeleteLocalRef(result) if result

        value
      elsif Native::Platform.ios?
        ptr = LibIOS.user_defaults_get(key.to_utf8)
        if ptr
          result = String.new(ptr)
          LibIOS.free_string(ptr)
          result
        else
          default
        end
      else
        default
      end
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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        jkey = env.NewStringUTF(key)

        get_prefs = env.GetMethodID(env.GetObjectClass(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.CallObjectMethod(activity, get_prefs, env.NewStringUTF(@name), 0)

        contains = env.GetMethodID(env.GetObjectClass(prefs), "contains", "(Ljava/lang/String;)Z")
        result = env.CallBooleanMethod(prefs, contains, jkey)

        env.DeleteLocalRef(jkey)
        env.DeleteLocalRef(prefs)

        result
      elsif Native::Platform.ios?
        LibIOS.user_defaults_contains(key.to_utf8)
      else
        false
      end
    end

    def delete(key : String) : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        jkey = env.NewStringUTF(key)

        get_prefs = env.GetMethodID(env.GetObjectClass(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.CallObjectMethod(activity, get_prefs, env.NewStringUTF(@name), 0)

        edit = env.GetMethodID(env.GetObjectClass(prefs), "edit", "()Landroid/content/SharedPreferences$Editor;")
        editor = env.CallObjectMethod(prefs, edit)

        remove = env.GetMethodID(env.GetObjectClass(editor), "remove", "(Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;")
        env.CallObjectMethod(editor, remove, jkey)

        apply = env.GetMethodID(env.GetObjectClass(editor), "apply", "()V")
        env.CallVoidMethod(editor, apply)

        env.DeleteLocalRef(jkey)
        env.DeleteLocalRef(prefs)
        env.DeleteLocalRef(editor)
      elsif Native::Platform.ios?
        LibIOS.user_defaults_delete(key.to_utf8)
      end
    end

    def clear : Nil
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return unless env && activity

        get_prefs = env.GetMethodID(env.GetObjectClass(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.CallObjectMethod(activity, get_prefs, env.NewStringUTF(@name), 0)

        edit = env.GetMethodID(env.GetObjectClass(prefs), "edit", "()Landroid/content/SharedPreferences$Editor;")
        editor = env.CallObjectMethod(prefs, edit)

        clr = env.GetMethodID(env.GetObjectClass(editor), "clear", "()Landroid/content/SharedPreferences$Editor;")
        env.CallObjectMethod(editor, clr)

        apply = env.GetMethodID(env.GetObjectClass(editor), "apply", "()V")
        env.CallVoidMethod(editor, apply)

        env.DeleteLocalRef(prefs)
        env.DeleteLocalRef(editor)
      elsif Native::Platform.ios?
        LibIOS.user_defaults_clear
      end
    end

    def all_keys : Array(String)
      if Native::Platform.android?
        keys = [] of String
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return keys unless env && activity

        get_prefs = env.GetMethodID(env.GetObjectClass(activity), "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;")
        prefs = env.CallObjectMethod(activity, get_prefs, env.NewStringUTF(@name), 0)

        get_all = env.GetMethodID(env.GetObjectClass(prefs), "getAll", "()Ljava/util/Map;")
        map = env.CallObjectMethod(prefs, get_all)

        key_set = env.CallObjectMethod(map, env.GetMethodID(env.GetObjectClass(map), "keySet", "()Ljava/util/Set;"))
        iterator = env.CallObjectMethod(key_set, env.GetMethodID(env.GetObjectClass(key_set), "iterator", "()Ljava/util/Iterator;"))

        while env.CallBooleanMethod(iterator, env.GetMethodID(env.GetObjectClass(iterator), "hasNext", "()Z"))
          jkey = env.CallObjectMethod(iterator, env.GetMethodID(env.GetObjectClass(iterator), "next", "()Ljava/lang/Object;"))
          keys << env.GetStringUTFChars(jkey, nil).to_s
          env.DeleteLocalRef(jkey)
        end

        env.DeleteLocalRef(prefs)
        env.DeleteLocalRef(map)
        env.DeleteLocalRef(key_set)
        env.DeleteLocalRef(iterator)

        keys
      elsif Native::Platform.ios?
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
      else
        [] of String
      end
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
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        method_name = case @type
                      when StorageType::Documents then "getFilesDir"
                      when StorageType::Cache then "getCacheDir"
                      when StorageType::Temporary then "getCacheDir"
                      end

        get_dir = env.GetMethodID(env.GetObjectClass(activity), method_name, "()Ljava/io/File;")
        dir = env.CallObjectMethod(activity, get_dir)

        get_path = env.GetMethodID(env.GetObjectClass(dir), "getPath", "()Ljava/lang/String;")
        path = env.CallObjectMethod(dir, get_path)

        full_path = "#{env.GetStringUTFChars(path, nil).to_s}/#{filename}"
        env.DeleteLocalRef(dir)
        env.DeleteLocalRef(path)

        file_class = env.FindClass("java/io/File")
        file_constructor = env.GetMethodID(file_class, "<init>", "(Ljava/lang/String;)V")
        file = env.NewObject(file_class, file_constructor, env.NewStringUTF(full_path))

        fos_class = env.FindClass("java/io/FileOutputStream")
        fos_constructor = env.GetMethodID(fos_class, "<init>", "(Ljava/io/File;)V")
        fos = env.NewObject(fos_class, fos_constructor, file)

        write_method = env.GetMethodID(fos_class, "write", "([B)V")
        byte_array = env.NewByteArray(data.size)
        env.SetByteArrayRegion(byte_array, 0, data.size, data)
        env.CallVoidMethod(fos, write_method, byte_array)

        close_method = env.GetMethodID(fos_class, "close", "()V")
        env.CallVoidMethod(fos, close_method)

        env.DeleteLocalRef(file)
        env.DeleteLocalRef(fos)
        env.DeleteLocalRef(byte_array)

        true
      elsif Native::Platform.ios?
        LibIOS.file_write(filename.to_utf8, data, data.size, @type.value)
      else
        false
      end
    end

    def write_text(filename : String, content : String) : Bool
      write(filename, content.to_slice)
    end

    def read(filename : String) : Bytes?
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return nil unless env && activity

        method_name = case @type
                      when StorageType::Documents then "getFilesDir"
                      when StorageType::Cache then "getCacheDir"
                      when StorageType::Temporary then "getCacheDir"
                      end

        get_dir = env.GetMethodID(env.GetObjectClass(activity), method_name, "()Ljava/io/File;")
        dir = env.CallObjectMethod(activity, get_dir)

        get_path = env.GetMethodID(env.GetObjectClass(dir), "getPath", "()Ljava/lang/String;")
        path = env.CallObjectMethod(dir, get_path)

        full_path = "#{env.GetStringUTFChars(path, nil).to_s}/#{filename}"
        env.DeleteLocalRef(dir)
        env.DeleteLocalRef(path)

        file_class = env.FindClass("java/io/File")
        file_constructor = env.GetMethodID(file_class, "<init>", "(Ljava/lang/String;)V")
        file = env.NewObject(file_class, file_constructor, env.NewStringUTF(full_path))

        fis_class = env.FindClass("java/io/FileInputStream")
        fis_constructor = env.GetMethodID(fis_class, "<init>", "(Ljava/io/File;)V")
        fis = env.NewObject(fis_class, fis_constructor, file)

        available = env.GetMethodID(fis_class, "available", "()I")
        size = env.CallIntMethod(fis, available)

        if size <= 0
          env.DeleteLocalRef(file)
          env.DeleteLocalRef(fis)
          return nil
        end

        byte_array = env.NewByteArray(size)
        read_method = env.GetMethodID(fis_class, "read", "([B)I")
        env.CallIntMethod(fis, read_method, byte_array)

        close_method = env.GetMethodID(fis_class, "close", "()V")
        env.CallVoidMethod(fis, close_method)

        data = Bytes.new(size)
        env.GetByteArrayRegion(byte_array, 0, size, data)

        env.DeleteLocalRef(file)
        env.DeleteLocalRef(fis)
        env.DeleteLocalRef(byte_array)

        data
      elsif Native::Platform.ios?
        size_ptr = Pointer(Int32).malloc(1)
        data_ptr = LibIOS.file_read(filename.to_utf8, size_ptr, @type.value)
        if data_ptr && size_ptr.value > 0
          data = Bytes.new(size_ptr.value) { |i| data_ptr[i] }
          LibIOS.free(data_ptr)
          data
        else
          nil
        end
      else
        nil
      end
    end

    def read_text(filename : String) : String?
      data = read(filename)
      data ? String.new(data) : nil
    end

    def exists?(filename : String) : Bool
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        method_name = case @type
                      when StorageType::Documents then "getFilesDir"
                      when StorageType::Cache then "getCacheDir"
                      when StorageType::Temporary then "getCacheDir"
                      end

        get_dir = env.GetMethodID(env.GetObjectClass(activity), method_name, "()Ljava/io/File;")
        dir = env.CallObjectMethod(activity, get_dir)

        get_path = env.GetMethodID(env.GetObjectClass(dir), "getPath", "()Ljava/lang/String;")
        path = env.CallObjectMethod(dir, get_path)

        full_path = "#{env.GetStringUTFChars(path, nil).to_s}/#{filename}"
        env.DeleteLocalRef(dir)
        env.DeleteLocalRef(path)

        file_class = env.FindClass("java/io/File")
        file_constructor = env.GetMethodID(file_class, "<init>", "(Ljava/lang/String;)V")
        file = env.NewObject(file_class, file_constructor, env.NewStringUTF(full_path))

        exists_method = env.GetMethodID(file_class, "exists", "()Z")
        result = env.CallBooleanMethod(file, exists_method)

        env.DeleteLocalRef(file)

        result
      elsif Native::Platform.ios?
        LibIOS.file_exists(filename.to_utf8, @type.value)
      else
        false
      end
    end

    def delete(filename : String) : Bool
      if Native::Platform.android?
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        method_name = case @type
                      when StorageType::Documents then "getFilesDir"
                      when StorageType::Cache then "getCacheDir"
                      when StorageType::Temporary then "getCacheDir"
                      end

        get_dir = env.GetMethodID(env.GetObjectClass(activity), method_name, "()Ljava/io/File;")
        dir = env.CallObjectMethod(activity, get_dir)

        get_path = env.GetMethodID(env.GetObjectClass(dir), "getPath", "()Ljava/lang/String;")
        path = env.CallObjectMethod(dir, get_path)

        full_path = "#{env.GetStringUTFChars(path, nil).to_s}/#{filename}"
        env.DeleteLocalRef(dir)
        env.DeleteLocalRef(path)

        file_class = env.FindClass("java/io/File")
        file_constructor = env.GetMethodID(file_class, "<init>", "(Ljava/lang/String;)V")
        file = env.NewObject(file_class, file_constructor, env.NewStringUTF(full_path))

        delete_method = env.GetMethodID(file_class, "delete", "()Z")
        result = env.CallBooleanMethod(file, delete_method)

        env.DeleteLocalRef(file)

        result
      elsif Native::Platform.ios?
        LibIOS.file_delete(filename.to_utf8, @type.value)
      else
        false
      end
    end

    def list(directory : String = "") : Array(String)
      if Native::Platform.android?
        files = [] of String
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return files unless env && activity

        method_name = case @type
                      when StorageType::Documents then "getFilesDir"
                      when StorageType::Cache then "getCacheDir"
                      when StorageType::Temporary then "getCacheDir"
                      end

        get_dir = env.GetMethodID(env.GetObjectClass(activity), method_name, "()Ljava/io/File;")
        dir = env.CallObjectMethod(activity, get_dir)

        get_path = env.GetMethodID(env.GetObjectClass(dir), "getPath", "()Ljava/lang/String;")
        path = env.CallObjectMethod(dir, get_path)

        full_path = env.GetStringUTFChars(path, nil).to_s
        if !directory.empty?
          full_path = "#{full_path}/#{directory}"
        end
        env.DeleteLocalRef(dir)
        env.DeleteLocalRef(path)

        file_class = env.FindClass("java/io/File")
        file_constructor = env.GetMethodID(file_class, "<init>", "(Ljava/lang/String;)V")
        file = env.NewObject(file_class, file_constructor, env.NewStringUTF(full_path))

        list_method = env.GetMethodID(file_class, "list", "()[Ljava/lang/String;")
        array = env.CallObjectMethod(file, list_method)

        if array
          length = env.GetArrayLength(array.as(Void*))
          length.times do |i|
            jfile = env.GetObjectArrayElement(array, i)
            filename = env.GetStringUTFChars(jfile, nil).to_s
            files << filename
            env.DeleteLocalRef(jfile)
          end
          env.DeleteLocalRef(array)
        end

        env.DeleteLocalRef(file)

        files
      elsif Native::Platform.ios?
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
      else
        [] of String
      end
    end
  end
end
