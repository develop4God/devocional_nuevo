import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocional_header_widget.dart';
import 'package:devocional_nuevo/widgets/pet_hero_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget that displays the content of a devotional.
class DevocionalesContentWidget extends StatelessWidget {
  final Devocional devocional;
  final double fontSize;
  final VoidCallback onVerseCopy;
  final VoidCallback onStreakBadgeTap;
  final int currentStreak;
  final Future<int> streakFuture;
  final String Function(BuildContext) getLocalizedDateFormat;
  final ScrollController? scrollController;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;

  /// Pet service injected by the caller — keeps [build] free of service-locator
  /// calls, which violates the project's DI rules.
  final SupporterPetService petService;

  const DevocionalesContentWidget({
    super.key,
    required this.devocional,
    required this.fontSize,
    required this.onVerseCopy,
    required this.onStreakBadgeTap,
    required this.currentStreak,
    required this.streakFuture,
    required this.getLocalizedDateFormat,
    this.scrollController,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onShare,
    required this.petService,
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
          if (petService.showPetHeader && petService.isPetUnlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: PetHeroSection(
                formattedDate: getLocalizedDateFormat(context),
                showPetHint: false,
                onTap: () {
                  // Optional: navigate to selection or do nothing
                },
                selectedPet: petService.selectedPet,
                selectedTheme: (
                  colors: [colorScheme.primary, colorScheme.tertiary]
                ),
                // Simple theme for now
              ),
            ),
          DevocionalHeaderWidget(
            date: getLocalizedDateFormat(context),
            currentStreak: currentStreak,
            streakFuture: streakFuture,
            isFavorite: isFavorite,
            onFavoriteToggle: onFavoriteToggle,
            onShare: onShare,
            onStreakTap: onStreakBadgeTap,
          ),
          GestureDetector(
            onTap: onVerseCopy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.25),
                    colorScheme.primary.withValues(alpha: 0.08),
                    colorScheme.secondary.withValues(alpha: 0.06),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
              padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                    'devotionals.version'.tr({'version': devocional.version}),
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 10),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Consumer<DevocionalProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          CopyrightUtils.getCopyrightText(
                            provider.selectedLanguage,
                            provider.selectedVersion,
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
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
}
