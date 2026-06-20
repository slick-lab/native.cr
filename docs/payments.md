# Payments (In-App Purchases)

native.cr provides a unified in-app purchase API for Android (Google Play Billing) and iOS (StoreKit) through `Native::Payment`.

---

## Product types

| Type | Description |
|---|---|
| `Consumable` | Can be bought multiple times (coins, lives, credits) |
| `NonConsumable` | Bought once, kept forever (unlock a feature, remove ads) |
| `Subscription` | Recurring billing (weekly, monthly, yearly) |

---

## Setup

Call `initialize` once when your app starts:

```crystal
def setup
  Native::Payment::Payment.initialize
  # ...rest of setup
end
```

---

## Fetching product information

Retrieve price and description from the App Store / Play Store using the product IDs you set up in your developer console:

```crystal
product_ids = ["com.myapp.coins_100", "com.myapp.remove_ads"]

products = Native::Payment::Payment.products(product_ids)

products.each do |product|
  puts "#{product.title} — #{product.price_for_display}"
  # e.g. "100 Coins — $0.99"
end
```

The `Product` struct has these fields:

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Your product identifier |
| `title` | `String` | Display name from the store |
| `description` | `String` | Product description |
| `price` | `String` | Formatted price string |
| `price_amount` | `Float64` | Numeric price |
| `currency` | `String` | Currency code (e.g. `"USD"`) |
| `currency_symbol` | `String` | Symbol (e.g. `"$"`) |
| `type` | `ProductType` | Consumable / NonConsumable / Subscription |
| `price_for_display` | `String` | Nicely formatted price (uses currency symbol) |

---

## Making a purchase

```crystal
Native::Payment::Payment.purchase("com.myapp.coins_100") do |result|
  if result.success
    puts "Purchase successful!"
    puts "Transaction ID: #{result.transaction_id}"

    # Grant the purchase to the user
    add_coins(100)
  else
    puts "Purchase failed: #{result.error_message}"
  end
end
```

The `PurchaseResult` struct:

| Field | Type | Description |
|---|---|---|
| `success` | `Bool` | Whether the purchase went through |
| `product_id` | `String` | Which product was bought |
| `transaction_id` | `String` | Unique transaction identifier |
| `receipt_data` | `String` | Receipt for server-side verification |
| `error_message` | `String?` | Error description (if `success` is false) |
| `purchase_date` | `Int64` | Unix timestamp |
| `expiration_date` | `Int64?` | For subscriptions: when it expires |

---

## Checking if something is purchased

```crystal
if Native::Payment::Payment.is_purchased?("com.myapp.remove_ads")
  hide_ads
end
```

---

## Subscriptions

```crystal
# Check if a subscription is still active
if Native::Payment::Payment.is_subscription_active?("com.myapp.pro_monthly")
  show_pro_features
else
  show_upgrade_screen
end
```

---

## Restoring previous purchases

Users who reinstall the app (or get a new device) can restore their non-consumable purchases and active subscriptions:

```crystal
restore_btn = UI::Button.new
restore_btn.text = "Restore Purchases"
restore_btn.on_click do
  Native::Payment::Payment.restore do |result|
    if result.success
      puts "Restored #{result.restored_count} purchase(s)"
      result.product_ids.each do |id|
        puts "  Restored: #{id}"
      end
      apply_restored_purchases(result.product_ids)
    else
      puts "Restore failed: #{result.error_message}"
    end
  end
end
```

---

## Helper constructors

native.cr provides shortcut methods for common product setups:

```crystal
# A consumable coins pack
coins = Native::Payment::Payment.coins_pack(
  id: "com.myapp.coins_500",
  title: "500 Coins",
  coin_amount: 500,
  price: "$4.99"
)

# A subscription product
pro = Native::Payment::Payment.subscription(
  id: "com.myapp.pro_monthly",
  title: "Pro Monthly",
  period: Native::Payment::SubscriptionPeriod::Monthly,
  price: "$9.99"
)
```

---

## Full example — a simple shop screen

```crystal
class ShopApp < Native::App
  COIN_PACK_ID = "com.myapp.coins_100"
  PRO_ID       = "com.myapp.pro_monthly"

  def setup
    Native::Payment::Payment.initialize

    @status = UI::Text.new
    @status.text = "Loading store..."

    coins_btn = UI::Button.new
    coins_btn.text = "Buy 100 Coins"
    coins_btn.on_click { buy_coins }

    pro_btn = UI::Button.new
    pro_btn.text = "Go Pro"
    pro_btn.on_click { buy_pro }

    restore_btn = UI::Button.new
    restore_btn.text = "Restore Purchases"
    restore_btn.on_click { restore }

    col = UI::Column.new
    col.spacing = 16
    col.alignment = Alignment::Center
    col.add_child(@status)
    col.add_child(coins_btn)
    col.add_child(pro_btn)
    col.add_child(restore_btn)
    @root = col

    load_prices
  end

  def load_prices
    products = Native::Payment::Payment.products([COIN_PACK_ID, PRO_ID])
    products.each do |p|
      puts "#{p.title}: #{p.price_for_display}"
    end
    @status.text = "Store ready"
  end

  def buy_coins
    @status.text = "Purchasing..."
    Native::Payment::Payment.purchase(COIN_PACK_ID) do |result|
      if result.success
        @status.text = "Got 100 coins!"
      else
        @status.text = "Purchase failed: #{result.error_message}"
      end
    end
  end

  def buy_pro
    Native::Payment::Payment.purchase(PRO_ID) do |result|
      @status.text = result.success ? "Welcome to Pro!" : "Failed: #{result.error_message}"
    end
  end

  def restore
    Native::Payment::Payment.restore do |result|
      @status.text = result.success ?
        "Restored #{result.restored_count} item(s)" :
        "Restore failed"
    end
  end

  def draw
    @root.draw(renderer)
  end
end
```

---

## Important notes

- In-app purchases require your products to be set up in the **Google Play Console** (Android) or **App Store Connect** (iOS) before they can be purchased.
- Always verify purchase receipts on your server for non-trivial purchases to prevent fraud.
- Apple requires a "Restore Purchases" button in any app that has non-consumable purchases or subscriptions.
