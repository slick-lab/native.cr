# src/native/framework/payment.cr

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

        billing_class = env.FindClass("com/nativecr/BillingHelper")
        if billing_class == Pointer(Void).null
          return false
        end

        init_method = env.GetStaticMethodID(billing_class, "init", "(Landroid/app/Activity;Ljava/lang/String;)V")
        env.CallStaticVoidMethod(billing_class, init_method, activity, env.NewStringUTF(merchant_id))

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

        billing_class = env.FindClass("com/nativecr/BillingHelper")
        return false if billing_class == Pointer(Void).null

        purchase_method = env.GetStaticMethodID(billing_class, "purchase", "(Landroid/app/Activity;Ljava/lang/String;)V")
        env.CallStaticVoidMethod(billing_class, purchase_method, Native::Android::JNI.activity, env.NewStringUTF(product_id))
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

        billing_class = env.FindClass("com/nativecr/BillingHelper")
        return false if billing_class == Pointer(Void).null

        restore_method = env.GetStaticMethodID(billing_class, "restore", "()V")
        env.CallStaticVoidMethod(billing_class, restore_method)
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

        billing_class = env.FindClass("com/nativecr/BillingHelper")
        return false if billing_class == Pointer(Void).null

        purchased_method = env.GetStaticMethodID(billing_class, "isPurchased", "(Ljava/lang/String;)Z")
        env.CallStaticBooleanMethod(billing_class, purchased_method, env.NewStringUTF(product_id))
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

        billing_class = env.FindClass("com/nativecr/BillingHelper")
        return false if billing_class == Pointer(Void).null

        active_method = env.GetStaticMethodID(billing_class, "isSubscriptionActive", "(Ljava/lang/String;)Z")
        env.CallStaticBooleanMethod(billing_class, active_method, env.NewStringUTF(product_id))
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

        callback_class = env.FindClass("com/nativecr/BillingCallback")
        if callback_class == Pointer(Void).null
          return
        end

        callback_obj = env.NewObject(callback_class, env.GetMethodID(callback_class, "<init>", "(J)V"), Pointer(Void).address.to_i64)

        billing_class = env.FindClass("com/nativecr/BillingHelper")
        return if billing_class == Pointer(Void).null

        set_callback = env.GetStaticMethodID(billing_class, "setCallback", "(Lcom/nativecr/BillingCallback;)V")
        env.CallStaticVoidMethod(billing_class, set_callback, callback_obj)
      {% elsif flag?(:native_ios) %}
        # iOS callbacks are handled by the Swift bridge
      {% end %}
    end

    private def self.fetch_products_android(product_ids : Array(String)) : Array(Product)
      products = [] of Product

      env = Native::Android::JNI.env
      return products unless env

      billing_class = env.FindClass("com/nativecr/BillingHelper")
      return products if billing_class == Pointer(Void).null

      fetch_method = env.GetStaticMethodID(billing_class, "fetchProducts", "([Ljava/lang/String;)Ljava/lang/String;")

      product_array = env.NewObjectArray(product_ids.size, env.FindClass("java/lang/String"), nil)
      product_ids.each_with_index do |id, i|
        env.SetObjectArrayElement(product_array, i, env.NewStringUTF(id))
      end

      result = env.CallStaticObjectMethod(billing_class, fetch_method, product_array)

      if result
        json = env.GetStringUTFChars(result, nil).to_s
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
