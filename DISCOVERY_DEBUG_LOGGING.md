# Discovery Debug Logging - Complete Trace

## Added Comprehensive Logging

I've added detailed logging throughout the Discovery Bible Studies flow to diagnose why studies are
not showing. The logs will now track every step from network fetch to UI rendering.

## Logging Points Added

### 1. **Repository Layer** (`discovery_repository.dart`)

#### `_fetchIndex()` method:

- 🌐 Network request initiation with cache-buster timestamp
- 📍 Full URL being requested
- 📡 HTTP response status code
- ✅ Response body length
- 📚 Number of studies parsed from JSON
- 💾 Cache save confirmation
- ❌ Server errors
- ⚠️ Network errors with fallback to cache
- 📦 Cache loading confirmation
- 🚫 No cache available warning

**Expected logs:**

```
🌐 Discovery: Buscando índice en la red (buster: 1768955071579)...
📍 Discovery: URL = https://raw.githubusercontent.com/...?cb=1768955071579
📡 Discovery: Response status = 200
✅ Discovery: Response body length = 2345
📚 Discovery: Parsed 7 studies from index
💾 Discovery: Index cached successfully
```

### 2. **Bloc Layer** (`discovery_bloc.dart`)

#### `_fetchAndEmitIndex()` method:

- 🔵 Method start with parameters
- 🔵 Index fetch confirmation
- 🔵 Favorites loaded count
- 🔵 Detected/provided locale
- 🔵 Number of studies to process
- 🔍 Processing each study individually:
    - Study ID
    - Available files map
    - Locale validation result
    - Filter decision (added/skipped)
    - Title, subtitle, emoji, reading minutes
    - Completion status
- 🔵 Final filtering summary
- 🔵 Lists of filtered IDs, titles, subtitles
- 🔵 State emission confirmation
- ❌ Error with stack trace

**Expected logs per study:**

```
🔍 [BLOC] Processing study: morning_star_001
  📁 Files available: [es, en]
  ✓ hasValidFile: true (locale: es, has es: true, has en: true)
  ✅ Study morning_star_001 ADDED to filtered list
  📝 Title: Estrella de la Mañana
  📋 Subtitle: El testimonio más poderoso sobre la identidad de Jesús
  😀 Emoji: 🌟
  ⏱️ Reading minutes: 6
  🎯 Completed: false
```

### 3. **UI Layer** (`discovery_list_page.dart`)

#### BlocBuilder:

- 🟢 State type on rebuild
- 🟢 Available study IDs
- 🟢 All state maps (titles, subtitles, emojis, minutes)
- ⚠️ Empty state warning
- 🟢 Carousel building with item count
- 🟢 Sorted IDs list
- ⚠️ Unknown state type

#### Carousel itemBuilder:

- 🎠 Card construction per index
- 🎠 Card data (title, subtitle, emoji, minutes)

**Expected logs:**

```
🟢 [DiscoveryListPage] BlocBuilder rebuilding with state: DiscoveryLoaded
🟢 [DiscoveryListPage] DiscoveryLoaded state received
🟢 [DiscoveryListPage] availableStudyIds: [morning_star_001, logos_creation_001, ...]
🟢 [DiscoveryListPage] studyTitles: {morning_star_001: Estrella de la Mañana, ...}
🟢 [DiscoveryListPage] Building carousel with 7 studies
🎠 [Carousel] Building carousel with 7 items
🎠 [Carousel] Building card at index 0 for study: morning_star_001
🎠 [Carousel] Card 0 data - title: "Estrella de la Mañana", subtitle: "El testimonio...", emoji: "🌟", minutes: 6
```

### 4. **Card Widget** (`devotional_card_premium.dart`)

Already has constructor logging:

```
✨🎴 [Card Premium Instance] -------------------
✨🏷️ Title: "Estrella de la Mañana"
✨📝 Subtitle: "El testimonio más poderoso..."
✨⏱️ Reading Time: 6 min
✨🆔 ID: morning_star_001
✨🎴 ------------------------------------------
```

## How to Use These Logs

### Step 1: Run the app

```bash
flutter run
```

### Step 2: Navigate to Discovery section

### Step 3: Check the console output

Look for the sequence:

1. **Network fetch** (🌐 📍 📡)
2. **JSON parsing** (✅ 📚)
3. **Bloc processing** (🔵 🔍)
4. **UI rendering** (🟢 🎠)
5. **Card construction** (✨)

### Debugging Scenarios

#### Scenario A: Network issues

```
🌐 Discovery: Buscando índice...
❌ Discovery: Server error 404
⚠️ Discovery: Error de red, usando cache
📦 Discovery: Cache encontrado
```

→ Network problem, but cache works

#### Scenario B: Empty studies list

```
📚 Discovery: Parsed 0 studies from index
🔵 [BLOC] Processing 0 studies from index
⚠️ [DiscoveryListPage] availableStudyIds is EMPTY
```

→ Index JSON is empty or malformed

#### Scenario C: Filtering failure

```
🔵 [BLOC] Processing 7 studies from index
🔍 [BLOC] Processing study: morning_star_001
  ❌ Study morning_star_001 SKIPPED (no valid files)
🔵 [BLOC] Filtering complete: 0 studies passed filter
```

→ Locale/files mismatch (should not happen with current fix)

#### Scenario D: State not reaching UI

```
🔵 [BLOC] DiscoveryLoaded state emitted with 7 studies
(no 🟢 [DiscoveryListPage] logs)
```

→ BlocBuilder not rebuilding or wrong context

## Expected Full Log Sequence

```
🌐 Discovery: Buscando índice en la red (buster: 1768955071579)...
📍 Discovery: URL = https://raw.githubusercontent.com/.../index.json?cb=1768955071579
📡 Discovery: Response status = 200
✅ Discovery: Response body length = 3456
📚 Discovery: Parsed 7 studies from index
💾 Discovery: Index cached successfully
🔵 [BLOC] _fetchAndEmitIndex START (languageCode: es, forceRefresh: false)
🔵 [BLOC] Index fetched successfully
🔵 [BLOC] Favorites loaded: 0 items
🔵 [BLOC] Using provided locale: es
🔵 [BLOC] Processing 7 studies from index
🔍 [BLOC] Processing study: morning_star_001
  📁 Files available: [es, en]
  ✓ hasValidFile: true (locale: es, has es: true, has en: true)
  ✅ Study morning_star_001 ADDED to filtered list
  📝 Title: Estrella de la Mañana
  📋 Subtitle: El testimonio más poderoso...
  😀 Emoji: 🌟
  ⏱️ Reading minutes: 6
  🎯 Completed: false
(... repeat for each study ...)
🔵 [BLOC] Filtering complete: 7 studies passed filter
🔵 [BLOC] Filtered IDs: [morning_star_001, logos_creation_001, ...]
🔵 [BLOC] DiscoveryLoaded state emitted with 7 studies
🟢 [DiscoveryListPage] BlocBuilder rebuilding with state: DiscoveryLoaded
🟢 [DiscoveryListPage] availableStudyIds: [morning_star_001, ...]
🟢 [DiscoveryListPage] Building carousel with 7 studies
🎠 [Carousel] Building carousel with 7 items
🎠 [Carousel] Building card at index 0 for study: morning_star_001
✨🎴 [Card Premium Instance] -------------------
✨🏷️ Title: "Estrella de la Mañana"
✨📝 Subtitle: "El testimonio más poderoso..."
✨⏱️ Reading Time: 6 min
```

## Files Modified

1. `/lib/repositories/discovery_repository.dart` - Network and cache logging
2. `/lib/blocs/discovery/discovery_bloc.dart` - State management and filtering logging
3. `/lib/pages/discovery_list_page.dart` - UI rendering logging
4. `/lib/pages/devotional_discovery/widgets/devotional_card_premium.dart` - Already had card logging

## Next Steps

Run the app, navigate to Discovery, and share the complete console output. This will show us exactly
where the flow breaks.
