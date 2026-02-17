# Hindi Translation TODO

## Status: Pending Translation

The Hindi language support infrastructure is complete, but the translation file `i18n/hi.json` currently contains English text as placeholders. 

## What's Done ✅

- ✅ Language configuration (hi code added to all systems)
- ✅ Bible version support (ERV and BDS configured)
- ✅ TTS locale mapping (hi-IN)
- ✅ Copyright information (in Hindi)
- ✅ Translation file structure created
- ✅ All code changes tested

## What Needs Translation 📝

The file `i18n/hi.json` contains **English placeholder text** that needs to be translated to Hindi.

### Priority Translation Sections

#### High Priority (Most Visible to Users)
1. **app** section - App title, common buttons, loading messages
2. **devotionals** section - Main devotional page text
3. **settings** section - Settings page text
4. **bible_reader** section - Bible reader interface
5. **application_language** section - Language selection page

#### Medium Priority
6. **discovery** section - Discovery studies
7. **prayers** section - Prayer management
8. **notifications** section - Notification settings
9. **favorites** section - Favorites management
10. **share** section - Sharing functionality

#### Lower Priority (Less Frequently Seen)
11. **onboarding** section - First-time user experience
12. **backup** section - Cloud backup features
13. **about** section - About page
14. **error_messages** section - Error handling

## Translation Guidelines

### General Guidelines
1. **Maintain Formality**: Use respectful, formal Hindi appropriate for religious content
2. **Use Devanagari Script**: All text should be in Hindi Devanagari script (हिन्दी)
3. **Keep Placeholders**: Maintain parameter placeholders like `{parameter}` unchanged
4. **Preserve Special Characters**: Keep emoji, punctuation marks as they are
5. **Test Length**: Ensure translated text fits in UI (some Hindi text may be longer)

### Religious Terminology
- Use appropriate Hindi religious terms:
  - God = परमेश्वर (Parmeshwar)
  - Bible = बाइबिल (Bible) or पवित्र बाइबिल (Pavitra Bible)
  - Prayer = प्रार्थना (Prarthana)
  - Faith = विश्वास (Vishwas)
  - Devotional = भक्ति (Bhakti) or आध्यात्मिक (Aadhyatmik)

### Example Translations

**Before (English):**
```json
{
  "app": {
    "title": "Christian Devotionals",
    "loading": "Loading...",
    "error": "Error"
  }
}
```

**After (Hindi):**
```json
{
  "app": {
    "title": "ईसाई भक्ति",
    "loading": "लोड हो रहा है...",
    "error": "त्रुटि"
  }
}
```

## How to Translate

### Option 1: Manual Translation
1. Open `i18n/hi.json`
2. Replace English text with Hindi translations
3. Test the app to ensure translations fit properly
4. Run validation: `dart run lib/utils/translation_validator.dart hi`

### Option 2: Professional Translation
1. Export `i18n/hi.json` to a translation service
2. Have professional translators work on it
3. Import back and test
4. Validate completeness

### Option 3: Community Translation
1. Create a translation document (Google Docs/Sheets)
2. Share with Hindi-speaking community members
3. Review and consolidate translations
4. Update `i18n/hi.json`
5. Test and validate

## Validation

After translation, run:

```bash
# Check for missing translations
dart run lib/utils/translation_validator.dart hi

# Test the app with Hindi language
flutter run
# Then: Settings > Application Language > हिन्दी
```

## Important Notes

1. **Copyright Text**: The copyright information in `lib/utils/copyright_utils.dart` is already in Hindi and correct.

2. **Bible Version Names**: The Bible version names should remain as they are:
   - `पवित्र बाइबिल (ओ.वी.)` (ERV - Easy-to-Read Version)
   - `पवित्र बाइबिल` (BDS - Bible Society version)

3. **Testing**: Test on actual device with Hindi TTS voices installed for best results.

4. **Partial Updates OK**: You can translate sections gradually. The app will fall back to English for untranslated keys.

## Resources

### Hindi Translation Resources
- Google Translate: https://translate.google.com/?sl=en&tl=hi
- Microsoft Translator: https://www.bing.com/translator
- Hindi Bible Online: https://www.bible.com/hi
- Hindi Christian Resources: Various Hindi Christian websites

### Professional Translation Services
- Gengo: https://gengo.com/
- One Hour Translation: https://www.onehourtranslation.com/
- TranslationServices.com: https://www.translationservices.com/

## Progress Tracking

Create a checklist to track translation progress:

- [ ] App section (20 keys)
- [ ] Devotionals section (50 keys)
- [ ] Settings section (30 keys)
- [ ] Bible reader section (40 keys)
- [ ] Application language section (10 keys)
- [ ] Discovery section (35 keys)
- [ ] Prayers section (25 keys)
- [ ] Notifications section (20 keys)
- [ ] Favorites section (15 keys)
- [ ] Share section (10 keys)
- [ ] Onboarding section (15 keys)
- [ ] Backup section (15 keys)
- [ ] About section (10 keys)
- [ ] Error messages section (20 keys)

**Estimated Total**: ~315 translation keys

## Questions?

If you have questions about:
- **Technical aspects**: Open an issue on GitHub
- **Translation choices**: Consult with Hindi-speaking Christian community
- **UI/UX considerations**: Test on device and provide feedback

## Timeline

Suggested timeline for translation:
- Week 1: High priority sections (app, devotionals, settings)
- Week 2: Medium priority sections (discovery, prayers, notifications)
- Week 3: Lower priority sections + review and testing
- Week 4: Final testing, adjustments, and polish

---

**Last Updated**: February 2026
**Status**: Awaiting Hindi translations
**Contact**: Open an issue on GitHub for questions
