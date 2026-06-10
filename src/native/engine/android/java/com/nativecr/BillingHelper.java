// src/native/engine/android/java/com/nativecr/BillingHelper.java

package com.nativecr;

import android.app.Activity;
import android.util.Log;

import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.QueryPurchasesParams;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.ProductDetailsResponseListener;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class BillingHelper implements PurchasesUpdatedListener {
    private static BillingHelper instance;
    private BillingClient billingClient;
    private Activity currentActivity;
    private BillingCallback callback;
    private List<ProductDetails> productDetailsCache = new ArrayList<>();

    public interface BillingCallback {
        void onProductsFetched(String json);
        void onPurchaseCompleted(String productId, String transactionId, String receipt);
        void onPurchaseFailed(String error);
        void onRestoreCompleted(String json);
    }

    public static void init(Activity activity, String merchantId) {
        if (instance == null) {
            instance = new BillingHelper();
        }
        instance.currentActivity = activity;
        instance.setupBillingClient();
    }

    public static void setCallback(BillingCallback callback) {
        if (instance != null) {
            instance.callback = callback;
        }
    }

    private void setupBillingClient() {
        billingClient = BillingClient.newBuilder(currentActivity)
                .setListener(this)
                .enablePendingPurchases()
                .build();

        billingClient.startConnection(new BillingClientStateListener() {
            @Override
            public void onBillingSetupFinished(BillingResult billingResult) {
                if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                    Log.d("BillingHelper", "Billing client connected");
                    restorePurchases();
                }
            }

            @Override
            public void onBillingServiceDisconnected() {
                Log.d("BillingHelper", "Billing client disconnected");
            }
        });
    }

    public static void fetchProducts(String[] productIds) {
        if (instance == null || instance.billingClient == null) return;

        List<QueryProductDetailsParams.Product> products = new ArrayList<>();
        for (String id : productIds) {
            products.add(QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(id)
                    .setProductType(BillingClient.ProductType.INAPP)
                    .build());
        }

        QueryProductDetailsParams params = QueryProductDetailsParams.newBuilder()
                .setProductList(products)
                .build();

        instance.billingClient.queryProductDetailsAsync(params, new ProductDetailsResponseListener() {
            @Override
            public void onProductDetailsResponse(BillingResult billingResult, List<ProductDetails> productDetailsList) {
                if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                    instance.productDetailsCache = productDetailsList;
                    try {
                        JSONArray array = new JSONArray();
                        for (ProductDetails details : productDetailsList) {
                            JSONObject obj = new JSONObject();
                            obj.put("id", details.getProductId());
                            obj.put("title", details.getTitle());
                            obj.put("description", details.getDescription());
                            obj.put("price", details.getOneTimePurchaseOfferDetails().getFormattedPrice());
                            obj.put("price_amount", details.getOneTimePurchaseOfferDetails().getPriceAmountMicros() / 1000000.0);
                            obj.put("currency", details.getOneTimePurchaseOfferDetails().getPriceCurrencyCode());
                            obj.put("type", 0);
                            array.put(obj);
                        }
                        if (instance.callback != null) {
                            instance.callback.onProductsFetched(array.toString());
                        }
                    } catch (Exception e) {
                        Log.e("BillingHelper", "Error parsing products", e);
                    }
                }
            }
        });
    }

    public static void purchase(Activity activity, String productId) {
        if (instance == null || instance.billingClient == null) return;
        instance.currentActivity = activity;

        ProductDetails productToPurchase = null;
        for (ProductDetails details : instance.productDetailsCache) {
            if (details.getProductId().equals(productId)) {
                productToPurchase = details;
                break;
            }
        }

        if (productToPurchase != null) {
            BillingFlowParams flowParams = BillingFlowParams.newBuilder()
                    .setProductDetailsParamsList(
                            List.of(BillingFlowParams.ProductDetailsParams.newBuilder()
                                    .setProductDetails(productToPurchase)
                                    .build())
                    )
                    .build();
            instance.billingClient.launchBillingFlow(activity, flowParams);
        }
    }

    public static void restore() {
        if (instance == null || instance.billingClient == null) return;
        instance.restorePurchases();
    }

    private void restorePurchases() {
        billingClient.queryPurchasesAsync(QueryPurchasesParams.newBuilder()
                        .setProductType(BillingClient.ProductType.INAPP)
                        .build(),
                (billingResult, list) -> {
                    if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                        try {
                            JSONArray array = new JSONArray();
                            for (Purchase purchase : list) {
                                array.put(purchase.getProducts().get(0));
                            }
                            if (callback != null) {
                                callback.onRestoreCompleted(array.toString());
                            }
                        } catch (Exception e) {
                            Log.e("BillingHelper", "Error restoring purchases", e);
                        }
                    }
                });
    }

    public static boolean isPurchased(String productId) {
        if (instance == null || instance.billingClient == null) return false;
        // Implementation would check purchases
        return false;
    }

    public static boolean isSubscriptionActive(String productId) {
        return false;
    }

    @Override
    public void onPurchasesUpdated(BillingResult billingResult, List<Purchase> purchases) {
        if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK && purchases != null) {
            for (Purchase purchase : purchases) {
                if (callback != null) {
                    String receipt = purchase.getOriginalJson();
                    callback.onPurchaseCompleted(purchase.getProducts().get(0), purchase.getOrderId(), receipt);
                }
            }
        } else if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.USER_CANCELED) {
            if (callback != null) {
                callback.onPurchaseFailed("User cancelled");
            }
        } else {
            if (callback != null) {
                callback.onPurchaseFailed("Purchase failed: " + billingResult.getDebugMessage());
            }
        }
    }
}
