import 'package:shared_preferences/shared_preferences.dart';

import '../models/supporter_pet.dart';

class SupporterPetService {
  static const String _selectedPetKey = 'supporter_selected_pet';
  static const String _showPetHeaderKey = 'supporter_show_pet_header';
  static const String _isPetUnlockedKey = 'supporter_is_pet_unlocked';
  static const String _goldSetupPendingKey = 'supporter_gold_setup_pending';

  final SharedPreferences _prefs;

  SupporterPetService(this._prefs);

  bool get isPetUnlocked => _prefs.getBool(_isPetUnlockedKey) ?? false;

  /// True when Gold was purchased but the user dismissed the setup dialog
  /// before choosing a name/pet. The supporter_page shows a banner to resume.
  bool get isGoldSetupPending => _prefs.getBool(_goldSetupPendingKey) ?? false;

  Future<void> markGoldSetupPending() async {
    await _prefs.setBool(_goldSetupPendingKey, true);
  }

  Future<void> clearGoldSetupPending() async {
    await _prefs.setBool(_goldSetupPendingKey, false);
  }

  Future<void> unlockPetFeature() async {
    await _prefs.setBool(_isPetUnlockedKey, true);
    await _prefs.setBool(_showPetHeaderKey, true);
    await _prefs.setBool(_goldSetupPendingKey, false); // setup complete
  }

  SupporterPet get selectedPet {
    final id = _prefs.getString(_selectedPetKey) ?? 'dog';
    return SupporterPet.getById(id);
  }

  Future<void> setSelectedPet(String petId) async {
    await _prefs.setString(_selectedPetKey, petId);
  }

  bool get showPetHeader => _prefs.getBool(_showPetHeaderKey) ?? false;

  Future<void> setShowPetHeader(bool show) async {
    await _prefs.setBool(_showPetHeaderKey, show);
  }
}
