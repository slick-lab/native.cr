# Payments (In-App Purchases)

native.cr provides a unified in-app purchase API through `Native::Payment`. On Android it uses Google Play Billing; on iOS it uses StoreKit. Your Crystal code is the same on both platforms.

---

## Product types

| Type | Description | Example use cases |
|---|---|---|
| `Consumable` | Can be bought repeatedly | Coins, lives, credits, boosts |
| `NonConsumable` | Bought once, kept forever | Remove ads, unlock a level pack |
| `Subscription` | Recurring billing | Weekly / monthly / yearly Pro plan |

---

## Setup

Call `Payment.initialize` once — ideally in your `setup` method — before doing anything else with payments:

```crystal
def setup
  Native::Payment::Payment.initialize    # no arguments needed for most apps
  # ...
end
```

If you use Apple Pay and need a merchant ID:

```crystal
Native::Payment::Payment.initialize(merchant_id: "merchant.com.myapp")
```

---

## Fetching product information

Product details (title, description, localised price) come from the App Store / Play Store. You must fetch them before displaying prices to the user.

```crystal
ids = ["com.myapp.coins_100", "com.myapp.remove_ads", "com.myapp.pro_monthly"]

products = Native::Payment::Payment.products(ids)   # => Array(Product)

products.each do |p|
  puts "#{p.title}"
  puts "  #{p.description}"
  puts "  #{p.price_for_display}"   # e.g. "$0.99" or "¥120"
  puts "  #{p.type}"                # Consumable / NonConsumable / Subscription
end
```

### The `Product` struct

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Your product identifier |
| `title` | `String` | Localised title from the store |
| `description` | `String` | Localised description |
| `price` | `String` | Raw price string from the store |
| `price_amount` | `Float64` | Numeric price |
| `currency` | `String` | ISO currency code, e.g. `"USD"` |
| `currency_symbol` | `String` | Symbol, e.g. `"$"` |
| `type` | `ProductType` | Consumable / NonConsumable / Subscription |
| `subscription_period` | `SubscriptionPeriod?` | Weekly / Monthly / Quarterly / Yearly |
| `price_for_display` | `String` | `"$0.99"` — formatted with symbol and 2 decimal places |
| `formatted_price` | `String` | Same as `price` (raw store string) |

---

## Making a purchase

```crystal
Native::Payment::Payment.purchase("com.myapp.coins_100") do |result|
  if result.success
    puts "Purchased! Transaction: #{result.transaction_id}"

    # Grant the purchase in your app
    add_coins(100)

    # Optionally verify the receipt on your server
    verify_on_server(result.receipt_data, result.product_id)
  else
    puts "Purchase failed: #{result.error_message}"
  end
end
```

### The `PurchaseResult` struct

| Field | Type | Description |
|---|---|---|
| `success` | `Bool` | Whether the purchase completed |
| `product_id` | `String` | Which product was purchased |
| `transaction_id` | `String` | Unique ID for this transaction |
| `receipt_data` | `String` | Receipt bytes (base64) for server-side verification |
| `error_message` | `String?` | Failure reason (when `success` is false) |
| `purchase_date` | `Int64` | Unix timestamp of purchase |
| `expiration_date` | `Int64?` | For subscriptions: when the period ends |
| `verified?` | `Bool` | `success && !receipt_data.empty?` |
| `is_subscription?` | `Bool` | `true` if `expiration_date` is set |
| `is_active?` | `Bool` | For subscriptions: `true` if not yet expired |

---

## Checking if a product is already purchased

Use this to gate features without making a network call:

```crystal
# Check a non-consumable
if Native::Payment::Payment.is_purchased?("com.myapp.remove_ads")
  hide_ads
end

# Check a subscription
if Native::Payment::Payment.is_subscription_active?("com.myapp.pro_monthly")
  enable_pro_features
else
  show_upgrade_screen
end
```

---

## Restoring purchases

Apple requires every app with non-consumable purchases or subscriptions to include a **Restore Purchases** button. When the user taps it, call:

```crystal
Native::Payment::Payment.restore do |result|
  if result.success
    puts "Restored #{result.restored_count} item(s)"
    result.product_ids.each do |id|
      apply_purchase(id)
    end
  else
    puts "Restore failed: #{result.error_message}"
  end
end
```

### The `RestoreResult` struct

| Field | Type | Description |
|---|---|---|
| `success` | `Bool` | Whether the restore call succeeded |
| `restored_count` | `Int32` | Number of items restored |
| `product_ids` | `Array(String)` | IDs of restored items |
| `error_message` | `String?` | Failure reason (when `success` is false) |

---

## Helper constructors

native.cr provides shortcut methods to build `Product` structs for common use cases:

```crystal
# A consumable coins pack
coins = Native::Payment::Payment.coins_pack(
  id:          "com.myapp.coins_500",
  title:       "500 Coins",
  coin_amount: 500,
  price:       "$4.99"
)

# A subscription product
pro = Native::Payment::Payment.subscription(
  id:     "com.myapp.pro_monthly",
  title:  "Pro Monthly",
  period: Native::Payment::SubscriptionPeriod::Monthly,
  price:  "$9.99"
)
```

Subscription periods: `Weekly`, `Monthly`, `Quarterly`, `Yearly`.

---

## Full example — in-app shop screen

```crystal
class ShopApp < Native::App
  COINS_ID = "com.myapp.coins_100"
  PRO_ID   = "com.myapp.pro_monthly"
  ADS_ID   = "com.myapp.remove_ads"

  def setup
    Native::Payment::Payment.initialize

    @status = Native::UI::TextView.new("Loading store…")
    @status.text_size = 16
    @status.center_horizontal

    @coins_btn = Native::UI::Button.new("100 Coins")
    @coins_btn.on_click { buy_coins }

    @pro_btn = Native::UI::Button.new("Go Pro")
    @pro_btn.on_click { buy_pro }

    @ads_btn = Native::UI::Button.new("Remove Ads")
    @ads_btn.on_click { buy_remove_ads }

    restore_btn = Native::UI::Button.new("Restore Purchases")
    restore_btn.on_click { restore_purchases }

    layout = Native::UI::LinearLayout.new
    layout.orientation = Native::UI::LinearLayout::Orientation::Vertical
    layout.gravity = Native::UI::LinearLayout::Gravity::Center
    layout.set_padding(24, 24, 24, 24)
    layout.addView(@status)
    layout.addView(@coins_btn)
    layout.addView(@pro_btn)
    layout.addView(@ads_btn)
    layout.addView(restore_btn)
    @root = layout

    # Check current state
    apply_current_entitlements

    # Fetch prices from the store
    load_prices
  end

  def load_prices
    spawn do
      products = Native::Payment::Payment.products([COINS_ID, PRO_ID, ADS_ID])
      products.each do |p|
        case p.id
        when COINS_ID then @coins_btn.text = "100 Coins — #{p.price_for_display}"
        when PRO_ID   then @pro_btn.text   = "Pro Monthly — #{p.price_for_display}"
        when ADS_ID   then @ads_btn.text   = "Remove Ads — #{p.price_for_display}"
        end
      end
      @status.text = "Tap to purchase"
    end
  end

  def apply_current_entitlements
    # Hide the Remove Ads button if already purchased
    if Native::Payment::Payment.is_purchased?(ADS_ID)
      @ads_btn.enabled = false
      @ads_btn.text    = "Ads Removed ✓"
    end

    # Show Pro badge if subscription is active
    if Native::Payment::Payment.is_subscription_active?(PRO_ID)
      @pro_btn.enabled = false
      @pro_btn.text    = "Pro Active ✓"
    end
  end

  def buy_coins
    @status.text = "Purchasing…"
    Native::Payment::Payment.purchase(COINS_ID) do |result|
      if result.success
        @status.text = "You now have more coins!"
        # grant_coins(100) — your own logic
      else
        @status.text = "Purchase cancelled or failed."
      end
    end
  end

  def buy_pro
    @status.text = "Purchasing…"
    Native::Payment::Payment.purchase(PRO_ID) do |result|
      if result.success
        @status.text      = "Welcome to Pro!"
        @pro_btn.enabled  = false
        @pro_btn.text     = "Pro Active ✓"
      else
        @status.text = result.error_message || "Purchase failed."
      end
    end
  end

  def buy_remove_ads
    @status.text = "Purchasing…"
    Native::Payment::Payment.purchase(ADS_ID) do |result|
      if result.success
        @status.text     = "Ads removed!"
        @ads_btn.enabled = false
        @ads_btn.text    = "Ads Removed ✓"
      else
        @status.text = result.error_message || "Purchase failed."
      end
    end
  end

  def restore_purchases
    @status.text = "Restoring…"
    Native::Payment::Payment.restore do |result|
      if result.success && result.restored_count > 0
        @status.text = "Restored #{result.restored_count} item(s)"
        apply_current_entitlements
      elsif result.success
        @status.text = "Nothing to restore"
      else
        @status.text = "Restore failed: #{result.error_message}"
      end
    end
  end
end

Native::App.start(ShopApp)
```

---

## Pre-launch checklist

Before you can test real purchases, you need to set up your products in the store developer portals:

**Android (Google Play Console)**
- Create your app and enable billing
- Add products under Monetise → Products
- Use test accounts in Settings → Licence Testing

**iOS (App Store Connect)**
- Create your app and set up In-App Purchases
- Add `StoreKit` to your Xcode capabilities
- Test with Sandbox accounts in Settings → App Store → Sandbox Account

**In your app**
- Declare `com.android.vending.BILLING` in `AndroidManifest.xml`
- Add `StoreKit.framework` in your Xcode project
- Always verify receipts on your server for non-trivial purchases

Apple also requires a "Restore Purchases" button in any app that has non-consumable purchases or subscriptions.
