// lib/blocs/onboarding/onboarding_bloc.dart
import 'dart:convert'; // ✅ Required for jsonEncode/jsonDecode

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Configuration persistence keys
  static const String _configurationKey = 'onboarding_configuration';
  static const String _progressKey = 'onboarding_progress';

  // Schema versioning for persistence migration
  static const int _currentSchemaVersion = 1;

  // Race condition protection
  bool _isProcessingStep = false;
  bool _isCompletingOnboarding = false;
  bool _isSavingConfiguration = false;

  // SharedPreferences operation mutex
  static bool _isSharedPrefsOperation = false;

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
          '⚠️ [ONBOARDING_BLOC] Cannot skip backup - not in active step state');
      return;
    }

    try {
      final currentState = state as OnboardingStepActive;

      final updatedSelections =
          Map<String, dynamic>.from(currentState.userSelections);
      updatedSelections['backupSkipped'] = true;
      updatedSelections['backupEnabled'] = false;

      await _saveConfiguration(updatedSelections);
      debugPrint(
          '🟢 [ONBOARDING_BLOC] userSelections después de SkipBackupForNow: $updatedSelections');
      emit(currentState.copyWith(
        userSelections: updatedSelections,
        stepConfiguration: {'backupSkipped': true},
      ));

      debugPrint(
          '✅ [ONBOARDING_BLOC] Backup marcado como "configurar más tarde"');
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
            '✅ [ONBOARDING_BLOC] Onboarding ya completado, emitiendo OnboardingCompleted');
        emit(OnboardingCompleted(
          appliedConfigurations: await _loadSavedConfiguration(),
          completionTimestamp: DateTime.now(),
        ));
        return;
      }
      // 🔧 NUEVO: Marcar onboarding como en progreso
      await _onboardingService.setOnboardingInProgress(true);
      debugPrint('🚀 [ONBOARDING_BLOC] Onboarding marcado como en progreso');

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

    // Race condition protection
    if (_isProcessingStep) {
      debugPrint(
          '⚠️ [ONBOARDING_BLOC] Step progression already in progress, ignoring duplicate event');
      return;
    }

    if (state is! OnboardingStepActive) {
      debugPrint(
          '⚠️ [ONBOARDING_BLOC] Cannot progress - not in active step state');
      return;
    }

    _isProcessingStep = true;
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
        userSelections: currentState.userSelections,
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
      _themeBloc.add(ChangeThemeFamily(event.themeFamily));
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
      debugPrint(
          '🟢 [DEBUG] userSelections después de SelectTheme: $updatedSelections');
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

      // Don't emit OnboardingConfiguring - just update the state silently
      // This keeps state as OnboardingStepActive so navigation can proceed

      final updatedSelections =
          Map<String, dynamic>.from(currentState.userSelections);
      updatedSelections['backupEnabled'] = event.enableBackup;
      updatedSelections['backupSkipped'] = false;

      // Coordinate with BackupBloc if available and backup is enabled
      if (event.enableBackup && _backupBloc != null) {
        debugPrint(
            '🔧 [ONBOARDING_BLOC] Configurando backup a través de BackupBloc');
        _backupBloc!.add(const ToggleAutoBackup(true));
      }

      // Save configuration
      await _saveConfiguration(updatedSelections);

      debugPrint(
          '🟢 [ONBOARDING_BLOC] userSelections después de ConfigureBackupOption: $updatedSelections');

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

    // Race condition protection
    if (_isCompletingOnboarding) {
      debugPrint(
          '⚠️ [ONBOARDING_BLOC] Onboarding completion already in progress, ignoring duplicate event');
      return;
    }

    _isCompletingOnboarding = true;
    try {
      // Get configurations from current state before emitting loading
      Map<String, dynamic> configurations;
      if (state is OnboardingStepActive) {
        configurations = (state as OnboardingStepActive).userSelections;
      } else {
        configurations = await _loadSavedConfiguration();
      }
      debugPrint(
          '🟣 [ONBOARDING_BLOC] State al completar onboarding: ${state.runtimeType}');
      debugPrint(
          '🟣 [ONBOARDING_BLOC] Configuraciones al completar onboarding: $configurations');

      emit(const OnboardingLoading());

      // 🔧 NUEVO: Enriquecer con estado REAL del backup desde BackupBloc
      if (_backupBloc != null && configurations['backupEnabled'] == true) {
        final backupState = _backupBloc!.state;
        debugPrint(
            '📊 [ONBOARDING_BLOC] BackupBloc estado: ${backupState.runtimeType}');

        if (backupState is BackupLoaded) {
          configurations['hasActiveBackup'] =
              backupState.lastBackupTime != null;
          configurations['backupCompleted'] =
              backupState.lastBackupTime != null;

          debugPrint(
              '✅ [ONBOARDING_BLOC] Backup info agregada: hasActiveBackup=${backupState.lastBackupTime != null}');
        }
      }

      // Mark onboarding as complete
      await _onboardingService.setOnboardingComplete();
      debugPrint('✅ [ONBOARDING_BLOC] Onboarding marcado como completado');

      // Clear temporary progress data
      await _clearSavedProgress();
      debugPrint(
          '🟣 [BLOC] Emitiendo OnboardingCompleted con configuración: $configurations');
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
        // Enhanced JSON validation and corruption detection
        Map<String, dynamic> wrapper;
        try {
          wrapper = jsonDecode(configJson) as Map<String, dynamic>;
        } catch (e) {
          debugPrint(
              '❌ [ONBOARDING_BLOC] Corrupted JSON detected in configuration: $e');
          debugPrint(
              '🔄 [ONBOARDING_BLOC] Clearing corrupted configuration data');
          await prefs.remove(_configurationKey);
          return {};
        }

        // Validate JSON structure
        if (!_isValidConfigurationStructure(wrapper)) {
          debugPrint(
              '⚠️ [ONBOARDING_BLOC] Invalid configuration structure detected, falling back to defaults');
          await prefs.remove(_configurationKey);
          return {};
        }

        // Check for schema version
        final schemaVersion = wrapper['schemaVersion'] as int? ?? 0;
        Map<String, dynamic> config =
            wrapper['payload'] as Map<String, dynamic>? ?? wrapper;

        // Apply migration if needed
        if (schemaVersion < _currentSchemaVersion) {
          config = _migrateConfiguration(config, schemaVersion);
          debugPrint(
              '🔄 [ONBOARDING_BLOC] Configuration migrated from v$schemaVersion to v$_currentSchemaVersion');

          // Save migrated configuration
          await _saveConfiguration(config);
        }

        debugPrint(
            '📊 [ONBOARDING_BLOC] Configuración cargada: ${config.keys}');
        return config;
      }
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Error loading saved configuration: $e');
      debugPrint('🔄 [ONBOARDING_BLOC] Falling back to empty configuration');
    }
    return {};
  }

  /// Save configuration to SharedPreferences with schema versioning
  Future<void> _saveConfiguration(Map<String, dynamic> configuration) async {
    if (_isSavingConfiguration) {
      debugPrint(
          '⚠️ [ONBOARDING_BLOC] Configuration save already in progress, skipping');
      return;
    }

    // Wait for any ongoing SharedPreferences operations
    while (_isSharedPrefsOperation) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    _isSavingConfiguration = true;
    _isSharedPrefsOperation = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final wrapper = {
        'schemaVersion': _currentSchemaVersion,
        'payload': configuration,
      };
      final configJson = jsonEncode(wrapper);
      await prefs.setString(_configurationKey, configJson);
      debugPrint(
          '💾 [ONBOARDING_BLOC] Configuración guardada: ${configuration.keys}');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Error saving configuration: $e');
    } finally {
      _isSavingConfiguration = false;
      _isSharedPrefsOperation = false;
    }
  }

  /// Load saved progress from SharedPreferences
  Future<OnboardingProgress?> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);

      if (progressJson != null) {
        // Enhanced JSON validation and corruption detection
        Map<String, dynamic> wrapper;
        try {
          wrapper = jsonDecode(progressJson) as Map<String, dynamic>;
        } catch (e) {
          debugPrint(
              '❌ [ONBOARDING_BLOC] Corrupted JSON detected in progress: $e');
          debugPrint('🔄 [ONBOARDING_BLOC] Clearing corrupted progress data');
          await prefs.remove(_progressKey);
          return null;
        }

        // Validate JSON structure
        if (!_isValidProgressStructure(wrapper)) {
          debugPrint(
              '⚠️ [ONBOARDING_BLOC] Invalid progress structure detected, falling back to defaults');
          await prefs.remove(_progressKey);
          return null;
        }

        // Check for schema version
        final schemaVersion = wrapper['schemaVersion'] as int? ?? 0;
        Map<String, dynamic> progressData =
            wrapper['payload'] as Map<String, dynamic>? ?? wrapper;

        // Apply migration if needed
        if (schemaVersion < _currentSchemaVersion) {
          progressData = _migrateProgress(progressData, schemaVersion);
          debugPrint(
              '🔄 [ONBOARDING_BLOC] Progress migrated from v$schemaVersion to v$_currentSchemaVersion');
        }

        final progress = OnboardingProgress.fromJson(progressData);
        debugPrint(
            '📊 [ONBOARDING_BLOC] Progreso cargado: ${progress.completedSteps}/${progress.totalSteps}');
        return progress;
      }
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Error loading saved progress: $e');
      debugPrint('🔄 [ONBOARDING_BLOC] Falling back to null progress');
    }
    return null;
  }

  /// Save progress to SharedPreferences with schema versioning
  Future<void> _saveProgress(OnboardingProgress progress) async {
    // Wait for any ongoing SharedPreferences operations
    while (_isSharedPrefsOperation) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    _isSharedPrefsOperation = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final wrapper = {
        'schemaVersion': _currentSchemaVersion,
        'payload': progress.toJson(),
      };
      final progressJson = jsonEncode(wrapper);
      await prefs.setString(_progressKey, progressJson);
      debugPrint(
          '💾 [ONBOARDING_BLOC] Progreso guardado: ${progress.completedSteps}/${progress.totalSteps}');
    } catch (e) {
      debugPrint('⚠️ [ONBOARDING_BLOC] Error saving progress: $e');
    } finally {
      _isSharedPrefsOperation = false;
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
          debugPrint(
              '❌ [ONBOARDING_BLOC] Invalid theme family type: ${themeFamily.runtimeType}');
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
              '❌ [ONBOARDING_BLOC] Invalid backup enabled type: ${backupEnabled.runtimeType}');
          return false;
        }
      }

      // Check for valid language if provided
      if (configuration.containsKey('selectedLanguage')) {
        final language = configuration['selectedLanguage'];
        if (language != null && language is! String) {
          debugPrint(
              '❌ [ONBOARDING_BLOC] Invalid language type: ${language.runtimeType}');
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
    final supportedThemes = [
      'Deep Purple',
      'Blue',
      'Green',
      'Red',
      'Orange',
      'Purple'
    ];
    if (!supportedThemes.contains(themeFamily)) {
      debugPrint(
          '⚠️ [ONBOARDING_BLOC] Theme family "$themeFamily" not in supported list, but allowing it');
    }

    return true;
  }

  /// Migrate configuration from older schema versions
  Map<String, dynamic> _migrateConfiguration(
      Map<String, dynamic> config, int fromVersion) {
    debugPrint(
        '🔄 [ONBOARDING_BLOC] Migrating configuration from version $fromVersion to $_currentSchemaVersion');

    try {
      Map<String, dynamic> migratedConfig = Map<String, dynamic>.from(config);

      // Version 0 -> 1: No changes needed for now, but this is where future migrations would go
      if (fromVersion < 1) {
        // Example: migratedConfig['newField'] = 'defaultValue';
        debugPrint(
            '✅ [ONBOARDING_BLOC] Configuration migration v0->v1 completed');
      }

      return migratedConfig;
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Configuration migration failed: $e');
      debugPrint('🔄 [ONBOARDING_BLOC] Falling back to original configuration');
      return config;
    }
  }

  /// Migrate progress data from older schema versions
  Map<String, dynamic> _migrateProgress(
      Map<String, dynamic> progressData, int fromVersion) {
    debugPrint(
        '🔄 [ONBOARDING_BLOC] Migrating progress from version $fromVersion to $_currentSchemaVersion');

    try {
      Map<String, dynamic> migratedProgress =
          Map<String, dynamic>.from(progressData);

      // Version 0 -> 1: No changes needed for now, but this is where future migrations would go
      if (fromVersion < 1) {
        // Example: Ensure all required fields exist
        migratedProgress['totalSteps'] ??= 4;
        migratedProgress['completedSteps'] ??= 0;
        migratedProgress['stepCompletionStatus'] ??=
            List<bool>.filled(4, false);
        migratedProgress['progressPercentage'] ??= 0.0;
        debugPrint('✅ [ONBOARDING_BLOC] Progress migration v0->v1 completed');
      }

      return migratedProgress;
    } catch (e) {
      debugPrint('❌ [ONBOARDING_BLOC] Progress migration failed: $e');
      debugPrint('🔄 [ONBOARDING_BLOC] Falling back to original progress data');
      return progressData;
    }
  }

  /// Validate configuration JSON structure
  bool _isValidConfigurationStructure(Map<String, dynamic> data) {
    try {
      // For wrapped format (with schema version)
      if (data.containsKey('schemaVersion') && data.containsKey('payload')) {
        final payload = data['payload'];
        if (payload is! Map<String, dynamic>) return false;

        // Validate known configuration keys if present
        for (final key in payload.keys) {
          if (!_isValidConfigurationKey(key)) {
            debugPrint('⚠️ [ONBOARDING_BLOC] Unknown configuration key: $key');
          }
        }
        return true;
      }

      // For legacy format (direct configuration)
      for (final key in data.keys) {
        if (!_isValidConfigurationKey(key)) {
          debugPrint(
              '⚠️ [ONBOARDING_BLOC] Unknown legacy configuration key: $key');
        }
      }
      return true;
    } catch (e) {
      debugPrint(
          '❌ [ONBOARDING_BLOC] Configuration structure validation failed: $e');
      return false;
    }
  }

  /// Validate progress JSON structure
  bool _isValidProgressStructure(Map<String, dynamic> data) {
    try {
      // For wrapped format (with schema version)
      if (data.containsKey('schemaVersion') && data.containsKey('payload')) {
        final payload = data['payload'];
        if (payload is! Map<String, dynamic>) return false;
        return _isValidProgressPayload(payload);
      }

      // For legacy format (direct progress)
      return _isValidProgressPayload(data);
    } catch (e) {
      debugPrint(
          '❌ [ONBOARDING_BLOC] Progress structure validation failed: $e');
      return false;
    }
  }

  /// Validate configuration key
  bool _isValidConfigurationKey(String key) {
    const validKeys = {
      'selectedThemeFamily',
      'backupEnabled',
      'backupSkipped',
      'hasActiveBackup',
      'backupCompleted',
      'selectedLanguage',
      'notificationsEnabled',
      'additionalSettings',
      'lastUpdated',
    };
    return validKeys.contains(key);
  }

  /// Validate progress payload structure
  bool _isValidProgressPayload(Map<String, dynamic> payload) {
    const requiredKeys = [
      'totalSteps',
      'completedSteps',
      'stepCompletionStatus',
      'progressPercentage'
    ];

    for (final key in requiredKeys) {
      if (!payload.containsKey(key)) {
        debugPrint('❌ [ONBOARDING_BLOC] Missing required progress key: $key');
        return false;
      }
    }

    // Validate data types
    if (payload['totalSteps'] is! int || payload['completedSteps'] is! int) {
      debugPrint('❌ [ONBOARDING_BLOC] Invalid progress step count types');
      return false;
    }

    if (payload['stepCompletionStatus'] is! List ||
        payload['progressPercentage'] is! num) {
      debugPrint('❌ [ONBOARDING_BLOC] Invalid progress data types');
      return false;
    }

    return true;
  }
}
