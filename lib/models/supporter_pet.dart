import 'package:equatable/equatable.dart';

class SupporterPet extends Equatable {
  final String id;
  final String name;
  final String lottieAsset;
  final String emoji;

  const SupporterPet({
    required this.id,
    required this.name,
    required this.lottieAsset,
    required this.emoji,
  });

  static const List<SupporterPet> allPets = [
    SupporterPet(
      id: 'dog',
      name: 'Fiel amigo',
      lottieAsset: 'assets/lottie/pets/box_dog.json',
      emoji: '🐶',
    ),
    SupporterPet(
      id: 'fish',
      name: 'Pecesito de paz',
      lottieAsset: 'assets/lottie/pets/lion_fish.json',
      emoji: '🐠',
    ),
    SupporterPet(
      id: 'tiger',
      name: 'Valiente',
      lottieAsset: 'assets/lottie/pets/tiger_cute.json',
      emoji: '🐯',
    ),
    SupporterPet(
      id: 'cat',
      name: 'Compañero',
      lottieAsset: 'assets/lottie/pets/cat_play_ball.json',
      emoji: '🐱',
    ),
  ];

  static SupporterPet getById(String id) {
    return allPets.firstWhere((pet) => pet.id == id,
        orElse: () => allPets.first);
  }

  @override
  List<Object?> get props => [id, name, lottieAsset, emoji];
}
