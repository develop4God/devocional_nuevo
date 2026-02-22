import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/pages/progress_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Success confirmation dialog shown after a Bronze or Silver tier purchase.
///
/// • Back / system-navigation — always allowed (badge is already persisted).
///   [onConfirm] is still called so BLoC state is cleaned up.
/// • Two action buttons:
///     – Primary  "Go to Progress"  → badge page
///     – Secondary "Close"          → stay in supporter page (card updates)
///
/// [onConfirm] must handle badge-unlock BLoC events but must NOT call
/// Navigator.pop or navigate — the widget owns those responsibilities.
class SupporterPurchaseDialog extends StatefulWidget {
  final SupporterTier tier;
  final BuildContext dialogContext;

  /// Async badge-unlock + BLoC cleanup. Must NOT pop or navigate.
  final Future<void> Function() onConfirm;

  const SupporterPurchaseDialog({
    super.key,
    required this.tier,
    required this.dialogContext,
    required this.onConfirm,
  });

  @override
  State<SupporterPurchaseDialog> createState() =>
      _SupporterPurchaseDialogState();
}

class _SupporterPurchaseDialogState extends State<SupporterPurchaseDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  // ── Tier-specific palette ─────────────────────────────────────────────────

  bool get _isSilver => widget.tier.level == SupporterTierLevel.silver;

  /// Dark background derived from tier
  Color get _bgStart =>
      _isSilver ? const Color(0xFF1C1C2E) : const Color(0xFF1A0D00);

  Color get _bgEnd =>
      _isSilver ? const Color(0xFF2A2A40) : const Color(0xFF2E1500);

  /// Accent color (matches badge but darker)
  Color get _accent => widget.tier.badgeColor;

  Color get _accentDark => _isSilver
      ? const Color(0xFF8A8A9A)
      : const Color(0xFF8B4513); // silver-gray / saddle-brown

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _handleAction({required bool goToProgress}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await widget.onConfirm();
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context); // Use local context, not widget.dialogContext
    if (goToProgress && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProgressPage()),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // PopScope: back is always allowed — purchase is done, badge persists.
    // We still run onConfirm silently to clean up BLoC state.
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_isLoading) {
          widget.onConfirm();
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgStart, _bgEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ScaleTransition(
                scale: _entryAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Animated badge ──────────────────────────────────────
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Lottie.asset('assets/lottie/confetti.json',
                            width: 200, height: 200, repeat: false),
                        _buildBadgeCircle(),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // ── Shimmer title ───────────────────────────────────────
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          _accentDark,
                          _accent,
                          Colors.white,
                          _accent,
                          _accentDark
                        ],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        'supporter.purchase_success_title'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Body ───────────────────────────────────────────────
                    Text(
                      'supporter.medal_unlocked_body'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // ── Verse card ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _accent.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'supporter.purchase_success_verse'.tr(),
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'supporter.purchase_success_verse_ref'.tr(),
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Primary CTA ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(color: _accent))
                          : _TierButton(
                              label:
                                  'supporter.go_to_progress'.tr().toUpperCase(),
                              icon: Icons.auto_graph_rounded,
                              accent: _accent,
                              accentDark: _accentDark,
                              onTap: () => _handleAction(goToProgress: true),
                            ),
                    ),
                    const SizedBox(height: 10),

                    // ── Secondary: close ────────────────────────────────────
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleAction(goToProgress: false),
                      child: Text(
                        'app.close'.tr(),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Badge circle ─────────────────────────────────────────────────────────

  Widget _buildBadgeCircle() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [_accent, _accentDark],
          center: const Alignment(-0.3, -0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.55),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.tier.emoji,
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}

// ── Reusable tier-colored filled button ──────────────────────────────────────

class _TierButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final Color accentDark;
  final VoidCallback onTap;

  const _TierButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.accentDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentDark, accent, Colors.white, accent, accentDark],
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black87, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
