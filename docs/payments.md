# Payments

In-app purchases and subscriptions via Google Play and StoreKit.

---

## Setup

```crystal
Native::Payment::Payment.initialize
```

---

## Product Types

| Type | Description |
|------|-------------|
| Consumable | Buy repeatedly (coins, lives) |
| NonConsumable | Buy once (remove ads) |
| Subscription | Recurring (monthly pro) |

---

## Fetch Products

```crystal
ids = ["com.app.coins", "com.app.pro"]
products = Native::Payment::Payment.products(ids)

products.each do |p|
  puts "#{p.title}: #{p.price_for_display}"
end
```

---

## Purchase

```crystal
Native::Payment::Payment.purchase("com.app.coins") do |result|
  if result.success
    puts "Purchased!"
    grant_coins(100)
  else
    puts "Failed: #{result.error_message}"
  end
end
```

---

## Check Ownership

```crystal
if Native::Payment::Payment.is_purchased?("com.app.remove_ads")
  hide_ads
end

if Native::Payment::Payment.is_subscription_active?("com.app.pro")
  enable_pro_features
end
```

---

## Restore Purchases

Apple requires this for non-consumables:

```crystal
Native::Payment::Payment.restore do |result|
  if result.success
    result.product_ids.each { |id| apply_purchase(id) }
  end
end
```

---

## Example: Shop

```crystal
class ShopApp < Native::App
  COINS = "com.app.coins"
  
  def setup
    Native::Payment::Payment.initialize
    
    @status = Native::UI::TextView.new("Loading...")
    buy = Native::UI::Button.new("Buy Coins")
    buy.on_click { purchase }
    restore = Native::UI::Button.new("Restore")
    restore.on_click { restore_purchases }
    
    # ... layout
  end

  def purchase
    Native::Payment::Payment.purchase(COINS) do |r|
      @status.text = r.success ? "Done!" : r.error_message
    end
  end

  def restore_purchases
    Native::Payment::Payment.restore { |r| @status.text = "Restored" }
  end
end
```

---

## Platform Setup

**Android — AndroidManifest.xml:**

```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

**iOS — Xcode:**

- Add StoreKit capability
- Create products in App Store Connect
