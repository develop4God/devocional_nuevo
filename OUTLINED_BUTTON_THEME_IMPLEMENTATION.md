# OutlinedButtonTheme Border Color Implementation

This document provides copy-paste ready code blocks for implementing theme-driven border colors in the Devocional app.

## Summary of Changes

1. **theme_constants.dart**: Added `outlinedButtonTheme` to all theme variants (Deep Purple, Green, Pink, Cyan, Light Blue) for both light and dark modes
2. **bible_reader_page.dart**: Updated selector containers and buttons to use theme-driven border colors instead of hardcoded values
3. **Tests**: Created comprehensive tests to validate border colors for all theme combinations

## Implementation Details

### 1. Theme Constants (theme_constants.dart)

For each theme variant, add an `outlinedButtonTheme` configuration:

#### Light Theme Pattern
```dart
outlinedButtonTheme: OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    side: const BorderSide(color: Colors.black, width: 1.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
  ),
),
```

#### Dark Theme Pattern
```dart
outlinedButtonTheme: OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    side: const BorderSide(color: Colors.white, width: 1.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
  ),
),
```

### 2. Bible Reader Page (bible_reader_page.dart)

#### Book Selector Container
Replace hardcoded border color with theme-driven color:

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  decoration: BoxDecoration(
    border: Border.all(
      color: Theme.of(context)
              .outlinedButtonTheme
              .style
              ?.side
              ?.resolve({})?.color ??
          colorScheme.outline,
      width: 1.0,
    ),
    borderRadius: BorderRadius.circular(25),
  ),
  // ... child widgets
)
```

#### Chapter and Verse OutlinedButtons
Remove any hardcoded `side` parameter and let the button use the theme:

```dart
OutlinedButton.icon(
  onPressed: _showChapterGridSelector,
  icon: Icon(Icons.format_list_numbered, size: 18, color: colorScheme.primary),
  label: Text('C. ${_selectedChapter ?? 1}', style: const TextStyle(fontSize: 14)),
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 12),
    // No 'side' parameter - uses theme automatically
  ),
)
```

### 3. Border Color Specifications

- **Light Mode**: Black border (`Colors.black`)
- **Dark Mode**: White border (`Colors.white`)
- **Border Width**: 1.0
- **Border Radius**: 25 (matches inputDecorationTheme)

### 4. Theme Variants Covered

All five theme variants have been updated for both light and dark modes:

1. **Deep Purple** (Realeza)
   - Light: Black border
   - Dark: White border

2. **Green** (Vida)
   - Light: Black border
   - Dark: White border

3. **Pink** (Pureza)
   - Light: Black border
   - Dark: White border

4. **Cyan** (Obediencia)
   - Light: Black border
   - Dark: White border

5. **Light Blue** (Celestial)
   - Light: Black border
   - Dark: White border

## Test Coverage

### Unit Tests (theme_outlined_button_border_test.dart)

Tests validate:
- Each theme variant has the correct border color
- Border width is 1.0 for all themes
- Border radius is 25 for all themes
- Border properties match inputDecorationTheme

### Widget Tests (bible_reader_page_border_theme_test.dart)

Tests validate:
- OutlinedButton respects theme border colors
- Custom containers can extract theme border colors
- Theme.of(context) provides correct border colors
- All themes are consistent

## Visual Validation Checklist

When manually testing, verify:

- [ ] Book selector container shows visible borders in all themes
- [ ] Chapter OutlinedButton shows visible borders in all themes
- [ ] Verse OutlinedButton shows visible borders in all themes
- [ ] Light mode themes show black borders
- [ ] Dark mode themes show white borders
- [ ] Border radius matches other UI elements (25)
- [ ] Border width is consistent (1.0)
- [ ] No visual regressions in other UI components

## Usage Pattern for Future Components

To use theme-driven border colors in custom containers:

```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: Theme.of(context)
              .outlinedButtonTheme
              .style
              ?.side
              ?.resolve({})?.color ??
          Colors.grey,  // fallback color
      width: 1.0,
    ),
    borderRadius: BorderRadius.circular(25),
  ),
  // ... child widgets
)
```

For OutlinedButton widgets, simply omit the `side` parameter in `styleFrom()` to use the theme default.

## Benefits

1. **Consistency**: All outlined controls use the same border styling
2. **Maintainability**: Border colors are centralized in theme definitions
3. **Accessibility**: High contrast borders (black on light, white on dark)
4. **Flexibility**: Easy to change border styling for all components at once
5. **Theme Support**: Fully supports all theme variants and modes
