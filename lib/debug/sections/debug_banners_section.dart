import 'package:devocional_nuevo/widgets/bible/kjv_kj2000_banner.dart';
import 'package:devocional_nuevo/widgets/update_ready_banner.dart';
import 'package:flutter/material.dart';

/// Debug section to preview the in-app notice banners without waiting for a
/// Play update or a Bible version change. Actions only report through a
/// SnackBar: nothing is installed and no service is called.
class DebugBannersSection extends StatefulWidget {
  final String updateTitle;
  final String updateMessage;
  final String updateCloseTooltip;
  final String updateRestartFailedMessage;

  const DebugBannersSection({
    super.key,
    required this.updateTitle,
    required this.updateMessage,
    required this.updateCloseTooltip,
    required this.updateRestartFailedMessage,
  });

  @override
  State<DebugBannersSection> createState() => _DebugBannersSectionState();
}

class _DebugBannersSectionState extends State<DebugBannersSection> {
  final ValueNotifier<bool> _updateReady = ValueNotifier(true);
  bool _showUpdate = false;
  bool _showKjv = false;

  @override
  void dispose() {
    _updateReady.dispose();
    super.dispose();
  }

  void _report(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Banner previews',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => _showUpdate = !_showUpdate),
          child:
              Text(_showUpdate ? 'Hide update banner' : 'Show update banner'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() => _showKjv = !_showKjv),
          child: Text(_showKjv ? 'Hide KJV banner' : 'Show KJV banner'),
        ),
        if (_showUpdate)
          Center(
            child: ClipRRect(
              key: const Key('debug_banner_preview_area'),
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 360,
                height: 420,
                child: UpdateReadyBanner(
                  updateReady: _updateReady,
                  onRestart: () async {
                    _report('Restart tapped (preview only)');
                    return true;
                  },
                  title: widget.updateTitle,
                  message: widget.updateMessage,
                  closeTooltip: widget.updateCloseTooltip,
                  restartFailedMessage: widget.updateRestartFailedMessage,
                  child: const _FakeDevotionalPage(),
                ),
              ),
            ),
          ),
        if (_showKjv)
          KjvKj2000Banner(
            onDismiss: () => setState(() => _showKjv = false),
            onOpenDrawer: () => _report('Open drawer tapped (preview only)'),
          ),
      ],
    );
  }
}

/// Mimics the devotional page (photo hero, app bar actions, text) so the
/// preview shows what the floating banner covers.
class _FakeDevotionalPage extends StatelessWidget {
  const _FakeDevotionalPage();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            key: const Key('debug_banner_preview_hero'),
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B4C), Color(0xFF00897B)],
              ),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: const Row(
              children: [
                Icon(Icons.menu, color: Colors.white),
                Spacer(),
                Icon(Icons.share_outlined, color: Colors.white),
                SizedBox(width: 16),
                Icon(Icons.favorite_border, color: Colors.white),
              ],
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'For God so loved the world that he gave his one and only '
                'Son, that whoever believes in him shall not perish but have '
                'eternal life. A fake devotional text to show the banner '
                'floating over the page.',
                overflow: TextOverflow.fade,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
