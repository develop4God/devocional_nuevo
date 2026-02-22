import 'package:equatable/equatable.dart';

class SupporterPet extends Equatable {
  final String id;

  /// Translation key for the pet's display name (e.g. 'supporter.pet_dog_name').
  /// Use `.tr()` to resolve the localized string at render time.
  final String nameKey;
  final String lottieAsset;
  final String emoji;

  const SupporterPet({
    required this.id,
    required this.nameKey,
    required this.lottieAsset,
    required this.emoji,
  });

  static const List<SupporterPet> allPets = [
    SupporterPet(
      id: 'dog',
      nameKey: 'supporter.pet_dog_name',
      lottieAsset: 'assets/lottie/pets/box_dog.json',
      emoji: '🐶',
    ),
    SupporterPet(
      id: 'fish',
      nameKey: 'supporter.pet_fish_name',
      lottieAsset: 'assets/lottie/pets/lion_fish.json',
      emoji: '🐠',
    ),
    SupporterPet(
      id: 'tiger',
      nameKey: 'supporter.pet_tiger_name',
      lottieAsset: 'assets/lottie/pets/tiger_cute.json',
      emoji: '🐯',
    ),
    SupporterPet(
      id: 'cat',
      nameKey: 'supporter.pet_cat_name',
      lottieAsset: 'assets/lottie/pets/cat_play_ball.json',
      emoji: '🐱',
    ),
  ];

  static SupporterPet getById(String id) {
    return allPets.firstWhere((pet) => pet.id == id,
        orElse: () => allPets.first);
  }

  @override
  List<Object?> get props => [id, nameKey, lottieAsset, emoji];
}
