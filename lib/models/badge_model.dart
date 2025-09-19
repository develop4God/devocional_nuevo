// lib/models/badge_model.dart
class Badge {
  final String id;
  final String name;
  final String description;
  final String verse;
  final String reference;
  final String imageUrl;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.verse,
    required this.reference,
    required this.imageUrl,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      verse: json['verse'] as String,
      reference: json['reference'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'verse': verse,
      'reference': reference,
      'imageUrl': imageUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Badge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Badge(id: $id, name: $name, verse: $verse)';
  }
}

class BadgeConfig {
  final String version;
  final String lastUpdated;
  final List<Badge> badges;

  const BadgeConfig({
    required this.version,
    required this.lastUpdated,
    required this.badges,
  });

  factory BadgeConfig.fromJson(Map<String, dynamic> json) {
    return BadgeConfig(
      version: json['version'] as String,
      lastUpdated: json['lastUpdated'] as String,
      badges: (json['badges'] as List<dynamic>)
          .map((badgeJson) => Badge.fromJson(badgeJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'lastUpdated': lastUpdated,
      'badges': badges.map((badge) => badge.toJson()).toList(),
    };
  }
}
