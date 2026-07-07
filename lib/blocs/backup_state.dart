// lib/blocs/backup_state.dart
import 'package:equatable/equatable.dart';

import '../extensions/string_extensions.dart';
import '../models/backup_content_summary.dart';

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
  final bool isAuthenticated;
  final String? userEmail;

  /// Item-count summary for the backup payload. Null until first load.
  final BackupContentSummary? contentSummary;

  const BackupLoaded({
    required this.autoBackupEnabled,
    required this.backupFrequency,
    required this.wifiOnlyEnabled,
    required this.compressionEnabled,
    required this.backupOptions,
    this.lastBackupTime,
    this.nextBackupTime,
    required this.estimatedSize,
    required this.isAuthenticated,
    this.userEmail,
    this.contentSummary,
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
        isAuthenticated,
        userEmail,
        contentSummary,
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
    bool? isAuthenticated,
    String? userEmail,
    BackupContentSummary? contentSummary,
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
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: userEmail ?? this.userEmail,
      contentSummary: contentSummary ?? this.contentSummary,
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

/// Signing in to Google Drive state
class BackupSigningIn extends BackupState {
  const BackupSigningIn();
}

/// Restoring backup state
class BackupRestoring extends BackupState {
  const BackupRestoring();
}

/// Backup restored successfully
class BackupRestored extends BackupState {
  final String? restoredVersion;
  const BackupRestored({this.restoredVersion});

  @override
  List<Object?> get props => [restoredVersion];
}

/// Error state
class BackupError extends BackupState {
  final String message;

  /// True when [message] is raw text (an interpolated exception, or a
  /// hardcoded literal) that must never be shown to the user verbatim.
  /// False (default) means [message] is a real translation key, safe to
  /// resolve via .tr(). Not part of [props] -- it's a display hint tied to
  /// how [message] was constructed at the call site, not part of the
  /// error's identity for equality purposes.
  final bool isRawText;

  const BackupError(this.message, {this.isRawText = false});

  /// Resolves [message] for display: a real key through .tr(), raw text
  /// through the generic localized error instead of showing it verbatim.
  String get localizedMessage =>
      isRawText ? 'backup.error_generic'.tr() : message.tr();

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

  /// Optional content summary shown in the success overlay.
  final BackupContentSummary? contentSummary;

  const BackupSuccess(this.title, this.message, {this.contentSummary});

  @override
  List<Object?> get props => [title, message, contentSummary];
}
