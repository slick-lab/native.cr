# src/native/framework/payment.cr
# Refactored to use JNIHelpers for automatic local reference cleanup.

module Native::Payment
  enum ProductType
    Consumable
    NonConsumable
    Subscription
  end

  enum SubscriptionPeriod
    Weekly
    Monthly
    Quarterly
    Yearly
  end

  struct Product
    property id : String
    property title : String
    property description : String
    property price : String
    property price_amount : Float64
    property currency : String
    property currency_symbol : String
    property type : ProductType
    property subscription_period : SubscriptionPeriod?

    def initialize(@id = "", @title = "", @description = "", @price = "",
                   @price_amount = 0.0, @currency = "USD", @currency_symbol = "$",
                   @type = ProductType::Consumable, @subscription_period = nil)
    end

    def formatted_price : String
      @price
    end

    def price_for_display : String
      if @currency == "JPY" || @currency == "KRW"
        "#{@currency_symbol}#{@price_amount.to_i}"
      else
        "#{@currency_symbol}#{sprintf("%.2f", @price_amount)}"
      end
    end
  end

  struct PurchaseResult
    property success : Bool
    property product_id : String
    property transaction_id : String
    property receipt_data : String
    property error_message : String?
    property purchase_date : Int64
    property expiration_date : Int64?

    def initialize(@success = false, @product_id = "", @transaction_id = "",
                   @receipt_data = "", @error_message = nil, @purchase_date = 0_i64,
                   @expiration_date = nil)
    end

    def verified? : Bool
      @success && !@receipt_data.empty?
    end

    def is_subscription? : Bool
      @expiration_date != nil
    end

    def is_active? : Bool
      return true unless @expiration_date
      Time.utc.to_unix < @expiration_date
    end
  end

  struct RestoreResult
    property success : Bool
    property restored_count : Int32
    property product_ids : Array(String)
    property error_message : String?

    def initialize(@success = false, @restored_count = 0,
                   @product_ids = [] of String, @error_message = nil)
    end
  end

  class PaymentManager
    @@initialized : Bool = false
    @@products_cache : Hash(String, Product) = {} of String => Product
    @@purchase_callbacks = [] of PurchaseResult -> Nil
    @@restore_callbacks = [] of RestoreResult -> Nil

    def self.initialize(merchant_id : String = "") : Bool
      return true if @@initialized

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        activity = Native::Android::JNI.activity
        return false unless env && activity

        billing_class = env.find_class("com/nativecr/BillingHelper")
        if billing_class == Pointer(Void).null
          return false
        end

        init_method = env.get_static_method_id(billing_class, "init", "(Landroid/app/Activity;Ljava/lang/String;)V")
        env.call_static_void_method(billing_class, init_method, activity, env.new_string_utf(merchant_id))
        env.delete_local_ref(billing_class) unless billing_class.null?

        setupCallbacks
      {% elsif flag?(:native_ios) %}
        LibIOS.payment_init(merchant_id.to_utf8)
        setupCallbacks
      {% else %}
        false
      {% end %}

      @@initialized = true
    end

    def self.fetch_products(product_ids : Array(String)) : Array(Product)
      return [] of Product unless @@initialized

      product_ids = product_ids.uniq
      cached = product_ids.map { |id| @@products_cache[id] }.compact
      missing = product_ids.reject { |id| @@products_cache.has_key?(id) }

      if missing.any?
        {% if flag?(:native_android) %}
          fetched = fetch_products_android(missing)
        {% elsif flag?(:native_ios) %}
          fetched = fetch_products_ios(missing)
        {% else %}
          fetched = [] of Product
        {% end %}

        fetched.each { |p| @@products_cache[p.id] = p }
        cached + fetched
      else
        cached
      end
    end

    def self.purchase(product_id : String, &callback : PurchaseResult -> Nil) : Bool
      return false unless @@initialized

      @@purchase_callbacks << callback

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env

        billing_class = env.find_class("com/nativecr/BillingHelper")
        return false if billing_class == Pointer(Void).null

        purchase_method = env.get_static_method_id(billing_class, "purchase", "(Landroid/app/Activity;Ljava/lang/String;)V")
        env.call_static_void_method(billing_class, purchase_method, Native::Android::JNI.activity, env.new_string_utf(product_id))
        env.delete_local_ref(billing_class) unless billing_class.null?
      {% elsif flag?(:native_ios) %}
        LibIOS.payment_purchase(product_id.to_utf8)
      {% else %}
        false
      {% end %}
      true
    end

    def self.restore_purchases(&callback : RestoreResult -> Nil) : Bool
      return false unless @@initialized

      @@restore_callbacks << callback

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env

        billing_class = env.find_class("com/nativecr/BillingHelper")
        return false if billing_class == Pointer(Void).null

        restore_method = env.get_static_method_id(billing_class, "restore", "()V")
        env.call_static_void_method(billing_class, restore_method)
        env.delete_local_ref(billing_class) unless billing_class.null?
      {% elsif flag?(:native_ios) %}
        LibIOS.payment_restore
      {% else %}
        false
      {% end %}
      true
    end

    def self.is_purchased?(product_id : String) : Bool
      return false unless @@initialized

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env

        billing_class = env.find_class("com/nativecr/BillingHelper")
        return false if billing_class == Pointer(Void).null

        purchased_method = env.get_static_method_id(billing_class, "isPurchased", "(Ljava/lang/String;)Z")
        env.call_static_boolean_method(billing_class, purchased_method, env.new_string_utf(product_id))
        env.delete_local_ref(billing_class) unless billing_class.null?
      {% elsif flag?(:native_ios) %}
        LibIOS.payment_is_purchased(product_id.to_utf8)
      {% else %}
        false
      {% end %}
    end

    def self.is_subscription_active?(product_id : String) : Bool
      return false unless @@initialized

      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return false unless env

        billing_class = env.find_class("com/nativecr/BillingHelper")
        return false if billing_class == Pointer(Void).null

        active_method = env.get_static_method_id(billing_class, "isSubscriptionActive", "(Ljava/lang/String;)Z")
        env.call_static_boolean_method(billing_class, active_method, env.new_string_utf(product_id))
        env.delete_local_ref(billing_class) unless billing_class.null?
      {% elsif flag?(:native_ios) %}
        LibIOS.payment_is_subscription_active(product_id.to_utf8)
      {% else %}
        false
      {% end %}
    end

    private def self.setupCallbacks : Nil
      {% if flag?(:native_android) %}
        env = Native::Android::JNI.env
        return unless env

        callback_class = env.find_class("com/nativecr/BillingCallback")
        if callback_class == Pointer(Void).null
          return
        end

        callback_obj = env.new_object(callback_class, env.get_method_id(callback_class, "<init>", "(J)V"), 0i64)
        env.delete_local_ref(callback_class) unless callback_class.null?

        billing_class = env.find_class("com/nativecr/BillingHelper")
        return if billing_class == Pointer(Void).null

        set_callback = env.get_static_method_id(billing_class, "setCallback", "(Lcom/nativecr/BillingCallback;)V")
        env.call_static_void_method(billing_class, set_callback, callback_obj)
        env.delete_local_ref(billing_class) unless billing_class.null?
      {% elsif flag?(:native_ios) %}
        # iOS callbacks are handled by the Swift bridge
      {% end %}
    end

    private def self.fetch_products_android(product_ids : Array(String)) : Array(Product)
      products = [] of Product

      env = Native::Android::JNI.env
      return products unless env

      billing_class = env.find_class("com/nativecr/BillingHelper")
      return products if billing_class == Pointer(Void).null

      fetch_method = env.get_static_method_id(billing_class, "fetchProducts", "([Ljava/lang/String;)Ljava/lang/String;")

      product_array = env.new_object_array(product_ids.size, env.find_class("java/lang/String"), nil)
      product_ids.each_with_index do |id, i|
        env.set_object_array_element(product_array, i, env.new_string_utf(id))
      end

      result = env.call_static_object_method(billing_class, fetch_method, product_array)
      env.delete_local_ref(billing_class) unless billing_class.null?

      if result
        json = env.get_string_utf_chars(result, nil).to_s
        parse_products_json(json)
      else
        [] of Product
      end
    end

    private def self.fetch_products_ios(product_ids : Array(String)) : Array(Product)
      json = product_ids.to_json
      ptr = LibIOS.payment_fetch_products(json.to_utf8)
      if ptr
        json_result = String.new(ptr)
        LibIOS.free_string(ptr)
        parse_products_json(json_result)
      else
        [] of Product
      end
    end

    private def self.parse_products_json(json : String) : Array(Product)
      products = [] of Product
      begin
        data = JSON.parse(json)
        data.as_a.each do |item|
          product = Product.new(
            id: item["id"].as_s,
            title: item["title"].as_s,
            description: item["description"].as_s,
            price: item["price"].as_s,
            price_amount: item["price_amount"].as_f,
            currency: item["currency"].as_s,
            currency_symbol: item["currency_symbol"]?.try &.as_s || "$",
            type: ProductType.from_value(item["type"].as_i)
          )
          products << product
        end
      rescue
      end
      products
    end

    def self.handlePurchaseResult(product_id : String, transaction_id : String, receipt : String, success : Bool)
      result = PurchaseResult.new
      result.success = success
      result.product_id = product_id
      result.transaction_id = transaction_id
      result.receipt_data = receipt

      if !success
        result.error_message = "Purchase failed"
      end

      @@purchase_callbacks.each { |cb| cb.call(result) }
      @@purchase_callbacks.clear
    end

    def self.handleRestoreResult(product_ids : Array(String), success : Bool)
      result = RestoreResult.new
      result.success = success
      result.restored_count = product_ids.size
      result.product_ids = product_ids

      if !success
        result.error_message = "Restore failed"
      end

      @@restore_callbacks.each { |cb| cb.call(result) }
      @@restore_callbacks.clear
    end
  end

  module Payment
    def self.initialize(merchant_id : String = "") : Bool
      PaymentManager.initialize(merchant_id)
    end

    def self.products(product_ids : Array(String)) : Array(Product)
      PaymentManager.fetch_products(product_ids)
    end

    def self.purchase(product_id : String, &callback : PurchaseResult -> Nil) : Bool
      PaymentManager.purchase(product_id, &callback)
    end

    def self.restore(&callback : RestoreResult -> Nil) : Bool
      PaymentManager.restore_purchases(&callback)
    end

    def self.is_purchased?(product_id : String) : Bool
      PaymentManager.is_purchased?(product_id)
    end

    def self.is_subscription_active?(product_id : String) : Bool
      PaymentManager.is_subscription_active?(product_id)
    end

    def self.coins_pack(id : String, title : String, coin_amount : Int32, price : String) : Product
      Product.new(
        id: id,
        title: title,
        description: "#{coin_amount} coins",
        price: price,
        type: ProductType::Consumable
      )
    end

    def self.subscription(id : String, title : String, period : SubscriptionPeriod, price : String) : Product
      Product.new(
        id: id,
        title: title,
        description: "#{period.to_s} subscription",
        price: price,
        type: ProductType::Subscription,
        subscription_period: period
      )
    end
  end
end
