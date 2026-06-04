# src/native/framework/payment.cr

module Native
  module Payment
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

      def localized_price : String
        "#{@currency_symbol}#{@price_amount}"
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
        
        {% if flag?(:android) }}
          result = LibPayment.android_initialize_billing
        {% elsif flag?(:ios) }}
          result = LibPayment.ios_initialize_payment(merchant_id.to_utf8)
        {% else }}
          result = false
        {% end }}
        
        if result
          @@initialized = true
          setup_callbacks
        end
        
        result
      end

      def self.fetch_products(product_ids : Array(String)) : Array(Product)
        return [] of Product unless @@initialized
        
        product_ids = product_ids.uniq
        cached = product_ids.map { |id| @@products_cache[id] }.compact
        missing = product_ids.reject { |id| @@products_cache.has_key?(id) }
        
        if missing.any?
          {% if flag?(:android) }}
            fetched = fetch_products_android(missing)
          {% elsif flag?(:ios) }}
            fetched = fetch_products_ios(missing)
          {% else }}
            fetched = [] of Product
          {% end }}
          
          fetched.each { |p| @@products_cache[p.id] = p }
          cached + fetched
        else
          cached
        end
      end

      def self.purchase(product_id : String, &callback : PurchaseResult -> Nil) : Bool
        return false unless @@initialized
        
        @@purchase_callbacks << callback
        
        {% if flag?(:android) }}
          LibPayment.android_purchase_product(product_id.to_utf8)
        {% elsif flag?(:ios) }}
          LibPayment.ios_purchase_product(product_id.to_utf8)
        {% else }}
          false
        {% end }}
      end

      def self.restore_purchases(&callback : RestoreResult -> Nil) : Bool
        return false unless @@initialized
        
        @@restore_callbacks << callback
        
        {% if flag?(:android) }}
          LibPayment.android_restore_purchases
        {% elsif flag?(:ios) }}
          LibPayment.ios_restore_purchases
        {% else }}
          false
        {% end }}
      end

      def self.is_purchased?(product_id : String) : Bool
        return false unless @@initialized
        
        {% if flag?(:android) }}
          LibPayment.android_is_purchased(product_id.to_utf8)
        {% elsif flag?(:ios) }}
          LibPayment.ios_is_purchased(product_id.to_utf8)
        {% else }}
          false
        {% end }}
      end

      def self.is_subscription_active?(product_id : String) : Bool
        return false unless @@initialized
        
        {% if flag?(:android) }}
          LibPayment.android_is_subscription_active(product_id.to_utf8)
        {% elsif flag?(:ios) }}
          LibPayment.ios_is_subscription_active(product_id.to_utf8)
        {% else }}
          false
        {% end }}
      end

      def self.get_subscription_expiry(product_id : String) : Int64?
        return nil unless @@initialized
        
        {% if flag?(:android) }}
          LibPayment.android_get_subscription_expiry(product_id.to_utf8)
        {% elsif flag?(:ios) }}
          LibPayment.ios_get_subscription_expiry(product_id.to_utf8)
        {% else }}
          nil
        {% end }}
      end

      private def self.setup_callbacks : Nil
        {% if flag?(:android) }}
          LibPayment.android_set_purchase_callback(
            ->(product_id_ptr : UInt8*, transaction_id_ptr : UInt8*, receipt_ptr : UInt8*, success : Bool) {
              handle_purchase_result(product_id_ptr, transaction_id_ptr, receipt_ptr, success)
            },
            ->(product_ids_ptr : UInt8**, count : Int32, success : Bool) {
              handle_restore_result(product_ids_ptr, count, success)
            }
          )
        {% elsif flag?(:ios) }}
          LibPayment.ios_set_purchase_callback(
            ->(product_id_ptr : UInt8*, transaction_id_ptr : UInt8*, receipt_ptr : UInt8*, success : Bool) {
              handle_purchase_result(product_id_ptr, transaction_id_ptr, receipt_ptr, success)
            },
            ->(product_ids_ptr : UInt8**, count : Int32, success : Bool) {
              handle_restore_result(product_ids_ptr, count, success)
            }
          )
        {% end }}
      end

      private def self.handle_purchase_result(product_id_ptr : UInt8*, transaction_id_ptr : UInt8*,
                                               receipt_ptr : UInt8*, success : Bool) : Nil
        result = PurchaseResult.new
        result.success = success
        result.product_id = String.new(product_id_ptr)
        result.transaction_id = String.new(transaction_id_ptr)
        result.receipt_data = String.new(receipt_ptr)
        
        if !success
          result.error_message = "Purchase failed"
        end
        
        @@purchase_callbacks.each { |cb| cb.call(result) }
        @@purchase_callbacks.clear
        
        LibPayment.free_string(product_id_ptr)
        LibPayment.free_string(transaction_id_ptr)
        LibPayment.free_string(receipt_ptr)
      end

      private def self.handle_restore_result(product_ids_ptr : UInt8**, count : Int32, success : Bool) : Nil
        product_ids = [] of String
        count.times do |i|
          product_ids << String.new(product_ids_ptr[i])
        end
        
        result = RestoreResult.new
        result.success = success
        result.restored_count = product_ids.size
        result.product_ids = product_ids
        
        if !success
          result.error_message = "Restore failed"
        end
        
        @@restore_callbacks.each { |cb| cb.call(result) }
        @@restore_callbacks.clear
        
        LibPayment.free_string_array(product_ids_ptr, count)
      end

      private def self.fetch_products_android(product_ids : Array(String)) : Array(Product)
        products = [] of Product
        
        product_ids.each do |pid|
          title = LibPayment.android_get_product_title(pid.to_utf8)
          description = LibPayment.android_get_product_description(pid.to_utf8)
          price = LibPayment.android_get_product_price(pid.to_utf8)
          price_amount = LibPayment.android_get_product_price_amount(pid.to_utf8)
          currency = LibPayment.android_get_product_currency(pid.to_utf8)
          currency_symbol = LibPayment.android_get_product_currency_symbol(pid.to_utf8)
          type_code = LibPayment.android_get_product_type(pid.to_utf8)
          
          product = Product.new(
            id: pid,
            title: String.new(title),
            description: String.new(description),
            price: String.new(price),
            price_amount: price_amount,
            currency: String.new(currency),
            currency_symbol: String.new(currency_symbol),
            type: ProductType.from_value(type_code)
          )
          
          products << product
          
          LibPayment.free_string(title)
          LibPayment.free_string(description)
          LibPayment.free_string(price)
          LibPayment.free_string(currency)
          LibPayment.free_string(currency_symbol)
        end
        
        products
      end

      private def self.fetch_products_ios(product_ids : Array(String)) : Array(Product)
        products = [] of Product
        
        product_ids.each do |pid|
          title = LibPayment.ios_get_product_title(pid.to_utf8)
          description = LibPayment.ios_get_product_description(pid.to_utf8)
          price = LibPayment.ios_get_product_price(pid.to_utf8)
          price_amount = LibPayment.ios_get_product_price_amount(pid.to_utf8)
          currency = LibPayment.ios_get_product_currency(pid.to_utf8)
          currency_symbol = LibPayment.ios_get_product_currency_symbol(pid.to_utf8)
          type_code = LibPayment.ios_get_product_type(pid.to_utf8)
          
          product = Product.new(
            id: pid,
            title: String.new(title),
            description: String.new(description),
            price: String.new(price),
            price_amount: price_amount,
            currency: String.new(currency),
            currency_symbol: String.new(currency_symbol),
            type: ProductType.from_value(type_code)
          )
          
          products << product
          
          LibPayment.free_string(title)
          LibPayment.free_string(description)
          LibPayment.free_string(price)
          LibPayment.free_string(currency)
          LibPayment.free_string(currency_symbol)
        end
        
        products
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

      def self.subscription_expiry(product_id : String) : Time?
        expiry = PaymentManager.get_subscription_expiry(product_id)
        expiry ? Time.unix(expiry) : nil
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
end
