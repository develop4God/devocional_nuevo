// Manual Testing Guide for Spiritual Progress Implementation

## Testing Steps

### 1. Visual Overflow Tests (Manual)

**Test Small Screen (Phone):**
1. Run app on small screen device or emulator (320x568 resolution)
2. Navigate to Progress tab (third tab in bottom navigation)  
3. Verify no overflow errors in console
4. Check that all sections are visible:
   - "Racha Actual" card with fire icon
   - Two stat cards (Devocionales, Favoritos)
   - "Logros" section with achievement grid
   - "Acciones Rápidas" section
5. Try scrolling to ensure all content is accessible
6. Rotate device to landscape and verify no overflow

**Test Large Screen (Tablet):**
1. Run app on tablet or large screen emulator
2. Navigate to Progress tab
3. Verify layout adapts properly without overflow
4. Check that achievement grid displays correctly

### 2. Devotional Reading Logic Tests (Manual)

**Test Basic Reading Tracking:**
1. Open app and go to main devotional page
2. Read a devotional completely (scroll through content)
3. Tap the "next" arrow to go to next devotional
4. Navigate to Progress tab
5. Verify "Devocionales" count shows 1
6. Verify "Primer Paso" achievement is unlocked (not grayed out)

**Test Anti-Spam Protection:**
1. Go to devotional page
2. Rapidly tap the "next" arrow multiple times (< 10 seconds apart)
3. Navigate to Progress tab 
4. Verify count only increased by 1, not by number of taps
5. Check that rapid tapping doesn't inflate statistics

**Test Unique ID Tracking:**
1. Navigate through several devotionals normally (with pauses)
2. Go back to a previously read devotional
3. Try to navigate "next" from that devotional again
4. Verify the count doesn't increase for already-read devotionals

**Test Streak Calculation:**
1. Read devotionals on consecutive days (if testing across days)
2. Check that streak counter increases appropriately
3. Verify streak resets if a day is missed

**Test Achievement Unlocking:**
1. Read first devotional → check "Primer Paso" unlocks
2. Read 7 devotionals → check "Lector Semanal" unlocks  
3. Add 1 favorite → check "Primer Favorito" unlocks
4. Add 10 favorites → check "Coleccionista" unlocks

**Test Favorites Integration:**
1. Add/remove devotionals from favorites
2. Navigate to Progress tab
3. Verify "Favoritos" count updates correctly
4. Verify favorite-based achievements unlock at correct thresholds

### 3. Navigation Tests

**Test Progress Tab Access:**
1. Verify bottom navigation has "Progreso" tab (not "Ajustes")
2. Tap Progress tab → verify page loads without errors
3. Test pull-to-refresh functionality
4. Test "Actualizar" button in app bar

**Test Alternative Progress Access:**
1. From devotional page, tap the trophy/awards icon in top bar
2. Verify it opens the same progress page
3. Test navigation back to devotional page

### 4. Error Handling Tests

**Test Network Issues:**
1. Disable internet connection
2. Navigate to Progress tab
3. Verify app doesn't crash and shows appropriate error message
4. Test retry functionality

**Test Empty Data:**
1. Reset app data (clear SharedPreferences if possible)
2. Navigate to Progress tab
3. Verify all stats show 0 and no achievements are unlocked
4. Verify app doesn't crash with empty data

### 5. Performance Tests

**Test Animation Performance:**
1. Navigate to Progress tab multiple times
2. Verify streak card animation runs smoothly
3. Check for any lag or stutter in animations

**Test Large Achievement Lists:**
1. Verify all 8+ predefined achievements display correctly
2. Check that achievement grid scrolls properly if more achievements added

### Expected Results

✅ **Visual**: No "OVERFLOWED BY X PIXELS" errors in console
✅ **Logic**: Reading tracking only counts legitimate reads, not rapid taps
✅ **IDs**: Each devotional counted only once using unique consecutive IDs
✅ **Achievements**: Unlock correctly based on real usage
✅ **Navigation**: Progress accessible from both bottom tab and devotional page
✅ **Performance**: Smooth animations and responsive UI

### Common Issues to Watch For

❌ Bottom overflow in achievement grid on small screens
❌ Statistics inflating from rapid arrow tapping
❌ Same devotional counted multiple times
❌ Achievements not unlocking despite meeting requirements  
❌ App crashes when accessing progress page
❌ Favorites count not syncing with actual favorites

## Files to Monitor for Errors

- `lib/pages/progress_page.dart` - Main UI implementation
- `lib/services/spiritual_stats_service.dart` - Core logic
- `lib/providers/devocional_provider.dart` - Integration layer
- Console logs for overflow errors and anti-spam messages