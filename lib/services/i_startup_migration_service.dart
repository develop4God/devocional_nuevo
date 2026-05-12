// lib/services/i_startup_migration_service.dart
import 'package:devocional_nuevo/models/devocional_model.dart';

abstract interface class IStartupMigrationService {
  /// Run all registered one-time startup migrations in order.
  /// Each migration is self-guarded and will no-op after its first run.
  Future<void> runAll(
    List<Devocional> devocionales,
    List<String> readDevocionalIds,
  );
}
