import 'package:flutter/foundation.dart';
import 'package:devocional_nuevo/widgets/green_banner_card.dart';
import 'package:flutter/material.dart';

/// Green banner shown above [child] when a background update finished
/// downloading. The user picks the moment: tapping the card applies it now,
/// close hides it only until the app returns from the background, so it keeps
/// coming back until the update is installed.
///
/// While visible the banner takes over the top safe-area inset, so [child]
/// does not leave a second gap under it.
///
/// Texts are passed in so the widget stays free of the localization service.
class UpdateReadyBanner extends StatefulWidget {
  final ValueListenable<bool> updateReady;
  final VoidCallback onRestart;
  final String title;
  final String message;
  final String closeTooltip;
  final Widget child;

  const UpdateReadyBanner({
    super.key,
    required this.updateReady,
    required this.onRestart,
    required this.title,
    required this.message,
    required this.closeTooltip,
    required this.child,
  });

  @override
  State<UpdateReadyBanner> createState() => _UpdateReadyBannerState();
}

class _UpdateReadyBannerState extends State<UpdateReadyBanner>
    with WidgetsBindingObserver {
  bool _dismissed = false;
  bool _wasHidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// `inactive` is skipped on purpose: it also fires for system dialogs while
  /// the app is still on screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasHidden = true;
    } else if (state == AppLifecycleState.resumed && _wasHidden) {
      _wasHidden = false;
      if (_dismissed) setState(() => _dismissed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.updateReady,
      builder: (context, ready, _) {
        final visible = ready && !_dismissed;
        // The child stays at index 1 in both states so its State survives.
        return Column(
          children: [
            visible ? _buildBanner(context) : const SizedBox.shrink(),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: visible,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: GreenBannerCard(
        onTap: widget.onRestart,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: kBannerGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_done_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.message,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              tooltip: widget.closeTooltip,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}
