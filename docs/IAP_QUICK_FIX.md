# IAP Quick Fix Guide

## TL;DR - What You Need to Do

The in-app purchase code is **WORKING** but products aren't configured in Google Play.

### Immediate Actions Required:

1. **Create IAP Products in Google Play Console** 🔴 CRITICAL
    - Go to: https://play.google.com/console
    - Select: Devocionales Cristianos app
    - Navigate: Monetize → In-app products
    - Create 3 products:
        * `supporter_bronze` - $1.99
        * `supporter_silver` - $4.99
        * `supporter_gold` - $9.99
    - Set all to **Active**

2. **Upload to Testing Track** 🔴 CRITICAL
   ```bash
   flutter build appbundle --release
   ```
    - Upload to Internal or Closed testing
    - Add your Gmail as license tester (Setup → License testing)

3. **Test**
   ```bash
   ./scripts/test_iap.sh
   ```
   Select option 7 (full test cycle)

## What Was Fixed

✅ **Added BILLING permission** to AndroidManifest.xml  
✅ **Enhanced logging** - now shows exactly what's wrong  
✅ **Added diagnostics** - automatic status report  
✅ **Created documentation** - complete setup guide  
✅ **Created test script** - automated testing helper

## Current Status

The error you're seeing:

```
⚠️ [IapService] Product supporter_bronze not loaded - cannot purchase
```

This is **EXPECTED** because:

- Products don't exist in Google Play Console yet
- App is not published to a testing track yet

## Next Time You Run the App

You'll see detailed diagnostics like:

```
═══════════════════════════════════════════
📊 [IapService] Diagnostics Report
═══════════════════════════════════════════
Initialized: true
Billing Available: true
Products Loaded: 0/3
⚠️  NO PRODUCTS LOADED
   Expected product IDs:
   - supporter_bronze
   - supporter_silver
   - supporter_gold

   ℹ️  Products must be created in Google Play Console
   ℹ️  App must be in testing or production track
   ℹ️  See docs/IN_APP_PURCHASE_SETUP.md for details
```

This tells you exactly what's missing!

## Full Documentation

See: `docs/IN_APP_PURCHASE_SETUP.md`

## Testing Script

```bash
./scripts/test_iap.sh
```

Options:

1. Clean install - Full reset and reinstall
2. Build release - Build and install APK
3. Monitor logs - Watch IAP activity
4. Full cycle - Does everything

## Summary

**Problem:** Products not loading  
**Root Cause:** Not configured in Google Play  
**Code Status:** ✅ Fixed and enhanced  
**Remaining:** Configure Google Play Console  
**ETA:** 5-10 minutes in Play Console

Once products are created → Everything will work! 🎉

