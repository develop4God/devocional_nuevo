import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/supporter_pet.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Three-phase Gold supporter dialog:
///
/// Phase 0 — Name input  (gold_step_name)
///   The user types an optional display name and taps "Continue".
///
/// Phase 1 — Pet selection  (gold_step_pet)
///   A grid of animated pets.  Tapping one calls [onConfirm], unlocks the
///   pet feature, then advances to Phase 2.
///
/// Phase 2 — Confirmation  (gold_confirmation_title)
///   Trophy + confetti celebration with two navigation CTAs:
///     ⚙️  go_to_settings   → SettingsPage
///     📖 go_to_devotionals → DevocionalesPage
///
/// Back-navigation behaviour:
///   • Phase 0/1: shows a warm confirmation sheet ("set up later?").
///     – "Set up later" → marks setup pending, pops dialog.
///     – "Continue"     → dismisses sheet, resumes setup.
///   • Phase 2: pops freely (setup is complete).
///
/// If the app crashes before Phase 2, [SupporterPetService.isGoldSetupPending]
/// is true and the supporter_page shows a resume banner.
class SupporterGoldPurchaseDialog extends StatefulWidget {
  final SupporterTier tier;
  final BuildContext dialogContext;
  final TextEditingController nameController;

  /// Async callback: save name to BLoC + clear errors.
  /// Must NOT Navigator.pop or navigate — widget owns that.
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

// ── Phases ──────────────────────────────────────────────────────────────────

enum _GoldPhase { name, pet, confirmation }

class _SupporterGoldPurchaseDialogState
    extends State<SupporterGoldPurchaseDialog>
    with SingleTickerProviderStateMixin {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _gold = Color(0xFFFFD700);
  static const _goldLight = Color(0xFFFFF8DC);
  static const _bgStart = Color(0xFF1A1A2E);
  static const _bgMid = Color(0xFF16213E);
  static const _bgEnd = Color(0xFF0F3460);

  _GoldPhase _phase = _GoldPhase.name;
  bool _isLoading = false;
  String? _selectedPetId;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    // Mark as pending immediately so crash-recovery banner appears if needed
    getService<SupporterPetService>().markGoldSetupPending();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Phase transitions ─────────────────────────────────────────────────────

  void _advanceTo(_GoldPhase next) {
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _phase = next);
      _fadeCtrl.forward();
    });
  }

  Future<void> _onNameContinue() async {
    _advanceTo(_GoldPhase.pet);
  }

  Future<void> _onPetSelected(SupporterPet pet) async {
    setState(() {
      _isLoading = true;
      _selectedPetId = pet.id;
    });

    final petService = getService<SupporterPetService>();
    await petService.setSelectedPet(pet.id);

    // Run onConfirm (saves name, unlocks pet feature, clears BLoC)
    await widget.onConfirm();

    if (!mounted) return;
    setState(() => _isLoading = false);
    _advanceTo(_GoldPhase.confirmation);
  }

  // ── Back-navigation handler ───────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    if (_phase == _GoldPhase.confirmation) return true;
    // Show warm "set up later?" sheet
    final leave = await _showLeaveSheet();
    // markGoldSetupPending() is already called in initState — no need to repeat here.
    return leave == true;
  }

  Future<bool?> _showLeaveSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: _bgMid,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Icon(Icons.warning_amber_rounded, color: _gold, size: 44),
                const SizedBox(height: 12),
                Text(
                  'supporter.gold_back_warning_title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'supporter.gold_back_warning_body'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // "Set up later"
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _gold, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'supporter.gold_back_confirm'.tr(),
                      style: const TextStyle(
                          color: _gold, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // "Continue setup"
                SizedBox(
                  width: double.infinity,
                  child: _GoldButton(
                    label: 'supporter.gold_back_dismiss'.tr(),
                    icon: Icons.arrow_forward_rounded,
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Final navigation ──────────────────────────────────────────────────────

  void _navigateTo(Widget page) {
    // Must use widget.dialogContext here — the gold dialog is a multi-phase
    // flow pushed from a parent route. By Phase 2, the local BuildContext may
    // no longer be associated with the original dialog route, so we hold a
    // reference to the push-site context to ensure the correct route is popped.
    Navigator.pop(widget.dialogContext);
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => page),
      );
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase == _GoldPhase.confirmation,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final nav = Navigator.of(widget.dialogContext);
          await _onWillPop().then((leave) {
            if (leave && mounted) nav.pop();
          });
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        clipBehavior: Clip.antiAlias,
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        // Reduce padding for autofit
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 280,
            maxWidth: 400,
            minHeight: 200,
            maxHeight: 600,
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bgStart, _bgMid, _bgEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildPhase(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context) {
    switch (_phase) {
      case _GoldPhase.name:
        return _buildNamePhase();
      case _GoldPhase.pet:
        return _buildPetPhase();
      case _GoldPhase.confirmation:
        return _buildConfirmationPhase();
    }
  }

  // ── Phase 0: Name ─────────────────────────────────────────────────────────

  Widget _buildNamePhase() {
    return Column(
      key: const ValueKey('phase_name'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step label
        _StepLabel(label: 'supporter.gold_step_name'.tr()),
        const SizedBox(height: 16),

        // Badge + confetti
        Stack(alignment: Alignment.center, children: [
          Lottie.asset('assets/lottie/confetti.json',
              width: 180, height: 180, repeat: false),
          _GoldCircle(emoji: widget.tier.emoji),
        ]),
        const SizedBox(height: 12),

        // Shimmer title
        _GoldShimmerText('supporter.purchase_success_title'.tr(), fontSize: 22),
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
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
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
            counterStyle:
                TextStyle(color: Colors.white.withValues(alpha: 0.45)),
          ),
          maxLength: 15,
          maxLines: 2,
          // Allow two lines for clearer text
          cursorColor: _gold,
          buildCounter: (BuildContext context,
              {required int currentLength,
              required bool isFocused,
              required int? maxLength}) {
            return currentLength > 15
                ? Text(
                    'Max 15 characters',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11),
                  )
                : null;
          },
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: _GoldButton(
            label: 'app.next'.tr(),
            icon: Icons.arrow_forward_rounded,
            onTap: _onNameContinue,
          ),
        ),
      ],
    );
  }

  // ── Phase 1: Pet selection ────────────────────────────────────────────────

  Widget _buildPetPhase() {
    return Column(
      key: const ValueKey('phase_pet'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepLabel(label: 'supporter.gold_step_pet'.tr()),
        const SizedBox(height: 12),
        _GoldShimmerText('supporter.pet_selection_title'.tr(), fontSize: 20),
        const SizedBox(height: 8),
        Text(
          'supporter.pet_preview_description'.tr(),
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(color: _gold),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemCount: SupporterPet.allPets.length,
            itemBuilder: (_, i) {
              final pet = SupporterPet.allPets[i];
              final isSelected = _selectedPetId == pet.id;
              return _PetCard(
                pet: pet,
                isSelected: isSelected,
                onTap: () => _onPetSelected(pet),
              );
            },
          ),
      ],
    );
  }

  // ── Phase 2: Confirmation ─────────────────────────────────────────────────

  Widget _buildConfirmationPhase() {
    return Column(
      key: const ValueKey('phase_confirmation'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trophy + confetti
        Stack(alignment: Alignment.center, children: [
          Lottie.asset('assets/lottie/confetti.json',
              width: 200, height: 200, repeat: false),
          Lottie.asset('assets/lottie/trophy_star.json',
              width: 110, height: 110, repeat: false),
        ]),
        const SizedBox(height: 8),

        // Shimmer title
        _GoldShimmerText('supporter.gold_confirmation_title'.tr(),
            fontSize: 24),
        const SizedBox(height: 12),

        // Gold helper / subtitle
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

        // ⚙️ Go to Settings
        SizedBox(
          width: double.infinity,
          child: _GoldButton(
            label: 'supporter.go_to_settings'.tr(),
            icon: Icons.settings_rounded,
            onTap: () => _navigateTo(const SettingsPage()),
          ),
        ),
        const SizedBox(height: 12),

        // 📖 Go to Devotionals
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigateTo(const DevocionalesPage()),
            icon: const Icon(Icons.home_filled, color: _gold),
            label: AutoSizeText(
              'supporter.go_to_devotionals'.tr(),
              maxLines: 1,
              minFontSize: 11,
              style: const TextStyle(
                  color: _gold, fontWeight: FontWeight.w700, fontSize: 15),
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
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _StepLabel extends StatelessWidget {
  final String label;

  const _StepLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _GoldShimmerText extends StatelessWidget {
  final String text;
  final double fontSize;

  const _GoldShimmerText(this.text, {required this.fontSize});

  static const _gold = Color(0xFFFFD700);
  static const _goldDark = Color(0xFFB8860B);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [_goldDark, _gold, Colors.white, _gold, _goldDark],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
          color: Colors.white,
          height: 1.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _GoldCircle extends StatelessWidget {
  final String emoji;

  const _GoldCircle({required this.emoji});

  static const _gold = Color(0xFFFFD700);
  static const _goldDark = Color(0xFFB8860B);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 40)),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final SupporterPet pet;
  final bool isSelected;
  final VoidCallback onTap;

  const _PetCard(
      {required this.pet, required this.isSelected, required this.onTap});

  static const _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isSelected
            ? _gold.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: isSelected ? _gold : _gold.withValues(alpha: 0.2),
          width: isSelected ? 2.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Lottie.asset(
                  pet.lottieAsset,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      pet.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${pet.emoji} ${pet.nameKey.tr()}',
                style: TextStyle(
                  color: isSelected ? _gold : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Gold filled button (reusable) ─────────────────────────────────────────────

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.black87, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: AutoSizeText(
                    label,
                    maxLines: 1,
                    minFontSize: 11,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
