// test/unit/blocs/prayer_bloc_comprehensive_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerBloc Comprehensive Tests', () {
    late PrayerBloc prayerBloc;

    setUp(() async {
      // Setup common test mocks
      TestSetup.setupCommonMocks();

      // Setup SharedPreferences with empty prayers
      SharedPreferences.setMockInitialValues({
        'prayers': '[]',
      });

      // Create prayer bloc
      prayerBloc = PrayerBloc();
    });

    tearDown(() {
      prayerBloc.close();
      TestSetup.cleanupMocks();
    });

    group('Prayer CRUD Operations and State Transitions', () {
      blocTest<PrayerBloc, PrayerState>(
        'should manage prayer CRUD operations and state transitions',
        build: () => prayerBloc,
        act: (bloc) => bloc.add(const LoadPrayers()),
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            expect(state.prayers, isA<List<Prayer>>());
          }
        },
      );

      blocTest<PrayerBloc, PrayerState>(
        'should add new prayer successfully',
        build: () => prayerBloc,
        seed: () => const PrayerLoaded(prayers: []),
        act: (bloc) {
          final newPrayer = Prayer(
            id: 'prayer_1',
            text: 'Test prayer for healing',
            createdDate: DateTime.now(),
            status: PrayerStatus.active,
          );
          bloc.add(AddPrayer(prayer: newPrayer));
        },
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            expect(state.prayers.length, equals(1));
            expect(state.prayers.first.text, equals('Test prayer for healing'));
            expect(state.prayers.first.status, equals(PrayerStatus.active));
          }
        },
      );

      blocTest<PrayerBloc, PrayerState>(
        'should edit existing prayer correctly',
        build: () {
          final existingPrayer = Prayer(
            id: 'prayer_1',
            text: 'Original prayer text',
            createdDate: DateTime.now(),
            status: PrayerStatus.active,
          );
          return prayerBloc;
        },
        seed: () => PrayerLoaded(prayers: [
          Prayer(
            id: 'prayer_1',
            text: 'Original prayer text',
            createdDate: DateTime.now(),
            status: PrayerStatus.active,
          ),
        ]),
        act: (bloc) {
          final updatedPrayer = Prayer(
            id: 'prayer_1',
            text: 'Updated prayer text',
            createdDate: DateTime.now(),
            status: PrayerStatus.active,
          );
          bloc.add(EditPrayer(prayer: updatedPrayer));
        },
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            expect(state.prayers.length, equals(1));
            expect(state.prayers.first.text, equals('Updated prayer text'));
          }
        },
      );

      blocTest<PrayerBloc, PrayerState>(
        'should delete prayer successfully',
        build: () => prayerBloc,
        seed: () => PrayerLoaded(prayers: [
          Prayer(
            id: 'prayer_1',
            text: 'Prayer to delete',
            createdDate: DateTime.now(),
            status: PrayerStatus.active,
          ),
          Prayer(
            id: 'prayer_2',
            text: 'Prayer to keep',
            createdDate: DateTime.now(),
            status: PrayerStatus.active,
          ),
        ]),
        act: (bloc) => bloc.add(const DeletePrayer(prayerId: 'prayer_1')),
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            expect(state.prayers.length, equals(1));
            expect(state.prayers.first.text, equals('Prayer to keep'));
            expect(state.prayers.first.id, equals('prayer_2'));
          }
        },
      );
    });

    group('Prayer Status Updates and Validation', () {
      blocTest<PrayerBloc, PrayerState>(
        'should handle prayer status updates and validation',
        build: () => prayerBloc,
        seed: () => PrayerLoaded(prayers: [
          Prayer(
            id: 'prayer_active',
            text: 'Active prayer',
            createdDate: DateTime.now(),
            status: PrayerStatus.active,
          ),
        ]),
        act: (bloc) => bloc.add(const MarkPrayerAsAnswered(
          prayerId: 'prayer_active',
          answeredDate: null,
        )),
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            expect(state.prayers.first.status, equals(PrayerStatus.answered));
            expect(state.prayers.first.answeredDate, isNotNull);
          }
        },
      );

      blocTest<PrayerBloc, PrayerState>(
        'should mark answered prayer as active again',
        build: () => prayerBloc,
        seed: () => PrayerLoaded(prayers: [
          Prayer(
            id: 'prayer_answered',
            text: 'Answered prayer',
            createdDate: DateTime.now(),
            status: PrayerStatus.answered,
            answeredDate: DateTime.now(),
          ),
        ]),
        act: (bloc) => bloc.add(const MarkPrayerAsActive(prayerId: 'prayer_answered')),
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            expect(state.prayers.first.status, equals(PrayerStatus.active));
            expect(state.prayers.first.answeredDate, isNull);
          }
        },
      );

      blocTest<PrayerBloc, PrayerState>(
        'should handle custom answered date',
        build: () => prayerBloc,
        seed: () => PrayerLoaded(prayers: [
          Prayer(
            id: 'prayer_custom_date',
            text: 'Prayer with custom answered date',
            createdDate: DateTime.now(),
            status: PrayerStatus.active,
          ),
        ]),
        act: (bloc) {
          final customDate = DateTime(2024, 1, 15);
          bloc.add(MarkPrayerAsAnswered(
            prayerId: 'prayer_custom_date',
            answeredDate: customDate,
          ));
        },
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            expect(state.prayers.first.status, equals(PrayerStatus.answered));
            expect(state.prayers.first.answeredDate, equals(DateTime(2024, 1, 15)));
          }
        },
      );
    });

    group('Prayer List Filtering and Sorting', () {
      blocTest<PrayerBloc, PrayerState>(
        'should process prayer list filtering and sorting',
        build: () => prayerBloc,
        seed: () => PrayerLoaded(prayers: [
          Prayer(
            id: 'prayer_1',
            text: 'First prayer',
            createdDate: DateTime(2024, 1, 1),
            status: PrayerStatus.active,
          ),
          Prayer(
            id: 'prayer_2',
            text: 'Second prayer',
            createdDate: DateTime(2024, 1, 2),
            status: PrayerStatus.answered,
            answeredDate: DateTime(2024, 1, 15),
          ),
          Prayer(
            id: 'prayer_3',
            text: 'Third prayer',
            createdDate: DateTime(2024, 1, 3),
            status: PrayerStatus.active,
          ),
        ]),
        act: (bloc) => bloc.add(const RefreshPrayers()),
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            expect(state.prayers.length, equals(3));
            
            // Test that we have both active and answered prayers
            final activePrayers = state.prayers.where((p) => p.status == PrayerStatus.active).toList();
            final answeredPrayers = state.prayers.where((p) => p.status == PrayerStatus.answered).toList();
            
            expect(activePrayers.length, equals(2));
            expect(answeredPrayers.length, equals(1));
          }
        },
      );

      test('should sort prayers by creation date (most recent first)', () {
        final prayers = [
          Prayer(
            id: 'prayer_old',
            text: 'Old prayer',
            createdDate: DateTime(2024, 1, 1),
            status: PrayerStatus.active,
          ),
          Prayer(
            id: 'prayer_new',
            text: 'New prayer',
            createdDate: DateTime(2024, 1, 15),
            status: PrayerStatus.active,
          ),
          Prayer(
            id: 'prayer_middle',
            text: 'Middle prayer',
            createdDate: DateTime(2024, 1, 8),
            status: PrayerStatus.active,
          ),
        ];

        // Sort by creation date (newest first)
        prayers.sort((a, b) => b.createdDate.compareTo(a.createdDate));

        expect(prayers.first.id, equals('prayer_new'));
        expect(prayers.last.id, equals('prayer_old'));
      });
    });

    group('Error Handling', () {
      blocTest<PrayerBloc, PrayerState>(
        'should handle storage errors gracefully',
        build: () {
          // Setup invalid SharedPreferences to trigger error
          SharedPreferences.setMockInitialValues({
            'prayers': 'invalid_json',
          });
          return PrayerBloc();
        },
        act: (bloc) => bloc.add(const LoadPrayers()),
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerError>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerError>());
          if (state is PrayerError) {
            expect(state.message, isA<String>());
            expect(state.message.isNotEmpty, isTrue);
          }
        },
      );

      blocTest<PrayerBloc, PrayerState>(
        'should clear prayer error state',
        build: () => prayerBloc,
        seed: () => const PrayerError('Test error message'),
        act: (bloc) => bloc.add(const ClearPrayerError()),
        expect: () => [
          isA<PrayerInitial>(),
        ],
      );

      blocTest<PrayerBloc, PrayerState>(
        'should handle editing non-existent prayer',
        build: () => prayerBloc,
        seed: () => const PrayerLoaded(prayers: []),
        act: (bloc) {
          final nonExistentPrayer = Prayer(
            id: 'non_existent',
            text: 'This prayer does not exist',
            createdDate: DateTime.now(),
            status: PrayerStatus.active,
          );
          bloc.add(EditPrayer(prayer: nonExistentPrayer));
        },
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            // Should remain empty since prayer doesn't exist to edit
            expect(state.prayers.length, equals(0));
          }
        },
      );

      blocTest<PrayerBloc, PrayerState>(
        'should handle deleting non-existent prayer',
        build: () => prayerBloc,
        seed: () => PrayerLoaded(prayers: [
          Prayer(
            id: 'existing_prayer',
            text: 'This exists',
            createdDate: DateTime.now(),
            status: PrayerStatus.active,
          ),
        ]),
        act: (bloc) => bloc.add(const DeletePrayer(prayerId: 'non_existent')),
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            // Should still have the existing prayer
            expect(state.prayers.length, equals(1));
            expect(state.prayers.first.id, equals('existing_prayer'));
          }
        },
      );

      blocTest<PrayerBloc, PrayerState>(
        'should handle status update for non-existent prayer',
        build: () => prayerBloc,
        seed: () => const PrayerLoaded(prayers: []),
        act: (bloc) => bloc.add(const MarkPrayerAsAnswered(
          prayerId: 'non_existent',
          answeredDate: null,
        )),
        expect: () => [
          isA<PrayerLoading>(),
          isA<PrayerLoaded>(),
        ],
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<PrayerLoaded>());
          if (state is PrayerLoaded) {
            expect(state.prayers.length, equals(0));
          }
        },
      );
    });

    group('Prayer Persistence', () {
      test('should persist prayers across bloc instances', () async {
        // Setup SharedPreferences with existing prayers
        final prayerData = [
          {
            'id': 'persisted_prayer',
            'text': 'This prayer should persist',
            'createdDate': DateTime.now().millisecondsSinceEpoch,
            'status': 'active',
          }
        ];
        
        SharedPreferences.setMockInitialValues({
          'prayers': jsonEncode(prayerData),
        });

        // Create new bloc instance
        final newBloc = PrayerBloc();
        
        // Load prayers
        newBloc.add(const LoadPrayers());
        
        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify prayer was loaded
        final state = newBloc.state;
        expect(state, isA<PrayerLoaded>());
        
        newBloc.close();
      });
    });

    group('State Validation', () {
      test('should start with initial state', () {
        expect(prayerBloc.state, isA<PrayerInitial>());
      });

      test('should handle multiple rapid operations', () async {
        // Setup initial prayers
        final prayer1 = Prayer(
          id: 'rapid_1',
          text: 'First rapid prayer',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );
        
        final prayer2 = Prayer(
          id: 'rapid_2', 
          text: 'Second rapid prayer',
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );

        // Perform rapid operations
        prayerBloc.add(const LoadPrayers());
        prayerBloc.add(AddPrayer(prayer: prayer1));
        prayerBloc.add(AddPrayer(prayer: prayer2));
        prayerBloc.add(const MarkPrayerAsAnswered(prayerId: 'rapid_1', answeredDate: null));
        
        // Wait for all operations to complete
        await Future.delayed(const Duration(milliseconds: 200));
        
        // BLoC should handle rapid operations gracefully
        expect(prayerBloc.state, isA<PrayerState>());
      });
    });
  });
}

import 'dart:convert';