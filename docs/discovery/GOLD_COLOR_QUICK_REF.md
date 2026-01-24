# Quick Reference - Gold Color Update

## What Changed

Updated Discovery premium card gradient from standard Material amber to rich biblical gold.

---

## Color Values

### Before

```dart
Colors.amber // #FFC107
Colors.amber.shade300 // #FFD54F
```

### After

```dart
Color
(0xFFD4AF37) // Metallic Gold
Color(
0xFFF4D03F
) // Golden Yellow
```

---

## Visual Comparison

### Before (Material Amber)

- Base: `#FFC107` - Bright orange-amber
- Highlight: `#FFD54F` - Light yellow-amber
- Feel: Standard, generic

### After (Biblical Gold)

- Base: `#D4AF37` - Deep metallic gold
- Highlight: `#F4D03F` - Bright golden yellow
- Feel: Premium, biblical, manuscript-like

---

## How to See It

1. Open the Discovery (Extractos) page
2. Look at the incomplete study cards in the carousel
3. The cards now have a richer, warmer gold gradient
4. Should look similar to Greek word dictionary tiles
5. More premium, biblical manuscript aesthetic

---

## Technical Details

**File:** `lib/utils/tag_color_dictionary.dart`
**Line:** ~62
**Tag:** `'luz'` (used for incomplete Discovery studies)

---

## Color Psychology

**Old Amber:**

- Bright, energetic
- Standard Material Design
- Generic app feel

**New Gold:**

- Warm, inviting
- Biblical manuscript
- Premium, sacred
- Dictionary aesthetic

---

**Status:** ✅ Implemented
**Impact:** Visual only, no functionality changed
**Compatibility:** 100% backward compatible
