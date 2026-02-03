# Discovery Branch Selector - Simple Implementation

## 📖 Overview

Simple branch selector for Discovery Studies. Allows switching between GitHub branches in debug
mode.

## 🎯 Implementation

### Files Modified (3)

1. **`lib/utils/constants.dart`**
    - Added `debugBranch` variable (default: 'main')
    - Added `getDiscoveryIndexUrl()` method
    - Updated `getDiscoveryStudyFileUrl()` to use branch

2. **`lib/repositories/discovery_repository.dart`**
    - Updated `_fetchIndex()` to use `getDiscoveryIndexUrl()`

3. **`lib/pages/debug_page.dart`**
    - Converted to StatefulWidget
    - Added branch dropdown
    - Added GitHub API branch fetching
    - Added refresh button

## 🚀 How to Use

1. Open app in debug mode
2. Navigate to Debug page
3. Select branch from dropdown
4. Studies reload automatically from selected branch

## 🔧 Technical Details

### Branch Selection

- In **debug mode**: Uses `Constants.debugBranch` variable
- In **production**: Always uses 'main' branch
- Branch list fetched from GitHub API

### URLs Generated

```
Debug mode with branch 'dev':
https://raw.githubusercontent.com/.../refs/heads/dev/discovery/index.json

Production (always main):
https://raw.githubusercontent.com/.../refs/heads/main/discovery/index.json
```

## ✅ Features

- ✅ Simple dropdown selector
- ✅ Auto-fetch branches from GitHub
- ✅ Refresh button
- ✅ Instant study reload
- ✅ Debug mode only
- ✅ Production safe (always 'main')

## 📝 Code Changes

### Constants.dart

```dart

static String debugBranch = 'main';

static String getDiscoveryIndexUrl
() {

final branch = kDebugMode ? debugBranch : 'main';return '
.../
$
branch/discovery/index.json';
}
```

### Debug Page

```dart
DropdownButton<String>
(
value: Constants.debugBranch,
items: _branches.map((branch) =>
DropdownMenuItem(value: branch, child: Text(branch))
).toList(),
onChanged: (newBranch) {
setState(() => Constants.debugBranch = newBranch!);
context.read<DiscoveryBloc>().add(RefreshDiscoveryStudies());
},
)
```

## 🔒 Security

- Only works in `kDebugMode`
- Production always uses 'main' branch
- No user settings stored
- Simple and safe

---

**Status:** ✅ Complete  
**Complexity:** Simple  
**Production Safe:** Yes
