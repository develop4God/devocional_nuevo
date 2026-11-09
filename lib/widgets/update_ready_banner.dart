import 'package:devocional_nuevo/services/i_update_service.dart';
import 'package:devocional_nuevo/widgets/app_snack_bar.dart';
import 'package:devocional_nuevo/widgets/notice_banner_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Passive "update downloading" card: its state and the texts it shows. Kept as
/// one object so the texts cannot be forgotten when the card is enabled.
class UpdateDownloadNotice {
  final ValueListenable<bool> downloading;
  final String title;
  final String message;

  const UpdateDownloadNotice({
    required this.downloading,
    required this.title,
    required this.message,
  });
}

/// Banner floated over the top of [child] when a background update
/// finished downloading. The user picks the moment: tapping the card applies
/// it now, close hides it only until the app returns from the background, so
/// it keeps coming back until the update is installed.
///
/// The banner overlays [child] instead of shifting it: nothing around the card
/// is painted, and taps outside the card reach [child].
///
/// While the update downloads, a passive card with a spinner tells the user it
/// is happening (Play shows no progress for a flexible update). It is replaced
/// by the ready card once the download ends.
///
/// Texts are passed in so the widget stays free of the localization service.
class UpdateReadyBanner extends StatefulWidget {
  final ValueListenable<bool> updateReady;

  /// Optional: without it no download card is shown.
  final UpdateDownloadNotice? download;

  /// Only [UpdateInstallResult.failed] shows [restartFailedMessage]; an
  /// unconfirmed install leaves the card up and tappable again, silently.
  final Future<UpdateInstallResult> Function() onRestart;
  final String title;
  final String message;
  final String closeTooltip;
  final String restartFailedMessage;
  final Widget child;

  const UpdateReadyBanner({
    super.key,
    required this.updateReady,
    this.download,
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
  // Per phase: closing the passive download card must not hide the ready card
  // that replaces it.
  bool _dismissedDownload = false;
  bool _dismissedReady = false;
  bool _wasHidden = false;
  bool _restarting = false;

  /// Identifies the current restart call. Closing the card abandons a pending
  /// call (Play may never answer it); its late result is ignored.
  int _restartAttempt = 0;

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
      // Only the actionable ready card comes back: a closed download card is
      // purely informational.
      if (_dismissedReady) setState(() => _dismissedReady = false);
    }
  }

  Future<void> _restart() async {
    if (_restarting) return;
    final attempt = ++_restartAttempt;
    setState(() => _restarting = true);
    final UpdateInstallResult result;
    try {
      result = await widget.onRestart();
    } finally {
      if (mounted && attempt == _restartAttempt) {
        setState(() => _restarting = false);
      }
    }
    if (result != UpdateInstallResult.failed ||
        !mounted ||
        attempt != _restartAttempt) {
      return;
    }
    AppSnackBar.show(
      context,
      widget.restartFailedMessage,
      type: AppSnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadingListenable = widget.download?.downloading;
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.updateReady,
        if (downloadingListenable != null) downloadingListenable,
      ]),
      builder: (context, _) {
        final ready = widget.updateReady.value;
        final downloading = !ready && (downloadingListenable?.value ?? false);
        // A closed download card only stays closed for that download.
        if (!downloading) _dismissedDownload = false;
        final visible =
            ready ? !_dismissedReady : downloading && !_dismissedDownload;
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
                child: _buildBanner(context, downloading: downloading),
              ),
          ],
        );
      },
    );
  }

  void _dismiss(bool downloading) {
    // Abandons a pending restart so the card is idle when it comes back.
    _restartAttempt++;
    _restarting = false;
    if (downloading) {
      _dismissedDownload = true;
    } else {
      _dismissedReady = true;
    }
  }

  Widget _buildBanner(BuildContext context, {required bool downloading}) {
    final colorScheme = Theme.of(context).colorScheme;
    final download = widget.download;
    final title =
        downloading && download != null ? download.title : widget.title;
    final message =
        downloading && download != null ? download.message : widget.message;
    return SafeArea(
      bottom: false,
      child: NoticeBannerCard(
        onTap: _restarting || downloading ? null : _restart,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kNoticeIcon.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: _restarting || downloading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: title,
                        color: kNoticeIcon,
                      ),
                    )
                  : const Icon(
                      Icons.download_done_outlined,
                      color: kNoticeIcon,
                      size: 18,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
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
              onPressed: () => setState(() => _dismiss(downloading)),
            ),
          ],
        ),
      ),
    );
  }
}
