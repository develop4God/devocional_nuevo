# Semantic Keys for Robo Testing

This document lists all the semantic keys added to the Devocional Nuevo app for Firebase Robo testing.

## Purpose
These keys enable automated UI testing by providing stable identifiers for UI elements that are independent of text translations or visual styling.

## Drawer Navigation Keys

### DevocionalesDrawer Widget (`lib/widgets/devocionales_page_drawer.dart`)

| Key | Description | Widget Type |
|-----|-------------|-------------|
| `drawer_close_button` | Close drawer button | IconButton |
| `drawer_bible_version_selector` | Bible version dropdown selector | InkWell (drawerRow) |
| `drawer_saved_favorites` | Navigate to saved favorites | InkWell (drawerRow) |
| `drawer_my_prayers` | Navigate to prayers page | InkWell (drawerRow) |
| `drawer_dark_mode_toggle` | Toggle dark/light mode | InkWell (drawerRow) with Switch |
| `drawer_notifications_config` | Navigate to notifications config | InkWell (drawerRow) |
| `drawer_share_app` | Share app functionality | InkWell (drawerRow) |
| `drawer_download_devotionals` | Download devotionals for offline use | InkWell (drawerRow) |

## Bottom Navigation Keys

### DevocionalesPage Widget (`lib/pages/devocionales_page.dart`)

#### Navigation Buttons
| Key | Description | Widget Type |
|-----|-------------|-------------|
| `bottom_nav_previous_button` | Navigate to previous devotional | ElevatedButton |
| `bottom_nav_tts_player` | Text-to-speech player widget | TtsPlayerWidget |
| `bottom_nav_next_button` | Navigate to next devotional | ElevatedButton |

#### Bottom App Bar Icons
| Key | Description | Widget Type |
|-----|-------------|-------------|
| `bottom_appbar_favorite_icon` | Toggle favorite status | IconButton |
| `bottom_appbar_prayers_icon` | Navigate to prayers page | IconButton |
| `bottom_appbar_bible_icon` | Navigate to Bible reader | IconButton |
| `bottom_appbar_share_icon` | Share devotional | IconButton |
| `bottom_appbar_progress_icon` | Navigate to progress page | IconButton |
| `bottom_appbar_settings_icon` | Navigate to settings page | IconButton |

## Salvation Prayer Dialog Keys

### DevocionalesPage Widget (`lib/pages/devocionales_page.dart`)

| Key | Description | Widget Type |
|-----|-------------|-------------|
| `salvation_prayer_dialog` | The salvation prayer dialog itself | AlertDialog |
| `salvation_prayer_checkbox` | "Don't show again" checkbox | Checkbox |
| `salvation_prayer_continue_button` | Continue button | TextButton |

## Usage in Robo Tests

These keys can be used in Firebase Robo test JSON files with the `key` field:

```json
{
  "type": "click",
  "key": "drawer_my_prayers",
  "delay": 2000
}
```

## Test Coverage

The comprehensive test file `16_comprehensive_navigation_with_keys.json` exercises all of these keys in a realistic user flow:

1. Bottom navigation (previous/next/TTS)
2. Bottom app bar icons (all 6 icons)
3. Drawer navigation (all 8 drawer items)
4. Salvation prayer dialog (if shown)

## Benefits

✅ **Stable Testing**: Keys don't change with UI refactoring or translations  
✅ **Comprehensive Coverage**: All major navigation points are covered  
✅ **Maintainability**: Easy to update tests when features change  
✅ **Documentation**: Self-documenting test scripts  

## Notes

- Keys use a consistent naming convention: `<location>_<element>_<type>`
- All keys are defined as `const Key('key_name')` for performance
- Keys are added without affecting existing functionality
- Tests pass with 454/454 tests ✅
