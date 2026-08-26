// lib/blocs/devocionales/devocional_startup_event.dart

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:equatable/equatable.dart';

/// Events for the devotional startup phase machine
abstract class DevocionalStartupEvent extends Equatable {
  const DevocionalStartupEvent();

  @override
  List<Object?> get props => [];
}

/// Begin startup for [language]/[version]
class StartupRequested extends DevocionalStartupEvent {
  final String language;
  final String version;

  const StartupRequested({required this.language, required this.version});

  @override
  List<Object?> get props => [language, version];
}

/// Re-enter startup after an [StartupUnavailable] outcome
class StartupRetryRequested extends DevocionalStartupEvent {
  const StartupRetryRequested();
}

/// Internal: one year's devotionals finished downloading
class StartupYearLoaded extends DevocionalStartupEvent {
  final int year;
  final List<Devocional> devocionales;

  const StartupYearLoaded({required this.year, required this.devocionales});

  @override
  List<Object?> get props => [year, devocionales];
}

/// Internal: a phase could not produce its output
class StartupPhaseFailed extends DevocionalStartupEvent {
  final String reason;

  const StartupPhaseFailed(this.reason);

  @override
  List<Object?> get props => [reason];
}
