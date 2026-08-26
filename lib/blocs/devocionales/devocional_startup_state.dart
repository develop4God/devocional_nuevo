// lib/blocs/devocionales/devocional_startup_state.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:equatable/equatable.dart';

/// Why startup ended without any devotionals to show
enum StartupUnavailableReason {
  /// No cache and the network could not be reached
  network,

  /// No cache and the server answered but returned nothing usable
  serverContent,
}

/// States for the devotional startup phase machine.
///
/// Each transition is caused by a prior phase producing its output — never by
/// elapsed wall-clock time.
abstract class DevocionalStartupState extends Equatable {
  const DevocionalStartupState();

  /// True when the splash can be dismissed: content is available to render,
  /// or startup has definitively ended without any.
  bool get isServableOrTerminal => false;

  @override
  List<Object?> get props => [];
}

/// Nothing started yet
class StartupIdle extends DevocionalStartupState {
  const StartupIdle();
}

/// Fetching index.json to learn which years exist and how fresh the cache is
class StartupResolvingIndex extends DevocionalStartupState {
  const StartupResolvingIndex();
}

/// Comparing local cache files against the index
class StartupCheckingCache extends DevocionalStartupState {
  const StartupCheckingCache();
}

/// Cached devotionals are being shown; [refreshing] is true while newer
/// content is still downloading in the background.
class StartupServingCache extends DevocionalStartupState {
  final List<Devocional> devocionales;
  final bool refreshing;

  const StartupServingCache({
    required this.devocionales,
    required this.refreshing,
  });

  @override
  bool get isServableOrTerminal => true;

  @override
  List<Object?> get props => [devocionales, refreshing];
}

/// No cache to show — downloading year files in the foreground
class StartupFetching extends DevocionalStartupState {
  final int yearsDone;
  final int yearsTotal;

  const StartupFetching({required this.yearsDone, required this.yearsTotal});

  @override
  List<Object?> get props => [yearsDone, yearsTotal];
}

/// Devotionals are available
class StartupReady extends DevocionalStartupState {
  final List<Devocional> devocionales;

  const StartupReady(this.devocionales);

  @override
  bool get isServableOrTerminal => true;

  @override
  List<Object?> get props => [devocionales];
}

/// Terminal, retryable: no cache and nothing could be downloaded
class StartupUnavailable extends DevocionalStartupState {
  final StartupUnavailableReason reason;

  const StartupUnavailable(this.reason);

  @override
  bool get isServableOrTerminal => true;

  @override
  List<Object?> get props => [reason];
}
