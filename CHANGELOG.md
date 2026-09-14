# Changelog

Internal, developer-facing history generated from commit messages via
[git-cliff](https://git-cliff.org). For user-facing release notes, see
[RELEASE_NOTES.md](RELEASE_NOTES.md).

Regenerate with `git-cliff -o CHANGELOG.md` before tagging a release.

<!-- git-cliff: end of header -->
## [unreleased]

### 🐛 Bug Fixes

- *(ci)* Switch CodeQL java-kotlin analysis to manual build mode
- *(ci)* Make git-cliff download fail loudly and retry on transient errors
- *(ci)* Fix real root cause of git-cliff install failure — filename mismatch
## [1.16.5+126] - 2026-09-09

### 🚀 Features

- *(i18n)* Use translation key for devotional initialization error
- Fetch notification images dynamically with fallback

### 🐛 Bug Fixes

- Prevent text overflow in prayers page menu items and add behavioral tests
- Localize Bible reader book-selector placeholder text
- Merge preferred bible version and marked verses on automatic backup
- Switch CodeQL Java/Kotlin analysis to autobuild mode
- Close race in DevocionalProvider.initializeData re-entrancy guard
- Correct crashlytics log and exception ordering in MainActivity
- Add startup breadcrumbs and fix unbounded fallback-fetch timeout
- Revert to previous Bible version when switch fails due to no network
- Localize prayer/thanksgiving bloc error messages
- Update release notes with backup sync and mobile UI fixes

### 🚜 Refactor

- Extract Bible reader build() into focused widgets; fix backup viewer streak calc

### 🛡️ Security

- Add auto-generated CHANGELOG.md via git-cliff

### 💼 Other

- Google Drive backup sync, prayers menu overflow/translation fixes, offline Bible version fix
## [1.16.4+125] - 2026-09-01

### 💼 Other

- *(deps-dev)* Bump browserslist
- Bump version to 1.16.4+125, include dependabot browserslist security fix
## [1.16.3+124] - 2026-09-01

### 🚀 Features

- *(devocionales)* Make SliverAppBar height responsive
- *(backup)* Wire read_dates hotfix to Crashlytics and Analytics logging
- *(backup)* Add tappable CTA to session-expired snackbar
- *(test)* Add BackupBloc mock to DevocionalesPage widget tests

### 🐛 Bug Fixes

- *(android)* Remove explicit kotlin-android plugin to silence app KGP warning
- Add responsive minFontSize to verse card AutoSizeText
- *(emulator)* Force portrait orientation and fix boot wait syntax
- *(emulator)* Correct boot completion typo and force portrait orientation
- *(backup)* Preserve streak across Google Drive restore
- *(backup)* Migrate stale Drive backups missing read_dates
- *(backup)* Search Drive for the backup folder when no id is cached
- *(backup)* Log the already-migrated skip in the read_dates hotfix

### 💼 Other

- *(deps)* Upgrade plugins with Built-in Kotlin support; pin KGP 2.2.20
- *(deps)* Upgrade Firebase suite for AGP 9 / built-in Kotlin readiness
- *(android)* Restore KGP 2.3.20 — resolves Flutter deprecation warning
- Patch: fix backup restore streak preservation, improved notifications/session-expired prompt, layout fixes
- Patch: fix backup restore streak preservation, improved notifications/session-expired prompt, layout fixes
## [1.16.1+122] - 2026-08-30

### 🚀 Features

- *(ci)* Shard tests and parallelize coverage merging
- *(ci)* Create google-services.json from secret in CodeQL and build workflows
- *(devocionales)* Add hero background image behind the verse card
- *(devocionales)* Allow verse card text color override for hero image
- Add hero image section to devotional page with conditional rendering
- *(devocionales)* Collapsing full-bleed hero image with pinned toolbar

### 🐛 Bug Fixes

- Resolve CI pub get failure by aligning Flutter version and intl constraint
- Preserve deep-linked devotional across the first post-init rebuild
- *(ci)* Bump download-artifact to v8.0.1 to drop Node 20 deprecation
- Prevent bottom nav bar overflow when all tabs are enabled
- Migrate to android.app.Application and increase CodeQL build memory
- *(ci)* Free disk space in CodeQL workflow to prevent Jetifier OOM
- *(drawer)* Wrap label texts in Flexible to prevent overflow
- *(prayer)* Clear answered comment when comment is null
- Dispatch note delete before context.mounted check
- Bound devocional year-file fetch with a timeout
- *(devocionales)* Request WebP hero images instead of AVIF
- *(devocionales)* Fix drawer crash and broken tests found in code review
- *(devocionales)* Stop navigation from blocking on hero image fetch
- *(devocionales)* Pass imageRepository explicitly into navigation bloc
- *(devocionales)* Resolve RenderFlex overflow in drawer menu items
- *(devocionales)* Harden hero navigation
- *(devocionales)* Avoid blank hero on image download failure
- *(deps)* Restore PR 309 intl constraint

### ⚡ Performance

- *(devocionales)* Optimize image memory usage in DevocionalHeroSection

### 🚜 Refactor

- Centralize startup/fetch timing constants
- *(devocionales)* Move hero image to header banner, decoupled from verse
- *(devocionales)* Extract content widget builder and use colorScheme for icons

### 💼 Other

- *(devocionales)* Add trace prints for hero image feature
- New feature hero images
- New feature hero image, fix overflow on drawer, test coverage improved
## [1.15.0+116] - 2026-08-20

### 🚀 Features

- Auto-scroll text to follow TTS playback (shared)
- Highlight current verse during TTS (bible reader)
- Swipe-down chevron cue on TTS mini player
- Word-accurate TTS verse highlight via progress handler
- Section-level TTS highlight on the devotional page
- Continuous TTS scroll on devotional page + name timing constants
- Sentence-level TTS highlight on the devotional page
- *(tts-miniplayer)* Add pulse animation and tap-to-dismiss for swipe-down chevron
- Add multilingual RELEASE_NOTES.md for app update

### 🐛 Bug Fixes

- Patch websocket-driver CVE-2026-54466 via npm audit fix
- Patch high-severity npm advisories in functions/
- Scope CI pub-cache keys by trust boundary to prevent cache poisoning
- Add advanced CodeQL workflow for java-kotlin (Android)
- Upgrade to Flutter 3.47.0 stable, unpin CI Flutter version
- Skip PR comment job for Dependabot PRs
- Sync TTS verse highlight to word-based position estimate
- Scroll follows word-accurate verse index, not the estimate
- *(tts)* Preserve original text offsets when resuming or seeking
- *(tts)* Reset scroll index on content change and fix verse count cache
- *(tts)* Update drag icon to expand indicator for clarity

### 💼 Other

- Bump SDK versions and update dependencies
- New scroll and hightlight on tts
## [1.14.2+115] - 2026-08-13

### 🚀 Features

- Add update detection for downloaded Bible versions
- Add debug logging to BibleVersionRegistry version lookup
- *(bible-reader)* Add "Updated" chip to version items with updates
- Add update_available bubble translations and constants

### 🐛 Bug Fixes

- Clear update badge and overwrite stale version copy on re-download
- Correct redownload of currently-selected version and legacy hash false positive
- *(bible-version)* Correct update detection for legacy downloads without stored hashes
- Remove debug print statement in BibleReaderPage
- *(bible)* Wrap chapter text in FittedBox to prevent overflow on small screens

### 💼 Other

- ** `fix: preserve remoteUrl for updated downloaded versions`
- Update in_app_purchase_storekit to 0.4.11+1
- Chapter 100+ verses fix, new update Bible version
## [1.14.1+114] - 2026-08-12

### 🐛 Bug Fixes

- *(bible-normalizer)* Strip stray bullets and decode &quot; in LBLA text
- *(bible)* Handle MyBible-style morphology `<m>` tags in normalizer

### 💼 Other

- Fix LBLA regex
## [1.14.0+113] - 2026-08-11

### 🚀 Features

- Add downloadable remote Bible versions from bible_versions repo
- Allow NBS (French) in remote Bible version allowlist
- *(bible)* Replace version selection popup with navigation drawer
- *(bible)* Add Strong's tag normalization and parsing logic
- *(bible)* Carry per-version copyright disclaimer for remote versions
- *(bible)* Add KJ2000 version and update KJV assets
- *(bible)* Download versions inline from drawer, fix version-switch and stale-index bugs
- Add dismissible KJV/KJ2000 banner for English readers
- *(bible)* Make KJV/KJ2000 banner tappable to open the drawer
- Add IUserRecencyService for new-vs-existing user classification
- Move Bible versions panel from drawer to end drawer
- Remove white shadow effects from verse card text styles
- *(bible-reader)* Mark version download bubble as shown on tap

### 🐛 Bug Fixes

- Verse grid numbers overflow on small screens for chapters >100 verses
- Reuse app-level BackupBloc in onboarding to stop duplicate backup upload
- Ignore duplicate download requests for same version
- *(bible)* Use reader content language for remote versions fetch, not device locale
- *(bible)* Show download progress in drawer instead of closing immediately
- *(discovery)* Render Strong's number, identity statement, and greek word reference/application
- *(encounters)* Render the key verse as a leading swipeable page
- *(discovery)* Render hebrew_words on hebrew_exegesis cards
- *(encounters)* Key verse page now uses Discovery's theme-correct card surface
- *(bible)* Restore end drawer trigger and flag new remote versions
- *(bible)* Make drawer's new-version chip dismiss immediately on tap
- *(test)* Align testWidgets declaration formatting in key_verse_card_test

### 🚜 Refactor

- Drop hardcoded licensing allowlist for remote Bible versions
- Move download entry point into existing version popup menu
- Remove unused Strong's parsing and manage download subscription
- Extract markdown emphasis text into shared widget
- *(encounters)* Extract key verse card into dedicated widget
- *(encounters)* Reuse KeyVerseCard instead of a forked copy
## [1.13.2+111] - 2026-08-04

### 🚀 Features

- *(bubble)* Make feature bubbles reactive to manager state changes
- *(notes)* Unify add/view note icon and distinguish save feedback
- *(bible)* Differentiate note save messages and update icons
- *(notes)* Extract shared note editor and viewer components
- *(notes)* Unify note icons via shared NoteIcons and extract editor sheet

### 🐛 Bug Fixes

- *(bible)* Combine multi-verse copy/share into one block
- *(bubble,notes,bible)* Plug bubble listener leak, fix multi-verse sort, and confirm note saves via bloc state

### 💼 Other

- Fixes on notes, new bubble, verse sharing
## [1.13.1+110] - 2026-08-04

### 🚀 Features

- Add personal notes feature description to README
- Add Bible notes feature with BLoC pattern
- *(i18n)* Add empty state strings for prayer wall
- *(bible)* Refactor note side-effects to BlocListener and improve data robustness
- *(notes)* Show snackbar feedback upon note deletion
- *(bible)* Support jumping to scripture references from saved notes
- *(bible)* Display localized full book names in notes list
- *(bible)* Introduce read-only note viewer
- *(bible)* Introduce read-only viewer for existing notes
- *(bible)* Display full book names in verse note references
- *(backup)* Support Bible notes in backup and restore flows
- Migrate "new" feature bubble from TTS play buttons to notes
- *(backup)* Improve Bible note restoration robustness

### 🐛 Bug Fixes

- *(bible)* Harden scripture navigation and improve initialization robustness
- *(bible)* Pop routes before navigation and add debug logging
- Record daily visit on streak load to update streak on resume
- Set explicit colorScheme.outline per theme to fix invisible borders
- Address architect review findings on bible notes PR
- *(bubbles)* Use cancelable Timer for delayed animations

### 🚜 Refactor

- *(bible)* Conditionalize verse note indicator and update styling
- *(bible)* Swap order of edit and close buttons in note viewer
- *(bible)* Centralize book name resolution in BibleVerseFormatter
- *(bible)* Use BibleVerseFormatter for TTS book name resolution
- Reuse DevotionalFavoriteCard in notes page
- *(backup)* Extract Bible note restoration for testability
- *(bible)* Enforce strict validation for note deserialization

### 💼 Other

- New Bible notes, new badges, fix themes
## [1.13.0+109] - 2026-07-29

### 🚀 Features

- *(ci)* Wire translation_validator.dart into CI as a check-only gate
- *(ci)* Add README link validation, fix silent CI failure modes
- *(devotional)* Add persistent personal notes for devotionals
- *(i18n)* Add localized strings for notes feature
- *(notes)* Localize hardcoded strings in note widgets
- *(backup)* Include devotional notes in Google Drive sync
- *(backup)* Include notes in backup settings summary
- *(notes)* Add ability to delete devotional notes
- *(i18n)* Add empty state translations for prayer wall
- *(i18n)* Add strings for favorites confirmation and note actions
- *(i18n)* Add confirmation message for removing favorites
- *(ui)* Add favorite removal confirmation and devotional notes entry point
- *(i18n)* Add localized strings for prayer wall empty state
- *(notes)* Migrate devotional notes management to BLoC + Repository pattern
- *(notes)* Add loading_error translation and update BLoC test harness
- *(notes)* Handle malformed stored data gracefully with error logging
- Add prayer wall translations and harden notes repository
- *(notes)* Add validation for devotional notes
- *(i18n)* Add note validation error strings
- *(notes)* Add "My Notes" entry to side drawer
- *(notes)* Implement DevocionalesNotesPage to list devotionals with notes
- *(i18n)* Add empty state strings for notes list
- *(i18n)* Add localized prayer wall empty state strings
- *(favorites)* Require confirmation when removing a devotional from favorites

### 🐛 Bug Fixes

- *(ci)* Stop trusting lcov --list for coverage gap report
- *(ci)* Correct stale README stats and repair auto-update sed patterns
- *(ci)* Replace fragile README sed patches with a single Python script
- *(ci)* Trigger Flutter CI on README/scripts changes too
- *(ci)* Auto-generate lib/ and test/ tree diagrams, drop dead content
- *(ci)* Auto-update app version and copyright year in README
- *(bible_reader_core)* Validate reference before initializing DB connection
- *(security)* Use exact hostname match for badge URL skip, not substring
- *(ci)* Declare missing job deps in comment step, add actionlint pre-commit check

### 🚜 Refactor

- *(spiritual-stats)* Rewrite streak calculation using Set-based lookup

### 💼 Other

- New notes, tts double hindi fix, config for deleting favorites
## [1.12.6+108] - 2026-07-22

### 🚀 Features

- *(analytics)* Log encounter_completed event when user finishes an encounter

### 🚜 Refactor

- *(analytics)* Split encounter_action into distinct funnel events

### 💼 Other

- New data info for encounters
## [1.12.5+107] - 2026-07-22

### 🐛 Bug Fixes

- *(ui)* Render scriptureConnections in CinematicSceneCard
- *(contract)* Add scriptureConnections to cinematic_scene contract map
- *(ui)* Make donation header height responsive instead of crash-prone clamp
- *(onboarding)* Backfill onboarding_complete for pre-existing users
- *(bible-reader)* Stop duplicating version name in copy/share text
- *(onboarding)* Don't permanently skip backfill on transient stats-read failure
- *(docs)* Update Google Play Console checklist for debug symbol handling
- *(android)* Mitigate and instrument black-screen-on-resume freeze
- *(tts)* Prevent crash when native TTS engine isn't ready for setVoice
- *(dependencies)* Update flutter_cache_manager to version 3.4.2

### 🚜 Refactor

- *(onboarding)* Extract shared engaged-user devotional threshold
- *(startup)* Consolidate startup print() calls behind one helper

### 💼 Other

- Fix card on encounters, crashlytics erros, blackscreen telemetry, onboarding flow fixed only for new users
## [1.12.4+106] - 2026-07-16

### 🚀 Features

- *(debug)* Force reload bypasses cache and version checks for Discovery/Encounters
- *(onboarding)* Wire onboarding flow behind DI + remote config gate
- *(onboarding)* Add Skip option and step progress indicator to welcome flow
- *(onboarding)* Enhance theme selection page layout and add tests for responsiveness
- *(onboarding)* Add system back navigation and Skip to theme step
- *(onboarding)* Guard backup step navigation, add safeguard button + tests
- *(onboarding)* Add concurrency approach review document for OnboardingBloc refactor
- *(onboarding)* Implement isBackNavigationBlocked function and add unit tests
- *(onboarding)* Add confetti animation to completion page
- *(onboarding)* Add tap gesture to complete onboarding and enhance accessibility

### 🐛 Bug Fixes

- *(debug)* Force reload downloads all studies, not just the first
- *(security)* F-04/F-08 - disable cleartext+user-CA trust, drop unused permission
- *(i18n)* Correct onboarding_setup_theme_configured key mismatch
- *(onboarding)* Resolve overflow on complete page from Back header
- *(onboarding)* Disable Back on completion screen once backup connected
- *(theme)* Update button foreground color to improve visibility
- *(onboarding)* Derive completion button text color from theme instead of hardcoding
- *(onboarding)* Simplify color retrieval for elevated button text
- *(encounter-card)* Prevent clamp crash on short screens in visual header
- *(crashlytics)* Downgrade image codec decode failures to non-fatal
- *(crashlytics)* Downgrade Invalid image data codec errors to non-fatal
- *(notifications)* Catch errors in authStateChanges listener
- *(notifications)* Isolate plugin bootstrap failures from authStateChanges listener
- *(ci)* Prevent false dart fix failures on PRs with no changes
- *(ci)* Exclude generated .mocks.dart from dart fix PR diff check

### 🚜 Refactor

- *(onboarding)* Move persistence logic from OnboardingBloc to OnboardingService
- *(onboarding)* Replace particle animation with Lottie celebration animation and adjust layout spacing
- *(onboarding)* Simplify layout and scaling on completion page
- *(onboarding)* Optimize layout for onboarding welcome page
- *(notifications)* Inject Firebase deps into NotificationService for testability
- *(notifications)* Dedupe Firebase wiring and add FCM retry/backoff coverage

### 💼 Other

- Add onboarding step indicator translation key
- Bug fixes crashlytics, update onboarding, update notificacion service DI
## [1.12.3+105] - 2026-07-08

### 🐛 Bug Fixes

- *(discovery)* Add scriptureReferences field and update JSON parsing
- *(about)* Ensure launch URLs use non-www host to avoid app link conflicts

### 💼 Other

- New verse on each discovery card, fix google playstore warning, and deep links contingency
## [1.12.2+104] - 2026-07-07

### 🚀 Features

- *(skills)* Add flutter coding agent and senior architect reviewer skills
- *(skills)* Add flutter coding agent and senior architect reviewer skills
- *(icons)* Add Habitus faith icon to assets
- *(about)* Enhance About page with auto-fit tuning and new features section

### 🐛 Bug Fixes

- *(progress)* Refresh stats on tab return and fix broken card navigation
- *(progress)* Refresh stats when returning from the favorites page
- *(stats)* Unlock favorites achievements when favorites change
- *(progress)* Stop full-page spinner flash on background reloads
- *(encounters)* Stop showing raw exception text as the load error
- *(discovery)* Stop showing raw exception text as the load error
- *(backup)* Stop leaking raw exceptions in backup error messages
- *(prayer_wall)* Localize error messages instead of hardcoded English
- *(onboarding)* Localize error dialog instead of hardcoded English/raw exceptions
- *(onboarding)* Use BackupError.localizedMessage in backup config step
- *(encounters)* Fix raw exception leak in the study-load error path too
- *(stats)* Lock SpiritualStatsService's read-modify-write cycles
- *(stats)* Lock importStatsFromJson, extract shared _mutate helper
- *(test)* Register LocalizationService in devocional_provider_test
- *(progress)* Stop leaking raw exception text in stats-load snackbar
- *(settings)* Refresh Gold Supporter section on tab return
- *(bible_reader)* Guard against emitting to a disposed controller
- *(supporter)* Defer purchase-success dialog while Supporter tab is backgrounded
- *(supporter)* Never auto-show the celebration dialog, only a direct tap
- *(supporter)* Pet header taps to Settings; fix invisible switch thumb
- *(encounters)* Fix RenderFlex overflow on encounter card
- *(encounters)* Scale visual header height with screen width, not a fixed constant
- *(devocionales)* Update error messages to use translation keys for consistency
- *(i18n)* Add error messages for updating thanksgivings and testimonies in multiple languages and refactor for correct error handling
- *(i18n)* Update habitus faith tagline translations for consistency and clarity across multiple languages
- *(i18n)* Add missing newlines at the end of multiple language files and format code in About page for better readability
- *(urls)* Update URLs to remove 'www' for consistency across About, Contact, and Settings pages
- *(about)* Adjust scaling parameters for improved layout responsiveness
- *(i18n)* Simplify app description in multiple language files for clarity

### 🚜 Refactor

- *(discovery)* Centralize error fallback via a localizedMessage getter
- *(backup)* Mark raw-text BackupError messages explicitly
- *(onboarding)* Remove now-redundant errorContext field
- *(onboarding)* Remove dead OnboardingErrorCategory field
- *(encounters)* Converge EncounterError onto the localizedMessage pattern
- *(devocionales)* Replace SnackBar with AppSnackBar for error and success messages
- *(snackbars)* Unify snackbar implementation using AppSnackBar across contact and answer prayer modal pages

### 💼 Other

- Progress page links and data fix, new about us page, fix error meesage snack and current snacks
## [1.12.1+103] - 2026-07-06

### 🚀 Features

- *(progress)* Add isActive listener to manage visibility of achievement tip

### 💼 Other

- Progress page hint bubble fix
## [1.12.0+102] - 2026-07-06

### 🚀 Features

- *(notification)* Add debug logger for improved debug output in NotificationService
- *(discovery)* Integrate DevocionalProvider and improve test setup for DiscoverySectionCard
- *(navigation)* Implement AppNavigationShell with persistent bottom navigation bar
- *(navigation)* Enhance AppNavigationShell with global key and selectTab method for improved navigation
- *(navigation)* Make Supporter tab always visible, decoupled from remote config
- *(favorites)* Open a dedicated read-only page instead of the full pager
- *(encounters)* Add scrollbar to the encounters list view
- *(snack_bar)* Implement reusable AppSnackBar for consistent feedback across pages

### 🐛 Bug Fixes

- *(ui)* Handle empty bible version in encounter card widget
- *(ui)* Update copyright disclaimer to use selected bible version
- *(ui)* Update key verse card to display selected bible version
- *(notification)* Enable notifications by default and improve snackbar error handling
- *(notification)* Resilient FCM token retry and English release-safe logging
- *(notification)* Handle null user in NotificationConfigPage with anonymous sign-in retry
- *(navigation)* Manage TTS lifecycle on tab change to prevent audio conflicts
- *(tts)* Close bible reader miniplayer when playback completes
- *(navigation)* Show persistent shell bottom nav bar on FavoritesPage
- *(notifications)* Increase timeout and memory for daily devotional notification
- *(localization)* Persist auto-detected locale on first launch
- *(localization)* Correct unsupported locale in SharedPreferences
- *(localization)* Persist locale on unsupported saved code, guard writes
- *(localization)* Enhance error handling for locale persistence and improve test coverage
- *(localization)* Wrap Crashlytics call in unawaited, add DI guard tests
- *(progress_page)* Adjust padding in content layout for improved UI
- *(functions)* Pin uuid to 11.1.1 via override to resolve CVE-2026-41907
- *(notifications)* Retry FCM token fetch on connectivity/resume, not just cold-start burst
- *(notifications)* Add missing German and Filipino push notification translations
- *(encounters)* Restore bottom nav bar after encounter welcome screen
- *(encounters)* Attach explicit ScrollController so the scrollbar renders

### 🚜 Refactor

- *(notification)* Replace developer.log with debugPrint for improved logging
- *(notification)* Replace developer.log with debugPrint for background FCM message handling
- *(navigation)* Remove DiscoveryBottomNavBar and related tests; enhance AppNavigationShell functionality
- *(tts)* Update TtsAudioController to reattach FlutterTts instance and enhance native callback handling
- *(navigation)* Single tab source of truth and cached nav badges
- *(localization)* Inject DeviceLocaleProvider instead of test-only param
- *(devocionales_page_drawer)* Remove unused imports and prayers/discovery features from drawer
- *(navigation)* Replace direct navigation to ProgressPage with AppNavigationShell for consistency
- *(snack_bar)* Migrate remaining feedback snackbars to AppSnackBar, fix duration to 3s
- *(notifications)* Migrate remaining SnackBars to AppSnackBar, drop stale comment

### 💼 Other

- New freezed botton bar, new funciont, fcm improvements, drawer refactor, new verse update discovery Bible studies
## [1.11.7+101] - 2026-06-30

### 🚀 Features

- Add iOS Firebase config (GoogleService-Info.plist) for com.develop4god.devocional.appstore

### 🐛 Bug Fixes

- Bump iOS deployment target to 13.0
- Correct GoogleService-Info.plist path in pbxproj (was Runner/Runner/...)
- *(ios)* Align bundle identifier across pbxproj and Info.plist
- *(ui)* Prevent VisualHeader overflow on landscape orientation
- *(ui)* Prevent Column overflow on encounter intro page in landscape

### 🚜 Refactor

- *(tests)* Remove unused verseCopied logic and update test descriptions

### 💼 Other

- Untrack GoogleService-Info.plist, add to gitignore (exposed key already rotated)
- Verse copy/ fix encounters overflow/ IOS readiness
## [1.11.6+100] - 2026-06-24

### 💼 Other

- Encounters card refactor
## [1.11.5+99] - 2026-06-24

### 🐛 Bug Fixes

- *(encounters)* Close EncounterCard field-rendering gaps + add contract

### 💼 Other

- Fix for encouters card not showing the title, subtitles or verses, refactor
## [1.11.4+98] - 2026-06-21

### 🚀 Features

- *(encounters)* Resolve verse text via selected Bible version with JSON fallback

### 💼 Other

- Normalize Bible verse text during resolution
- Add debug logging for VerseResolver exceptions
- New verse resolver for encounters with the current user Bible on drawer, fix the NTV and ESV on drawer
## [1.11.3+97] - 2026-06-19

### 🚀 Features

- Add flutter coding agent execution rules for project consistency
- Add NTV Spanish Bible translation database asset
- Add Nueva Traducción Viviente (NTV) Bible version support
- Add NTV bible version support for Spanish
- Add ESV Bible SQLite database asset

### 🐛 Bug Fixes

- Remove Step 5 sync-back from createBackup

### 💼 Other

- Add English Standard Version (ESV) support
- Streak sync fixed/new ESV en and NTV es Bibles
## [1.11.2+96] - 2026-05-31

### 🚀 Features

- Add answered prayers to backup content summary
- Add backup_viewer.py for inspecting and comparing backup files
- Sync answered prayer counts and update backup viewer logic
- Add debug streak section and interface
- Add streak manipulation tools to debug page

### 🐛 Bug Fixes

- Add answered prayers to backup and verify streak backup logic
- Add edit tracking for prayers, thanksgivings, and testimonies in backup

### 🚜 Refactor

- Integrate `ISpiritualStatsService` into `PrayerBloc` for stats tracking
- Reorder answered prayers in backup summary list

### 💼 Other

- Answered prayers fixes and edit prayers, thanksgiving , testimonies for backup feature
- Answered prayers fixÂ/ testimony, prayers, thanksgiving edit on backup feature
## [1.11.0+94] - 2026-05-31

### 🚀 Features

- Add Tagalog support for Bible text formatting and TTS
- Add jni plugin support and update dependencies in pubspec.lock
- Add Tagalog (tl) language support
- Reorder and update supported languages in `constants.dart`
- Improve IAP service robustness and purchase handling
- Implement automatic initial backup creation in `BackupBloc`
- Introduce `ILocalizationService` interface and refactor dependencies
- Add remote config toggle for backup settings
- Introduce BackupKeys class for centralized backup field management
- Add `show_backup_section` remote config and use `BackupKeys` in tests
- Expand backup/restore categories and improve data persistence
- Trigger discovery and encounter data reload after backup restore
- Improve Google Drive sign-in flow and error handling
- Improve devotional loading logic and state synchronization
- Rename 'tl' language key to 'fil' for Filipino
- Update Tagalog language code to Filipino and add MBB05 Bible version
- Improve Bible text sanitization and UI for version selection
- Enhance TTS voice filtering and localization in debug section
- Include testimonies in backup and restore operations
- Integrate `VoiceDataRegistry` for Tagalog/Filipino TTS voices
- Enhance logging for spiritual stats during backup and restore
- Synchronize spiritual stats and navigation after backup restore
- Implement multi-device backup merging for `SpiritualStats`
- Add new Google Drive and shield check JSON files
- Add localization strings for Google Drive backup and restore status
- Enhance backup and restore UI with Lottie animations and specific signing-in state
- Emit success state after creating initial backup during Google Drive sign-in
- Add Bible version and marked verses to Google Drive backup
- Sync selected Bible version after successful backup restore
- Enhance deep link handling and improve tracking on DevocionalesPage
- Distinguish between new purchases and restored items in IAP flow
- Reload Bible version after backup restoration
- Transition favorite devotionals backup to version-independent IDs
- Add debug logging for backup schedule timing
- Enable backup feature and remove redundant initialization logic
- Add debug tool to force auto-backup bypass
- Add sign-out logic to prevent inconsistent backup frequency state
- Disable backup feature by default
- Remove backup feature initialization and disable by default
- Implement Protestant 66-book canon filtering
- Add canon filter logging and update book number test values
- Add Bible section titles to reader UI
- Add initialization check for devocional provider before backup
- Add timeout handling for provider initialization in backup process
- Add JNI to Flutter FFI plugin list
- Integrate BackupContentSummary into backup states and expand test coverage
- Display summary of items included in backup
- Include read devotionals in backup content summary
- Add read devotionals to backup content summary
- Add StartupMigrationService and legacy gap fix migration
- Add Firebase Crashlytics monitoring to AppInitializer startup
- Add app_links and gtk plugins to project dependencies
- Migrate deep links to Android HTTPS App Links
- Add firebase_installations and update project dependencies
- Add backup route support to DeepLinkHandler

### 🐛 Bug Fixes

- Prevent text overflow in backup protection status
- Stop reporting transient network errors to Firebase Crashlytics
- Update default locale from Spanish to English in localization tests
- Localize backup error messages and update error keys
- Update Filipino translations for consistency and accuracy
- Update Tagalog/Filipino voice identifiers and descriptions in `VoiceDataRegistry`
- Prevent exceptions in `_downloadCurrentDriveBackup` and ensure null safety
- *(deep-link)* Self-flush pending link on next frame for warm-start FIAM taps
- *(deep-link)* Extend deduplication window to 10 seconds and improve comments
- Simplify preferred Bible version retrieval in Google Drive backup service
- Ensure Bible version is reloaded before favorites and stats after backup restore
- Ensure favorites reload on version change and update backup tests
- *(backup)* Prevent race condition corrupting favorites on cold start
- Update spiritual stats restore logging structure in Google Drive service
- Apply black screen and legacy gap migration fixes
- Remove autoVerify from Firebase In-App Messaging intent filter
- Update firebase installations to use firebase_app_installations package
- Refine spiritual stats handling in GoogleDriveBackupService
- Enhance spiritual stats restoration to support multiple backup formats
- Restore merged spiritual stats during automatic backup to prevent streak reset

### 🚜 Refactor

- Improve step indicator in `SupporterGoldPurchaseDialog`
- Remove Google Drive storage info functionality
- Localize Google Drive backup folder name and update backup filename
- Remove redundant blank line in `localization_service.dart`
- Make Google Drive backup filename dynamic and localized
- Remove singleton pattern and implement dependency injection for `GoogleDriveAuthService`
- Move backup-related services to a dedicated `backup` directory
- Delegate TTS voice assignment logic to `TtsService`
- Rename Tagalog formatter to Filipino and add Japanese version names
- Remove redundant SharedPreferences verification in `GoogleDriveBackupService`
- Reorganize constants into dedicated directory structure
- Simplify favorite devotional ID storage in Google Drive backup
- Remove redundant blank line in `google_drive_backup_service.dart`
- Extract backup settings logic to a dedicated service
- Adjust daily backup frequency interval
- Improve backup initialization flow and update settings key
- Clean up formatting and remove unused auto-backup logic
- Remove auto-backup functionality from spiritual stats service
- Remove automatic backup check on startup
- Centralize backup interval constant
- Use constant for daily backup interval
- Translate debug logs to English and refine backup frequency logic
- Remove unnecessary blank line in _initNonCriticalServices method
- Migrate backup feature flag to Remote Config and clean up imports
- Reformat mockFoundBook map in bible_reader_service_test.dart
- Remove manual backup UI from backup settings
- Remove manual backup restoration functionality
- Centralize backup state loading logic in BackupBloc
- Centralize backup state loading logic in BackupBloc
- Centralize backup summary logic and discovery progress keys
- Update startup timeout signature and explicit diagnostics casting
- Update legacy gap migration to target single-entry gaps
- Move legacy gap migration logic to StartupMigrationService
- Implement IStartupMigrationService and enhance dependency injection
- Expand startup migration to detect leading gaps
- Update legacy gap migration to version V3
- Centralize SharedPreferences keys into constant classes
- Rename startup migrations to fixes and update gap fix terminology
- Update debug log prefix in SpiritualStatsService
- Change read-gap migration to run idempotently on every startup
- Simplify spiritual stats restore logging in GoogleDriveBackupService
- Clean up spiritual stats restoration logging in GoogleDriveBackupService
- Move "new feature" badge from Bible to Settings icon

### 💼 Other

- Update Tagalog (tl) translations for app preparing message and drawer title
- Update Tagalog translation for app title in `tl.json`
- Update Tagalog translation for "my_intimate_space_with_god"
- Update Tagalog (tl) Bible version priorities in `constants.dart`
- Update Tagalog (tl) Bible version priorities in `constants.dart`
- Update default locale to English in `LocalizationService`
- Refactor header layout in `SupporterGoldPurchaseDialog`
- Update application language description across multiple locales
- Update project path in `tests.sh`
- Update `vm_service` to version 15.2.0
- Improve Filipino (fil) translations and phrasing
- Improve Filipino (fil) translations and phrasing
- Add logging for orphan favorite IDs in DevocionalProvider
- Add saved_verses translation key
- Add saved_verses translation key in Arabic
- Add empty state translation keys for prayer wall
- Bump version to 1.10.2+93
- Add Kotlin compiler session artifact
- Update dependencies and remove compiler session artifact
- New backup feature/new language fil/
## [1.10.2+92] - 2026-04-14

### 🚀 Features

- Add Arabic notification support and randomize notification images
- Add randomized notification variants and update ESLint config

### 🚜 Refactor

- Update comments and logging messages to English for consistency
- Remove silence watchdog logic from TtsAudioController

### 💼 Other

- Watchdog remove, fix functions
## [1.10.1+91] - 2026-04-14

### 🐛 Bug Fixes

- Downgrade transient TLS and connection-drop errors to non-fatal in Crashlytics

### 💼 Other

- Testimony test helper refactor, remove gray theme badge
- Crashlytic fix for network error in encounters images + fix TTS test + deleted bubble on devocionales_drawer theme selector
## [1.10.0+90] - 2026-04-13

### 🚀 Features

- Add Gray theme (Serenidad) based on Cyan template with 27 validation tests
- *(encounters)* AVIF-first image architecture with persisted PNG fallback
- *(encounters)* Add Arabic and German localizations for "Peter Walking on Water"
- *(tts)* Enhance Arabic voice support and selection logic
- *(i18n)* Dynamically discover supported languages from i18n directory
- Enhance `translation_validator.dart` with consolidated reporting and reverse validation
- Refactor `ThemeSelectorCircleGrid` into an animated pill-shaped selector
- Redesign `ThemeSelectorCircleGrid` with a compact pill UI and modal bottom sheet
- Add RTL support for floating action button and enhance date formatting for Arabic
- Refactor `BibleReaderPage` app bar and add Arabic language support
- Update Arabic Bible version names and expand registry tests
- Suppress version abbreviations for Arabic Bible versions
- Enhance TTS reliability and Arabic voice support
- *(bible-reader)* Add TTS playback with Arabic voice reliability fixes
- Implement text chunking for TTS playback to prevent engine failures
- *(tts)* Implement rate-aware chunking and dynamic timeouts
- Improve TTS reliability and miniplayer lifecycle in `BibleReaderPage`
- Extract TTS text-chunking logic into `TtsChunkProcessor`
- Enhance TTS reliability and add "new feature" UI indicators
- Abstract authentication service and integrate `IAuthService` in `PrayerWallPage`
- Refine TTS duration estimation for Japanese and Chinese

### 🐛 Bug Fixes

- *(encounters)* Resolve base filename to full AVIF URL before precache
- *(encounters)* Resolve base filename to full AVIF URL before precache
- *(encounters)* Update completion image for Peter Walking on Water study
- *(ui)* Increase max lines for theme name in drawer
- Prevent memory leaks and crashes in `PostSplashAnimationController`
- Ensure saved voice is applied to the active TTS controller instance
- Ensure saved voice is applied to the active TTS controller instance
- Improve TTS multi-chunk handling and resume logic
- Eliminate progress slider drift in multi-chunk TTS playback
- Improve TTS reliability and prevent silent utterance failures on Android
- Harden TTS services and text formatting with null-safety and defensive checks
- Add safety guards and comprehensive regression tests for TTS text formatting
- Prevent double-pop bug when TTS playback completes in `BibleReaderPage`
- Rewrite `errors.sh` to automate formatting, fixing, and analysis
- Suppress permission errors when cleaning up older log files in `tests.sh`
- Enhance encounter caching and harden TTS modal navigation tests all the copilot review gaps
- Apply tts_rtl_fix.md - move 400ms guard, simplify watchdog to detect-only
- Add jni to Flutter FFI plugin list in generated_plugins.cmake
- Update copilot instructions to reflect changes in required file readings
- Implement TTS silent-utterance retry and optimize lifecycle state handling
- Refine TTS audio lifecycle and background behavior
- Harden TTS playback logic and resolve "zombie" engine states on Android
- Prevent duplicate pop attempts in TTS mini-player modals
- Implement deep link deduplication and improve cold start handling
- Update CJK character rate for TTS duration estimation
- Adjust Japanese TTS duration estimation rate
- Improve TTS reliability with watchdog and refine lifecycle handling

### 🚜 Refactor

- Remove bundled asset fallbacks from `EncounterRepository`
- Update Arabic Bible translation names for NAV and SVDA
- Enhance `AnimatedFabWithText` with `Row` layout and RTL support
- Standardize and simplify reset and testing utility methods
- Enhance TTS controller stability and fix `BuildContext` usage
- Introduce `IAnalyticsService` interface and add Bible-related tracking
- Harden TTS mini-player auto-close logic in Bible and Devotional presenters
- Consolidate TTS miniplayer modal state logic in Bible and Devotional presenters
- Decoupling code by replacing `AnalyticsService` with `IAnalyticsService` interface
- Extract TTS duration estimation logic into a dedicated utility service

### 🛡️ Security

- Update GitHub Action versions and refactor Trivy security scan

### 💼 Other

- Update dependencies, SDK versions, and add JNI support
- Implement `SKILL.md` execution rules and synchronize Copilot instructions
- Bible TTS, AR language, Grey theme, Deeplink fix
## [1.9.4+89] - 2026-04-01

### 🚀 Features

- Add German (de) language support
- Update German premium voices in `VoiceMetadata` registry
- Wrap ProgressPage body in SafeArea
- Prevent transient network errors from reporting as fatal crashes
- Prevent transient network errors from reporting as fatal crashes

### 🐛 Bug Fixes

- Add missing German voice preferences and fix pre-existing test for new language
- Address code review - use English comments for German voice entries and fix version count comment
- Apply PR review feedback - null-guard, test rename, and no-op resetCache default
- Expand transient network error detection to include file system errors
- Capture lcov summary from stdout instead of stderr in CI workflow

### 🚜 Refactor

- Remove unused PathProviderPlugin registration
- Remove unused PathProviderPlugin registration
- Remove unused PathProviderPlugin registration
- Remove leading underscores from local helper functions in DebugPage
- Modularize `DebugPage` by extracting sections into dedicated widgets

### 🛡️ Security

- Pin Flutter version and improve workflow dependency logic
- Optimize Flutter CI workflow and improve job concurrency

### 💼 Other

- Update dependencies and increment version to 1.9.3+88
- Update async dependency to 2.13.1
- Set 1-second duration for developer mode SnackBar in about page
- Add support for German (de) language and Bible versions
- Add support for German (de) language and Bible versions
- Add German language support for Bible text TTS normalization
- Add German language support for Bible text TTS normalization
- Move debug branch flags from `Constants` to `DebugFlags`
- Update pre-commit hook to improve reliability and performance
- Complete new localization on german, crashlytics errors for chache and fetch encounters
## [1.9.3+87] - 2026-03-25

### 🚀 Features

- Add unlock animation for newly completed encounters in EncountersListPage
- Implement predictive image preloading and background prefetching for Encounters

### 💼 Other

- Encounters grid view locking not enforced for locked encounters
- Navigate back to list after discovery study completion celebration
- Increase encounter unlock animation display duration to 4 seconds
- Fix typo in Spanish encounter and prevent state updates after TTS disposal
- Encounters fix crashlytics, overlay showing bartimaneus available, crash tts disposal.
## [1.9.2+86] - 2026-03-25

### 🚀 Features

- Dynamic discovery of available devotional years from remote index

### 🐛 Bug Fixes

- Buffer deep links when navigator context is null (cold start / splash)
- Replace Image.asset placeholders with Container and use unawaited precache (Crashlytics fixes)

### 💼 Other

- Enhance deep link handler with verbose logging and stack traces
- Crashlytics errors/deep link and new intelligent fetch for 2025 and 2026 devotionals
- Fix: deeelink/crashlytics bartimeus/intelligent fetch for 2025,2026 and next
## [1.9.0+84] - 2026-03-21

### 🚀 Features

- Replace flag emoji method with Constants for language flags
- Add Hindi language support with initial translations and share message updates
- Add support for Hindi language and improve TTS stability
- Implement Encounters feature (data layer, BLoC, UI, tests)
- Implement Encounters feature
- Add Encounters feature and background image support
- Support Hindi and enhance Encounters UI
- Overhaul Encounters UI with a modern, immersive aesthetic
- Redesign Encounters UI with a "Visual First" approach
- Enhance Encounter card scrolling and UI feedback
- Redesign Encounters list UI and enhance card widgets
- Redesign Encounters list with a high-impact, modern aesthetic
- Enhance Encounters feature with cinematic intro and dynamic images
- Implement localization and UI refinements for Encounters
- Implement Firebase In-App Messaging deep link handling for Android & iOS
- Implement deep link handling and enhance Hindi TTS support
- Standardize localization and enhance translation validation
- Update Peter encounter content and clean up code
- Refine Encounters list UI and update Spanish fallback content
- Refine Encounters list UI and update Spanish fallback content
- Add Peter's "Walking on Water" encounter and improve UI loading states
- Enhance fallback asset handling for encounters with multi-language support
- Implement devotional cache invalidation via index.json
- Implement version-aware caching for encounter studies
- Implement bundled asset fallback for encounter images
- Implement Prayer Wall feature (TASK-001 to TASK-009)
- Add ownerUid field and PrayerWallPendingUpdated test cases
- Add prayer_wall deep link and use Constants.prayerWallPageSize
- Implement prayer wall enhancements - deep link navigation, pull-to-refresh, and optimized Firestore writes
- Reuse Bible studies UI patterns for encounters feature
- Update testament localization and logic in Encounters
- Redesign entry button in `EncounterIntroPage` with a modern gold gradient
- Enhance Encounter UI with gold-themed styling and multi-language exit support
- Add deep link support for Encounters and refine supporter navigation
- Enhance deep link handling for Android while app is running
- Improve deep link handling for active Android instances
- Update Encounter UI with gold-themed styling and improved text visibility
- Refactor encounter detail navigation and implement responsive exit button
- Update dependencies and remove unused path_provider_foundation plugin
- Update exit button functionality to navigate back on press
- Implement animated exit transition for Encounter Detail page
- Update Encounter completion UI with delayed success message
- Add control over scroll indicator visibility in encounter cards
- Implement persistence for encounter completion progress
- Implement abstract interface for Encounter progress service and improve completion UI
- Enhance encounter completion button with gold-themed styling
- Increase gold shadow visibility in Encounter Detail UI
- Refactor Encounter image resolution to use encounter-specific directories
- Integrate `ThemeBloc` and `AnnotatedRegion` into `EncountersListPage`
- Implement encounter progression locking and welcome screen
- Internationalize encounter welcome page and update translation validator documentation
- Add unlocked.json for encounter animations and graphics
- Add release date support to encounter cards
- Register PathProviderPlugin and update dependencies in pubspec.lock
- Implement encounter locking, image pre-caching, and UI enhancements
- Simplify completed encounter card display by removing badge
- Reposition emoji display and add floating toggle button for grid/list view
- Replace CardSwiper with PageView in encounter reader
- Add friendly locale names and enhance voice selector debug info
- Refactor Bible version identifiers and add Hindi display names
- Allow devotional updates during initial navigation state
- *(bible-reader)* Add Hindi language support for chapter and verse prefixes
- *(tts)* Improve Hindi Bible reference parsing and formatting
- *(ui)* Add "new" feature badge to Encounters icon in bottom bar
- *(tts)* Add specialized normalization for Hindi text processing
- Add new Kotlin compiler configuration file
- Refactor "Rate App" drawer item and add share bubble tracking

### 🐛 Bug Fixes

- Address code review - use resetModalState() instead of dispose() for TTS modal, remove dead code
- Resolve language/version mismatch and enhance error recovery
- Update share message and correct mixed language in gratitude message
- Correct mixed language in Portuguese strings and enhance share message
- *(i18n)* Correct whitespace in Hindi "donate" description
- Update flutter analyze command to include fatal-infos flag
- Refine TTS modal behavior and controller state
- Completion fires on button tap not swipe; remove recursive lang fallback
- Apply pr223_fixes 3-7 — state equality, 10-card fallback, 4 widget tests
- Encounter bugs — spinner, fallback files, images, completion Lottie, AutoSizeText
- Add late modifier to onTap callback in EncountersListPage
- Add explicit type annotation to `imageUrl` in `EncounterIntroPage`
- Update language count tests to include Hindi (7 languages) + add PR architecture documentation
- Address code review - cache supportedLanguages, assert exact Devanagari description
- Make build_runner optional in CI workflow (package version incompatibility)
- Remove dead loadedApiYears set left over from refactor
- Correct formatting in analyze_report.txt output
- Resolve encounter tests and UI issues
- Address PR review — DI factory, Firestore rules, originalText cleared after masking, watchMyPendingPrayer wired up
- Address code review - optimize indexOf, add try-finally in test
- Adjust position of progress indicator for improved spacing
- Remove await from Navigator.push in prayer_wall deep link handler to prevent test timeout
- Improve layout responsiveness and prevent overflow in encounters list
- Update language flags to use single country representation
- Use explicit UTF-8 decoding for devocional API responses
- Use explicit UTF-8 decoding for devocional API responses
- Update Hindi Bible version database filename in registry
- Update copyright text retrieval to use display name and extract version code for Latin-script languages

### ⚡ Performance

- Optimize Discovery index fetching with caching and revalidation

### 🚜 Refactor

- Extract FontSizeController, LocalizedDateFormatter, SalvationPrayerDialog, and TtsModalManager from devocionales_page.dart
- Rename TtsModalManager → DevocionalTtsMiniplayerPresenter + extract DevocionalTtsTextBuilder
- Extract DevocionalNavigationHelper — deduplicate next/previous navigation (130+ lines → 24 lines)
- Extract PostSplashAnimationController — animation state management (SRP)
- Extract VoiceDataRegistry (SOLID on voice selector) + add Hindi TTS premium voices + complete hi.json translations
- Improve readability of translation validation output
- Rename `DiscoveryBottomNavBar` to `BottomNavBar`
- Rename devotional card and improve encounters list layout
- Remove `DiscoveryActionBar` widget
- Replace DiscoveryActionBar with DiscoveryActionsBar and update Discovery UI
- Simplify filename fallback logic in `EncounterRepository`
- Clean up `DevocionalProvider` logic and improve test code style
- Optimize language switching and clean up code formatting
- Resolve `use_build_context_synchronously` lint in `ApplicationLanguagePage`
- Simplify `DiscoveryRepository` cache logic to session-based fetching
- Replace prayer wall stream with fetch + cancel pending stream on status change
- Refine EncounterProgressService interface and add DI architecture tests
- Cleanup encounter image utility and enhance unit tests
- Remove emoji scale animation from Encounter intro page
- Relocate discovery detail page to bible studies directory
- Reorganize page files into domain-specific subdirectories
- Remove Prayer Wall entry from drawer
- Clean up formatting in voice data registry and selector dialog
- Update Hindi Bible version codes and add encoding debug logs
- Replace error state UI with loading indicator in DevocionalesPage
- Centralize Bible version abbreviation logic and improve Hindi TTS formatting
- Use dbFileName for version identification and update Hindi localization
- *(bible-reader)* Enforce SRP on BibleVersion.name field
- Use dbFileName for copyright lookup
- Display Bible version on a new line in KeyVerseCard

### 💼 Other

- Update Hindi translations for share message and system labels
- Refine test failure detection in `tests.sh`
- Plan Prayer Wall feature implementation
- Fix dependency warnings and adjust header layout
- Enhance `tests.sh` with comprehensive test runner and reporting features
- Center layout and improve alignment on About page
- *(drawer)* Enhance share app row with subtitle and updated icon
- *(drawer)* Enhance share app row with subtitle and updated icon
- *(drawer)* Update rate app icon to thumbs up
- *(drawer)* Add bubble ID to rate app button for tracking
- Update encounter bubble icon in DevocionalesBottomBar
- Remove temporary Kotlin compiler session file
- Update dependencies in `pubspec.lock`
- New encounter feature, refactor devocionales, deep link, bug fixes, new Hindi
## [1.8.1+83] - 2026-02-23

### 🐛 Bug Fixes

- Handle IAP cancellations to prevent infinite loading spinners
- Update dependencies in pubspec.lock and increment version to 1.8.0+82

### 💼 Other

- Remove Kotlin compiler session file
- New version fix infinite spinner after cancel/back IAP bronze, silver, gold supporter
## [1.8.0+81] - 2026-02-23

### 🚀 Features

- Add Google Play IAP Supporter Badges feature with 3 tiers
- Add Gold supporter Gracias section to about page and name capture dialog
- Add pet animations and update dependencies
- Add heart emoji animations to hearts_love.json
- Add hand-holding heart animation to hands_heart.json
- Add coffee animation to coffee_enter.json
- Replace tier emojis with Lottie animations
- Update supporter tier names and improve badge styling
- Enhance badge visibility and scale Lottie animations
- Add In-App Purchase billing permission and enhance IAP diagnostics
- Update supporter page layout and styling for improved readability and alignment
- Enhance supporter page UI and add IAP documentation
- Adjust scroll hint positioning and simplify its display on supporter page
- Adjust scroll hint positioning and simplify its display on supporter page
- Enhance supporter badges and improve bottom navigation bar functionality
- Extend FakeRemoteConfigService with additional required members for testing
- Add script to run Flutter tests with error filtering
- Enhance Supporter Page UI/UX and purchase feedback
- *(iap)* Implement gap-fix tasks 1–10 — interface cleanup, dispose safety, restore race fix, about_page migration, diagnostics wire, profile repo, IapInitStatus, store compliance, smoke test, CI floor check
- Update Support/Donation button to navigate to external URL
- Enhance Gold supporter UX and refactor IAP architecture for SOLID compliance
- Improve supporter badge positioning and styling for better visibility
- Update supporter badge colors for improved readability and user experience
- Update CI workflow to improve security permissions and remove outdated mock file check
- Update silver supporter tier emoji for enhanced representation
- Add Gold Supporter pet companion feature and improve IAP debug tools
- Add PathProvider plugin registration for improved file path handling
- Integrate supporter pet header and enhance IAP persistence
- Enhance Gold supporter features and improve dependency injection
- Add debug logging for purchase flow and state transitions in SupporterBloc and SupporterPage
- Update setupServiceLocator to be async and ensure proper service registration
- Update setupServiceLocator calls to be async for improved initialization in tests
- Implement purchase error handling in `IapService` and `SupporterBloc`
- Refactor supporter profile management and improve UI integration
- Add "Restore Purchases" button and documentation for IAP support
- Improve "Restore Purchases" button text for clarity and user confidence
- Internationalize pet selection messages in `supporter_page.dart`
- Internationalize pet selection messages in `supporter_page.dart`
- Add bronze medal badge animations and graphics
- Add supporter badges and improve internationalization for pet selection messages
- Update internationalization for pet selection messages and add status titles in multiple languages
- Enhance internationalization for supporter badges and pet selection messages
- Update English and Spanish translations for pet selection and final celebration messages
- Add supporter badges with unlock logic and update translations
- Add restore purchases button and enhance medal unlock feedback
- Add supporter badge display logic and enhance translations
- Refactor settings page layout and improve code organization
- Add supporter section titles and pet display translations in English and Spanish
- Update supporter badge unlock logic to exclude Gold tier
- Add functionality to clear all purchased items and reset IAP state in debug mode
- Refactor supporter purchase dialogs into separate widgets and improve code organization
- Rename supporter purchase dialog files and update imports for improved clarity
- Update Spanish translations for supporter profile and navigation controls
- Add mounted check before clearing supporter error in badge unlock flow
- Refactor supporter purchase dialogs and update translations
- Refactor supporter purchase dialogs and update translations
- Enhance error reporting in analysis and test scripts
- Update error reporting in analysis script to log output to a file
- Fix gold supporter issues - compile errors, pet name display, button autofit, pet preview
- Localize supporter pet names and enhance UI robustness
- Add profile name localization in multiple languages
- Enhance profile name management and localization in settings
- Refactor and enhance profile name editing in SettingsPage
- Enhance Gold supporter profile name UI and localization
- Update and expand internationalization for supporter features and onboarding
- Implement bubble notification for supporter icon in bottom bar
- Enhance UI responsiveness and layout in supporter purchase dialogs
- Add and update profile name localization for multiple languages

### 🐛 Bug Fixes

- Ensure correct system UI styling on supporter page
- Update and refine English translations for UI consistency
- Enhance scroll hint UI and correct English translation
- Improve test stability and text normalization
- Ensure error handling for URL launch is properly wrapped in mounted checks
- Update analysis script and refine purchase dialog navigation logic
- Improve navigation logic in supporter gold purchase dialog
- Update profile name localization for supporter settings
- Update Spanish localization for supporter badges and adjust icon in purchase dialog
- Remove unnecessary icon from purchase success title in progress page
- Update gold purchase success title and Spanish name field hint
- Update Spanish localization for gold name helper and adjust purchase success title reference
- Update localization for donation terminology in English, Spanish, and Chinese
- Update French, Japanese, Portuguese, and Chinese localization for supporter features and messages
- Update silver tier localization for multiple languages
- Update ministry messages and localization for supporter features
- Update supporter page title localization to include ministry name across multiple languages
- Update gold supporter name hint in English localization
- Update profile name hint in Spanish localization
- Adjust layout and remove redundant step labels in gold supporter purchase dialog
- Remove arrow icon from "next" button label across all localizations
- Update dependencies in pubspec.lock and remove unused path_provider_foundation import

### 🚜 Refactor

- SOLID IAP architecture with IIapService interface, SupporterBloc, and service locator
- Implement Dependency Inversion for backup and stats services
- Reorganize widget imports for improved structure
- Update import paths for Bible grid selector tests
- Simplify `DevocionalesContentWidget` and improve dependency injection
- Remove unused introMessage parameter and streamline welcome message display
- Remove redundant methods from `SupporterProfileRepository`
- Remove unused imports and `_FakeThemeBloc` from `widget_pump_helper.dart`
- Remove legacy name persistence methods and update tests

### 💼 Other

- Update Spanish supporter page content and clean up `tier_card.dart`
- Refine Spanish purchase success messages
- Update `restore_purchases` label and clean up tests
- Update `restore_purchases` label and clean up tests
- Update Spanish and English translations for ministry support
- Refine Spanish translation for ministry support message
- New supporter version IAP
## [1.7.6+79] - 2026-02-14

### 🚀 Features

- Add debug button to access backup page
- Add BDS (Bible du Semeur) copyright and display name
- Add BDS (Bible du Semeur) copyright and display name
- Add bulk data generation to `DebugPage`
- Add continuous analysis script for Flutter/Dart project
- Add pre-push hook for repository checks and update package.json scripts

### 🐛 Bug Fixes

- Update French Bible asset filenames to use _fr suffix
- Correct string interpolation for prayer and testimony IDs
- Correct string interpolation for prayer and testimony IDs
- Verify context mounting before showing bottom sheet in `DevocionalesPage`

### 🚜 Refactor

- Move `devotional_card_premium.dart` to a common widgets directory

### 💼 Other

- New fr bible, new compress bibles, fix +100 prayers / new share and favorites out of botton bar
- New fr bible, new compress bibles, fix +100 prayers / new share and favorites out of botton bar
## [1.7.4+77] - 2026-02-04

### 🚜 Refactor

- Improve TTS controller testability and robustness
- Improve TTS controller testability and robustness

### 💼 Other

- Fix all failing test, no more slow test, previous to refactor and change the tags and folders. Update readme integrated in CI flutter
## [1.7.3+76] - 2026-02-03

### 🚀 Features

- Add branch selector for Discovery Studies and fix cache isolation
- Add "New" study tracking and badge to discovery list

### 🚜 Refactor

- Modularize and optimize `DevotionalCardPremium` UI

### 💼 Other

- Refine Chinese translations by replacing English conjunctions
- Improve text scaling and layout in `devotional_card_premium.dart`
- Improve text scaling and layout in `devotional_card_premium.dart`
- Auto fit text on bible studies with new bagde
## [1.7.2+75] - 2026-01-28

### 💼 Other

- Previous version used, Google playstore, Crashlytics on ShareParam, verse on bible studie, Fix on tracking
## [1.7.1+74] - 2026-01-28

### 🐛 Bug Fixes

- Improve reliability and error handling for discovery study sharing
- Localize "KEY VERSE" label and update Spanish translations
- Enhance devotional tracking reliability and logging

### 💼 Other

- Redesign `KeyVerseCard` with a modern premium aesthetic
- Update and fix translations across multiple languages
- Improve UI/UX and card navigation in `DiscoveryDetailPage`
- Enhance `KeyVerseCard` styling and clean up `DiscoveryDetailPage`
- Implement Instagram-style adaptive progress dots in `DiscoveryListPage`
- Add `firebase_remote_config_platform_interface` as a dev dependency
- Refine progress dots animation and layout in `DiscoveryListPage`
- Enhance text layout and overflow handling in `DiscoveryDetailPage`
- Refine dot indicator scaling and code formatting in `DiscoveryListPage`
- Crashlytics fix on share/restore and upgrade tracking/verse on bible studies
## [1.7.0+73] - 2026-01-24

### 🚀 Features

- Add senior architect review, dynamic README generation, and legacy cleanup
- Update architect review to A- grade and add CI workflow for README automation
- Add Discovery data layer (models and repository)
- Add Discovery BLoC and progress tracking
- Integrate Discovery feature with feature flag
- Add Japanese and Chinese translations for Discovery feature
- Add Discovery Studies feature with UI and backend integration
- Implement premium devotional card with image caching and enhanced UI
- Implement premium devotional card with image caching and enhanced UI
- Add Discovery Studies button to bottom navigation bar
- Add card_swiper dependency for enhanced card functionality
- Enhance Discovery Studies page with carousel and grid view toggle
- Add swipeable carousel and celebration animations to Discovery Detail page
- Add versiculoClave display to Discovery Section Card and improve debug logging
- Add imageUrl field to Devocional model and update background image handling
- Add discovery studies URLs and utility method for file retrieval
- Add localized titles to Devotional cards and update Discovery state management
- Refactor DiscoveryRepository to use Constants for GitHub URLs
- Add optional emoji field to Devocional model and update UI logic
- Add emoji support to Discovery studies and improve state management
- Support forced index refresh and dynamic emoji extraction in Discovery studies
- Implement intelligent version-based caching for Discovery studies
- Implement cache-busting for discovery index retrieval
- Refactor DiscoveryDetailPage UI and update DevotionalCardPremium styles
- Enhance Discovery repository and Discovery detail UI
- Implement study completion state and updated celebration UI
- Implement study completion tracking and status-based sorting
- Implement favorites and progress management for Discovery studies
- Implement favorite toggling for Discovery studies
- Implement tabbed layout for Favorites with support for Bible Studies
- Add language support to Discovery studies state management
- Ensure language consistency for Discovery studies
- Implement locale-aware study filtering and language-specific progress tracking
- Enhance Discovery study grid with localized titles and completion status
- Add localization strings for study filtering and status
- Enhance navigation and styling in discovery grid overlay
- Enhance navigation and interaction on DiscoveryListPage
- Update sharing implementation and fix formatting
- Add localized subtitles and reading time to discovery studies
- Update Spanish and English translations for daily studies and UI labels
- Add new localization keys and `tags` section across multiple locales
- Implement automatic copyright disclaimer in discovery studies
- Localize text and add copyright disclaimer to `DiscoveryDetailPage`
- Add "morning" and "night" translations for multiple locales
- Update Portuguese translations for UI labels and tags
- Add new localization keys for devotional status and grace category
- Update localization keys for favorite studies and downloads
- Implement comprehensive sharing system for Discovery Bible Studies
- Enhance localization and styling for Discovery sharing and cards
- Add navigation localization keys for multiple languages
- Add minimalistic navigation buttons to Discovery Bible Studies
- Add `DiscoveryGridOverlay` widget for filtered study selection
- Implement minimalistic navigation buttons in discovery detail and refactor grid overlay
- Add new localization keys and update UI labels across multiple languages
- Add `leading` widget support to `CustomAppBar`
- Add testimony support and refactor choice selection UI in `DevocionalesPage`
- Implement `AddEntryChoiceModal` widget for entry type selection
- Discovery UI improvements - next arrow, auto-reorder, completed status
- Discovery UI improvements - next arrow, auto-reorder, completed status
- Implement blocking loading dialog for Bible version switching
- Enhance study sharing with detailed footer and i18n support
- Add i18n support for share footer and remove redundant session initialization
- Implement stale session detection and background management
- Implement stale session detection and background management
- Implement analytics tracking for FAB interactions and Discovery actions
- Implement Firebase Analytics for FAB interactions and Discovery actions
- Enhance Discovery grid overlay with themed background and improved performance
- Add i18n support for loading and error handling states
- Implement user-friendly error handling and update i18n strings

### 🐛 Bug Fixes

- Address code review feedback in update_readme_stats.dart
- Address final code review feedback - improve logging and fix language list
- Implement dynamic study list from GitHub index.json
- Restore UI files and add missing dependencies
- Issues 2, 3, 4 - State management, i18n, and cache limits
- Remove broken integration tests not part of Discovery implementation
- Restore latest dependencies and fix @Tags annotation placement (P0 task complete)
- Resolve pre-existing test failure in add_thanksgiving_modal_test and update testing agent instructions
- Implement safe voice application and refactor VoiceSettingsService
- Update Chinese translations for Discovery studies
- Update Portuguese translations and finalize i18n JSON structure
- Prevent navigation race conditions in `DevocionalesPage`
- Resolve Discovery studies visibility and locale filtering issues
- Resolve Discovery studies visibility and locale filtering issues
- Update Spanish translations for empty devotional states
- Update `activation_prayer` translations across multiple languages
- Correct index calculation when updating devotionals in `DevocionalesNavigationBloc`
- Improve TTS pause/resume behavior for multibyte text and UI consistency
- Add validation for voice name and locale in `VoiceSettingsService` and `ApplicationLanguagePage`
- Resolve streak sync issues and improve Discovery grid toggle UX
- Resolve test errors and enhance premium card aesthetics
- Improve `DiscoveryBloc` state handling in `FavoritesPage`
- Resolve infinite spinner in Bible Studies favorites tab
- TTS modal auto-close on completion, verify favorites fix, add tests
- TTS modal auto-close on completion, add behavioral tests
- Resolve infinite spinner on Bible Studies favorites tab
- Resolve infinite spinner on Bible Studies tab in `FavoritesPage`
- Enhance `commit_version.sh` to automatically detect project root

### ⚡ Performance

- Improve Discovery carousel swipe responsiveness and gesture handling

### 🚜 Refactor

- Optimize TTS text processing and fix emulator performance
- Redesign DevotionalCardPremium for centered content and improved visual hierarchy
- Remove in-app review dialog example widget
- Update sharing implementation and UI icon in DiscoveryListPage
- Clean up `DevocionalesPage` and optimize navigation logic
- Remove legacy navigation code and feature flags in `DevocionalesPage`
- Remove legacy navigation logic from `DevocionalesPage`
- Remove verse reference badge from `DevotionalCardPremium`
- Improve devotional card interaction and swiper UX
- Enhance `DevotionalCardPremium` UI and localization
- Move `devocionales_page_drawer.dart` to `widgets/devocionales` subdirectory
- Relocate shared UI constants and widgets to `devocionales` directory
- Apply theme-based system UI overlay style to `DiscoveryListPage`
- Improve Discovery carousel fluidity and modernize visual design
- Enhance UI/UX of `DiscoveryListPage` and study grid
- Improve Discovery carousel and grid UI/UX
- Update icons and layout in `DevotionalCardPremium`
- Update action button styling in `DiscoveryListPage`
- Localize action buttons in `DiscoveryListPage` and update translations
- Update language and study download indicators and action button styling
- Update share text formatting and improve `DiscoveryListPage` feedback
- Improve safety and context usage in `_handleShareStudy`
- Localize share text and enhance feedback UI in `DiscoveryListPage`
- Improve visibility and styling of progress dots in `DiscoveryListPage`
- Update discovery studies icon in drawer
- Cleanup and update styling logic in `DevotionalCardPremium`
- Replace loading indicator with Lottie animation in `DiscoveryDetailPage`
- Enhance the empty state UI in `DiscoveryDetailPage`
- Improve navigation and state management in `DiscoveryListPage`
- Update choice selection UI in `PrayersPage`
- Extract `AddEntryChoiceModal` from `DevocionalesPage`
- Extract entry choice modal to a dedicated widget in `PrayersPage`
- Simplify modal presentation using static `show` methods
- Remove unused testimony model import in `testimony_integration_test.dart`
- Improve action bar layout and button responsiveness in `DiscoveryListPage`
- Remove tags from discovery share content
- Remove estimated reading time from share messages in `discovery_share_helper.dart`
- Implement auto-downloading for devotional data in `DevocionalProvider`
- Extract devotional sharing logic to `DevotionalShareHelper`
- Update `DevocionalesNavigationBloc` event signature and improve discovery list swiping
- Improve `DevocionalesPage` initialization, state management, and stability
- Remove `discovery_index_template.json`

### 💼 Other

- Add comprehensive test coverage for Blocs and services
- Develop4God <212957966+develop4God@users.noreply.github.com>
- Update share functionality to use SharePlus instance
- Update and refine Chinese, Japanese, and French translations
- Update Portuguese translations
- Update `offline_mode` translations across multiple languages
- Update `offline_mode` translation in `en.json`
- Translate pending achievement and footer strings in multiple languages
- Disable `shellcheck` SC2162 for `read` commands in `commit_version.sh`
- New bible studies, new testimony, fixes: black screen, legacy remove, multimple crashlytics fixes tts voice
## [1.6.3+70] - 2026-01-11

### 🚀 Features

- Add local font support for SplashScreen and create corresponding tests
- Add manual test script for complete AAB migration verification
- Implement concurrency protection for favorites with synchronized locks
- Refactor UI and provider for proper error handling

### 🐛 Bug Fixes

- Update dependencies in pubspec.lock to latest versions
- Add mounted checks to prevent async state update crashes
- Add error handling for BLoC initialization in devocionales_page
- Improve error handling and context management in download progress dialog
- Add output directory listing to manual test script for APK builds
- Enhance manual test script to improve APK detection and output listing
- Ensure script runs from project root for consistent execution
- Update migration log parsing to remove emoji characters for consistency
- Add retry logic for APK installation in manual test script
- Implement ID-based favorites storage and migration logic to resolve read status issues
- Add localization service import to favorites page integration test
- Resolve static analysis warnings and add comprehensive migration tests
- Add BuildContext safety checks and comprehensive migration tests
- Ensure favorites are saved after migration from legacy storage
- Resolve favorites synchronization bug after app restart and language switch
- Update test to verify migration of legacy favorites to ID format
- Add schema version persistence and telemetry for favorites ID mismatch
- Add favorites schema version and helper methods for persistence
- Enhance favorites persistence tests and migrate legacy favorites
- Implement PR#180 critical gaps - telemetry throttling, legacy cleanup, migration telemetry
- Replace debugPrint with developer.log for favorites, add error handling and missing logs
- Change toggleFavorite return type from Map to bool per requirement
- Move stats service outside lock, add duplicate check, remove unsafe cast
- Update error messages for favorite updates in multiple languages
- Refactor favorites integration tests for improved persistence and language handling
- Refactor favorites integration test setup and remove redundant mocks
- Update migration log parsing to remove emoji prefixes for consistency
- Enhance manual test script with directory handling and build options
- Improve manual test script with enhanced file existence checks and directory handling
- Add documentation for manual test script to enhance migration and legacy data validation
- Refactor DevocionalProvider to use dependency injection for HTTP client
- Refactor DevocionalProvider to support optional audio initialization

### 💼 Other

- Crashlytics fixes>drawer/font offline/bloc close/ favorites not read fix and tested version to Google Play Store
## [1.6.2+69] - 2026-01-04

### 🐛 Bug Fixes

- Update Flutter build configuration to release mode and increment version
- Address StringIndexOutOfBoundsException by adding validation and error handling in TTS controller
- Refactor salvation prayer dialog to use AlertDialog and improve layout
- Update icon in devocionales_page and change build mode to release
- *(tts)* Prevent player modal from closing during seek/speed change and improve user experience
- Ignore Flutter generated plugin registrant in .gitignore
- Ignore Flutter generated plugin registrant in .gitignore
- Update salvation prayer intro text to use heart emoji
- Ignore Patrol generated test bundle in .gitignore
- Ignore invalid use of visible_for_testing_member in multi_year_devotionals_patrol_test.dart
- Update copilot setup to start Android emulator and run Patrol tests
- Update copilot setup to clarify Android emulator step for Patrol tests
- Remove unnecessary steps for starting Android emulator in copilot setup

### 💼 Other

- Fix tts crashes on pause /complete auudio closes modal / salvation prayer restore
## [1.6.1+68] - 2026-01-02

### 🚀 Features

- Enhance Thanksgiving modal and add reusable gradient bottom sheet; update offline mode tests for Patrol integration

### 🐛 Bug Fixes

- *(about_page)* Restrict icon tap functionality to debug mode only
- Add local.properties to .gitignore
- Update test cases for devotional reading and TTS workflows; improve readability and adjust delays
- Add bottom spacing to AppGradientBottomSheet for better layout; update prayers_page to use new widget properties
- Resolve loading issue in DevocionalesPage by updating modal bottom sheet implementation and adjusting imports
- Improve layout and structure of salvation prayer dialog by using AppGradientDialog and adding spacing
- Add sparkle emoji to salvation prayer title in multiple language files for enhanced visual appeal
- Update salvation prayer intro and promise formatting for better readability across multiple languages
- Refactor button layout in BibleReaderPage for improved responsiveness on larger screens
- Enhance text display in BibleReaderPage by implementing FittedBox for better responsiveness
- Add chapter and verse prefixes based on language for improved localization
- Remove unused gradient bottom sheet import and simplify modal bottom sheet implementation

### 🚜 Refactor

- Streamline constructor formatting and improve code readability
- Streamline constructor formatting and improve code readability

### 💼 Other

- Load devotionals from both 2025 and 2026 consecutively
- Fix 2026 devocionales ahora carga dos anios con posible expansion a siguientes
## [1.6.0+67] - 2025-12-31

### 🚀 Features

- Enhance translation validation logging and tracking
- Implement Chinese (zh) language support
- Add Chinese (zh) localization and improve language switching
- Add Chinese support and improve language switching logic
- Implement Chinese (zh) support for TTS and duration estimation
- Add voice validation for Chinese (zh) in `VoiceSettingsService`
- Add Chinese language support to voice selector
- Add female Chinese voice support to voice selector
- Expand Chinese (zh) TTS voice support and visibility
- Add support for Taiwanese Chinese voices in voice selector
- Enhance Chinese (zh) TTS support and improve testing infrastructure
- Enhance Chinese (zh) TTS support and improve testing infrastructure
- Add Chinese and Hindi support to notification content
- Add Chinese (zh) support to copyright utilities
- Add Firebase Remote Config service with dependency injection
- Add Firebase Remote Config dependency and update related configurations
- Add commit message guidelines for consistency and clarity
- Integrate analytics tracking for devotional reading modes and handle errors
- Update reading criteria thresholds and improve code formatting

### 🐛 Bug Fixes

- *(tts)* Ensure correct default voice assignment for Chinese (zh)
- *(voice_selector)* Disable fallback for testing in production mode

### 🚜 Refactor

- Enhance translation validator to support multiple languages
- Streamline constructor formatting and improve code readability

### 💼 Other

- Fix failing tests after Chinese language addition
- Version en zh, arreglo para lectura tables y guardado de devocional leido, ajuste tts para tienda
## [1.5.2+66] - 2025-12-22

### 🚀 Features

- Add test output and coverage reports
- Add Japanese language support and translation validation tool
- Enhance translation utility and add Japanese localizations
- Add Japanese language support
- Add Japanese language and Bible support
- Update Japanese Bible version to SK2003
- Add JCB Japanese Bible version and update copyright texts
- Add JCB Japanese Bible version and update copyright texts
- Add Japanese bible versions and TTS support
- Add Japanese TTS support and improve language synchronization
- Update TTS context when changing application language
- Proactively initialize TTS service on app startup
- Add Japanese localization for notifications
- Add debug logging for language context changes
- Proactively assign TTS voice on app startup
- Set default TTS voice based on language settings
- Improve TTS timer for Japanese and add tests
- Display full thanksgiving text on prayer card
- Add detailed logging for devotional tracking
- Add multiple GenAI automation workflows and scripts for tests, docs, architecture, and quality
- Run integration tests on Android emulator
- *(analytics)* Implement Firebase Analytics for key user events
- Update googleapis and add Google Drive auth tests
- Add campaign tag for users with 7+ devotionals read
- Add debug buttons for Firebase Analytics and FID
- Improve TTS duration estimate and adjust campaign tag logic
- Update campaign tag threshold to 7 devotionals read
- Prevent multiple simultaneous language downloads
- Update dialog UI layout and opacity
- Enhance `TtsMiniplayerModal` with real-time position updates
- Improve TTS player UI and refactor miniplayer state management
- *(tts)* Improve playback reliability and observability
- Update prayer count badge colors and transparency
- Add loading message for Bible versions and new Lottie animation
- Add Lottie animation to Bible reader loading state
- Make streak badge interactive and improve styling
- Add debug flag page and update `SettingsPage`
- Restore TTS and Firebase debug components to Settings page
- Implement TTS miniplayer, analytics tracking, and streak UI improvements
- Localize messages in `NotificationConfigPage`
- Refine UI transitions and styling in `DevocionalesPage`
- Add copy-to-clipboard functionality for Bible verses
- Refine verse styling and BottomAppBar icons in `DevocionalesPage`
- Add badge to Bible icon and format code in `DevocionalesPage`
- Refactor verse display and UI styling in DevocionalesPage
- Trigger Firebase In-App Messaging event on TTS play
- Increase character limit for thanksgiving modal
- Standardize thanksgiving card header in PrayersPage
- Implement `AnimatedFabWithText` and integrate into prayer pages
- Refactor `AnimatedFabWithText` to use a layered circular design
- Add icon and update animation in AnimatedFabWithText
- Add `thankful_for` translation key
- Update translation key for thanksgiving label
- Refactor AppBar and update icon styling in DevocionalesPage

### 🐛 Bug Fixes

- Correct Japanese Bible version names
- Use exit code instead of text parsing for test success detection
- Update GenAI test generator with correct Gemini API format and English translations
- Address code review feedback - improve Dart validation and document temperature
- Update text styling in `ModernVoiceFeatureDialog`
- Update styling and add error handling block in `TtsMiniplayerModal`
- Update dependencies in pubspec.lock for improved stability
- Prevent mini-player from appearing during voice sample playback
- Set constant speech rate for TTS voice samples
- Disable manual fallback testing flag in `VoiceSelectorDialog`
- Remove unused Audio Settings header from Settings page
- Update Spanish translations for devotionals
- Update slider colors in `TtsMiniplayerModal`
- Update border styling in `TtsMiniplayerModal`
- Add braces to conditional blocks in `voice_selector_dialog.dart`
- Add context mounted check before HapticFeedback in `DevocionalesPage`

### ⚡ Performance

- Optimize app initialization and startup performance

### 🚜 Refactor

- Wrap TabBar in an Expanded widget
- Remove Bible version display in settings
- Proactively initialize TTS voice on language change
- Proactively initialize TTS voice on language change
- Improve Japanese TTS chunking logic
- Adjust SystemUiOverlayStyle for theme changes
- Improve code formatting and text alignment
- Replace Text with AutoSizeText for responsive layout
- Improve code formatting and test setup
- Update TTS player UI and internationalization
- Remove animation from TTS miniplayer title
- Optimize `TtsMiniplayerModal` with reactive architecture
- Rename `debug_voice_flag_page` to `debug_flag_page`
- Modularize and improve voice selection logic in `VoiceSelectorDialog`
- Improve voice fallback logic and locale handling in `VoiceSelectorDialog`
- Update translation validator to use English as reference and update Portuguese translations
- Simplify width calculation for AnimatedFabWithText

### 💼 Other

- Fix typo in commented out code
- Display Japanese Bible version names and adjust user cleanup logic
- Correct reading time calculation during pause/resume
- Improve TTS handling for Japanese
- Improve Japanese TTS normalization and clean up UI
- Improve TTS player state synchronization
- Enable play button when another devotional is paused
- Introduce TtsAudioController and simplify TTS widget
- Improve TTS audio for verses and add lifecycle handling
- Record devotional as heard upon TTS completion
- Update dependencies
- Remove share as image and verse normalization
- Remove scroll listener from Devotional page
- Move TTS text normalization to BibleTextFormatter
- Prepare full devotional text for TTS playback
- Normalize devotional content for Text-to-Speech
- Prevent duplicate "devotional heard" stats
- Stop TTS playback when app is backgrounded
- Simplify TTS playback by removing chunking logic
- Update TtsService tests
- Remove chunk navigation from AudioController
- Pause TTS on app background and enhance tests
- Truncate long log messages in BibleTextFormatter
- Enhance TTS player UI and add loading state
- Simplify TTS player button styles
- Enhance logging in `SpiritualStatsService` and improve overflow tests
- Load and apply TTS speech rate on playback
- Add TTS voice selector to settings
- Correctly display the selected TTS voice in settings
- Improve voice selection persistence and display
- Ensure valid initial voice in TTS settings dropdown
- Improve voice selection logic in settings
- Add voice selection dialog for TTS
- Add modern TTS voice selector dialog
- Enhance voice selector dialog UI and UX
- Enhance voice selector dialog UI and UX
- Replace TTS voice dropdown with a modern dialog
- Persist selected voice in VoiceSelectorDialog
- Adjust close button position in Voice Selector dialog
- Improve Spanish voice selection UI
- Correct typo in Spanish sample text
- Correct typo and adjust button color in voice selector
- Improve and unify sample text for voice selection
- Add support for English TTS voices
- Use translation key for voice sample text
- Reorganize French translations and improve voice selector UI
- Correct translation key for voice sample text
- Simplify voice selector UI
- Enhance VoiceSelectorDialog UI and layout
- Adjust UI padding in Voice Selector Dialog
- Improve UI and responsiveness of Voice Selector Dialog
- Improve voice selector labels and UI
- Adjust preferred Spanish voice locales
- Add Portuguese voice options to Voice Selector
- Update and correct Portuguese voice selection
- Correct Portuguese voice selection logic
- Prevent overflow on settings page
- Update dependencies and improve code formatting
- Add new internationalization keys
- Update onboarding screen text
- Add Japanese voice options to Voice Selector
- *(i18n)* Standardize French translations to use "Méditation"
- Add French voice display to Voice Selector
- Enhance Voice Selector Dialog UI
- Enhance Voice Selector Dialog UI
- Simplify and improve friendly voice name mapping
- Prompt user to select a voice on first TTS playback
- Prompt user to select a voice on first TTS playback
- Refactor voice saving logic and add debug tool
- Isolate voice sample playback from global settings
- Change voice selection behavior in settings
- Update Voice Selector to use Modal Bottom Sheet
- Initialize Flutter binding in tests
- Reset player state to idle after devotional is marked as heard
- Clean up and structure TtsPlayerWidget
- Update bottom navigation button styles
- Dark mode TextField styling and default TTS voices per language
- Cache VoiceSettingsService instances in StatefulWidgets
- Remove test anti-pattern, update comments, improve error handling, add ServiceLocator tests
- Introduce modern voice feature dialog
- Extract `AppGradientDialog` from `ModernVoiceFeatureDialog`
- Extract `AppGradientDialog` from `ModernVoiceFeatureDialog`
- Increase font size for "Skip" button text
- Ensure dialog respects safe area
- Redesign download dialog and update translations
- 🔊 Audio reengineering. 🔥 New streak animation. 🙏 Improved prayers/gratitude. 👨‍🔧 Bug fixes. 🇯🇵 Japanese translation
- Update NDK version to 28.2.13676358
- Use DevocionalProvider to record heard devotionals
- Consolidate devotional tracking and update dependencies
- Update i18n key for streak display
- Remove Non-SDK API check workflow and update loading text
- Update dependencies
- Add favorites count tracking and fire animation
- Update streak display on devocionales page
- Remove legacy TTS test file and update dependencies
- Centralize test service registration
- Unify devotional interaction tracking
- Add TTS miniplayer widget
- Integrate TTS Miniplayer and enhance audio controls
- Refactor TTS player logic and add completion tracking
- Centralize TTS playback rate cycling logic
- Simplify TTS playback speeds and centralize logic
- Centralize TTS playback rate logic and persistence
- Decouple TTS controller from playback rate logic
- Improve TTS playback rate change logic
- Correct devotional heard status and hide idle audio player
- Correct debug message for TTS rate change
- Redesign TTS miniplayer UI
- Auto-close TTS miniplayer on completion and optimize build
- Auto-close TTS miniplayer on completion and optimize build
- Update dependencies and fix typo in README
- Update NDK version to 28.2.13676358
- Migrate integration tests to integration_test directory
- Separate emulator start from test run
- Initial cleanup - dart format and dart fix applied
- Refactor settings and contact pages
- Version tienda 1.5.0 git commit -m "🔊 Audio reengineering. 🔥 New streak animation. 🙏 Improved prayers/gratitude. 👨‍🔧 Bug fixes. 🇯🇵 Japanese translation , new UI devotional, and improve navigation
- Gogle playstore version 🔊 Audio reengineering. 🔥 New streak animation. 🙏 Improved prayers/gratitude. 👨‍🔧 Bug fixes. 🇯🇵 Japanese translation, new UI devocionales page, new transitions, new copy option
- Downgrade Android dependencies for compatibility
- Update Android dependencies and remove ABI filter
- Cambio de letra en versiculo principal devocionales y firebase in app inicial
## [1.4.1+62] - 2025-11-17

### 🚀 Features

- Add more Lottie animations and refactor cleanup function
- Add new Lottie animations
- Add internationalization for prayers and remove unused animation

### 🚜 Refactor

- Improve TabBar design in PrayersPage
- Improve SnackBar handling on ProgressPage
- Simplify PayPal URL

### 💼 Other

- Update system navigation bar color
- Arreglo system navigation, compartir directo a texto, enlace paypal, thanks giving ajustado textos, bug del tip en progress corregido
## [1.4.0+61] - 2025-11-16

### 🚀 Features

- *(prayer)* Allow 400 chars in answer modal and add widget test
- Enable backup and restore feature
- Add "Develop4God" branding to splash screen
- Apply system UI styling to BackupSettingsPage
- Refactor icons and update dependencies
- Add option to create Prayer or Thanksgiving
- *(i18n)* Update "My Prayers" to "Prayers and Thanksgivings"
- Add happy bird Lottie animation
- Add post-splash screen animation
- Add random Lottie animations to Devocionales page

### 🚜 Refactor

- Add copyright notice to Bible reader and update UI
- Improve FCM token handling and add verification
- Clean up SettingsPage UI and code
- Remove backup settings section from SettingsPage
- Simplify Thanksgiving card layout
- Remove back button from modal headers
- Adjust spacing on PrayersPage for better autofitting
- Improve styling of splash screen text
- Adjust styling of "Develop4God" text on splash screen
- Make Bible chapter title scrollable with verses
- Adjust happy bird animation position
- Adjust Lottie animation position on DevocionalesPage

### 💼 Other

- Add spacer to prevent content from overlapping system navigation bar
- Optimize and enhance Cloud Functions for notifications and cleanup
- Redesign and center the layout of the About page
- Adjust font weight on splash screen
- Center BottomAppBar icons on Devocionales page
- Remove debug logs and `updateLastLogin` call from `main.dart`
- Clean up bible chapter navigation tests
- Update BibleReaderPage tests to include ThemeBloc provider
- Correct theme usage on BackupSettingsPage
- Nueva opcion de agradecimientos, mejoras biblia, nuevo intro lottie
- Nueva opcion de agradecimientos, mejoras biblia, nuevo intro lottie
## [1.2.5+59] - 2025-10-22

### 🚀 Features

- Add floating font control buttons widget
- Add font size controls to Devocionales page

### 💼 Other

- Remove donation and badge feature
- Redesign Bible book selector as a full-screen modal
- Revert book selector to a standard `AlertDialog`
- Modernize and improve Bible book selector dialog
- Apply system UI styling to settings page
- Centralize SystemUiOverlayStyle logic in ThemeBloc
- Apply correct system UI style on progress page
- Respect status bar theme on Devotionals page
- Remove dedicated notification permission page
- Improve loading state UI in Notification Config Page
- Add correct system UI overlay style to favorites page
- Apply `SystemUiOverlayStyle` to the contact page
- Apply correct `SystemUiOverlayStyle` to `BibleReaderPage`
- Apply system UI style on language selection screen
- Update drawer close icon
- Redesign floating font controls and update dependencies
- Redesign `FloatingFontControlButtons` widget
- Adjust styling and position of floating font controls
- Organize documentation files and update README
- Google Playstore version, Fix Chapter selection, fix sytem navigation bar, new floating button bible and devocionales page
- Google Playstore version, Fix Chapter selection, fix sytem navigation bar, new floating button bible and devocionales page
## [1.2.3+56] - 2025-10-18

### 🚀 Features

- Add user language preference to notification settings
- Implement complete automatic backup background execution
- *(donate)* [**breaking**] Refactor DonatePage into modular components
- *(settings)* Add Remote Config control for backup section visibility
- Bulletproof debug isolation + Remote Config backup control
- *(onboarding)* Fix multiple UI and localization issues - resolve overflow, progress bar visibility, Google Drive timeout, and add comprehensive localization
- Optimize onboarding backup flow to match settings page functionality
- Add one-off test task for backup scheduler in debug mode
- Add comprehensive GoogleDriveBackupService unit tests with 36 test cases covering all core business logic
- Add comprehensive NotificationService unit tests with 31 test cases covering core business logic and Firebase mocking setup
- Add comprehensive VoiceSettingsService unit tests with 26 test cases covering TTS voice configuration business logic
- Enhance onboarding welcome screen and update dependencies
- Add multiple Bible version databases
- Add Portuguese NVI Bible database
- Enhance AppBar to support a custom title widget
- Update user's last login time on app start
- *(i18n)* Localize bible reader action modal buttons

### 🐛 Bug Fixes

- *(onboarding)* Address i18n, login flow, and code coverage issues - resolve localization keys, enhance Google Drive timeout handling, add comprehensive tests, and update documentation
- *(onboarding)* Handle Google Drive authentication cancellation
- *(onboarding)* Handle Google Drive authentication cancellation
- *(onboarding)* Enhance responsive design and update setup summary display
- *(onboarding)* Refactor onboarding complete page layout and improve setup summary display

### 💼 Other

- Update BackupBloc tests with business logic
- Implement startup backup check and remove WorkManager
- Prevent multiple navigations on backup auto-configuration
- Improve onboarding state management and persistence
- Replace placeholder tests with real BLoC implementations using bloc_test - BackupBloc complete
- Improve onboarding backup configuration flow
- Localize BackupBloc in OnboardingBackupConfigurationPage
- Localize BackupBloc in OnboardingBackupConfigurationPage
- Remove `BackupSchedulerService` and simplify backup logic
- Simplify `main.dart` and initialization flow
- Add debug log for onboarding configurations
- Add debugging for onboarding completion
- Complete onboarding via Bloc event
- Improve backup connection UX with stateful button and clear feedback
- Streamline onboarding backup flow and improve UX
- Streamline onboarding backup flow and improve UX
- Streamline onboarding backup flow and improve UX
- Prevent user interaction during backup connection process
- Simplify setup summary card and backup logic
- Modernize AppBar with gradient and clean up code
- Centralize AppBar styling with `CustomAppBar` widget
- Add extensive debugging and minor UI adjustments
- Ensure user selections are correctly copied during onboarding completion
- Correctly reflect backup configuration status on completion screen
- Ensure backup status is accurately reflected on completion screen
- Improve debug logging on completion screen
- Simplify onboarding completion logic and improve state accuracy
- Simplify UI and data fetching on completion screen
- Optimize `BlocBuilder` in onboarding completion screen
- Ensure backup status is correctly displayed on completion screen
- Ensure navigation occurs after backup configuration
- Ensure navigation occurs after backup configuration
- Enhance backup UX and add robust error handling
- Eliminate flicker when transitioning from onboarding to the main app
- Refactor Onboarding Welcome screen with animated header
- Refactor Onboarding Welcome screen with animated header
- Prevent multiple navigation events during onboarding backup setup
- Update Spanish localization for backup onboarding
- Update Spanish localization for backup onboarding
- Update localization key for backup connection
- Enhance backup data and add detailed logging
- Refactor backup settings UI and improve "next backup" logic
- Enhance backup data and add detailed logging
- Internationalize 'Share as Text' tooltip
- Refactor localization keys and formatting
- Update devotional sharing format
- Change new feature highlight color and refactor icon badges
- Add "New" bubble to backup option
- Remove debug section and feature flag refresh from settings
- Remove debug section and feature flag refresh from settings
- Add extensive debug logging to backup settings navigation
- Add extensive debug logging to backup settings navigation
- Update dependencies and adjust splash screen timing
- Improve code formatting and bump version
- Remove unused prayer localization keys
- Refactor smoke test and clean up localization key
- Use Firebase Remote Config to control onboarding flow
- Use Firebase Remote Config to control onboarding flow
- Update onboarding text and animation color
- Update Spanish localization key
- Update Spanish translation and pubspec assets
- Refactor prayer status key and disable onboarding
- Refactor prayer status key and disable onboarding
- Bump app version to 1.1.1+49
- Update favorite icons and remove unused features
- Update Android dependencies and `minSdk` version
- Bump version to 1.1.1+50
- Bump version to 1.1.1+50
- Bump build number to 1.1.1+51
- Clean up AndroidManifest.xml and increment build number
- Clean up and document AndroidManifest.xml
- Remove Firebase Remote Config dependency
- Remove Firebase Remote Config dependency
- Introduce Bible text normalizer and update icon
- Remove RVR1960 Bible database file
- Align Bible language with app language and update Android minSdk
- Enhance UX on Bible reader and add copyright notice
- Enhance Bible version loading SnackBar
- Update Bible version selector icon
- Implement new feature badge for Bible icon
- Modernize Bible reader app bar
- Update app version and dependencies
- *(deps)* Remove `"peer": true"` from package-lock.json
- Create `bible_reader_core` package and move bible logic into it
- Update imports, dependencies, and add bible assets
- Improve verse marking UX, add debug logging, format tests
- Extract verse action modal to its own widget, add NVI Portuguese
- Extract verse formatting logic to pure Dart package
- *(KJV)* Correct mismatched verse in Genesis 1
- Update ARC_pt.SQLite3 database
- Inline Bible search bar UI into reader page
- Improve scroll-to-verse with GlobalKey
- Ensure verse scrolling happens after UI updates
- Add retry mechanism to `_scrollToVerse` for reliable scrolling
- Simplify `_scrollToVerse` and adjust scroll timing
- Replace ListView with ScrollablePositionedList
- Update dependencies
- Pre-scroll to approximate position before ensuring verse visibility
- Add retry loop to `_scrollToVerse` for robustness
- Pass full book name to selectors
- Simplify chapter selector button UI
- Improve verse selection modal behavior
- Clear verse selection after action
- Improve keyboard and focus handling on reader page
- Improve focus and search state management
- Enhance bible search functionality
- Initialize readerService DB and format code
- Initialize readerService DB and format code
- Improve styling of book selector search field and localize cancel button
- Set explicit text color in book selector
- Update KJV Bible database
- Enable RouteObserver for navigation events
- Use global RouteObserver in DevocionalesPage
- Clean up tests and minor code formatting
- Add library directive to core files
- Update lifecycle method for audio playback
- Add confirmation SnackBar for save/unsave actions
- Remove book short names from selector
- Auto-scroll to verse after search
- Ensure view resets when changing chapters
- Scroll to top on chapter change
- Correctly trigger delete action for saved verses
- Remove SnackBar from bible reader action modal
- Update dependencies and minor code formatting
- Improve verse selection comment
- Enhance and automate versioning script
- Update dependencies
- Nueva version para tienda, con arreglo en compartir y asjustados warnings
## [1.0.25+25] - 2025-07-18

### 🚀 Features

- Implementación y mejora de notificaciones y persistencia en Firestore
## [1.0.24+24] - 2025-07-18

### 💼 Other

- Feat: Implementación y mejora de notificaciones y persistencia en Firestore
## [1.0.0+7] - 2025-07-04

### 🚀 Features

- Implementar sistema completo de push notifications

### 💼 Other

- Solucionar bug de scroll en navegación de devocionales
## [1.0] - 2025-05-24
