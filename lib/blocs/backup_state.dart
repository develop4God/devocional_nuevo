// lib/blocs/backup_state.dart
import 'package:equatable/equatable.dart';

/// States for Google Drive backup functionality
abstract class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BackupInitial extends BackupState {
  const BackupInitial();
}

/// Loading state
class BackupLoading extends BackupState {
  const BackupLoading();
}

/// Loaded state with all backup settings and info
class BackupLoaded extends BackupState {
  final bool autoBackupEnabled;
  final String backupFrequency;
  final bool wifiOnlyEnabled;
  final bool compressionEnabled;
  final Map<String, bool> backupOptions;
  final DateTime? lastBackupTime;
  final DateTime? nextBackupTime;
  final int estimatedSize;
  final Map<String, dynamic> storageInfo;
  final bool isAuthenticated;
  final String? userEmail;

  const BackupLoaded({
    required this.autoBackupEnabled,
    required this.backupFrequency,
    required this.wifiOnlyEnabled,
    required this.compressionEnabled,
    required this.backupOptions,
    this.lastBackupTime,
    this.nextBackupTime,
    required this.estimatedSize,
    required this.storageInfo,
    required this.isAuthenticated,
    this.userEmail,
  });

  @override
  List<Object?> get props => [
    autoBackupEnabled,
    backupFrequency,
    wifiOnlyEnabled,
    compressionEnabled,
    backupOptions,
    lastBackupTime,
    nextBackupTime,
    estimatedSize,
    storageInfo,
    isAuthenticated,
    userEmail,
  ];

  /// Create a copy with updated values
  BackupLoaded copyWith({
    bool? autoBackupEnabled,
    String? backupFrequency,
    bool? wifiOnlyEnabled,
    bool? compressionEnabled,
    Map<String, bool>? backupOptions,
    DateTime? lastBackupTime,
    DateTime? nextBackupTime,
    int? estimatedSize,
    Map<String, dynamic>? storageInfo,
    bool? isAuthenticated,
    String? userEmail,
  }) {
    return BackupLoaded(
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      wifiOnlyEnabled: wifiOnlyEnabled ?? this.wifiOnlyEnabled,
      compressionEnabled: compressionEnabled ?? this.compressionEnabled,
      backupOptions: backupOptions ?? this.backupOptions,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      nextBackupTime: nextBackupTime ?? this.nextBackupTime,
      estimatedSize: estimatedSize ?? this.estimatedSize,
      storageInfo: storageInfo ?? this.storageInfo,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

/// Creating backup state
class BackupCreating extends BackupState {
  const BackupCreating();
}

/// Backup created successfully
class BackupCreated extends BackupState {
  final DateTime timestamp;

  const BackupCreated(this.timestamp);

  @override
  List<Object?> get props => [timestamp];
}

/// Restoring backup state
class BackupRestoring extends BackupState {
  const BackupRestoring();
}

/// Backup restored successfully
class BackupRestored extends BackupState {
  const BackupRestored();
}

/// Error state
class BackupError extends BackupState {
  final String message;

  const BackupError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Settings updated successfully
class BackupSettingsUpdated extends BackupState {
  const BackupSettingsUpdated();
}

/// Success state for UX feedback
class BackupSuccess extends BackupState {
  final String title;
  final String message;

  const BackupSuccess(this.title, this.message);

  @override
  List<Object?> get props => [title, message];
}
