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

  // --- Auto-fit tuning ---
  // Below this content height (in logical pixels, at scale = 1.0), we start
  // shrinking. This is an estimate of the "natural" height of the page
  // content on a normal-density phone with the gold section hidden.
  static const double _naturalContentHeight = 760.0;
  static const double _minScale = 0.55;

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
            duration: Duration(seconds: 1),
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
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Best-effort visual compression only — this is NEVER the
                  // thing preventing overflow. SingleChildScrollView below is
                  // the safety net that guarantees no overflow regardless of
                  // how wrong this estimate is.
                  final estimatedContent =
                      _naturalContentHeight + (isGold ? 70.0 : 0.0);
                  final availableHeight = constraints.maxHeight;

                  double scale = availableHeight / estimatedContent;
                  scale = scale.clamp(_minScale, 1.0);

                  final content = _AboutContent(
                    scale: scale,
                    appVersion: _appVersion,
                    developerMode: _developerMode,
                    isGold: isGold,
                    goldName: goldName,
                    onIconTapped: _onIconTapped,
                    onLaunchURL: _launchURL,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  );

                  // Always scrollable: guarantees zero overflow on any
                  // device/font-scale combination. On most screens the
                  // content + compression above fits within the viewport
                  // and this scrolls nowhere in practice; on outliers it
                  // quietly scrolls instead of crashing.
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: content,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  final double scale;
  final String appVersion;
  final bool developerMode;
  final bool isGold;
  final String? goldName;
  final VoidCallback onIconTapped;
  final ValueChanged<String> onLaunchURL;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _AboutContent({
    required this.scale,
    required this.appVersion,
    required this.developerMode,
    required this.isGold,
    required this.goldName,
    required this.onIconTapped,
    required this.onLaunchURL,
    required this.colorScheme,
    required this.textTheme,
  });

  // Scales a base gap size down (spacing takes the first cut).
  double _gap(double base) => base * scale;

  // Scales font size down more gently (a secondary, smaller cut so text
  // stays legible even at minScale).
  double? _font(double? base) {
    if (base == null) return null;
    final fontScale = 1.0 - ((1.0 - scale) * 0.5);
    return base * fontScale;
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = 76.0 * scale.clamp(0.45, 1.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: onIconTapped,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.cover,
                  ),
                ),
                if (developerMode)
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
          SizedBox(height: _gap(12)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'about.app_name'.tr(),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontSize: _font(textTheme.headlineMedium?.fontSize),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: _gap(6)),
          Text(
            '${'about.version'.tr()} $appVersion',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: _font(textTheme.bodySmall?.fontSize),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _gap(8)),
          Text(
            'about.description'.tr(),
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              fontSize: _font(15),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _gap(8)),
          Text(
            'about.main_features'.tr(),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: _font(17),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _gap(6)),
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _FeatureItem(
                  text: 'about.feature_daily'.tr(),
                  fontSize: _font(14),
                  gap: _gap(3),
                ),
                _FeatureItem(
                  text: 'about.feature_multiversion'.tr(),
                  fontSize: _font(14),
                  gap: _gap(3),
                ),
                _FeatureItem(
                  text: 'about.feature_favorites'.tr(),
                  fontSize: _font(14),
                  gap: _gap(3),
                ),
                _FeatureItem(
                  text: 'about.feature_sharing'.tr(),
                  fontSize: _font(14),
                  gap: _gap(3),
                ),
                _FeatureItem(
                  text: 'about.feature_language'.tr(),
                  fontSize: _font(14),
                  gap: _gap(3),
                ),
                _FeatureItem(
                  text: 'about.feature_themes'.tr(),
                  fontSize: _font(14),
                  gap: _gap(3),
                ),
                _FeatureItem(
                  text: 'about.feature_dark_light'.tr(),
                  fontSize: _font(14),
                  gap: _gap(3),
                ),
                _FeatureItem(
                  text: 'about.feature_notifications'.tr(),
                  fontSize: _font(14),
                  gap: _gap(3),
                ),
              ],
            ),
          ),
          SizedBox(height: _gap(12)),
          _buildOtherAppsSection(context),
          SizedBox(height: _gap(12)),
          if (isGold) ...[
            _buildGraciasSection(context),
            SizedBox(height: _gap(12)),
          ],
          Text(
            'about.developed_by'.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: _font(15),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _gap(12)),
          InkWell(
            // Do NOT change this to www.develop4God.com (matching the
            // display text below): AndroidManifest.xml registers an
            // autoVerify App Links intent filter for host
            // "www.develop4god.com", so a matching URL gets routed back
            // into this app instead of opening a browser. Keep the launch
            // URL on the non-www host so this link actually opens a
            // browser. See test/unit/translations/drawer_and_url_test.dart.
            onTap: () => onLaunchURL('https://develop4god.com'),
            child: Text(
              'https://www.develop4God.com',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
                fontSize: _font(15),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: _gap(12)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: ElevatedButton.icon(
              // Same App Links caveat as above: keep this on the non-www
              // host, not www.develop4God.com.
              onPressed: () => onLaunchURL('https://develop4god.com/'),
              icon: Icon(Icons.public, color: colorScheme.onPrimary),
              label: Text(
                'about.terms_copyright'.tr(),
                style: TextStyle(color: colorScheme.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale.clamp(0.6, 1.0),
                  vertical: 10 * scale.clamp(0.6, 1.0),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ),
          if (developerMode)
            Padding(
              padding: EdgeInsets.only(top: _gap(16.0), bottom: _gap(8.0)),
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
          SizedBox(height: _gap(16)),
        ],
      ),
    );
  }

  Widget _buildOtherAppsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_gap(16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.14),
            colorScheme.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14 * scale.clamp(0.6, 1.0),
                color: colorScheme.primary,
              ),
              SizedBox(width: _gap(7)),
              Text(
                'about.more_from_developer'.tr(),
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                  color: colorScheme.primary,
                  fontSize: _font(textTheme.labelSmall?.fontSize),
                ),
              ),
            ],
          ),
          SizedBox(height: _gap(10)),
          Container(
            padding: EdgeInsets.all(_gap(10)),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/icons/Habitus_faith_icon.png',
                    width: 46 * scale.clamp(0.55, 1.0),
                    height: 46 * scale.clamp(0.55, 1.0),
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: _gap(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Habitus+Faith',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          fontSize: _font(textTheme.bodyMedium?.fontSize),
                        ),
                      ),
                      Text(
                        'about.habitus_faith_tagline'.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: _font(textTheme.bodySmall?.fontSize),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _gap(8)),
                ElevatedButton(
                  onPressed: () => onLaunchURL(
                    'https://play.google.com/store/apps/details?id=com.develop4God.habitus_faith',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: _gap(14)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'about.view_app'.tr(),
                    style: TextStyle(fontSize: _font(14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraciasSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_gap(16)),
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
              SizedBox(width: _gap(8)),
              Text(
                'supporter.thanks_section_title'.tr(),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB8860B),
                  fontSize: _font(textTheme.titleSmall?.fontSize),
                ),
              ),
            ],
          ),
          if (goldName != null && goldName!.isNotEmpty) ...[
            SizedBox(height: _gap(8)),
            Text(
              goldName!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                fontSize: _font(textTheme.bodyMedium?.fontSize),
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
  final double? fontSize;
  final double gap;

  const _FeatureItem({required this.text, this.fontSize, this.gap = 3.0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: gap),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: fontSize ?? 14,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
