// lib/pages/settings_page.dart - SENIOR SIMPLE APPROACH (HARD DISABLE badges, backup, force PayPal donation)
import 'dart:developer' as developer;

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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadTtsSettings();
    final name = await _profileRepo.loadProfileName();
    if (mounted) {
      _nameController.text = name ?? '';
      setState(() {});
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
    await _profileRepo.saveProfileName(name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('settings.profile_name_saved'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
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
                'SOCIO DEL MINISTERIO',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'settings.profile_name'.tr(),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon:
                            Icon(Icons.person, color: Colors.amber.shade700),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.save_outlined,
                              color: Colors.amber.shade700),
                          tooltip: 'app.save'.tr(),
                          onPressed: () => _saveProfileName(),
                        ),
                      ),
                      onSubmitted: (_) => _saveProfileName(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(
                        'Mostrar mi mascota en el devocional',
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Actualmente: ${_petService.selectedPet.name} ${_petService.selectedPet.emoji}',
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
