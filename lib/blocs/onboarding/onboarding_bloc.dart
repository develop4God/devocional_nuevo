// lib/blocs/onboarding/onboarding_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/onboarding_service.dart';
import '../backup_bloc.dart';
import '../backup_event.dart';
import '../backup_state.dart';
import '../theme/theme_bloc.dart';
import '../theme/theme_event.dart';
import 'onboarding_event.dart';
import 'onboarding_models.dart';
import 'onboarding_state.dart';

/// BLoC for managing onboarding flow functionality
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingService _onboardingService;
  final ThemeBloc _themeBloc;
  final BackupBloc? _backupBloc;

  // Race condition protection
  bool _isProcessingStep = false;
  bool _isCompletingOnboarding = false;

  OnboardingBloc({
    required OnboardingService onboardingService,
    required ThemeBloc themeBloc,
    BackupBloc? backupBloc,
  })  : _onboardingService = onboardingService,
        _themeBloc = themeBloc,
        _backupBloc = backupBloc,
        super(const OnboardingInitial()) {
    // Register event handlers
    on<InitializeOnboarding>(_onInitializeOnboarding);
    on<ProgressToStep>(_onProgressToStep);
    on<SelectTheme>(_onSelectTheme);
    on<ConfigureBackupOption>(_onConfigureBackupOption);
    on<UpdateStepConfiguration>(_onUpdateStepConfiguration);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<ResetOnboarding>(_onResetOnboarding);
    on<SkipCurrentStep>(_onSkipCurrentStep);
    on<GoToPreviousStep>(_onGoToPreviousStep);
    on<UpdatePreview>(_onUpdatePreview);
    on<SkipBackupForNow>(_onSkipBackupForNow);
  }

  /// Skip backup configuration for later
  Future<void> _onSkipBackupForNow(
    SkipBackupForNow event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint('🔄 [ONBOARDING_BLOC] === INICIANDO SkipBackupForNow ===');

    if (state is! OnboardingStepActive) {
      debugPrint(
        '⚠️ [ONBOARDING_BLOC] Cannot skip backup - not in active step state',
      );
      return;
    }

    try {
      final currentState = state as OnboardingStepActive;

      final updatedSelections = Map<String, dynamic>.from(
        currentState.userSelections,
      );
      updatedSelections['backupSkipped'] = true;
      updatedSelections['backupEnabled'] = false;

      await _onboardingService.saveConfiguration(updatedSelections);
      debugPrint(
        '🟢 [ONBOARDING_BLOC] userSelections después de SkipBackupForNow: $updatedSelections',
      );
      emit(
        currentState.copyWith(
          userSelections: updatedSelections,
          stepConfiguration: {'backupSkipped': true},
        ),
      );

      debugPrint(
        '✅ [ONBOARDING_BLOC] Backup marcado como "configurar más tarde"',
      );
    } catch (e, stack) {
      debugPrint('❌ [ONBOARDING_BLOC] Error skipping backup: $e');
      debugPrint('❌ [ONBOARDING_BLOC] Stacktrace: $stack');
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN SkipBackupForNow ===');
  }

  /// Initialize onboarding flow and determine starting point
  Future<void> _onInitializeOnboarding(
    InitializeOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint('🔄 [ONBOARDING_BLOC] === INICIANDO InitializeOnboarding ===');

    try {
      emit(const OnboardingLoading());

      // Check if onboarding is complete
      final isComplete = await _onboardingService.isOnboardingComplete();
      debugPrint('📊 [ONBOARDING_BLOC] Onboarding completado: $isComplete');

      if (isComplete) {
        debugPrint(
          '✅ [ONBOARDING_BLOC] Onboarding ya completado, emitiendo OnboardingCompleted',
        );
        emit(
          OnboardingCompleted(
            appliedConfigurations: await _onboardingService.loadConfiguration(),
            completionTimestamp: DateTime.now(),
          ),
        );
        return;
      }
      // 🔧 NUEVO: Marcar onboarding como en progreso
      await _onboardingService.setOnboardingInProgress(true);
      debugPrint('🚀 [ONBOARDING_BLOC] Onboarding marcado como en progreso');

      // Load saved progress if any
      final savedConfiguration = await _onboardingService.loadConfiguration();
      final savedProgress = await _onboardingService.loadProgress();

      debugPrint(
        '📊 [ONBOARDING_BLOC] Configuración guardada: $savedConfiguration',
      );
      debugPrint('📊 [ONBOARDING_BLOC] Progreso guardado: $savedProgress');

      // Determine starting step
      int startingStep = 0;
      if (savedProgress != null && savedProgress.completedSteps > 0) {
        startingStep = savedProgress.completedSteps;
        if (startingStep >= OnboardingSteps.defaultSteps.length) {
          startingStep = OnboardingSteps.defaultSteps.length - 1;
        }
      }

      final currentStep = OnboardingSteps.defaultSteps[startingStep];
      final progress = savedProgress ??
          OnboardingProgress.fromStepCompletion(
            List.generate(
              OnboardingSteps.defaultSteps.length,
              (index) => false,
            ),
          );

      debugPrint('📊 [ONBOARDING_BLOC] Iniciando en paso: $startingStep');

      emit(
        OnboardingStepActive(
          currentStepIndex: startingStep,
          currentStep: currentStep,
          userSelections: savedConfiguration,
          stepConfiguration: {},
          canProgress: true,
          canGoBack: startingStep > 0,
          progress: progress,
        ),
      );

      debugPrint(
        '✅ [ONBOARDING_BLOC] OnboardingStepActive emitido exitosamente',
      );
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error initializing onboarding: $e');
      emit(
        OnboardingError(
          message: 'onboarding.onboarding_error_loading',
        ),
      );
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN InitializeOnboarding ===');
  }

  /// Progress to specific step with validation
  Future<void> _onProgressToStep(
    ProgressToStep event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint(
      '🔄 [ONBOARDING_BLOC] === INICIANDO ProgressToStep: ${event.stepIndex} ===',
    );

    // Race condition protection
    if (_isProcessingStep) {
      debugPrint(
        '⚠️ [ONBOARDING_BLOC] Step progression already in progress, ignoring duplicate event',
      );
      return;
    }

    if (state is! OnboardingStepActive) {
      debugPrint(
        '⚠️ [ONBOARDING_BLOC] Cannot progress - not in active step state',
      );
      return;
    }

    _isProcessingStep = true;
    try {
      final currentState = state as OnboardingStepActive;

      // Validate step index
      if (event.stepIndex < 0 ||
          event.stepIndex >= OnboardingSteps.defaultSteps.length) {
        debugPrint(
          '❌ [ONBOARDING_BLOC] Invalid step index: ${event.stepIndex}',
        );
        return;
      }

      // Update progress
      final updatedCompletionStatus = List<bool>.from(
        currentState.progress.stepCompletionStatus,
      );
      for (int i = 0; i <= event.stepIndex; i++) {
        if (i < updatedCompletionStatus.length) {
          updatedCompletionStatus[i] = true;
        }
      }

      final updatedProgress = OnboardingProgress.fromStepCompletion(
        updatedCompletionStatus,
      );
      await _onboardingService.saveProgress(updatedProgress);

      final newStep = OnboardingSteps.defaultSteps[event.stepIndex];

      emit(
        currentState.copyWith(
          currentStepIndex: event.stepIndex,
          currentStep: newStep,
          canProgress:
              event.stepIndex < OnboardingSteps.defaultSteps.length - 1,
          canGoBack: event.stepIndex > 0,
          progress: updatedProgress,
          userSelections: currentState.userSelections,
        ),
      );

      debugPrint(
        '✅ [ONBOARDING_BLOC] Progreso a paso ${event.stepIndex} exitoso',
      );
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error progressing to step: $e');
      emit(
        OnboardingError(
          message: 'onboarding.onboarding_error_loading',
        ),
      );
    } finally {
      _isProcessingStep = false;
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN ProgressToStep ===');
  }

  /// Select theme with immediate preview
  Future<void> _onSelectTheme(
    SelectTheme event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint(
      '🔄 [ONBOARDING_BLOC] === INICIANDO SelectTheme: ${event.themeFamily} ===',
    );

    if (state is! OnboardingStepActive) {
      debugPrint(
        '⚠️ [ONBOARDING_BLOC] Cannot select theme - not in active step state',
      );
      return;
    }

    try {
      // Validate theme family input
      if (event.themeFamily.trim().isEmpty) {
        debugPrint(
          '❌ [ONBOARDING_BLOC] Invalid theme family: ${event.themeFamily}',
        );
        emit(
          OnboardingError(
            message: 'onboarding.onboarding_error_loading',
          ),
        );
        return;
      }

      final currentState = state as OnboardingStepActive;

      emit(
        OnboardingConfiguring(
          configurationType: OnboardingConfigurationType.themeSelection,
          configurationData: const {},
        ),
      );

      // Apply theme immediately for preview
      _themeBloc.add(ChangeThemeFamily(event.themeFamily));
      debugPrint(
        '🎨 [ONBOARDING_BLOC] Tema aplicado para preview: ${event.themeFamily}',
      );

      final updatedSelections = Map<String, dynamic>.from(
        currentState.userSelections,
      );
      updatedSelections['selectedThemeFamily'] = event.themeFamily;

      // Validate configuration before saving
      if (!_validateConfiguration(updatedSelections)) {
        debugPrint(
          '❌ [ONBOARDING_BLOC] Invalid configuration: $updatedSelections',
        );
        emit(
          OnboardingError(
            message: 'onboarding.onboarding_error_loading',
          ),
        );
        return;
      }

      // Save configuration
      await _onboardingService.saveConfiguration(updatedSelections);

      emit(
        currentState.copyWith(
          userSelections: updatedSelections,
          stepConfiguration: {'themeApplied': true},
        ),
      );
      debugPrint(
        '🟢 [DEBUG] userSelections después de SelectTheme: $updatedSelections',
      );
      debugPrint('✅ [ONBOARDING_BLOC] Selección de tema exitosa');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error selecting theme: $e');
      emit(
        OnboardingError(
          message: 'onboarding.onboarding_error_loading',
        ),
      );
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN SelectTheme ===');
  }

  /// Configure backup option during onboarding
  Future<void> _onConfigureBackupOption(
    ConfigureBackupOption event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint(
      '🔄 [ONBOARDING_BLOC] === INICIANDO ConfigureBackupOption: ${event.enableBackup} ===',
    );

    if (state is! OnboardingStepActive) {
      debugPrint(
        '⚠️ [ONBOARDING_BLOC] Cannot configure backup - not in active step state',
      );
      return;
    }

    try {
      final currentState = state as OnboardingStepActive;

      // Don't emit OnboardingConfiguring - just update the state silently
      // This keeps state as OnboardingStepActive so navigation can proceed

      final updatedSelections = Map<String, dynamic>.from(
        currentState.userSelections,
      );
      updatedSelections['backupEnabled'] = event.enableBackup;
      updatedSelections['backupSkipped'] = false;

      // Coordinate with BackupBloc if available and backup is enabled
      if (event.enableBackup && _backupBloc != null) {
        debugPrint(
          '🔧 [ONBOARDING_BLOC] Configurando backup a través de BackupBloc',
        );
        _backupBloc?.add(const ToggleAutoBackup(true));
      }

      // Save configuration
      await _onboardingService.saveConfiguration(updatedSelections);

      debugPrint(
        '🟢 [ONBOARDING_BLOC] userSelections después de ConfigureBackupOption: $updatedSelections',
      );

      emit(
        currentState.copyWith(
          userSelections: updatedSelections,
          stepConfiguration: {'backupConfigured': event.enableBackup},
        ),
      );

      debugPrint('✅ [ONBOARDING_BLOC] Configuración de backup exitosa');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error configuring backup: $e');
      emit(
        OnboardingError(
          message: 'onboarding.onboarding_error_loading',
        ),
      );
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN ConfigureBackupOption ===');
  }

  /// Update step configuration
  Future<void> _onUpdateStepConfiguration(
    UpdateStepConfiguration event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint(
      '🔄 [ONBOARDING_BLOC] === INICIANDO UpdateStepConfiguration ===',
    );

    if (state is! OnboardingStepActive) {
      debugPrint(
        '⚠️ [ONBOARDING_BLOC] Cannot update configuration - not in active step state',
      );
      return;
    }

    try {
      final currentState = state as OnboardingStepActive;
      final updatedConfiguration = Map<String, dynamic>.from(
        currentState.stepConfiguration,
      );
      updatedConfiguration.addAll(event.configuration);

      emit(currentState.copyWith(stepConfiguration: updatedConfiguration));

      debugPrint('✅ [ONBOARDING_BLOC] Configuración actualizada');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error updating configuration: $e');
      emit(
        OnboardingError(
          message: 'onboarding.onboarding_error_loading',
        ),
      );
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN UpdateStepConfiguration ===');
  }

  /// Complete onboarding and finalize all configurations
  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint('🔄 [ONBOARDING_BLOC] === INICIANDO CompleteOnboarding ===');

    // Race condition protection
    if (_isCompletingOnboarding) {
      debugPrint(
        '⚠️ [ONBOARDING_BLOC] Onboarding completion already in progress, ignoring duplicate event',
      );
      return;
    }

    _isCompletingOnboarding = true;
    try {
      // 🔧 Step 1: Get base configurations from current state
      Map<String, dynamic> configurations;
      if (state is OnboardingStepActive) {
        configurations = Map<String, dynamic>.from(
          (state as OnboardingStepActive).userSelections,
        );
        debugPrint(
          '🔍 [ONBOARDING_BLOC] Configuraciones desde OnboardingStepActive: $configurations',
        );
      } else {
        configurations = await _onboardingService.loadConfiguration();
        debugPrint(
          '🔍 [ONBOARDING_BLOC] Configuraciones desde SharedPreferences: $configurations',
        );
      }

      debugPrint(
        '🟣 [ONBOARDING_BLOC] State al completar onboarding: ${state.runtimeType}',
      );
      debugPrint(
        '🟣 [ONBOARDING_BLOC] Configuraciones ANTES de enriquecer: $configurations',
      );

      // 🔧 Step 2: Enrich with REAL backup state from BackupBloc BEFORE emitting loading
      final backupBloc = _backupBloc;
      if (backupBloc != null) {
        final backupState = backupBloc.state;
        debugPrint(
          '📊 [ONBOARDING_BLOC] BackupBloc estado: \\${backupState.runtimeType}',
        );

        if (backupState is BackupLoaded) {
          debugPrint(
            '📊 [ONBOARDING_BLOC] BackupBloc isAuthenticated: ${backupState.isAuthenticated}',
          );
          debugPrint(
            '📊 [ONBOARDING_BLOC] BackupBloc autoBackupEnabled: ${backupState.autoBackupEnabled}',
          );

          // Solo sobrescribir si el backup realmente está configurado
          if (backupState.isAuthenticated && backupState.autoBackupEnabled) {
            configurations['backupEnabled'] = true;
            configurations['backupSkipped'] = false;
            configurations['hasActiveBackup'] =
                backupState.lastBackupTime != null;
            configurations['backupCompleted'] =
                backupState.lastBackupTime != null;

            debugPrint(
              '✅ [ONBOARDING_BLOC] Backup info actualizada desde BackupBloc',
            );
            debugPrint(
              '✅ [ONBOARDING_BLOC] backupEnabled: true, backupSkipped: false',
            );
          } else if (!backupState.isAuthenticated &&
              configurations['backupEnabled'] != true) {
            // Usuario no se autenticó Y no tiene backup configurado = skipped
            configurations['backupSkipped'] = true;
            configurations['backupEnabled'] = false;
            debugPrint(
              '📊 [ONBOARDING_BLOC] Backup marcado como skipped (no auth)',
            );
          }
        }
      }

      debugPrint(
        '🟣 [ONBOARDING_BLOC] Configuraciones DESPUÉS de enriquecer: $configurations',
      );

      // 🔧 Step 3: Save enriched configuration BEFORE marking complete
      await _onboardingService.saveConfiguration(configurations);
      debugPrint('💾 [ONBOARDING_BLOC] Configuraciones enriquecidas guardadas');

      // Step 4: Now emit loading
      emit(const OnboardingLoading());

      // Step 5: Mark onboarding as complete
      await _onboardingService.setOnboardingComplete();
      debugPrint('✅ [ONBOARDING_BLOC] Onboarding marcado como completado');

      // Step 6: Clear temporary progress data
      await _onboardingService.clearProgress();

      debugPrint(
        '🟣 [BLOC] Emitiendo OnboardingCompleted con configuración: $configurations',
      );
      emit(
        OnboardingCompleted(
          appliedConfigurations: configurations,
          completionTimestamp: DateTime.now(),
        ),
      );

      debugPrint('✅ [ONBOARDING_BLOC] Onboarding completado exitosamente');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error completing onboarding: $e');
      emit(
        OnboardingError(
          message: 'onboarding.onboarding_error_loading',
        ),
      );
    } finally {
      _isCompletingOnboarding = false;
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN CompleteOnboarding ===');
  }

  /// Reset onboarding for testing/debugging
  Future<void> _onResetOnboarding(
    ResetOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint('🔄 [ONBOARDING_BLOC] === INICIANDO ResetOnboarding ===');

    try {
      await _onboardingService.resetOnboarding();
      await _onboardingService.clearConfiguration();
      await _onboardingService.clearProgress();

      emit(const OnboardingInitial());

      debugPrint('✅ [ONBOARDING_BLOC] Onboarding reset exitoso');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error resetting onboarding: $e');
      emit(
        OnboardingError(
          message: 'onboarding.onboarding_error_loading',
        ),
      );
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN ResetOnboarding ===');
  }

  /// Skip current step
  Future<void> _onSkipCurrentStep(
    SkipCurrentStep event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint('🔄 [ONBOARDING_BLOC] === INICIANDO SkipCurrentStep ===');

    if (state is! OnboardingStepActive) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Cannot skip - not in active step state');
      return;
    }

    final currentState = state as OnboardingStepActive;

    if (!currentState.currentStep.isSkippable) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Current step is not skippable');
      return;
    }

    // Progress to next step
    final nextStepIndex = currentState.currentStepIndex + 1;
    if (nextStepIndex < OnboardingSteps.defaultSteps.length) {
      add(ProgressToStep(nextStepIndex));
    } else {
      add(const CompleteOnboarding());
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN SkipCurrentStep ===');
  }

  /// Go back to previous step
  Future<void> _onGoToPreviousStep(
    GoToPreviousStep event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint('🔄 [ONBOARDING_BLOC] === INICIANDO GoToPreviousStep ===');

    if (state is! OnboardingStepActive) {
      debugPrint(
        '⚠️ [ONBOARDING_BLOC] Cannot go back - not in active step state',
      );
      return;
    }

    final currentState = state as OnboardingStepActive;

    if (!currentState.canGoBack) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Cannot go back from current step');
      return;
    }

    // Progress to previous step
    final previousStepIndex = currentState.currentStepIndex - 1;
    if (previousStepIndex >= 0) {
      add(ProgressToStep(previousStepIndex));
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN GoToPreviousStep ===');
  }

  /// Update preview (for theme selection)
  Future<void> _onUpdatePreview(
    UpdatePreview event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint(
      '🔄 [ONBOARDING_BLOC] === INICIANDO UpdatePreview: ${event.previewType} ===',
    );

    if (state is! OnboardingStepActive) {
      debugPrint(
        '⚠️ [ONBOARDING_BLOC] Cannot update preview - not in active step state',
      );
      return;
    }

    try {
      final currentState = state as OnboardingStepActive;
      final updatedConfiguration = Map<String, dynamic>.from(
        currentState.stepConfiguration,
      );
      updatedConfiguration['preview_${event.previewType}'] = event.previewValue;

      emit(currentState.copyWith(stepConfiguration: updatedConfiguration));

      debugPrint('✅ [ONBOARDING_BLOC] Preview actualizado');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error updating preview: $e');
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN UpdatePreview ===');
  }

  /// Validate configuration before applying
  bool _validateConfiguration(Map<String, dynamic> configuration) {
    try {
      // Check for valid theme family if provided
      if (configuration.containsKey('selectedThemeFamily')) {
        final themeFamily = configuration['selectedThemeFamily'];
        if (themeFamily != null && themeFamily is! String) {
          debugPrint(
            '❌ [ONBOARDING_BLOC] Invalid theme family type: ${themeFamily.runtimeType}',
          );
          return false;
        }
        if (themeFamily is String && themeFamily.trim().isEmpty) {
          debugPrint('❌ [ONBOARDING_BLOC] Theme family cannot be empty');
          return false;
        }
      }

      // Check for valid backup enabled flag if provided
      if (configuration.containsKey('backupEnabled')) {
        final backupEnabled = configuration['backupEnabled'];
        if (backupEnabled != null && backupEnabled is! bool) {
          debugPrint(
            '❌ [ONBOARDING_BLOC] Invalid backup enabled type: ${backupEnabled.runtimeType}',
          );
          return false;
        }
      }

      // Check for valid language if provided
      if (configuration.containsKey('selectedLanguage')) {
        final language = configuration['selectedLanguage'];
        if (language != null && language is! String) {
          debugPrint(
            '❌ [ONBOARDING_BLOC] Invalid language type: ${language.runtimeType}',
          );
          return false;
        }
      }

      debugPrint('✅ [ONBOARDING_BLOC] Configuration validation passed');
      return true;
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Configuration validation error: $e');
      return false;
    }
  }
}
