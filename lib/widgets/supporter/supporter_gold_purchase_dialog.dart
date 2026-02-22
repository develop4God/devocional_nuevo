import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Two-phase Gold supporter dialog.
///
/// **Phase 1 — Name input** (shown first)
///   Collects the supporter's optional display name with the gold name field
///   ([gold_name_hint] / [gold_name_helper]) then calls [onConfirm] which
///   handles pet-unlock BLoC logic.  The widget pops itself after [onConfirm]
///   returns successfully and advances to Phase 2 automatically.
///
/// **Phase 2 — Confirmation** (shown after onConfirm succeeds)
///   Luxury gold-branded success screen with animated trophy + confetti,
///   [gold_confirmation_title], and two exclusive CTAs:
///   • ⚙️  [go_to_settings]    → [SettingsPage]  (pet & name management)
///   • 📖 [go_to_devotionals]  → [DevocionalesPage] (start reading)
class SupporterGoldPurchaseDialog extends StatefulWidget {
  final SupporterTier tier;
  final BuildContext dialogContext;
  final TextEditingController nameController;

  /// Async business-logic callback (save name, unlock pet feature, clear BLoC
  /// errors).  Must NOT call Navigator.pop or navigate — the widget owns that.
  final Future<void> Function() onConfirm;

  const SupporterGoldPurchaseDialog({
    super.key,
    required this.tier,
    required this.dialogContext,
    required this.nameController,
    required this.onConfirm,
  });

  @override
  State<SupporterGoldPurchaseDialog> createState() =>
      _SupporterGoldPurchaseDialogState();
}

class _SupporterGoldPurchaseDialogState
    extends State<SupporterGoldPurchaseDialog>
    with SingleTickerProviderStateMixin {
  // ── Gold palette ──────────────────────────────────────────────────────────
  static const _gold = Color(0xFFFFD700);
  static const _goldDark = Color(0xFFB8860B);
  static const _goldLight = Color(0xFFFFF8DC);

  bool _isLoading = false;
  bool _showConfirmation = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    await widget.onConfirm();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _showConfirmation = true;
    });
    _fadeCtrl.forward();
  }

  void _navigateTo(Widget page) {
    Navigator.pop(widget.dialogContext);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _showConfirmation
                  ? _buildConfirmationPhase(context)
                  : _buildNamePhase(context),
            ),
          ),
        ),
      ),
    );
  }

  // ── Phase 1: name input ───────────────────────────────────────────────────

  Widget _buildNamePhase(BuildContext context) {
    return Column(
      key: const ValueKey('phase_name'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated badge
        Stack(
          alignment: Alignment.center,
          children: [
            Lottie.asset('assets/lottie/confetti.json',
                width: 180, height: 180, repeat: false),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [_gold, _goldDark],
                  center: Alignment(-0.3, -0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.6),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text('❤️', style: TextStyle(fontSize: 40)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_gold, Colors.white, _gold],
          ).createShader(bounds),
          child: Text(
            'supporter.gold_name_title'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        // Name field
        TextField(
          controller: widget.nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'supporter.gold_name_hint'.tr(),
            labelStyle: const TextStyle(color: _gold),
            helperText: 'supporter.gold_name_helper'.tr(),
            helperStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
            prefixIcon: const Icon(Icons.person, color: _gold),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _gold.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _gold, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          maxLength: 40,
          cursorColor: _gold,
        ),
        const SizedBox(height: 28),

        // CTA
        SizedBox(
          width: double.infinity,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : _GoldButton(
                  label: 'supporter.select_pet_button'.tr(),
                  icon: Icons.pets_rounded,
                  onTap: _handleConfirm,
                ),
        ),
      ],
    );
  }

  // ── Phase 2: confirmation ─────────────────────────────────────────────────

  Widget _buildConfirmationPhase(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        key: const ValueKey('phase_confirm'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy + confetti
          Stack(
            alignment: Alignment.center,
            children: [
              Lottie.asset('assets/lottie/confetti.json',
                  width: 200, height: 200, repeat: false),
              Lottie.asset('assets/lottie/trophy_star.json',
                  width: 110, height: 110, repeat: false),
            ],
          ),
          const SizedBox(height: 8),

          // ✨ Gold shimmer title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_goldDark, _gold, Colors.white, _gold, _goldDark],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ).createShader(bounds),
            child: Text(
              'supporter.gold_confirmation_title'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Colors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),

          // Helper / subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
            ),
            child: Text(
              'supporter.gold_name_helper'.tr(),
              style: TextStyle(
                color: _goldLight.withValues(alpha: 0.9),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // ── Button: Go to Settings ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: _GoldButton(
              label: 'supporter.go_to_settings'.tr(),
              icon: Icons.settings_rounded,
              onTap: () => _navigateTo(const SettingsPage()),
            ),
          ),
          const SizedBox(height: 12),

          // ── Button: Go to Devotionals ───────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateTo(const DevocionalesPage()),
              icon: const Icon(Icons.menu_book_rounded, color: _gold),
              label: Text(
                'supporter.go_to_devotionals'.tr(),
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: _gold, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable gold filled button ────────────────────────────────────────────

class _GoldButton extends StatelessWidget {
  static const _gold = Color(0xFFFFD700);
  static const _goldDark = Color(0xFFB8860B);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GoldButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_goldDark, _gold, Colors.white, _gold, _goldDark],
          stops: [0.0, 0.3, 0.5, 0.7, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.5),
            blurRadius: 16,
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
                  fontSize: 15,
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
