import 'package:devocional_nuevo/widgets/green_banner_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Green banner floated over the top of [child] when a background update
/// finished downloading. The user picks the moment: tapping the card applies
/// it now, close hides it only until the app returns from the background, so
/// it keeps coming back until the update is installed.
///
/// The banner overlays [child] instead of shifting it: nothing around the card
/// is painted, and taps outside the card reach [child].
///
/// Texts are passed in so the widget stays free of the localization service.
class UpdateReadyBanner extends StatefulWidget {
  final ValueListenable<bool> updateReady;

  /// Resolves to false when the update could not be installed.
  final Future<bool> Function() onRestart;
  final String title;
  final String message;
  final String closeTooltip;
  final String restartFailedMessage;
  final Widget child;

  const UpdateReadyBanner({
    super.key,
    required this.updateReady,
    required this.onRestart,
    required this.title,
    required this.message,
    required this.closeTooltip,
    required this.restartFailedMessage,
    required this.child,
  });

  @override
  State<UpdateReadyBanner> createState() => _UpdateReadyBannerState();
}

class _UpdateReadyBannerState extends State<UpdateReadyBanner>
    with WidgetsBindingObserver {
  bool _dismissed = false;
  bool _wasHidden = false;
  bool _restarting = false;

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

  Future<void> _restart() async {
    if (_restarting) return;
    setState(() => _restarting = true);
    final bool installed;
    try {
      installed = await widget.onRestart();
    } finally {
      if (mounted) setState(() => _restarting = false);
    }
    if (installed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.restartFailedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.updateReady,
      builder: (context, ready, _) {
        final visible = ready && !_dismissed;
        // The child stays the first Stack child in both states so its State
        // survives.
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (visible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildBanner(context),
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
        onTap: _restarting ? null : _restart,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: kBannerGreen,
                shape: BoxShape.circle,
              ),
              child: _restarting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: widget.title,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
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
              onPressed:
                  _restarting ? null : () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}
