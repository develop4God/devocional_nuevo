// lib/blocs/onboarding/onboarding_bloc.dart
import 'dart:convert'; // ✅ Required for jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/theme_provider.dart';
import '../../services/onboarding_service.dart';
import '../backup_bloc.dart';
import '../backup_event.dart';
import 'onboarding_event.dart';
import 'onboarding_models.dart';
import 'onboarding_state.dart';

/// BLoC for managing onboarding flow functionality
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingService _onboardingService;
  final ThemeProvider _themeProvider;
  final BackupBloc? _backupBloc;

  // Configuration persistence keys
  static const String _configurationKey = 'onboarding_configuration';
  static const String _progressKey = 'onboarding_progress';

  OnboardingBloc({
    required OnboardingService onboardingService,
    required ThemeProvider themeProvider,
    BackupBloc? backupBloc,
  })  : _onboardingService = onboardingService,
        _themeProvider = themeProvider,
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
            '✅ [ONBOARDING_BLOC] Onboarding ya completado, emitiendo OnboardingCompleted');
        emit(OnboardingCompleted(
          appliedConfigurations: await _loadSavedConfiguration(),
          completionTimestamp: DateTime.now(),
        ));
        return;
      }

      // Load saved progress if any
      final savedConfiguration = await _loadSavedConfiguration();
      final savedProgress = await _loadSavedProgress();

      debugPrint(
          '📊 [ONBOARDING_BLOC] Configuración guardada: $savedConfiguration');
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
                OnboardingSteps.defaultSteps.length, (index) => false),
          );

      debugPrint('📊 [ONBOARDING_BLOC] Iniciando en paso: $startingStep');

      emit(OnboardingStepActive(
        currentStepIndex: startingStep,
        currentStep: currentStep,
        userSelections: savedConfiguration,
        stepConfiguration: {},
        canProgress: true,
        canGoBack: startingStep > 0,
        progress: progress,
      ));

      debugPrint(
          '✅ [ONBOARDING_BLOC] OnboardingStepActive emitido exitosamente');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error initializing onboarding: $e');
      emit(OnboardingError(
        message: 'Error initializing onboarding: ${e.toString()}',
        category: OnboardingErrorCategory.unknown,
        errorContext: {'error': e.toString()},
      ));
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN InitializeOnboarding ===');
  }

  /// Progress to specific step with validation
  Future<void> _onProgressToStep(
    ProgressToStep event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint(
        '🔄 [ONBOARDING_BLOC] === INICIANDO ProgressToStep: ${event.stepIndex} ===');

    if (state is! OnboardingStepActive) {
      debugPrint(
          '⚠️ [ONBOARDING_BLOC] Cannot progress - not in active step state');
      return;
    }

    try {
      final currentState = state as OnboardingStepActive;

      // Validate step index
      if (event.stepIndex < 0 ||
          event.stepIndex >= OnboardingSteps.defaultSteps.length) {
        debugPrint(
            '❌ [ONBOARDING_BLOC] Invalid step index: ${event.stepIndex}');
        return;
      }

      // Update progress
      final updatedCompletionStatus =
          List<bool>.from(currentState.progress.stepCompletionStatus);
      for (int i = 0; i <= event.stepIndex; i++) {
        if (i < updatedCompletionStatus.length) {
          updatedCompletionStatus[i] = true;
        }
      }

      final updatedProgress =
          OnboardingProgress.fromStepCompletion(updatedCompletionStatus);
      await _saveProgress(updatedProgress);

      final newStep = OnboardingSteps.defaultSteps[event.stepIndex];

      emit(currentState.copyWith(
        currentStepIndex: event.stepIndex,
        currentStep: newStep,
        canProgress: event.stepIndex < OnboardingSteps.defaultSteps.length - 1,
        canGoBack: event.stepIndex > 0,
        progress: updatedProgress,
      ));

      debugPrint(
          '✅ [ONBOARDING_BLOC] Progreso a paso ${event.stepIndex} exitoso');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error progressing to step: $e');
      emit(OnboardingError(
        message: 'Error progressing to step: ${e.toString()}',
        category: OnboardingErrorCategory.unknown,
        errorContext: {'stepIndex': event.stepIndex, 'error': e.toString()},
      ));
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN ProgressToStep ===');
  }

  /// Select theme with immediate preview
  Future<void> _onSelectTheme(
    SelectTheme event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint(
        '🔄 [ONBOARDING_BLOC] === INICIANDO SelectTheme: ${event.themeFamily} ===');

    if (state is! OnboardingStepActive) {
      debugPrint(
          '⚠️ [ONBOARDING_BLOC] Cannot select theme - not in active step state');
      return;
    }

    try {
      // Validate theme family input
      if (!_validateThemeFamily(event.themeFamily)) {
        emit(OnboardingError(
          message: 'Invalid theme family: ${event.themeFamily}',
          category: OnboardingErrorCategory.invalidConfiguration,
          errorContext: {'themeFamily': event.themeFamily},
        ));
        return;
      }

      final currentState = state as OnboardingStepActive;
      
      emit(OnboardingConfiguring(
        configurationType: OnboardingConfigurationType.themeSelection,
        configurationData: const {},
      ));

      // Apply theme immediately for preview
      await _themeProvider.setThemeFamily(event.themeFamily);
      debugPrint(
          '🎨 [ONBOARDING_BLOC] Tema aplicado para preview: ${event.themeFamily}');

      final updatedSelections =
          Map<String, dynamic>.from(currentState.userSelections);
      updatedSelections['selectedThemeFamily'] = event.themeFamily;

      // Validate configuration before saving
      if (!_validateConfiguration(updatedSelections)) {
        emit(OnboardingError(
          message: 'Configuration validation failed',
          category: OnboardingErrorCategory.invalidConfiguration,
          errorContext: {'configuration': updatedSelections},
        ));
        return;
      }

      // Save configuration
      await _saveConfiguration(updatedSelections);

      emit(currentState.copyWith(
        userSelections: updatedSelections,
        stepConfiguration: {'themeApplied': true},
      ));

      debugPrint('✅ [ONBOARDING_BLOC] Selección de tema exitosa');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error selecting theme: $e');
      emit(OnboardingError(
        message: 'Error selecting theme: ${e.toString()}',
        category: OnboardingErrorCategory.invalidConfiguration,
        errorContext: {'themeFamily': event.themeFamily, 'error': e.toString()},
      ));
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN SelectTheme ===');
  }

  /// Configure backup option during onboarding
  Future<void> _onConfigureBackupOption(
    ConfigureBackupOption event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint(
        '🔄 [ONBOARDING_BLOC] === INICIANDO ConfigureBackupOption: ${event.enableBackup} ===');

    if (state is! OnboardingStepActive) {
      debugPrint(
          '⚠️ [ONBOARDING_BLOC] Cannot configure backup - not in active step state');
      return;
    }

    try {
      final currentState = state as OnboardingStepActive;
      
      emit(OnboardingConfiguring(
        configurationType: OnboardingConfigurationType.backupConfiguration,
        configurationData: {'enableBackup': event.enableBackup},
      ));

      final updatedSelections =
          Map<String, dynamic>.from(currentState.userSelections);
      updatedSelections['backupEnabled'] = event.enableBackup;

      // Coordinate with BackupBloc if available and backup is enabled
      if (event.enableBackup && _backupBloc != null) {
        debugPrint(
            '🔧 [ONBOARDING_BLOC] Configurando backup a través de BackupBloc');
        _backupBloc!.add(const ToggleAutoBackup(true));
      }

      // Save configuration
      await _saveConfiguration(updatedSelections);

      emit(currentState.copyWith(
        userSelections: updatedSelections,
        stepConfiguration: {'backupConfigured': event.enableBackup},
      ));

      debugPrint('✅ [ONBOARDING_BLOC] Configuración de backup exitosa');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error configuring backup: $e');
      emit(OnboardingError(
        message: 'Error configuring backup: ${e.toString()}',
        category: OnboardingErrorCategory.serviceUnavailable,
        errorContext: {
          'enableBackup': event.enableBackup,
          'error': e.toString()
        },
      ));
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN ConfigureBackupOption ===');
  }

  /// Update step configuration
  Future<void> _onUpdateStepConfiguration(
    UpdateStepConfiguration event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint(
        '🔄 [ONBOARDING_BLOC] === INICIANDO UpdateStepConfiguration ===');

    if (state is! OnboardingStepActive) {
      debugPrint(
          '⚠️ [ONBOARDING_BLOC] Cannot update configuration - not in active step state');
      return;
    }

    try {
      final currentState = state as OnboardingStepActive;
      final updatedConfiguration =
          Map<String, dynamic>.from(currentState.stepConfiguration);
      updatedConfiguration.addAll(event.configuration);

      emit(currentState.copyWith(stepConfiguration: updatedConfiguration));

      debugPrint('✅ [ONBOARDING_BLOC] Configuración actualizada');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error updating configuration: $e');
      emit(OnboardingError(
        message: 'Error updating configuration: ${e.toString()}',
        category: OnboardingErrorCategory.unknown,
        errorContext: {
          'configuration': event.configuration,
          'error': e.toString()
        },
      ));
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN UpdateStepConfiguration ===');
  }

  /// Complete onboarding and finalize all configurations
  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    debugPrint('🔄 [ONBOARDING_BLOC] === INICIANDO CompleteOnboarding ===');

    try {
      // Get configurations from current state before emitting loading
      Map<String, dynamic> configurations;
      if (state is OnboardingStepActive) {
        configurations = (state as OnboardingStepActive).userSelections;
      } else {
        configurations = await _loadSavedConfiguration();
      }

      emit(const OnboardingLoading());

      // Mark onboarding as complete
      await _onboardingService.setOnboardingComplete();
      debugPrint('✅ [ONBOARDING_BLOC] Onboarding marcado como completado');

      // Clear temporary progress data
      await _clearSavedProgress();

      emit(OnboardingCompleted(
        appliedConfigurations: configurations,
        completionTimestamp: DateTime.now(),
      ));

      debugPrint('✅ [ONBOARDING_BLOC] Onboarding completado exitosamente');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error completing onboarding: $e');
      emit(OnboardingError(
        message: 'Error completing onboarding: ${e.toString()}',
        category: OnboardingErrorCategory.unknown,
        errorContext: {'error': e.toString()},
      ));
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
      await _clearSavedConfiguration();
      await _clearSavedProgress();

      emit(const OnboardingInitial());

      debugPrint('✅ [ONBOARDING_BLOC] Onboarding reset exitoso');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error resetting onboarding: $e');
      emit(OnboardingError(
        message: 'Error resetting onboarding: ${e.toString()}',
        category: OnboardingErrorCategory.unknown,
        errorContext: {'error': e.toString()},
      ));
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
          '⚠️ [ONBOARDING_BLOC] Cannot go back - not in active step state');
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
        '🔄 [ONBOARDING_BLOC] === INICIANDO UpdatePreview: ${event.previewType} ===');

    if (state is! OnboardingStepActive) {
      debugPrint(
          '⚠️ [ONBOARDING_BLOC] Cannot update preview - not in active step state');
      return;
    }

    try {
      final currentState = state as OnboardingStepActive;
      final updatedConfiguration =
          Map<String, dynamic>.from(currentState.stepConfiguration);
      updatedConfiguration['preview_${event.previewType}'] = event.previewValue;

      emit(currentState.copyWith(stepConfiguration: updatedConfiguration));

      debugPrint('✅ [ONBOARDING_BLOC] Preview actualizado');
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Error updating preview: $e');
    }

    debugPrint('🏁 [ONBOARDING_BLOC] === FIN UpdatePreview ===');
  }

  /// Load saved configuration from SharedPreferences
  Future<Map<String, dynamic>> _loadSavedConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configurationKey);

      if (configJson != null) {
        final Map<String, dynamic> config = jsonDecode(configJson) as Map<String, dynamic>;
        debugPrint('📊 [ONBOARDING_BLOC] Configuración cargada: ${config.keys}');
        return config;
      }
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Error loading saved configuration: $e');
    }
    return {};
  }

  /// Save configuration to SharedPreferences
  Future<void> _saveConfiguration(Map<String, dynamic> configuration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(configuration);
      await prefs.setString(_configurationKey, configJson);
      debugPrint('💾 [ONBOARDING_BLOC] Configuración guardada: ${configuration.keys}');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Error saving configuration: $e');
    }
  }

  /// Load saved progress from SharedPreferences
  Future<OnboardingProgress?> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);

      if (progressJson != null) {
        final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
        final progress = OnboardingProgress.fromJson(progressData);
        debugPrint('📊 [ONBOARDING_BLOC] Progreso cargado: ${progress.completedSteps}/${progress.totalSteps}');
        return progress;
      }
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Error loading saved progress: $e');
    }
    return null;
  }

  /// Save progress to SharedPreferences
  Future<void> _saveProgress(OnboardingProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = jsonEncode(progress.toJson());
      await prefs.setString(_progressKey, progressJson);
      debugPrint('💾 [ONBOARDING_BLOC] Progreso guardado: ${progress.completedSteps}/${progress.totalSteps}');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Error saving progress: $e');
    }
  }

  /// Clear saved configuration
  Future<void> _clearSavedConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_configurationKey);
      debugPrint('🗑️ [ONBOARDING_BLOC] Configuración limpiada');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Error clearing configuration: $e');
    }
  }

  /// Clear saved progress
  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      debugPrint('🗑️ [ONBOARDING_BLOC] Progreso limpiado');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Error clearing progress: $e');
    }
  }

  /// Validate configuration before applying
  bool _validateConfiguration(Map<String, dynamic> configuration) {
    try {
      // Check for valid theme family if provided
      if (configuration.containsKey('selectedThemeFamily')) {
        final themeFamily = configuration['selectedThemeFamily'];
        if (themeFamily != null && themeFamily is! String) {
          debugPrint('❌ [ONBOARDING_BLOC] Invalid theme family type: ${themeFamily.runtimeType}');
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
          debugPrint('❌ [ONBOARDING_BLOC] Invalid backup enabled type: ${backupEnabled.runtimeType}');
          return false;
        }
      }

      // Check for valid language if provided
      if (configuration.containsKey('selectedLanguage')) {
        final language = configuration['selectedLanguage'];
        if (language != null && language is! String) {
          debugPrint('❌ [ONBOARDING_BLOC] Invalid language type: ${language.runtimeType}');
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

  /// Validate theme family input
  bool _validateThemeFamily(String themeFamily) {
    if (themeFamily.trim().isEmpty) {
      debugPrint('❌ [ONBOARDING_BLOC] Theme family cannot be empty');
      return false;
    }

    // You could add additional validation here for supported themes
    final supportedThemes = ['Deep Purple', 'Blue', 'Green', 'Red', 'Orange', 'Purple'];
    if (!supportedThemes.contains(themeFamily)) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Theme family "$themeFamily" not in supported list, but allowing it');
    }

    return true;
  }
}
