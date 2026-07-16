// lib/models/encounter_card_contract.dart

/// Single source of truth for which EncounterCard fields each card type
/// actually renders in encounter_card_widgets.dart.
///
/// Used by the debug-mode contract check (see EncounterCard.fromJson) to
/// detect orphaned content: a field with a real value that no widget for
/// that card type claims to render. This file IS the contract — update it
/// in the same change whenever a widget's field-checks change.
const Map<String, Set<String>> kEncounterCardRenderedFields = {
  'cinematic_scene': {
    'mood',
    'imageUrl',
    'title',
    'narrative',
    'verseOverlay',
    'revelationKey',
  },
  'scripture_moment': {
    'mood',
    'imageUrl',
    'title',
    'subtitle',
    'verseReference',
    'verseText',
    'reflection',
    'scriptureConnections',
    'revelationKey',
  },
  'character_moment': {
    'mood',
    'imageUrl',
    'icon',
    'title',
    'subtitle',
    'content',
    'verseOverlay',
    'scriptureConnections',
    'revelationKey',
  },
  'theological_depth': {
    'mood',
    'imageUrl',
    'icon',
    'title',
    'subtitle',
    'content',
    'verseOverlay',
    'scriptureConnections',
    'revelationKey',
  },
  'discovery_activation': {
    'mood',
    'imageUrl',
    'title',
    'subtitle',
    'discoveryQuestions',
    'prayer',
  },
  'completion': {'mood', 'imageUrl', 'completionVerse', 'reflectionPrompt'},
  'interactive_moment': {
    'mood',
    'imageUrl',
    'icon',
    'title',
    'subtitle',
    'reflectionPrompt',
    'revelationKey',
  },
};

/// Fields reserved for future implementation. Authored in JSON content today,
/// intentionally not yet wired to any renderer. The debug contract check
/// must never flag these as gaps — this is a documented decision, not a bug.
const Set<String> kDeferredEncounterCardFields = {
  'ambientSound',
  'haptic',
  'celebrationType',
};
