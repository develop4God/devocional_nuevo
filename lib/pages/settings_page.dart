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
  bool _isSavingName = false;
  bool _nameSavedSuccess = false;

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
      if (mounted) setState(() => _nameController.text = name);
    } else {
      // Fallback: load directly from SharedPreferences (e.g. BLoC not yet initialized)
      _profileRepo.loadProfileName().then((name) {
        debugPrint(
            '📱 [SettingsPage] Loaded name from SharedPreferences: "$name"');
        if (mounted) setState(() => _nameController.text = name ?? '');
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

    try {
      // 1. Persist to SharedPreferences via repository
      await _profileRepo.saveProfileName(name);
      debugPrint('✅ [SettingsPage] Name saved to SharedPreferences: "$name"');

      // 2. Verify the save by reading back
      final verified = await _profileRepo.loadProfileName();
      debugPrint(
          '🔍 [SettingsPage] Verification read from SharedPreferences: "$verified"');
      if (verified != name) {
        debugPrint(
            '❌ [SettingsPage] Verification FAILED — expected "$name" got "$verified"');
      } else {
        debugPrint(
            '✅ [SettingsPage] Verification OK — name persisted correctly.');
      }

      // 3. Dispatch to BLoC so in-memory state and other widgets update
      if (mounted) {
        context.read<SupporterBloc>().add(SaveGoldSupporterName(name));
        debugPrint(
            '📡 [SettingsPage] Dispatched SaveGoldSupporterName("$name") to SupporterBloc');
      }

      if (mounted) {
        setState(() {
          _isSavingName = false;
          _nameSavedSuccess = true;
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
                      setState(() => _nameController.text = name);
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header with icon
                      Row(
                        children: [
                          Icon(Icons.person_pin,
                              color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'supporter.profile_name'.tr(),
                            style: textTheme.labelMedium?.copyWith(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Name text field (no confusing icon button inside)
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.done,
                        maxLength: 15,
                        onSubmitted: (_) => _saveProfileName(),
                        decoration: InputDecoration(
                          hintText: 'supporter.profile_name_hint'.tr(),
                          helperText: 'supporter.profile_name_helper'.tr(),
                          helperMaxLines: 2,
                          counterText: '',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.amber.shade300
                                    .withValues(alpha: 0.6)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.amber.shade600, width: 2),
                          ),
                          prefixIcon:
                              Icon(Icons.person, color: Colors.amber.shade700),
                          suffixIcon: _nameController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 18),
                                  tooltip: 'app.close'.tr(),
                                  onPressed: () {
                                    _nameController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      // Explicit save button — clear and prominent
                      SizedBox(
                        width: double.infinity,
                        child: _isSavingName
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                ),
                              )
                            : _nameSavedSuccess
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.green.shade400),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.green.shade600,
                                            size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'supporter.profile_name_saved'.tr(),
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _saveProfileName,
                                    icon: const Icon(Icons.save_outlined,
                                        size: 18),
                                    label: Text(
                                        'supporter.profile_name_save'.tr()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade600,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
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
                        activeThumbColor: colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Language Selection
            _buildSettingTile(
              icon: Icons.language,
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

            const SizedBox(height: 20),

            // Contact
            _buildSettingTile(
              icon: Icons.contact_mail,
              title: 'settings.contact_us'.tr(),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ContactPage())),
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),

            const SizedBox(height: 20),

            // About
            _buildSettingTile(
              icon: Icons.perm_device_info_outlined,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontSize: 16, color: colorScheme.onSurface),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
