# src/native/framework/storage.cr

module Native
  module Storage
    enum StorageType
      UserDefaults   # iOS UserDefaults / Android SharedPreferences
      Cache          # Temporary cache that can be cleared
      Documents      # User documents that persist
      Temporary      # Temp files deleted on app restart
    end

    struct StorageEntry
      property key : String
      property value : String
      property type : StorageType
      property created_at : Int64
      property updated_at : Int64

      def initialize(@key : String, @value : String, @type : StorageType = StorageType::UserDefaults,
                     @created_at : Int64 = Time.utc.to_unix, @updated_at : Int64 = Time.utc.to_unix)
      end
    end

    class Preferences
      @storage_type : StorageType
      
      def initialize(type : StorageType = StorageType::UserDefaults)
        @storage_type = type
      end

      def set(key : String, value : String) : Nil
        save_to_platform(key, value)
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
        value = get_from_platform(key)
        value.is_a?(String) ? value : default
      end

      def get_int(key : String, default : Int32 = 0) : Int32
        value = get_from_platform(key)
        value.to_i? || default
      end

      def get_float(key : String, default : Float64 = 0.0) : Float64
        value = get_from_platform(key)
        value.to_f64? || default
      end

      def get_bool(key : String, default : Bool = false) : Bool
        value = get_from_platform(key)
        value == "true" ? true : (value == "false" ? false : default)
      end

      def contains?(key : String) : Bool
        {% if flag?(:android) %}
          LibAndroid.preferences_contains(key.to_utf8, type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          LibIOS.preferences_contains(key.to_utf8, type_to_int(@storage_type))
        {% else %}
          false
        {% end %}
      end

      def delete(key : String) : Nil
        {% if flag?(:android) %}
          LibAndroid.preferences_remove(key.to_utf8, type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          LibIOS.preferences_remove(key.to_utf8, type_to_int(@storage_type))
        {% end %}
      end

      def clear : Nil
        {% if flag?(:android) %}
          LibAndroid.preferences_clear(type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          LibIOS.preferences_clear(type_to_int(@storage_type))
        {% end %}
      end

      def all_keys : Array(String)
        {% if flag?(:android) %}
          keys_ptr = LibAndroid.preferences_get_all_keys(type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          keys_ptr = LibIOS.preferences_get_all_keys(type_to_int(@storage_type))
        {% else %}
          return [] of String
        {% end %}
        
        keys = [] of String
        if keys_ptr
          i = 0
          while true
            ptr = keys_ptr[i]
            break if ptr.null?
            keys << String.new(ptr)
            i += 1
          end
          LibAndroid.free_string_array(keys_ptr)
        end
        keys
      end

      private def save_to_platform(key : String, value : String) : Nil
        {% if flag?(:android) %}
          LibAndroid.preferences_set(key.to_utf8, value.to_utf8, type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          LibIOS.preferences_set(key.to_utf8, value.to_utf8, type_to_int(@storage_type))
        {% end %}
      end

      private def get_from_platform(key : String) : String
        {% if flag?(:android) %}
          ptr = LibAndroid.preferences_get(key.to_utf8, type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          ptr = LibIOS.preferences_get(key.to_utf8, type_to_int(@storage_type))
        {% else %}
          return ""
        {% end %}
        
        if ptr
          value = String.new(ptr)
          LibAndroid.free_string(ptr)
          value
        else
          ""
        end
      end

      private def type_to_int(type : StorageType) : Int32
        case type
        when StorageType::UserDefaults then 0
        when StorageType::Cache then 1
        when StorageType::Documents then 2
        when StorageType::Temporary then 3
        else 0
        end
      end
    end

    class FileStorage
      @storage_type : StorageType
      
      def initialize(type : StorageType = StorageType::Documents)
        @storage_type = type
      end

      def write(filename : String, data : Bytes) : Bool
        {% if flag?(:android) %}
          LibAndroid.file_write(filename.to_utf8, data, data.size, type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          LibIOS.file_write(filename.to_utf8, data, data.size, type_to_int(@storage_type))
        {% else %}
          false
        {% end %}
      end

      def write_text(filename : String, content : String) : Bool
        write(filename, content.to_slice)
      end

      def read(filename : String) : Bytes?
        {% if flag?(:android) %}
          size_ptr = Pointer(Int32).malloc(1)
          data_ptr = LibAndroid.file_read(filename.to_utf8, size_ptr, type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          size_ptr = Pointer(Int32).malloc(1)
          data_ptr = LibIOS.file_read(filename.to_utf8, size_ptr, type_to_int(@storage_type))
        {% else %}
          return nil
        {% end %}
        
        if data_ptr && size_ptr.value > 0
          data = Bytes.new(size_ptr.value) { |i| data_ptr[i] }
          LibAndroid.free(data_ptr)
          data
        else
          nil
        end
      end

      def read_text(filename : String) : String?
        data = read(filename)
        data ? String.new(data) : nil
      end

      def exists?(filename : String) : Bool
        {% if flag?(:android) %}
          LibAndroid.file_exists(filename.to_utf8, type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          LibIOS.file_exists(filename.to_utf8, type_to_int(@storage_type))
        {% else %}
          false
        {% end %}
      end

      def delete(filename : String) : Bool
        {% if flag?(:android) %}
          LibAndroid.file_delete(filename.to_utf8, type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          LibIOS.file_delete(filename.to_utf8, type_to_int(@storage_type))
        {% else %}
          false
        {% end %}
      end

      def list(directory : String = "") : Array(String)
        {% if flag?(:android) %}
          files_ptr = LibAndroid.file_list(directory.to_utf8, type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          files_ptr = LibIOS.file_list(directory.to_utf8, type_to_int(@storage_type))
        {% else %}
          return [] of String
        {% end %}
        
        files = [] of String
        if files_ptr
          i = 0
          while true
            ptr = files_ptr[i]
            break if ptr.null?
            files << String.new(ptr)
            i += 1
          end
          LibAndroid.free_string_array(files_ptr)
        end
        files
      end

      def size(filename : String) : Int64
        {% if flag?(:android) %}
          LibAndroid.file_size(filename.to_utf8, type_to_int(@storage_type))
        {% elsif flag?(:ios) %}
          LibIOS.file_size(filename.to_utf8, type_to_int(@storage_type))
        {% else %}
          0
        {% end %}
      end

      private def type_to_int(type : StorageType) : Int32
        case type
        when StorageType::UserDefaults then 0
        when StorageType::Cache then 1
        when StorageType::Documents then 2
        when StorageType::Temporary then 3
        end
      end
    end

    class Database
      @db_ptr : Void*? = nil
      @is_open : Bool = false

      def initialize(@name : String = "app.db")
      end

      def open : Bool
        return true if @is_open
        
        {% if flag?(:android) %}
          @db_ptr = LibAndroid.db_open(@name.to_utf8)
        {% elsif flag?(:ios) %}
          @db_ptr = LibIOS.db_open(@name.to_utf8)
        {% else %}
          return false
        {% end %}
        
        @is_open = @db_ptr ? true : false
        @is_open
      end

      def close : Nil
        return unless @is_open && @db_ptr
        
        {% if flag?(:android) %}
          LibAndroid.db_close(@db_ptr)
        {% elsif flag?(:ios) %}
          LibIOS.db_close(@db_ptr)
        {% end %}
        
        @is_open = false
        @db_ptr = nil
      end

      def execute(sql : String, params : Array(String) = [] of String) : Bool
        return false unless @is_open && @db_ptr
        
        param_ptrs = params.map(&.to_utf8)
        
        {% if flag?(:android) %}
          LibAndroid.db_execute(@db_ptr, sql.to_utf8, param_ptrs, param_ptrs.size)
        {% elsif flag?(:ios) %}
          LibIOS.db_execute(@db_ptr, sql.to_utf8, param_ptrs, param_ptrs.size)
        {% else %}
          false
        {% end %}
      end

      def query(sql : String, params : Array(String) = [] of String) : Array(Hash(String, String))
        results = [] of Hash(String, String)
        
        return results unless @is_open && @db_ptr
        
        param_ptrs = params.map(&.to_utf8)
        
        {% if flag?(:android) %}
          rows_ptr = LibAndroid.db_query(@db_ptr, sql.to_utf8, param_ptrs, param_ptrs.size)
        {% elsif flag?(:ios) %}
          rows_ptr = LibIOS.db_query(@db_ptr, sql.to_utf8, param_ptrs, param_ptrs.size)
        {% else %}
          return results
        {% end %}
        
        if rows_ptr
          i = 0
          while true
            row_ptr = rows_ptr[i]
            break if row_ptr.null?
            
            row = parse_row(row_ptr)
            results << row if row
            i += 1
          end
          LibAndroid.free_result_set(rows_ptr)
        end
        
        results
      end

      def insert(table : String, data : Hash(String, String)) : Int64
        columns = data.keys.join(", ")
        placeholders = Array.new(data.size, "?").join(", ")
        sql = "INSERT INTO #{table} (#{columns}) VALUES (#{placeholders})"
        
        values = data.values.to_a
        
        if execute(sql, values)
          {% if flag?(:android) %}
            LibAndroid.db_last_insert_rowid(@db_ptr)
          {% elsif flag?(:ios) %}
            LibIOS.db_last_insert_rowid(@db_ptr)
          {% else %}
            -1
          {% end %}
        else
          -1
        end
      end

      def update(table : String, data : Hash(String, String), where : String, where_params : Array(String) = [] of String) : Bool
        set_clause = data.keys.map { |k| "#{k} = ?" }.join(", ")
        sql = "UPDATE #{table} SET #{set_clause} WHERE #{where}"
        
        values = data.values.to_a + where_params
        execute(sql, values)
      end

      def delete(table : String, where : String, params : Array(String) = [] of String) : Bool
        sql = "DELETE FROM #{table} WHERE #{where}"
        execute(sql, params)
      end

      def create_table(name : String, columns : Array(String)) : Bool
        columns_def = columns.join(", ")
        sql = "CREATE TABLE IF NOT EXISTS #{name} (#{columns_def})"
        execute(sql)
      end

      def table_exists?(name : String) : Bool
        result = query("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [name])
        result.size > 0
      end

      private def parse_row(row_ptr : Void*) : Hash(String, String)?
        {% if flag?(:android) %}
          columns_ptr = LibAndroid.row_get_columns(row_ptr)
          values_ptr = LibAndroid.row_get_values(row_ptr)
          count = LibAndroid.row_get_count(row_ptr)
        {% elsif flag?(:ios) %}
          columns_ptr = LibIOS.row_get_columns(row_ptr)
          values_ptr = LibIOS.row_get_values(row_ptr)
          count = LibIOS.row_get_count(row_ptr)
        {% else %}
          return nil
        {% end %}
        
        if columns_ptr && values_ptr && count > 0
          row = {} of String => String
          count.times do |i|
            col = String.new(columns_ptr[i])
            val = String.new(values_ptr[i])
            row[col] = val
          end
          row
        else
          nil
        end
      end
    end

    module Storage
      def self.preferences(type : StorageType = StorageType::UserDefaults) : Preferences
        Preferences.new(type)
      end

      def self.files(type : StorageType = StorageType::Documents) : FileStorage
        FileStorage.new(type)
      end

      def self.database(name : String = "app.db") : Database
        db = Database.new(name)
        db.open
        db
      end

      def self.cache_dir : String
        {% if flag?(:android) %}
          String.new(LibAndroid.get_cache_dir)
        {% elsif flag?(:ios) %}
          String.new(LibIOS.get_cache_dir)
        {% else %}
          "./cache"
        {% end %}
      end

      def self.documents_dir : String
        {% if flag?(:android) %}
          String.new(LibAndroid.get_documents_dir)
        {% elsif flag?(:ios) %}
          String.new(LibIOS.get_documents_dir)
        {% else %}
          "./documents"
        {% end %}
      end

      def self.temp_dir : String
        {% if flag?(:android) %}
          String.new(LibAndroid.get_temp_dir)
        {% elsif flag?(:ios) %}
          String.new(LibIOS.get_temp_dir)
        {% else %}
          "./temp"
        {% end %}
      end
    end
  end
end
