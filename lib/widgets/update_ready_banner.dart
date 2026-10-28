import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Banner shown above [child] when a background update finished downloading.
/// The user picks the moment: Restart applies it now, close hides it only until
/// the app returns from the background, so it keeps coming back until the
/// update is installed.
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
  final String restartLabel;
  final String closeTooltip;
  final Widget child;

  const UpdateReadyBanner({
    super.key,
    required this.updateReady,
    required this.onRestart,
    required this.title,
    required this.message,
    required this.restartLabel,
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
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.secondary.withValues(alpha: 0.35),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.system_update_rounded,
                color: colorScheme.secondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: widget.onRestart,
                      child: Text(widget.restartLabel),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: colorScheme.secondary),
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
