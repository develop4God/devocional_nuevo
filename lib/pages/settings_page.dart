// lib/pages/settings_page.dart - SENIOR SIMPLE APPROACH (HARD DISABLE badges, backup, force PayPal donation)
import 'dart:developer' as developer;

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/about_page.dart';
import 'package:devocional_nuevo/pages/application_language_page.dart';
import 'package:devocional_nuevo/pages/contact_page.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/repositories/i_supporter_profile_repository.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return const _SettingsView();
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  late final VoiceSettingsService _voiceSettingsService =
      getService<VoiceSettingsService>();
  late final SupporterPetService _petService =
      getService<SupporterPetService>();
  late final ISupporterProfileRepository _profileRepo =
      getService<ISupporterProfileRepository>();

  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  String _initialName = '';
  bool _isSavingName = false;
  bool _nameSavedSuccess = false;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadTtsSettings();
    _loadNameFromBlocOrPrefs();
  }

  /// Loads the current profile name, preferring the BLoC state (in-memory)
  /// over the repository (SharedPreferences) so we get the freshest value.
  void _loadNameFromBlocOrPrefs() {
    final supporterState = context.read<SupporterBloc>().state;
    if (supporterState is SupporterLoaded &&
        supporterState.goldSupporterName != null) {
      final name = supporterState.goldSupporterName!;
      debugPrint('📱 [SettingsPage] Loaded name from BLoC state: "$name"');
      if (mounted) {
        setState(() {
          _nameController.text = name;
          _initialName = name;
        });
      }
    } else {
      // Fallback: load directly from SharedPreferences (e.g. BLoC not yet initialized)
      _profileRepo.loadProfileName().then((name) {
        debugPrint(
            '📱 [SettingsPage] Loaded name from SharedPreferences: "$name"');
        if (mounted) {
          setState(() {
            _nameController.text = name ?? '';
            _initialName = name ?? '';
          });
        }
      });
    }
  }

  Future<void> _loadTtsSettings() async {
    final localizationProvider = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );

    try {
      final currentLanguage = localizationProvider.currentLocale.languageCode;
      await _voiceSettingsService.autoAssignDefaultVoice(currentLanguage);
    } catch (e) {
      developer.log('Error loading TTS settings: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveProfileName() async {
    final name = _nameController.text.trim();
    debugPrint('💾 [SettingsPage] _saveProfileName() called — name: "$name"');

    if (_isSavingName) {
      debugPrint('⚠️ [SettingsPage] Save already in progress, skipping.');
      return;
    }

    setState(() {
      _isSavingName = true;
      _nameSavedSuccess = false;
    });

    FocusScope.of(context).unfocus();

    try {
      // 1. Persist to SharedPreferences via repository
      await _profileRepo.saveProfileName(name);
      debugPrint('✅ [SettingsPage] Name saved to SharedPreferences: "$name"');

      // 2. Dispatch to BLoC so in-memory state and other widgets update
      if (mounted) {
        context.read<SupporterBloc>().add(SaveGoldSupporterName(name));
      }

      if (mounted) {
        setState(() {
          _isSavingName = false;
          _nameSavedSuccess = true;
          _initialName = name;
          _isEditingName = false;
        });
        // Auto-hide success indicator after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _nameSavedSuccess = false);
        });
      }
    } catch (e) {
      debugPrint('❌ [SettingsPage] Error saving name: $e');
      if (mounted) {
        setState(() => _isSavingName = false);
        _showErrorSnackBar('app.error'.tr());
      }
    }
  }

  void _startEditing() {
    setState(() {
      _isEditingName = true;
    });
    // Use a small delay to ensure the text field is built before requesting focus.
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _isEditingName) {
        _focusNode.requestFocus();
      }
    });
  }

  void _cancelEditing() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isEditingName = false;
      _nameController.text = _initialName;
    });
  }

  bool get _isDirty => _nameController.text.trim() != _initialName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(titleText: 'settings.title'.tr()),
        body: _buildSettingsBody(context, colorScheme, theme.textTheme),
      ),
    );
  }

  Widget _buildSettingsBody(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Support/Donation Button
            SizedBox(
              child: Align(
                alignment: Alignment.topRight,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final Uri url =
                        Uri.parse('https://www.develop4god.com/apoyanos');
                    try {
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      } else {
                        if (mounted) {
                          _showErrorSnackBar('settings.cannot_open_url'.tr());
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        _showErrorSnackBar('${'settings.url_error'.tr()}: $e');
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.primary, width: 2.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                  ),
                  icon: const Icon(Icons.volunteer_activism),
                  label: Text(
                    'settings.donate'.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // GOLD SUPPORTER SECTION
            if (_petService.isPetUnlocked) ...[
              Text(
                'supporter.supporter_section_title'.tr(),
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              BlocListener<SupporterBloc, SupporterState>(
                listenWhen: (_, state) => state is SupporterLoaded,
                listener: (context, state) {
                  if (state is SupporterLoaded) {
                    final name = state.goldSupporterName ?? '';
                    if (_nameController.text != name) {
                      debugPrint(
                          '🔄 [SettingsPage] BLoC state updated — syncing name field: "$name"');
                      setState(() {
                        _nameController.text = name;
                        _initialName = name;
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_pin,
                                color: Colors.amber.shade700, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'supporter.profile_name'.tr(),
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (!_isEditingName && !_nameSavedSuccess)
                            IconButton(
                              onPressed: _startEditing,
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              color: Colors.amber.shade700,
                              tooltip: 'supporter.gold_edit_name_button'.tr(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isEditingName
                            ? Column(
                                key: const ValueKey('editing_state'),
                                children: [
                                  TextField(
                                    controller: _nameController,
                                    focusNode: _focusNode,
                                    textInputAction: TextInputAction.done,
                                    maxLength: 15,
                                    onSubmitted: (_) {
                                      if (_isDirty) _saveProfileName();
                                    },
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'supporter.profile_name_hint'.tr(),
                                      counterText: '',
                                      filled: true,
                                      fillColor: colorScheme.surface,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                            color: Colors.amber.shade300,
                                            width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                            color: Colors.amber.shade700,
                                            width: 2),
                                      ),
                                      prefixIcon: Icon(Icons.badge_outlined,
                                          color: Colors.amber.shade700,
                                          size: 20),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: _cancelEditing,
                                          child: Text('app.cancel'.tr()),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isDirty && !_isSavingName
                                              ? _saveProfileName
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.amber.shade600,
                                            foregroundColor: Colors.black87,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                          child: _isSavingName
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                )
                                              : Text(
                                                  'app.save'.tr(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : GestureDetector(
                                key: const ValueKey('display_state'),
                                onTap: _startEditing,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _nameSavedSuccess
                                          ? Colors.green.withValues(alpha: 0.3)
                                          : colorScheme.outline
                                              .withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.badge_outlined,
                                          color: _nameSavedSuccess
                                              ? Colors.green
                                              : Colors.amber.shade700,
                                          size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _nameController.text.isNotEmpty
                                              ? _nameController.text
                                              : 'supporter.profile_name_hint'
                                                  .tr(),
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: _nameController
                                                    .text.isNotEmpty
                                                ? colorScheme.onSurface
                                                : colorScheme.onSurfaceVariant
                                                    .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                      if (_nameSavedSuccess)
                                        const Icon(Icons.check_circle_rounded,
                                            color: Colors.green, size: 18)
                                      else
                                        Icon(Icons.edit_rounded,
                                            color: colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.3),
                                            size: 16),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      if (!_isEditingName)
                        Text(
                          'supporter.profile_name_helper'.tr(),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'supporter.show_pet_header'.tr(),
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${'supporter.pet_currently_selected'.tr()}: ${_petService.selectedPet.nameKey.tr()} ${_petService.selectedPet.emoji}',
                            style: textTheme.bodySmall,
                          ),
                          value: _petService.showPetHeader,
                          onChanged: (bool value) async {
                            await _petService.setShowPetHeader(value);
                            setState(() {});
                          },
                          activeThumbColor: Colors.amber.shade700,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Language Selection
            _buildSettingTile(
              icon: Icons.language_rounded,
              title: 'settings.language'.tr(),
              subtitle: Constants.supportedLanguages[
                      localizationProvider.currentLocale.languageCode] ??
                  localizationProvider.currentLocale.languageCode,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ApplicationLanguagePage())),
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),

            const SizedBox(height: 12),

            // Contact
            _buildSettingTile(
              icon: Icons.contact_support_rounded,
              title: 'settings.contact_us'.tr(),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ContactPage())),
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),

            const SizedBox(height: 12),

            // About
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'settings.about_app'.tr(),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutPage())),
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
