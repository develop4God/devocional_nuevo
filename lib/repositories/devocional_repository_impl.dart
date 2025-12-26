// lib/repositories/devocional_repository_impl.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'devocional_repository.dart';

/// Concrete implementation of DevocionalRepository
class DevocionalRepositoryImpl implements DevocionalRepository {
  @override
  int findFirstUnreadDevocionalIndex(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  ) {
    if (devocionales.isEmpty) return 0;

    // Start from index 0 and find the first unread devotional
    for (int i = 0; i < devocionales.length; i++) {
      if (!readDevocionalIds.contains(devocionales[i].id)) {
        return i;
      }
    }

    // If all devotionals are read, start from the beginning
    return 0;
  }
}
