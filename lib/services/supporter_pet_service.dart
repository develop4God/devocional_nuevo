import 'package:shared_preferences/shared_preferences.dart';
import '../models/supporter_pet.dart';

class SupporterPetService {
  static const String _selectedPetKey = 'supporter_selected_pet';
  static const String _showPetHeaderKey = 'supporter_show_pet_header';
  static const String _isPetUnlockedKey = 'supporter_is_pet_unlocked';

  final SharedPreferences _prefs;

  SupporterPetService(this._prefs);

  bool get isPetUnlocked => _prefs.getBool(_isPetUnlockedKey) ?? false;

  Future<void> unlockPetFeature() async {
    await _prefs.setBool(_isPetUnlockedKey, true);
    await _prefs.setBool(_showPetHeaderKey, true); // Auto-enable on unlock
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
