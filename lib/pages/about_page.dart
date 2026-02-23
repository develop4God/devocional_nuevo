// lib/pages/about_page.dart
//
// Requires a [SupporterBloc] ancestor in the widget tree.
// (Provided by [settings_page.dart] via BlocProvider on navigation.)
import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = 'about.loading_version'.tr();
  int _iconTapCount = 0;
  static const int _tapThreshold = 7;
  bool _developerMode = false;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _loadDeveloperMode();
    // Kick off IAP initialization via the BLoC — no direct IIapService call.
    // The BlocProvider<SupporterBloc> is set up at app level (main.dart).
    // Guard prevents a redundant Loading → Loaded flicker on re-navigation.
    final bloc = context.read<SupporterBloc>();
    if (bloc.state is! SupporterLoaded) {
      bloc.add(InitializeSupporter());
    }
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<void> _loadDeveloperMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _developerMode = prefs.getBool('developerMode') ?? false;
    });
  }

  Future<void> _setDeveloperMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('developerMode', enabled);
    setState(() {
      _developerMode = enabled;
    });
  }

  void _onIconTapped() async {
    if (_developerMode) return;
    if (!kDebugMode) return; // Solo permitir en debug
    _iconTapCount++;
    if (_iconTapCount >= _tapThreshold) {
      await _setDeveloperMode(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modo desarrollador activado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('about.link_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: BlocBuilder<SupporterBloc, SupporterState>(
        builder: (context, supporterState) {
          final isGold = supporterState is SupporterLoaded &&
              supporterState.isPurchased(SupporterTierLevel.gold);
          final goldName = supporterState is SupporterLoaded
              ? supporterState.goldSupporterName
              : null;

          return Scaffold(
            appBar: CustomAppBar(titleText: 'about.title'.tr()),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: _onIconTapped,
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (_developerMode)
                          Container(
                            margin: const EdgeInsets.only(top: 4, right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'DEV',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'about.app_name'.tr(),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${'about.version'.tr()} $_appVersion',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'about.description'.tr(),
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'about.main_features'.tr(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _FeatureItem(text: 'about.feature_daily'.tr()),
                      _FeatureItem(text: 'about.feature_multiversion'.tr()),
                      _FeatureItem(text: 'about.feature_favorites'.tr()),
                      _FeatureItem(text: 'about.feature_sharing'.tr()),
                      _FeatureItem(text: 'about.feature_language'.tr()),
                      _FeatureItem(text: 'about.feature_themes'.tr()),
                      _FeatureItem(text: 'about.feature_dark_light'.tr()),
                      _FeatureItem(text: 'about.feature_notifications'.tr()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isGold) ...[
                    _buildGraciasSection(colorScheme, textTheme, goldName),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'about.developed_by'.tr(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _launchURL('https://www.develop4God.com'),
                    child: Text(
                      'https://www.develop4God.com',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _launchURL('https://www.develop4god.com/'),
                      icon: Icon(Icons.public, color: colorScheme.onPrimary),
                      label: Text(
                        'about.terms_copyright'.tr(),
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                    ),
                  ),
                  if (_developerMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bug_report, color: Colors.white),
                        label: const Text('Debug Tools'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/debug');
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGraciasSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String? goldName,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.15),
            const Color(0xFFFFD700).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('❤️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'supporter.thanks_section_title'.tr(),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB8860B),
                ),
              ),
            ],
          ),
          if (goldName != null && goldName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              goldName,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
