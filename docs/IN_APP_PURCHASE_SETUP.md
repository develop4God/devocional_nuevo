# In-App Purchase Setup Guide

## Problem Summary

The app shows the error:

```
⚠️ [IapService] Product supporter_bronze not loaded - cannot purchase
⚠️ [IapService] Product supporter_silver not loaded - cannot purchase
⚠️ [IapService] Product supporter_gold not loaded - cannot purchase
```

This means the IAP products are not being loaded from Google Play Store.

## Root Cause

Products are not configured in Google Play Console, or the app is not properly set up for testing
IAP.

## Solution Checklist

### ✅ 1. Android Manifest Permission (COMPLETED)

Added the required billing permission to `android/app/src/main/AndroidManifest.xml`:

```xml

<uses-permission android:name="com.android.vending.BILLING" />
```

### ⚠️ 2. Google Play Console Setup (REQUIRED)

#### A. Create Products in Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app: **Devocionales Cristianos** (`com.develop4god.devocional_nuevo`)
3. Navigate to: **Monetize** → **In-app products**
4. Click **Create product** and add the following:

**Product 1: Bronze Supporter**

- Product ID: `supporter_bronze`
- Name: Cafecito / Support Coffee
- Description: Un café para el camino — ¡cada granito cuenta! / A coffee for the journey — every bit
  counts!
- Status: Active
- Price: $1.99 USD (adjust for local currencies)

**Product 2: Silver Supporter**

- Product ID: `supporter_silver`
- Name: Huella / Offering
- Description: Apoyando para crecimiento / A heartfelt offering to the ministry
- Status: Active
- Price: $4.99 USD

**Product 3: Gold Supporter**

- Product ID: `supporter_gold`
- Name: Socio del Ministerio / Ministry Partner
- Description: Compañero fiel de este ministerio / Faithful companion of this ministry
- Status: Active
- Price: $9.99 USD

#### B. Publish or Test the App

**Option 1: Internal/Closed Testing (Recommended for Development)**

1. Go to **Testing** → **Internal testing** or **Closed testing**
2. Create a test track if not already done
3. Upload a signed APK/AAB
4. Add testers by email
5. Share the testing link with testers
6. **Important**: Testers must join via the link AND have a license tester account

**Option 2: Open Testing or Production**

1. Upload to Open testing or Production track
2. Wait for Google review approval
3. Once approved, IAP products will work

#### C. Add License Testers

For testing in-app purchases without actual charges:

1. Go to **Setup** → **License testing**
2. Add your Gmail accounts as license testers
3. Select test response: **Always approve** (for easy testing)
4. Save changes

**Important Notes:**

- License testers can make purchases without being charged
- The account must be added BEFORE installing the test app
- Clear Google Play Store cache after adding testers

### ⚠️ 3. App Signing Configuration

#### Verify Build Configuration

The app must be signed with the same signature as uploaded to Play Console:

**For Release Build:**

```bash
cd /home/develop4god/projects/devocional_nuevo
flutter build appbundle --release
```

**For Debug Testing (if testing locally):**

- Debug builds won't work with real products
- You MUST use a signed release build uploaded to a test track

#### Check Signing

Make sure `android/key.properties` exists with:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-keystore-file>
```

### ⚠️ 4. Testing Steps

#### A. Clear Cache and Reinstall

```bash
# Stop the app
adb shell am force-stop com.develop4god.devocional_nuevo

# Clear app data
adb uninstall com.develop4god.devocional_nuevo

# Clear Play Store cache
adb shell pm clear com.android.vending

# Install fresh build
flutter install --release
```

#### B. Verify Logs

Run the app and check logs:

```bash
flutter run --release | grep -i iap
```

Expected successful output:

```
🚀 [IapService] Starting initialization...
📱 [IapService] Billing available: true
🔍 [IapService] Querying products: {supporter_bronze, supporter_silver, supporter_gold}
📦 [IapService] Found 3 products
✅ [IapService] Loaded product: supporter_bronze - $1.99
✅ [IapService] Loaded product: supporter_silver - $4.99
✅ [IapService] Loaded product: supporter_gold - $9.99
✅ [IapService] Initialization complete
```

If products not found:

```
⚠️ [IapService] Products not found in store: {supporter_bronze, supporter_silver, supporter_gold}
   ℹ️ Possible reasons:
   • Products not created in Google Play Console
   • App not published or in testing track
   • Product IDs mismatch
   • Testing account not added to closed test
   • App signature mismatch (debug vs release)
```

### ⚠️ 5. Common Issues and Solutions

#### Issue: "Billing not available on this device"

**Causes:**

- No Google Play Store installed
- Device not compatible
- Play Store not logged in
- Play Store outdated

**Solution:**

```bash
# Check Play Store is installed
adb shell pm list packages | grep vending

# Update Play Store
adb shell am start -a android.intent.action.VIEW -d 'market://details?id=com.android.vending'
```

#### Issue: "Products not found in store"

**Causes:**

- Products not created in Play Console (most common)
- App not in testing/production track
- Signature mismatch
- Tester account not added

**Solution:**

1. Verify products exist in Play Console with exact IDs
2. Ensure app is published to at least internal testing
3. Add Gmail account as license tester
4. Use release-signed build, not debug build
5. Wait 2-24 hours after creating products (rare)

#### Issue: "This item is not available in your country"

**Causes:**

- Products not available in device's country
- Pricing not set for country

**Solution:**

1. Go to Play Console → In-app products → Select product
2. Click on "Prices" tab
3. Add pricing for more countries or use "Apply default prices"

#### Issue: Purchase dialog shows but fails

**Causes:**

- Payment method not set up
- Testing without license tester account

**Solution:**

1. Add account as license tester (no charges)
2. Or set up a payment method in Google Play

### 6. Verification Checklist

Before testing, ensure:

- [ ] BILLING permission added to AndroidManifest.xml
- [ ] All 3 products created in Play Console with correct IDs
- [ ] Products are set to "Active" status
- [ ] App uploaded to at least internal testing track
- [ ] Your Gmail account added as license tester
- [ ] App installed from Play Store test link (not via `flutter run`)
- [ ] Using release-signed build
- [ ] Google Play Store is updated
- [ ] Waited at least 2 hours after product creation

### 7. Testing Commands

```bash
# Build and install release APK
cd /home/develop4god/projects/devocional_nuevo
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk

# Monitor IAP logs
adb logcat | grep -i -E "(IapService|billing|purchase)"

# Test purchase flow
# 1. Open app
# 2. Navigate to Support page
# 3. Tap on a supporter tier
# 4. Verify purchase dialog appears
# 5. Complete purchase (as license tester, it's free)
# 6. Verify badge is awarded
```

### 8. Debug Enhanced Logging

The IapService now provides detailed diagnostics. Check logs for:

```
🚀 [IapService] Starting initialization...
📱 [IapService] Billing available: true/false
🔍 [IapService] Querying products: {...}
📦 [IapService] Found X products
✅ [IapService] Loaded product: ...
⚠️ [IapService] Products not found in store: {...}
```

## Product IDs Reference

Current products in code:

- `supporter_bronze` - Bronze tier ($1.99)
- `supporter_silver` - Silver tier ($4.99)
- `supporter_gold` - Gold tier ($9.99)

These MUST match exactly in Google Play Console.

## Support Resources

- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [in_app_purchase Flutter Plugin](https://pub.dev/packages/in_app_purchase)
- [Testing In-App Purchases](https://developer.android.com/google/play/billing/test)

## Next Steps

1. **Create products in Google Play Console** (most critical)
2. **Upload app to testing track**
3. **Add yourself as license tester**
4. **Install from Play Store test link**
5. **Test purchase flow**

Once products are created and the app is in a test track, the error should disappear and purchases
will work correctly.

