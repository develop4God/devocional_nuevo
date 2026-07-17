# TTS for Encounters and Discovery/Bible Studies

## Goal
Add text-to-speech playback to the Encounters and Discovery/Bible Studies
reader screens without touching or risking the existing TTS used by
Devocionales and the Bible reader.

## Why this is safe
`TtsAudioController` (`lib/controllers/tts_audio_controller.dart`) is
already content-agnostic (`setText(String)`) and page-owned: Devocionales
and the Bible reader each construct their own `FlutterTts` instance and
`TtsAudioController` in `initState` and dispose them in `dispose()`.
Neither is registered in `ServiceLocator`. `TtsMiniplayerModal`
(`lib/widgets/tts_miniplayer_modal.dart`) is a shared, generic UI widget
driven by `ValueListenable`s with no model coupling.

This change replicates that established pattern for two more readers. No
existing TTS file was modified:
`TtsAudioController`, `TtsService`, `ITtsService`, `TtsMiniplayerModal`,
`DevocionalTtsMiniplayerPresenter`, `BibleReaderTtsMiniplayerPresenter`,
`DevocionalTtsTextBuilder`, `BibleReaderTtsTextBuilder`,
`devocionales_page.dart`, `bible_reader_page.dart`, `service_locator.dart`.

## flutter_tts single-instance constraint
Only one live `FlutterTts` instance can own native callbacks at a time.
`EncounterDetailPage` and `DiscoveryDetailPage` are both reached via
`Navigator.push`/`MaterialPageRoute` (not persistent tabs), so plain
`initState`/`dispose()` lifecycle is sufficient — no `reattachTts()`
guard needed.

This holds specifically because `app_navigation_shell.dart` disposes the
Bible reader tab (and its `FlutterTts`) whenever the user leaves that tab,
so a live Bible reader instance can never sit underneath a pushed
Encounters/Discovery detail page fighting for the channel. **If that
shell behavior for the Bible tab ever changes, or a deep link pushes a
detail page over a live Bible tab, this assumption must be re-verified.**

## New files
- `lib/services/tts/encounter_tts_text_builder.dart` —
  `EncounterTtsTextBuilder.build(EncounterCard)`, a stateless static that
  reads only the fields `kEncounterCardRenderedFields`
  (`lib/models/encounter_card_contract.dart`) marks as rendered for the
  card's `type`, so narration always matches what's visually shown. Throws
  a `StateError` for an unrecognized card type rather than narrating
  nothing silently.
- `lib/services/tts/discovery_tts_text_builder.dart` —
  `DiscoveryTtsTextBuilder.build(DiscoveryCard)`, same shape, mirroring
  the fields `DiscoveryDetailPage._buildCardContent` renders. Note:
  `DiscoveryDevotional extends Devocional`, but the inherited base-class
  fields (verse/reflection/meditar/prayer) don't reflect the actual
  per-card content shown, so `DevocionalTtsTextBuilder` was intentionally
  not reused.
- `lib/widgets/tts/reader_tts_miniplayer_presenter.dart` —
  `ReaderTtsMiniplayerPresenter<T>`, a single generic presenter shared by
  both new readers (rather than two more copy-pasted ~200-line presenter
  classes) that opens the existing `TtsMiniplayerModal` and wires
  play/pause/seek/rate-cycle/voice-selector. Templated on
  `BibleReaderTtsMiniplayerPresenter`'s constructor-injected
  `IAnalyticsService` — not `DevocionalTtsMiniplayerPresenter`, which has
  a known (already-fixed-elsewhere) inline-`getService`-in-closure
  antipattern.

## Page wiring
`EncounterDetailPage` and `DiscoveryDetailPage` each gained, in
`initState`: their own `FlutterTts`, a page-scoped `TtsAudioController`
(voice settings + chunk processor resolved via `getService<T>()` — the
allowed composition-root location, not inside a BLoC/service), and a
`ReaderTtsMiniplayerPresenter`. Both are disposed in `dispose()`. A TTS
play button was added to each reader's header/controls, and the
`PageView`'s `onPageChanged` stops playback if a card is swiped away
mid-playback (rather than silently resetting playback position or
continuing to narrate a now-hidden card) — the user must tap play again
for the newly visible card.

## Tests
- `test/unit/services/tts/encounter_tts_text_builder_test.dart` — one
  case per representative card type, asserting both included fields and
  the absence of fields not in that type's rendered-fields contract, plus
  the unknown-type throw and the empty-card case.
- `test/unit/services/tts/discovery_tts_text_builder_test.dart` — same
  shape per `DiscoveryCard` type.

## Deferred (follow-up, not blocking this change)
- Widget-level test for the dispose-during-in-flight-`play()` race (modal
  open → pop the detail page mid-await).
- Widget-level test asserting the page-change-while-playing `stop()`
  policy fires on an actual `PageView` swipe.
- `no_singleton_antipatterns_test.dart`: no entry needed — nothing new was
  registered in `service_locator.dart` (per-page-owned controllers, same
  as the existing Bible reader/Devocionales pattern).
