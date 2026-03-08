// lib/widgets/encounter/encounter_grid_overlay.dart
//
// Grid overlay for Encounters feature.
// Mirrors DiscoveryGridOverlay pattern with All / Pending / Completed filters.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:flutter/material.dart';

enum EncounterFilter { all, pending, completed }

class EncounterGridOverlay extends StatefulWidget {
  final EncounterLoaded state;
  final List<EncounterIndexEntry> entries;
  final int currentIndex;
  final String lang;
  final Function(EncounterIndexEntry entry, int originalIndex)
      onEncounterSelected;
  final VoidCallback onClose;
  final Animation<double> animation;

  const EncounterGridOverlay({
    super.key,
    required this.state,
    required this.entries,
    required this.currentIndex,
    required this.lang,
    required this.onEncounterSelected,
    required this.onClose,
    required this.animation,
  });

  @override
  State<EncounterGridOverlay> createState() => _EncounterGridOverlayState();
}

class _EncounterGridOverlayState extends State<EncounterGridOverlay> {
  EncounterFilter _activeFilter = EncounterFilter.all;

  List<EncounterIndexEntry> get _filteredEntries {
    final all = List<EncounterIndexEntry>.from(widget.entries);
    List<EncounterIndexEntry> result;
    switch (_activeFilter) {
      case EncounterFilter.all:
        result = all;
        break;
      case EncounterFilter.pending:
        result = all.where((e) => !widget.state.isCompleted(e.id)).toList();
        break;
      case EncounterFilter.completed:
        result = all.where((e) => widget.state.isCompleted(e.id)).toList();
        break;
    }
    // Incomplete first, then by original order
    result.sort((a, b) {
      final aCompleted = widget.state.isCompleted(a.id);
      final bCompleted = widget.state.isCompleted(b.id);
      if (!aCompleted && bCompleted) return -1;
      if (aCompleted && !bCompleted) return 1;
      return widget.entries.indexOf(a).compareTo(widget.entries.indexOf(b));
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final opacity = widget.animation.value;
        if (opacity <= 0) return const SizedBox.shrink();

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(color: colorScheme.surface),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(colorScheme),
                  _buildFilterBar(colorScheme),
                  Expanded(child: _buildGrid(colorScheme)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'encounters.all_encounters'.tr(),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: colorScheme.onSurface, size: 28),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _filterButton(
                EncounterFilter.all, 'encounters.all'.tr(), colorScheme),
            _filterButton(EncounterFilter.pending, 'encounters.pending'.tr(),
                colorScheme),
            _filterButton(EncounterFilter.completed,
                'encounters.badge_completed'.tr(), colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(
      EncounterFilter filter, String label, ColorScheme colorScheme) {
    final isActive = _activeFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(ColorScheme colorScheme) {
    final filtered = _filteredEntries;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.3), size: 64),
            const SizedBox(height: 16),
            Text(
              'encounters.no_encounters_found'.tr(),
              style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final entry = filtered[index];
        final isCompleted = widget.state.isCompleted(entry.id);
        final originalIndex = widget.entries.indexOf(entry);
        final isActive = originalIndex == widget.currentIndex;

        return _EncounterGridCard(
          entry: entry,
          lang: widget.lang,
          isCompleted: isCompleted,
          isActive: isActive,
          onTap: () => widget.onEncounterSelected(entry, originalIndex),
        );
      },
    );
  }
}

class _EncounterGridCard extends StatelessWidget {
  final EncounterIndexEntry entry;
  final String lang;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback onTap;

  const _EncounterGridCard({
    required this.entry,
    required this.lang,
    required this.isCompleted,
    required this.isActive,
    required this.onTap,
  });

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
      if (clean.length == 8) return Color(int.parse(clean, radix: 16));
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = _parseColor(entry.accentColor) ?? colorScheme.primary;

    final imageUrl = entry.introImage != null
        ? Constants.getEncounterImageUrl(entry.introImage!)
        : null;

    return Card(
      elevation: isActive ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isActive
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isActive ? 2.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: entry.isPublished ? onTap : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or accent gradient
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.4),
                        accentColor.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: accentColor.withValues(alpha: 0.2),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: 0.4),
                      accentColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            // Dark gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji top center
                  Center(
                    child: Text(
                      entry.emoji ?? '✨',
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    entry.titleFor(lang),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (isCompleted)
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 12, color: Colors.greenAccent),
                        const SizedBox(width: 4),
                        Text(
                          'encounters.badge_completed'.tr().toUpperCase(),
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  else if (isActive)
                    Row(
                      children: [
                        Icon(Icons.play_circle_fill_rounded,
                            size: 12, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'encounters.current'.tr().toUpperCase(),
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Completion badge
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.black, size: 10),
                ),
              ),
            // Coming soon overlay
            if (!entry.isPublished)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Text(
                    'encounters.coming_soon'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
