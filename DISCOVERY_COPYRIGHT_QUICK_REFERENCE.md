# Quick Reference: Discovery Copyright Disclaimers

## JSON File Format

Make sure each Discovery JSON file includes these fields:

```json
{
  "id": "your_study_id",
  "type": "discovery",
  "date": "2026-01-18",
  "title": "Study Title",
  "subtitle": "Study subtitle",
  "language": "en",
  "version": "KJV",
  "cards": [
    ...
  ]
}
```

## Supported Versions by Language

### English (`"language": "en"`)

- `"KJV"` - King James Version® Public Domain
- `"NIV"` - New International Version® © 2011 Biblica, Inc.
- **Default**: KJV

### Spanish (`"language": "es"`)

- `"RVR1960"` - Reina-Valera 1960® Sociedades Bíblicas
- `"NVI"` - Nueva Versión Internacional® © 1999 Biblica, Inc.
- **Default**: RVR1960

### Portuguese (`"language": "pt"`)

- `"ARC"` - Almeida Revista e Corrigida® Domínio Público
- `"NVI"` - Nova Versão Internacional® © 2000 Biblica, Inc.
- **Default**: ARC

### French (`"language": "fr"`)

- `"LSG1910"` - Louis Segond 1910® Domaine Public
- `"TOB"` - Traduction Oecuménique de la Bible® © Société Biblique Française
- **Default**: LSG1910

### Japanese (`"language": "ja"`)

- `"新改訳2003"` - 新改訳2003聖書® © 2003 新日本聖書刊行会
- `"リビングバイブル"` - リビングバイブル® © 1997 新日本聖書刊行会
- **Default**: 新改訳2003

### Chinese (`"language": "zh"`)

- `"和合本1919"` - 圣经和合本版权属于公有领域
- `"新译本"` - 圣经《新译本》版权属于环球圣经公会
- **Default**: 和合本1919

## Adding New Versions

To add a new Bible version, edit `/lib/utils/copyright_utils.dart`:

```dart
static String getCopyrightText
(String language, String version) {

const Map<String, Map<String, String>> copyrightMap = {
  'en': {
    'KJV': 'The biblical text King James Version® Public Domain.',
    'NIV': '...',
    'ESV': 'Your new version copyright here', // Add here
    'default': '...',
  },
  // ...
};
// ...
}
```

## Testing Checklist

When adding a new Discovery study:

1. ✅ Include `"language"` field in JSON
2. ✅ Include `"version"` field in JSON
3. ✅ Verify version is supported in `CopyrightUtils`
4. ✅ Test display in app
5. ✅ Verify copyright appears at bottom of each card
6. ✅ Check text matches expected copyright

## Troubleshooting

### Copyright not showing

- Verify JSON has `"language"` and `"version"` fields
- Check if version is supported in `CopyrightUtils`
- App will fall back to default if version not found

### Wrong copyright text

- Verify exact spelling of version in JSON
- Version names are case-sensitive
- Check `copyrightMap` in `CopyrightUtils`

### Want to hide copyright temporarily

- The disclaimer is always shown for compliance
- To modify styling, edit `_buildCopyrightDisclaimer()` in `discovery_detail_page.dart`

## Performance Notes

- ✅ No API calls needed
- ✅ No database queries
- ✅ Uses already-fetched JSON data
- ✅ Minimal rendering impact
- ✅ Cached copyright strings

## Compliance

Always ensure:

- Correct copyright attribution for each Bible version
- Text matches publisher requirements
- Attribution is visible to users
- Updates to copyright text when versions change
