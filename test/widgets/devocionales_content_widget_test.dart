import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

/// Widget that displays the content of a devotional.
///
/// This is a stateless widget extracted from DevocionalesPage to improve
/// maintainability and reduce file size. It displays:
/// - Date and streak badge
/// - Verse (with copy functionality)
/// - Reflection
/// - Meditations
/// - Prayer
/// - Details (version, tags, copyright)
class DevocionalesContentWidget extends StatelessWidget {
  final Devocional devocional;
  final double fontSize;
  final VoidCallback onVerseCopy;
  final VoidCallback onStreakBadgeTap;
  final int currentStreak;
  final Future<int> streakFuture;
  final String formattedDate; // ✅ MEJORADO: String directo en lugar de función
  final ScrollController? scrollController;

  const DevocionalesContentWidget({
    super.key,
    required this.devocional,
    required this.fontSize,
    required this.onVerseCopy,
    required this.onStreakBadgeTap,
    required this.currentStreak,
    required this.streakFuture,
    required this.formattedDate, // ✅ MEJORADO
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      formattedDate, // ✅ MEJORADO: uso directo
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FutureBuilder<int>(
                  future: streakFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      );
                    }
                    final streak = snapshot.data ?? currentStreak;
                    if (streak <= 0) {
                      return const SizedBox.shrink();
                    }
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return _buildStreakBadge(context, isDark, streak);
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onVerseCopy,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withAlpha((0.25 * 255).round()),
                    colorScheme.primary.withAlpha((0.08 * 255).round()),
                    colorScheme.secondary.withAlpha((0.06 * 255).round()),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withAlpha((0.3 * 255).round()),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha((0.2 * 255).round()),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha((0.05 * 255).round()),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: AutoSizeText(
                devocional.versiculo,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'devotionals.reflection'.tr(),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            devocional.reflexion,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: fontSize,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'devotionals.to_meditate'.tr(),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...devocional.paraMeditar.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.cita}: ',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                        color: colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: item.texto,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: fontSize,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Text(
            'devotionals.prayer'.tr(),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            devocional.oracion,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: fontSize,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          if (devocional.version != null ||
              devocional.language != null ||
              devocional.tags != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'devotionals.details'.tr(),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                if (devocional.tags != null && devocional.tags!.isNotEmpty)
                  Text(
                    'devotionals.topics'.tr({
                      'topics': devocional.tags!.join(', '),
                    }),
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                if (devocional.version != null)
                  Text(
                    'devotionals.version'.tr({
                      'version': devocional.version,
                    }),
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 10),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Consumer<DevocionalProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          CopyrightUtils.getCopyrightText(
                            provider.selectedLanguage,
                            provider.selectedVersion,
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(BuildContext context, bool isDark, int streak) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;
    final backgroundColor =
    colorScheme.surfaceContainerHighest.withValues(alpha: 0.06);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onStreakBadgeTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Lottie.asset(
                        'assets/lottie/fire.json',
                        repeat: true,
                        animate: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${'progress.streak'.tr()} $streak',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}