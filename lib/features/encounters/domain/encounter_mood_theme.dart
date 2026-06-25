import 'package:flutter/material.dart';

abstract class EncounterMoodTheme {
  static Color fromMood(String? mood) {
    switch (mood) {
      // Darkness arc
      case 'falling':
        return const Color(0xFF040810);
      case 'darkness':
        return const Color(0xFF050508);
      case 'panic':
        return const Color(0xFF1A0808);
      case 'grief':
        return const Color(0xFF0D0A14);
      case 'ache':
        return const Color(0xFF100A0E);

      // Tension arc
      case 'intense':
        return const Color(0xFF1A0A0E);
      case 'tense':
        return const Color(0xFF0F1828);
      case 'storm':
        return const Color(0xFF0D1A2E);
      case 'crowd':
        return const Color(0xFF0E1410);
      case 'heat':
        return const Color(0xFF1A1008);

      // Transition arc
      case 'mysterious':
        return const Color(0xFF0A0E1A);
      case 'solitude':
        return const Color(0xFF080E14);
      case 'depth':
        return const Color(0xFF0A0E12);
      case 'liminal':
        return const Color(0xFF0E0A14);
      case 'shifting':
        return const Color(0xFF0A1414);
      case 'exposed':
        return const Color(0xFF14100A);

      // Awakening arc
      case 'awe':
        return const Color(0xFF0A1220);
      case 'awakening':
        return const Color(0xFF0A1A12);
      case 'turning_point':
        return const Color(0xFF14120A);
      case 'breakthrough':
        return const Color(0xFF0A1612);
      case 'revelation':
        return const Color(0xFF12140A);
      case 'transformation':
        return const Color(0xFF0A1410);

      // Restoration arc
      case 'grace':
        return const Color(0xFF12100A);
      case 'wonder':
        return const Color(0xFF0A1418);
      case 'intimate':
        return const Color(0xFF120C0A);
      case 'dawn':
        return const Color(0xFF141208);
      case 'sending':
        return const Color(0xFF0C1410);

      // Resolution arc
      case 'peace':
        return const Color(0xFF0A120E);
      case 'open':
        return const Color(0xFF0A1210);

      default:
        return const Color(0xFF0A0E1A);
    }
  }
}
