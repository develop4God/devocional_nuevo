// lib/widgets/prayer_wall/prayer_wall_card.dart

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/prayer_wall_entry.dart';
import 'package:flutter/material.dart';

/// Displays a single prayer on the Prayer Wall.
///
/// Shows:
/// - 🙏 pray count with tap animation
/// - Language badge (for cross-language Section 2)
/// - Masked prayer text (PII-free)
/// - "Being reviewed 🙏" placeholder while status = [PrayerWallStatus.pending]
class PrayerWallCard extends StatefulWidget {
  final PrayerWallEntry prayer;
  final bool showLanguageBadge;
  final bool isCompact;
  final VoidCallback? onPrayTap;
  final VoidCallback? onReport;

  const PrayerWallCard({
    super.key,
    required this.prayer,
    this.showLanguageBadge = false,
    this.isCompact = false,
    this.onPrayTap,
    this.onReport,
  });

  @override
  State<PrayerWallCard> createState() => _PrayerWallCardState();
}

class _PrayerWallCardState extends State<PrayerWallCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePrayTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onPrayTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isPending = widget.prayer.status == PrayerWallStatus.pending;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: widget.isCompact ? 4 : 6,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: widget.isCompact ? 1 : 2,
      child: Padding(
        padding: EdgeInsets.all(widget.isCompact ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: language badge + report button
            if (widget.showLanguageBadge || widget.onReport != null)
              Row(
                children: [
                  if (widget.showLanguageBadge)
                    _LanguageBadge(language: widget.prayer.language),
                  const Spacer(),
                  if (widget.onReport != null && !isPending)
                    _ReportButton(onTap: widget.onReport!),
                ],
              ),

            // Prayer text or pending placeholder
            if (isPending)
              _PendingPlaceholder(isCompact: widget.isCompact)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  widget.prayer.maskedText,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: widget.isCompact ? 13 : 15,
                    height: 1.4,
                  ),
                  maxLines: widget.isCompact ? 3 : null,
                  overflow: widget.isCompact
                      ? TextOverflow.ellipsis
                      : TextOverflow.visible,
                ),
              ),

            const SizedBox(height: 8),

            // Footer: pray count
            if (!isPending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _PrayCountButton(
                    count: widget.prayer.prayCount,
                    scaleAnimation: _scaleAnimation,
                    onTap: _handlePrayTap,
                    color: colorScheme.primary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingPlaceholder extends StatelessWidget {
  final bool isCompact;
  const _PendingPlaceholder({this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded,
              size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'prayer_wall.pending'.tr(),
              style: TextStyle(
                fontSize: isCompact ? 12 : 14,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  final String language;
  const _LanguageBadge({required this.language});

  static const Map<String, String> _flags = {
    'en': '🇬🇧',
    'es': '🇪🇸',
    'pt': '🇧🇷',
    'fr': '🇫🇷',
    'hi': '🇮🇳',
    'ja': '🇯🇵',
    'zh': '🇨🇳',
  };

  @override
  Widget build(BuildContext context) {
    final flag = _flags[language] ?? '🌐';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        flag,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.flag_outlined, size: 18),
      tooltip: 'prayer_wall.report'.tr(),
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

class _PrayCountButton extends StatelessWidget {
  final int count;
  final Animation<double> scaleAnimation;
  final VoidCallback onTap;
  final Color color;

  const _PrayCountButton({
    required this.count,
    required this.scaleAnimation,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: scaleAnimation,
            child: const Text('🙏', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
