import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

/// Bottom action bar for Discovery detail modal with Share, Add to Prayers, TTS, and Mark Complete actions
class DiscoveryActionBar extends StatelessWidget {
  final Devocional devocional;
  final VoidCallback? onMarkComplete;
  final bool isComplete;
  final VoidCallback? onPlayPause;
  final bool isPlaying;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const DiscoveryActionBar({
    super.key,
    required this.devocional,
    this.onMarkComplete,
    this.isComplete = false,
    this.onPlayPause,
    this.isPlaying = false,
    this.onNext,
    this.onPrevious,
  });

  void _shareDevocional(BuildContext context) async {
    HapticFeedback.lightImpact();

    final verse = devocional.paraMeditar.isNotEmpty
        ? devocional.paraMeditar.first.cita
        : devocional.versiculo;

    final shareText = '''
📖 Devocional

$verse

${devocional.reflexion}

---
${'discovery.shared_from_app'.tr()}
''';

    await SharePlus.instance.share(ShareParams(text: shareText));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('discovery.share_success'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addToPrayers(BuildContext context) {
    HapticFeedback.mediumImpact();

    if (devocional.reflexion.isEmpty) {
      return;
    }

    final reflexionSnippet = devocional.reflexion.length > 100
        ? devocional.reflexion.substring(0, 100)
        : devocional.reflexion;
    final prayerText = 'Devocional: $reflexionSnippet...';

    context.read<PrayerBloc>().add(AddPrayer(prayerText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('discovery.added_to_prayers'.tr()),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _markAsComplete(BuildContext context) {
    HapticFeedback.heavyImpact();

    if (onMarkComplete != null) {
      onMarkComplete!();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isComplete
              ? 'discovery.marked_incomplete'.tr()
              : 'discovery.marked_complete'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (onPrevious != null)
                _ActionButton(
                  icon: Icons.arrow_back_ios,
                  label: 'navigation.previous'.tr(),
                  onPressed: onPrevious!,
                  color: Colors.blueGrey,
                ),
              _ActionButton(
                icon: Icons.share,
                label: 'discovery.share'.tr(),
                onPressed: () => _shareDevocional(context),
                color: theme.colorScheme.primary,
              ),
              _ActionButton(
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                label: isPlaying ? 'Pause' : 'Play',
                onPressed: onPlayPause ?? () {},
                color: Colors.deepPurple,
              ),
              _ActionButton(
                icon: Icons.favorite_border,
                label: 'discovery.add_prayer'.tr(),
                onPressed: () => _addToPrayers(context),
                color: Colors.pink,
              ),
              _ActionButton(
                icon: isComplete
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                label: isComplete
                    ? 'discovery.completed'.tr()
                    : 'discovery.mark_complete'.tr(),
                onPressed: () => _markAsComplete(context),
                color: isComplete ? Colors.green : theme.colorScheme.secondary,
              ),
              if (onNext != null)
                _ActionButton(
                  icon: Icons.arrow_forward_ios,
                  label: 'navigation.next'.tr(),
                  onPressed: onNext!,
                  color: Colors.blueGrey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.1),
            foregroundColor: color,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
