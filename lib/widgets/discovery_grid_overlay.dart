// lib/widgets/discovery_grid_overlay.dart

import 'dart:ui';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

enum StudyFilter { all, pending, completed }

class DiscoveryGridOverlay extends StatefulWidget {
  final DiscoveryLoaded state;
  final List<String> studyIds;
  final int currentIndex;
  final Function(String studyId, int originalIndex) onStudySelected;
  final VoidCallback onClose;
  final Animation<double> animation;

  const DiscoveryGridOverlay({
    super.key,
    required this.state,
    required this.studyIds,
    required this.currentIndex,
    required this.onStudySelected,
    required this.onClose,
    required this.animation,
  });

  @override
  State<DiscoveryGridOverlay> createState() => _DiscoveryGridOverlayState();
}

class _DiscoveryGridOverlayState extends State<DiscoveryGridOverlay> {
  StudyFilter _activeFilter = StudyFilter.all;

  List<String> get _filteredIds {
    final ids = List<String>.from(widget.studyIds);
    
    // Apply status filter
    List<String> result;
    switch (_activeFilter) {
      case StudyFilter.all:
        result = ids;
        break;
      case StudyFilter.pending:
        result = ids.where((id) => !(widget.state.completedStudies[id] ?? false)).toList();
        break;
      case StudyFilter.completed:
        result = ids.where((id) => widget.state.completedStudies[id] ?? false).toList();
        break;
    }

    // Sort: Incomplete first, then by original order
    result.sort((a, b) {
      final aCompleted = widget.state.completedStudies[a] ?? false;
      final bCompleted = widget.state.completedStudies[b] ?? false;
      if (!aCompleted && bCompleted) return -1;
      if (aCompleted && !bCompleted) return 1;
      return widget.studyIds.indexOf(a).compareTo(widget.studyIds.indexOf(b));
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
            // Background Blur
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10 * opacity, sigmaY: 10 * opacity),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6 * opacity),
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(colorScheme),
                  _buildFilterBar(colorScheme),
                  Expanded(
                    child: _buildGrid(colorScheme),
                  ),
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
            'discovery.all_studies'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
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
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildFilterButton(StudyFilter.all, 'discovery.all'.tr()),
            _buildFilterButton(StudyFilter.pending, 'discovery.pending'.tr()),
            _buildFilterButton(StudyFilter.completed, 'discovery.completed'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(StudyFilter filter, String label) {
    final isActive = _activeFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.black87 : Colors.white70,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(ColorScheme colorScheme) {
    final filtered = _filteredIds;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: Colors.white.withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            Text(
              'discovery.no_studies_found'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
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
        final studyId = filtered[index];
        final title = widget.state.studyTitles[studyId] ?? studyId;
        final emoji = widget.state.studyEmojis[studyId];
        final isCompleted = widget.state.completedStudies[studyId] ?? false;
        final originalIndex = widget.studyIds.indexOf(studyId);
        final isActive = originalIndex == widget.currentIndex;

        return _StudyGridCard(
          studyId: studyId,
          title: title,
          emoji: emoji,
          isCompleted: isCompleted,
          isActive: isActive,
          onTap: () => widget.onStudySelected(studyId, originalIndex),
        );
      },
    );
  }
}

class _StudyGridCard extends StatelessWidget {
  final String studyId;
  final String title;
  final String? emoji;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback onTap;

  const _StudyGridCard({
    required this.studyId,
    required this.title,
    this.emoji,
    required this.isCompleted,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isActive ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isActive
              ? colorScheme.primary
              : Colors.white.withValues(alpha: 0.1),
          width: isActive ? 2.5 : 1,
        ),
      ),
      color: Colors.white.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isActive
                            ? [colorScheme.primary.withValues(alpha: 0.3), colorScheme.primary.withValues(alpha: 0.1)]
                            : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji ?? '📖',
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (isCompleted)
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 14, color: Colors.greenAccent),
                              SizedBox(width: 4),
                              Text(
                                'OK',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        else if (isActive)
                          Row(
                            children: [
                              Icon(Icons.play_circle_fill_rounded, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              const Text(
                                'NOW',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
          ],
        ),
      ),
    );
  }
}
