# Firebase Remote Config - Supporter Feature

## Parameter Configuration

### Copy and paste this into Firebase Remote Config:

```json
{
  "parameter_key": "feature_supporter",
  "value_type": "BOOLEAN",
  "default_value": true,
  "conditional_values": {},
  "description": "Enable or disable supporter features (IAP and bottom navigation icon)"
}
```

## Setup Instructions

### Via Firebase Console (Recommended):

1. Go to: https://console.firebase.google.com
2. Select your project: **Devocionales Cristianos**
3. Click on **Remote Config** in left menu
4. Click **Add parameter**
5. Fill in:
    - **Parameter key:** `feature_supporter`
    - **Data type:** Boolean
    - **Default value:** `true` ✅
    - **Description:** Enable/disable supporter features
6. Click **Save**
7. Click **Publish changes**

### Via Firebase CLI:

```bash
# Download current config
firebase remoteconfig:get -o remoteconfig.json

# Add parameter to remoteconfig.json:
{
  "parameters": {
    "feature_legacy": { ... },
    "feature_bloc": { ... },
    "feature_supporter": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable or disable supporter features (IAP and bottom navigation icon)",
      "valueType": "BOOLEAN"
    }
  }
}

# Upload updated config
firebase remoteconfig:publish remoteconfig.json
```

## Default Values in App

The app has these defaults if Remote Config fails to load:

```dart
// lib/services/remote_config_service.dart
await
_remoteConfig.setDefaults
(
{'feature_legacy': false,
'feature_bloc': false,
'feature_supporter': true, // ← NEW: Default enabled
});
```

## Conditional Values Examples

### Example 1: Enable for Beta Users Only

```json
{
  "parameter_key": "feature_supporter",
  "conditional_values": {
    "beta_testers": {
      "value": "true"
    }
  },
  "default_value": false
}
```

### Example 2: Enable by Country

```json
{
  "parameter_key": "feature_supporter",
  "conditional_values": {
    "us_users": {
      "value": "true",
      "condition": {
        "name": "us_users",
        "expression": "device.country in ['US', 'CA', 'MX']"
      }
    }
  },
  "default_value": false
}
```

### Example 3: Percentage Rollout

```json
{
  "parameter_key": "feature_supporter",
  "conditional_values": {
    "10_percent": {
      "value": "true",
      "condition": {
        "name": "10_percent",
        "expression": "percent <= 10"
      }
    }
  },
  "default_value": false
}
```

### Example 4: A/B Test

```json
{
  "parameter_key": "feature_supporter",
  "conditional_values": {
    "variant_a": {
      "value": "true",
      "condition": {
        "name": "variant_a",
        "expression": "app.userProperty['ab_test'] == 'a'"
      }
    },
    "variant_b": {
      "value": "false",
      "condition": {
        "name": "variant_b",
        "expression": "app.userProperty['ab_test'] == 'b'"
      }
    }
  },
  "default_value": true
}
```

## Fetch Intervals

The app fetches Remote Config values at these intervals:

```dart
// Debug mode: 1 minute
minimumFetchInterval: const Duration
(
minutes: 1)

// Release mode: 12 hours
minimumFetchInterval: const Duration(hours: 12
)
```

This means:

- **Debug builds:** Changes visible within 1 minute
- **Release builds:** Changes visible within 12 hours

## Testing

### Force Fetch in Debug Mode:

```dart
// Call in debug mode to immediately fetch new values
final remoteConfig = getService<RemoteConfigService>();
await
remoteConfig.refresh
();
```

### Verify Current Value:

```dart
// Check current value
final remoteConfig = getService<RemoteConfigService>();
print
('feature_supporter: 
${remoteConfig.
featureSupporter
}
'
);
```

### Log Output:

When initialized, you'll see:

```
RemoteConfigService: feature_supporter = true
```

## Monitoring

### Check Value in Firebase Analytics:

```sql
SELECT 
  user_pseudo_id,
  event_name,
  (SELECT value.string_value FROM UNNEST(user_properties) 
   WHERE key = 'feature_supporter') as supporter_enabled
FROM `your-project.analytics_XXXXXXXX.events_*`
WHERE event_name = 'app_open'
LIMIT 100
```

### Track Feature Usage:

```dart
AnalyticsService.logCustomEvent
(
eventName: 'feature_flag_check',
parameters: {
'flag_name': 'feature_supporter',
'flag_value': remoteConfig.featureSupporter,
},
);
```

## Troubleshooting

### Value Not Updating?

1. Check fetch interval (12 hours in release)
2. Force refresh in debug mode
3. Clear app data and reinstall
4. Verify parameter published in Firebase Console

### Default Value Used?

If you see this log:

```
RemoteConfigService: Error reading feature_supporter, using default: true
```

Possible causes:

- Parameter not created in Firebase
- Network error
- Firebase not initialized

### Icon Not Appearing?

Check:

1. Remote Config value: `feature_supporter = true`
2. App restarted after config change
3. No console errors
4. Firebase initialized before Remote Config

## Security

Remote Config values are:

- ✅ Fetched over HTTPS
- ✅ Cached locally
- ✅ Validated by Firebase SDK
- ✅ Not modifiable by users

## Best Practices

1. **Always set a default value** in the app code
2. **Use descriptive parameter names** (`feature_supporter` not `fs`)
3. **Document parameter purpose** in description field
4. **Test changes** in staging before production
5. **Monitor analytics** after value changes
6. **Keep fetch intervals** reasonable (12 hours is good)
7. **Use conditions** for gradual rollouts
8. **Version parameters** if needed (`feature_supporter_v2`)

## Backup Plan

If Remote Config fails:

1. App uses default value (`true`)
2. Feature remains functional
3. No user impact
4. Can be disabled via app update if needed

## Complete Remote Config Template

```json
{
  "conditions": [],
  "parameters": {
    "feature_legacy": {
      "defaultValue": {
        "value": "false"
      },
      "description": "Enable legacy features",
      "valueType": "BOOLEAN"
    },
    "feature_bloc": {
      "defaultValue": {
        "value": "false"
      },
      "description": "Enable BLoC architecture features",
      "valueType": "BOOLEAN"
    },
    "feature_supporter": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable supporter features (IAP and bottom nav icon)",
      "valueType": "BOOLEAN",
      "conditionalValues": {}
    }
  },
  "version": {
    "versionNumber": "1",
    "updateTime": "2026-02-18T00:00:00Z",
    "updateUser": {
      "email": "your-email@example.com"
    },
    "updateOrigin": "CONSOLE",
    "updateType": "INCREMENTAL_UPDATE"
  }
}
```

## Support

- **Firebase Documentation:** https://firebase.google.com/docs/remote-config
- **Flutter Plugin:** https://pub.dev/packages/firebase_remote_config
- **Implementation Guide:** `docs/SUPPORTER_FEATURE_IMPLEMENTATION.md`

---

**Status:** Ready for Firebase Setup ✅

