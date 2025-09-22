// lib/blocs/backup_event.dart
import 'package:equatable/equatable.dart';

/// Events for Google Drive backup functionality
abstract class BackupEvent extends Equatable {
  const BackupEvent();

  @override
  List<Object?> get props => [];
}

/// Load backup settings and status
class LoadBackupSettings extends BackupEvent {
  const LoadBackupSettings();
}

/// Toggle automatic backup on/off
class ToggleAutoBackup extends BackupEvent {
  final bool enabled;

  const ToggleAutoBackup(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Change backup frequency (daily, weekly, monthly)
class ChangeBackupFrequency extends BackupEvent {
  final String frequency;

  const ChangeBackupFrequency(this.frequency);

  @override
  List<Object?> get props => [frequency];
}

/// Toggle WiFi-only backup
class ToggleWifiOnly extends BackupEvent {
  final bool enabled;

  const ToggleWifiOnly(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Toggle data compression
class ToggleCompression extends BackupEvent {
  final bool enabled;

  const ToggleCompression(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Update backup options (what to include)
class UpdateBackupOptions extends BackupEvent {
  final Map<String, bool> options;

  const UpdateBackupOptions(this.options);

  @override
  List<Object?> get props => [options];
}

/// Create manual backup
class CreateManualBackup extends BackupEvent {
  const CreateManualBackup();
}

/// Restore from backup
class RestoreFromBackup extends BackupEvent {
  const RestoreFromBackup();
}

/// Load storage information
class LoadStorageInfo extends BackupEvent {
  const LoadStorageInfo();
}

/// Refresh backup status
class RefreshBackupStatus extends BackupEvent {
  const RefreshBackupStatus();
}

/// Sign in to Google Drive
class SignInToGoogleDrive extends BackupEvent {
  const SignInToGoogleDrive();
}

/// Sign out from Google Drive
class SignOutFromGoogleDrive extends BackupEvent {
  const SignOutFromGoogleDrive();
}