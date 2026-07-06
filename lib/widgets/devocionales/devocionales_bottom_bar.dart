import 'package:devocional_nuevo/controllers/audio_controller.dart';
import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/widgets/tts_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Bottom navigation bar for Devocionales page
/// Contains previous/next devotional controls and the TTS player.
/// The app-wide action icons live in AppBottomNavBar (owned by the shell).
class DevocionalesBottomBar extends StatelessWidget {
  final Devocional currentDevocional;
  final bool canNavigateNext;
  final bool canNavigatePrevious;
  final TtsAudioController ttsAudioController;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onShowInvitation;

  const DevocionalesBottomBar({
    super.key,
    required this.currentDevocional,
    required this.canNavigateNext,
    required this.canNavigatePrevious,
    required this.ttsAudioController,
    required this.onPrevious,
    required this.onNext,
    required this.onShowInvitation,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_buildNavigationControls(context, colorScheme)],
    );
  }

  Widget _buildNavigationControls(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Consumer<AudioController>(
            builder: (context, audioController, _) {
              final progress = audioController.progress;
              return LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorScheme.onSurface.withAlpha(51),
                color: colorScheme.primary,
              );
            },
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 45,
                  child: OutlinedButton.icon(
                    key: const Key('bottom_nav_previous_button'),
                    onPressed: canNavigatePrevious ? onPrevious : null,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: canNavigatePrevious
                          ? colorScheme.primary
                          : colorScheme.onSurface.withAlpha(97),
                    ),
                    label: Text(
                      'devotionals.previous'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: canNavigatePrevious
                            ? colorScheme.primary
                            : colorScheme.onSurface.withAlpha(97),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: canNavigatePrevious
                            ? colorScheme.primary
                            : colorScheme.onSurface.withAlpha(51),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      foregroundColor: canNavigatePrevious
                          ? colorScheme.primary
                          : colorScheme.onSurface.withAlpha(97),
                      overlayColor: canNavigatePrevious
                          ? colorScheme.primary.withAlpha((0.1 * 255).round())
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Builder(
                    builder: (context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TtsPlayerWidget(
                            key: const Key('bottom_nav_tts_player'),
                            devocional: currentDevocional,
                            audioController: ttsAudioController,
                            onCompleted: () {
                              onShowInvitation();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 45,
                  child: OutlinedButton(
                    key: const Key('bottom_nav_next_button'),
                    onPressed: canNavigateNext ? onNext : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: canNavigateNext
                            ? colorScheme.primary
                            : colorScheme.onSurface.withAlpha(51),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      foregroundColor: canNavigateNext
                          ? colorScheme.primary
                          : colorScheme.onSurface.withAlpha(97),
                      overlayColor: canNavigateNext
                          ? colorScheme.primary.withAlpha((0.1 * 255).round())
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'devotionals.next'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: canNavigateNext
                                ? colorScheme.primary
                                : colorScheme.onSurface.withAlpha(97),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: canNavigateNext
                              ? colorScheme.primary
                              : colorScheme.onSurface.withAlpha(97),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
