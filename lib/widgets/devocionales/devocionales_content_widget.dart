import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/repositories/i_supporter_profile_repository.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocional_header_widget.dart';
import 'package:devocional_nuevo/widgets/pet_hero_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget that displays the content of a devotional.
class DevocionalesContentWidget extends StatefulWidget {
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

  // Allow injection of a SupporterPetService for tests; when null the widget
  // will use the global service locator (moved out of build to initState).
  final SupporterPetService? petService;

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
    this.petService,
  });

  @override
  State<DevocionalesContentWidget> createState() =>
      _DevocionalesContentWidgetState();
}

class _DevocionalesContentWidgetState extends State<DevocionalesContentWidget> {
  String? _profileName;

  // Both services resolved once in initState — keeps build() pure and avoids
  // repeated service-locator lookups on every rebuild.
  late final SupporterPetService _petService;
  late final ISupporterProfileRepository _profileRepo;

  @override
  void initState() {
    super.initState();
    _petService = widget.petService ?? getService<SupporterPetService>();
    _profileRepo = getService<ISupporterProfileRepository>();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final name = await _profileRepo.loadProfileName();
    if (mounted) {
      setState(() {
        _profileName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use the cached _petService instead of resolving inside build
          if (_petService.showPetHeader && _petService.isPetUnlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: PetHeroSection(
                profileName: _profileName,
                showPetHint: false,
                onTap: () {
                  // Optional: navigate to selection or do nothing
                },
                selectedPet: _petService.selectedPet,
                selectedTheme: (
                  colors: [colorScheme.primary, colorScheme.tertiary]
                ), // Simple theme for now
              ),
            ),
          DevocionalHeaderWidget(
            date: widget.getLocalizedDateFormat(context),
            currentStreak: widget.currentStreak,
            streakFuture: widget.streakFuture,
            isFavorite: widget.isFavorite,
            onFavoriteToggle: widget.onFavoriteToggle,
            onShare: widget.onShare,
            onStreakTap: widget.onStreakBadgeTap,
          ),
          GestureDetector(
            onTap: widget.onVerseCopy,
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
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AutoSizeText(
                widget.devocional.versiculo,
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
            widget.devocional.reflexion,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: widget.fontSize,
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
          ...widget.devocional.paraMeditar.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.cita}: ',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: widget.fontSize,
                        color: colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: item.texto,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: widget.fontSize,
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
            widget.devocional.oracion,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: widget.fontSize,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.devocional.version != null ||
              widget.devocional.language != null ||
              widget.devocional.tags != null)
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
                if (widget.devocional.tags != null &&
                    widget.devocional.tags!.isNotEmpty)
                  Text(
                    'devotionals.topics'.tr({
                      'topics': widget.devocional.tags!.join(', '),
                    }),
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                if (widget.devocional.version != null)
                  Text(
                    'devotionals.version'
                        .tr({'version': widget.devocional.version}),
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
