// lib/repositories/devocional_repository.dart

import 'package:devocional_nuevo/models/devocional_model.dart';

/// Abstract repository for managing devotional-related data
abstract class DevocionalRepository {
  /// Find the index of the first unread devotional
  /// Returns 0 if all devotionals are read or list is empty
  int findFirstUnreadDevocionalIndex(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  );
}
