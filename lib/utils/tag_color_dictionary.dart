// lib/utils/tag_color_dictionary.dart

import 'package:flutter/material.dart';

/// Dictionary for tag colors and translations
class TagColorDictionary {
  /// Get tag translation based on language
  static String getTagTranslation(String tag, String languageCode) {
    final translations = <String, Map<String, String>>{
      'luz': {
        'es': 'Luz',
        'en': 'Light',
        'pt': 'Luz',
        'fr': 'Lumière',
      },
      'esperanza': {
        'es': 'Esperanza',
        'en': 'Hope',
        'pt': 'Esperança',
        'fr': 'Espoir',
      },
      'fe': {
        'es': 'Fe',
        'en': 'Faith',
        'pt': 'Fé',
        'fr': 'Foi',
      },
      'amor': {
        'es': 'Amor',
        'en': 'Love',
        'pt': 'Amor',
        'fr': 'Amour',
      },
      'paz': {
        'es': 'Paz',
        'en': 'Peace',
        'pt': 'Paz',
        'fr': 'Paix',
      },
      'gracia': {
        'es': 'Gracia',
        'en': 'Grace',
        'pt': 'Graça',
        'fr': 'Grâce',
      },
    };

    final tagKey = tag.toLowerCase();
    final translation = translations[tagKey];
    if (translation != null && translation.containsKey(languageCode)) {
      return translation[languageCode]!;
    }

    // Return capitalized tag if no translation found
    return tag[0].toUpperCase() + tag.substring(1);
  }

  /// Get gradient colors for a tag
  static List<Color> getGradientForTag(String tag) {
    final gradients = <String, List<Color>>{
      'luz': [Colors.amber, Colors.orange],
      'esperanza': [Colors.blue, Colors.lightBlue],
      'fe': [Colors.purple, Colors.deepPurple],
      'amor': [Colors.pink, Colors.red],
      'paz': [Colors.green, Colors.teal],
      'gracia': [Colors.indigo, Colors.blue],
    };

    final tagKey = tag.toLowerCase();
    return gradients[tagKey] ?? [Colors.blue, Colors.lightBlue];
  }
}
