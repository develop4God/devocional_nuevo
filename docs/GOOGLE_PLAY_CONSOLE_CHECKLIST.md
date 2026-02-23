# ✅ Google Play Console Setup Checklist

Use this checklist to configure In-App Purchases correctly.

## Prerequisites

- [ ] You have access to Google Play Console
- [ ] You are an admin for the app: `com.develop4god.devocional_nuevo`
- [ ] You have a Gmail account for testing

---

## Phase 1: Create In-App Products

### Step 1: Navigate to Products

- [ ] Go to https://play.google.com/console
- [ ] Select app: **Devocionales Cristianos**
- [ ] Click: **Monetize** → **In-app products**

### Step 2: Create Bronze Tier

- [ ] Click **Create product**
- [ ] Product ID: `supporter_bronze` (must be exact)
- [ ] Name: `Cafecito` (Spanish) / `Support Coffee` (English)
- [ ] Description: `Un café para el camino — ¡cada granito cuenta!`
- [ ] Status: **Active** (toggle on)
- [ ] Click **Add a price**
    - [ ] Base price: $1.99 USD
    - [ ] Or use **Apply default prices**
- [ ] Click **Save**

### Step 3: Create Silver Tier

- [ ] Click **Create product**
- [ ] Product ID: `supporter_silver` (must be exact)
- [ ] Name: `Huella` (Spanish) / `Offering` (English)
- [ ] Description: `Apoyando para crecimiento`
- [ ] Status: **Active** (toggle on)
- [ ] Click **Add a price**
    - [ ] Base price: $4.99 USD
    - [ ] Or use **Apply default prices**
- [ ] Click **Save**

### Step 4: Create Gold Tier

- [ ] Click **Create product**
- [ ] Product ID: `supporter_gold` (must be exact)
- [ ] Name: `Socio del Ministerio` (Spanish) / `Ministry Partner` (English)
- [ ] Description: `Compañero fiel de este ministerio`
- [ ] Status: **Active** (toggle on)
- [ ] Click **Add a price**
    - [ ] Base price: $9.99 USD
    - [ ] Or use **Apply default prices**
- [ ] Click **Save**

### Step 5: Verify Products

- [ ] All 3 products show as **Active**
- [ ] Product IDs are exactly: `supporter_bronze`, `supporter_silver`, `supporter_gold`
- [ ] Prices are set for at least your test country

---

## Phase 2: Set Up Testing

### Step 6: Configure License Testers

- [ ] In Play Console, go to **Setup** (left menu)
- [ ] Click **License testing**
- [ ] Click **Add license testers**
- [ ] Enter your Gmail address(es), one per line
- [ ] Select test response: **Always approve** (recommended for testing)
- [ ] Click **Save changes**

### Step 7: Create Testing Track

- [ ] Go to **Testing** → **Internal testing** (or Closed testing)
- [ ] Click **Create new release** (if needed)
- [ ] Upload your release bundle/APK:
  ```bash
  cd /home/develop4god/projects/devocional_nuevo
  flutter build appbundle --release
  ```
- [ ] Upload `build/app/outputs/bundle/release/app-release.aab`
- [ ] Fill in release notes (can be simple: "IAP testing")
- [ ] Click **Review release**
- [ ] Click **Start rollout to internal testing**

### Step 8: Add Testers to Track

- [ ] In the testing track, click **Testers** tab
- [ ] Create an email list with your testers
- [ ] Add the same Gmail accounts from Step 6
- [ ] Copy the **Opt-in URL**
- [ ] Share URL with testers (or just yourself)

---

## Phase 3: Install Test Build

### Step 9: Join Test and Install App

- [ ] Open the opt-in URL from Step 8 in a browser
- [ ] Sign in with your tester Gmail account
- [ ] Click **Become a tester**
- [ ] Click **Download it on Google Play**
- [ ] Install the app from Play Store
- [ ] Wait for installation to complete

**IMPORTANT:** Do NOT install via `flutter run` or `adb install` for testing IAP. Must install from
Play Store!

---

## Phase 4: Test In-App Purchases

### Step 10: Clear Cache and Prepare

On your computer:

```bash
cd /home/develop4god/projects/devocional_nuevo
./scripts/test_iap.sh
```

Select option 3 to monitor logs.

On your device:

- [ ] Clear Play Store cache: Settings → Apps → Google Play Store → Storage → Clear cache
- [ ] Ensure device is signed in with tester Gmail account
- [ ] Open Devocionales app

### Step 11: Verify Products Load

- [ ] Open the app
- [ ] Navigate to **Support** page (from menu or about page)
- [ ] Check computer logs for:
  ```
  ✅ [IapService] Loaded product: supporter_bronze - $1.99
  ✅ [IapService] Loaded product: supporter_silver - $4.99
  ✅ [IapService] Loaded product: supporter_gold - $9.99
  ```
- [ ] Diagnostics report shows: `Products Loaded: 3/3`

### Step 12: Test Purchase Flow

- [ ] Tap on **Bronze tier** card
- [ ] Purchase dialog appears (from Google Play)
- [ ] Shows price as $1.99 (or free for license testers)
- [ ] Complete the purchase
- [ ] Success message appears in app
- [ ] Bronze badge is awarded
- [ ] Check logs for: `✅ [IapService] Delivered product: supporter_bronze`

### Step 13: Test All Tiers

Repeat Step 12 for:

- [ ] Silver tier ($4.99)
- [ ] Gold tier ($9.99)

### Step 14: Test Restore Purchases

- [ ] Clear app data: Settings → Apps → Devocionales → Storage → Clear data
- [ ] Open app again
- [ ] Go to Support page
- [ ] Tap **Restore purchases**
- [ ] Verify badges are restored
- [ ] Check logs for purchase restoration

---

## Phase 5: Verification

### Step 15: Final Checks

- [ ] All 3 products appear in Support page
- [ ] Prices are correct
- [ ] Purchase dialogs work
- [ ] Badges are awarded after purchase
- [ ] Restore purchases works
- [ ] No error messages in logs
- [ ] Diagnostics show all green

### Step 16: Production Checklist (when ready)

Before publishing to production:

- [ ] Test on at least 2 devices
- [ ] Test with non-license tester (real purchase)
- [ ] Verify prices in multiple countries
- [ ] Check badge displays correctly
- [ ] Verify gold supporter name feature works
- [ ] Test purchases across app restarts
- [ ] Document any issues

---

## Troubleshooting

### Products Not Loading?

- [ ] Verify product IDs are exact (case-sensitive)
- [ ] Ensure products are set to **Active**
- [ ] Wait 2-24 hours after creating products (rare)
- [ ] Check app is installed from Play Store, not ADB
- [ ] Verify using release-signed build

### Purchase Dialog Doesn't Appear?

- [ ] Add Gmail as license tester
- [ ] Clear Play Store cache
- [ ] Ensure device has valid payment method (or is license tester)
- [ ] Check country restrictions on products

### "Item not available in your country"?

- [ ] Go to product in Play Console
- [ ] Click **Prices** tab
- [ ] Add pricing for more countries
- [ ] Or use **Apply default prices**

### Billing Not Available?

- [ ] Ensure Google Play Store is installed and updated
- [ ] Check BILLING permission in AndroidManifest.xml (should already be added)
- [ ] Verify device supports Play Store (not emulator without Play Services)

---

## Resources

- **Setup Guide:** `docs/IN_APP_PURCHASE_SETUP.md`
- **Quick Reference:** `docs/IAP_QUICK_FIX.md`
- **Testing Script:** `scripts/test_iap.sh`
- **Google Play Console:** https://play.google.com/console
- **Billing Docs:** https://developer.android.com/google/play/billing

---

## Timeline Estimate

| Phase              | Time          | Status |
|--------------------|---------------|--------|
| Create Products    | 5-10 min      | ⏳      |
| Set Up Testing     | 10-15 min     | ⏳      |
| Install Test Build | 5 min         | ⏳      |
| Test Purchases     | 5-10 min      | ⏳      |
| **Total**          | **25-40 min** | ⏳      |

---

## Notes

- Products may take up to 24 hours to activate (usually instant)
- License testers see "free" or are not charged
- Must use release-signed build, not debug
- Install from Play Store, not via ADB
- Clear caches if issues persist

---

**Once all checkboxes are checked, IAP should work perfectly!** ✅

Print this checklist and follow it step by step for guaranteed success.

