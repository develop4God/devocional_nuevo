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

  const DebugBannersSection({
    super.key,
    required this.updateTitle,
    required this.updateMessage,
    required this.updateCloseTooltip,
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
          SizedBox(
            height: 150,
            child: UpdateReadyBanner(
              updateReady: _updateReady,
              onRestart: () => _report('Restart tapped (preview only)'),
              title: widget.updateTitle,
              message: widget.updateMessage,
              closeTooltip: widget.updateCloseTooltip,
              child: const SizedBox.shrink(),
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
