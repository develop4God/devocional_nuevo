// lib/blocs/prayer_wall/prayer_wall_bloc.dart

import 'dart:async';

import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_event.dart';
import 'package:devocional_nuevo/blocs/prayer_wall/prayer_wall_state.dart';
import 'package:devocional_nuevo/models/prayer_wall_entry.dart';
import 'package:devocional_nuevo/repositories/i_prayer_wall_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC for the Prayer Wall feature.
///
/// Depends on [IPrayerWallRepository] (not concrete implementation — DIP).
/// No singletons; registered and injected via ServiceLocator.
class PrayerWallBloc extends Bloc<PrayerWallEvent, PrayerWallState> {
  final IPrayerWallRepository _repository;

  StreamSubscription<List<PrayerWallEntry>>? _wallSubscription;
  String _userLanguage = 'en';

  PrayerWallBloc({required IPrayerWallRepository repository})
      : _repository = repository,
        super(PrayerWallInitial()) {
    on<LoadPrayerWall>(_onLoadPrayerWall);
    on<PrayerWallStreamUpdated>(_onPrayerWallUpdated);
    on<SubmitPrayer>(_onSubmitPrayer);
    on<TapPrayerHand>(_onTapPrayerHand);
    on<ReportPrayer>(_onReportPrayer);
    on<DeletePrayer>(_onDeletePrayer);
  }

  Future<void> _onLoadPrayerWall(
    LoadPrayerWall event,
    Emitter<PrayerWallState> emit,
  ) async {
    _userLanguage = event.userLanguage;

    emit(PrayerWallLoading());

    await _wallSubscription?.cancel();
    _wallSubscription = _repository
        .watchApprovedPrayers(userLanguage: _userLanguage)
        .listen(
          (prayers) => add(PrayerWallStreamUpdated(prayers)),
          onError: (Object e) {
            debugPrint('❌ [PrayerWallBloc] Stream error: $e');
          },
        );
  }

  void _onPrayerWallUpdated(
    PrayerWallStreamUpdated event,
    Emitter<PrayerWallState> emit,
  ) {
    final prayers = event.prayers.cast<PrayerWallEntry>();
    final sameLanguage =
        prayers.where((p) => p.language == _userLanguage).toList();
    final otherLanguage =
        prayers.where((p) => p.language != _userLanguage).toList();

    final current = state;
    if (current is PrayerWallLoaded) {
      emit(current.copyWith(
        sameLanguagePrayers: sameLanguage,
        otherLanguagePrayers: otherLanguage,
      ));
    } else {
      emit(PrayerWallLoaded(
        sameLanguagePrayers: sameLanguage,
        otherLanguagePrayers: otherLanguage,
      ));
    }
  }

  Future<void> _onSubmitPrayer(
    SubmitPrayer event,
    Emitter<PrayerWallState> emit,
  ) async {
    final trimmed = event.text.trim();
    if (trimmed.isEmpty || trimmed.length > 500) return;

    emit(PrayerSubmitting());

    try {
      final prayerId = await _repository.submitPrayer(
        originalText: trimmed,
        language: event.language,
        isAnonymous: event.isAnonymous,
        authorHash: event.authorHash,
      );

      emit(PrayerSubmitted(prayerId: prayerId));

      // Re-emit loaded state so the wall continues to be visible
      final pending = PrayerWallEntry(
        id: prayerId,
        maskedText: trimmed,
        language: event.language,
        status: PrayerWallStatus.pending,
        isAnonymous: event.isAnonymous,
        prayCount: 0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final current = state;
      if (current is PrayerWallLoaded) {
        emit(current.copyWith(myPendingPrayer: pending));
      } else {
        emit(PrayerWallLoaded(
          sameLanguagePrayers: const [],
          otherLanguagePrayers: const [],
          myPendingPrayer: pending,
        ));
      }
    } catch (e) {
      debugPrint('❌ [PrayerWallBloc] Submit error: $e');
      emit(PrayerWallError('Failed to submit prayer. Please try again.'));
    }
  }

  Future<void> _onTapPrayerHand(
    TapPrayerHand event,
    Emitter<PrayerWallState> emit,
  ) async {
    // Optimistic update
    final current = state;
    if (current is PrayerWallLoaded) {
      final updatedSame = _incrementPrayCount(
          current.sameLanguagePrayers, event.prayerId);
      final updatedOther = _incrementPrayCount(
          current.otherLanguagePrayers, event.prayerId);
      emit(current.copyWith(
        sameLanguagePrayers: updatedSame,
        otherLanguagePrayers: updatedOther,
      ));
    }

    try {
      await _repository.tapPrayHand(prayerId: event.prayerId);
    } catch (e) {
      debugPrint('❌ [PrayerWallBloc] Tap pray error: $e');
    }
  }

  Future<void> _onReportPrayer(
    ReportPrayer event,
    Emitter<PrayerWallState> emit,
  ) async {
    try {
      await _repository.reportPrayer(prayerId: event.prayerId);
    } catch (e) {
      debugPrint('❌ [PrayerWallBloc] Report error: $e');
    }
  }

  Future<void> _onDeletePrayer(
    DeletePrayer event,
    Emitter<PrayerWallState> emit,
  ) async {
    try {
      await _repository.deletePrayer(
        prayerId: event.prayerId,
        authorHash: event.authorHash,
      );
      final current = state;
      if (current is PrayerWallLoaded) {
        emit(current.copyWith(clearPending: true));
      }
    } catch (e) {
      debugPrint('❌ [PrayerWallBloc] Delete error: $e');
    }
  }

  List<PrayerWallEntry> _incrementPrayCount(
      List<PrayerWallEntry> prayers, String prayerId) {
    return prayers
        .map((p) => p.id == prayerId
            ? p.copyWith(prayCount: p.prayCount + 1)
            : p)
        .toList();
  }

  @override
  Future<void> close() {
    _wallSubscription?.cancel();
    return super.close();
  }
}
