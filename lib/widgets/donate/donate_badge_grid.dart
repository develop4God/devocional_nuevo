// lib/widgets/donate/donate_badge_grid.dart
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

import '../../models/badge_model.dart' as badge_model;
import '../badge_image_widget.dart';

class DonateBadgeGrid extends StatelessWidget {
  final List<badge_model.Badge> availableBadges;
  final badge_model.Badge? selectedBadge;
  final Function(badge_model.Badge) onBadgeSelected;
  final bool isLoading;

  const DonateBadgeGrid({
    required this.availableBadges,
    required this.selectedBadge,
    required this.onBadgeSelected,
    required this.isLoading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'donate.badge_selection'.tr(),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'donate.select_badge_message'.tr(),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        _buildBadgeContent(colorScheme, textTheme),
      ],
    );
  }

  Widget _buildBadgeContent(ColorScheme colorScheme, TextTheme textTheme) {
    if (isLoading) {
      return _buildLoadingState(textTheme);
    }

    if (availableBadges.isEmpty) {
      return _buildEmptyState(colorScheme, textTheme);
    }

    return _buildBadgeGrid(colorScheme, textTheme);
  }

  Widget _buildLoadingState(TextTheme textTheme) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando insignias...'),
            // Could use badges.loading_badges.tr()
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          'badges.no_badges_message'.tr(),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(ColorScheme colorScheme, TextTheme textTheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio:
            1.2, // ← Cambiado de 0.8 a 1.0 para mantener forma cuadrada
      ),
      itemCount: availableBadges.length,
      itemBuilder: (context, index) {
        final badge = availableBadges[index];
        final isSelected = selectedBadge?.id == badge.id;

        return _buildBadgeItem(badge, isSelected, colorScheme, textTheme);
      },
    );
  }

  Widget _buildBadgeItem(
    badge_model.Badge badge,
    bool isSelected,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      // ← Agregado para mejor control de espacio
      children: [
        // Contenedor cuadrado que mantiene la forma circular del badge
        SizedBox(
          width: 80, // ← Tamaño fijo para asegurar círculo perfecto
          height: 80, // ← Tamaño fijo para asegurar círculo perfecto
          child: BadgeImageWidget(
            badge: badge,
            size: 80,
            isSelected: isSelected,
            onTap: () => onBadgeSelected(badge),
          ),
        ),
        const SizedBox(height: 8),
        // Texto con altura flexible
        Flexible(
          child: Text(
            badge.name,
            style: textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
