// lib/pages/supporter_page.dart
//
// Uses [SupporterBloc] for all IAP state management.
// The bloc is provided by the caller (see settings_page.dart).

import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_event.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/spiritual_stats_model.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/i_spiritual_stats_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/supporter/supporter_bronze_silver_purchase_dialog.dart';
import 'package:devocional_nuevo/widgets/supporter/supporter_gold_purchase_dialog.dart';
import 'package:devocional_nuevo/widgets/supporter/tier_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

/// Page that shows the 3 supporter tiers with Google Play Billing integration.
///
/// Requires a [SupporterBloc] ancestor in the widget tree
/// (provided by [settings_page.dart] navigation).
class SupporterPage extends StatefulWidget {
  const SupporterPage({super.key});

  @override
  State<SupporterPage> createState() => _SupporterPageState();
}

class _SupporterPageState extends State<SupporterPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeIn;
  late AnimationController _confettiController;

  bool _showScrollHint = true;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFadeIn = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerAnimController.forward();

    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _showConfetti = false);
          _confettiController.reset();
        }
      });

    _scrollController.addListener(_scrollListener);

    // Kick off IAP initialization only if not already loaded.
    // The BLoC is hoisted to main.dart and lives across navigations — without
    // this guard, every navigation back to SupporterPage would re-subscribe to
    // onPurchaseDelivered and cause a SupporterLoaded → SupporterLoading →
    // SupporterLoaded flicker.
    final bloc = context.read<SupporterBloc>();
    if (bloc.state is! SupporterLoaded) {
      bloc.add(InitializeSupporter());
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      if (offset > 50 && _showScrollHint) {
        setState(() => _showScrollHint = false);
      } else if (offset <= 50 && !_showScrollHint) {
        setState(() => _showScrollHint = true);
      }
    }
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _confettiController.dispose();
    _scrollController
      ..removeListener(_scrollListener)
      ..dispose();
    super.dispose();
  }

  // ── Unlock Logic ──────────────────────────────────────────────────────────

  Future<void> _unlockSupporterBadge(SupporterTierLevel level) async {
    final statsService = getService<ISpiritualStatsService>();
    final stats = await statsService.getStats();
    final badgeId = 'supporter_${level.name}';

    // Check if already unlocked
    if (stats.unlockedAchievements.any((a) => a.id == badgeId)) return;

    // Find the badge definition
    final badgeTemplate = PredefinedAchievements.supporterBadges
        .firstWhere((a) => a.id == badgeId);

    final updatedAchievements =
        List<Achievement>.from(stats.unlockedAchievements)
          ..add(badgeTemplate.copyWith(isUnlocked: true));

    await statsService.saveStats(stats.copyWith(
      unlockedAchievements: updatedAchievements,
    ));
  }

  // ── Event callbacks ───────────────────────────────────────────────────────

  void _onPurchaseTier(SupporterTier tier) {
    debugPrint(
        '🛒 [SupporterPage] Request purchase -> ${tier.productId} (${tier.nameKey.tr()})');
    context.read<SupporterBloc>().add(PurchaseTier(tier));
  }

  void _onRestorePurchases() {
    debugPrint('🔄 [SupporterPage] Restore purchases requested');
    context.read<SupporterBloc>().add(RestorePurchases());
  }

  // ── Success dialog ────────────────────────────────────────────────────────

  void _showSuccessDialog(SupporterTier tier,
      {TextEditingController? existingNameController}) {
    final nameController = existingNameController ?? TextEditingController();
    final isGold = tier.level == SupporterTierLevel.gold;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => isGold
          ? SupporterGoldPurchaseDialog(
              tier: tier,
              dialogContext: dialogContext,
              nameController: nameController,
              // Business logic only — no Navigator.pop, no navigation.
              // Pet unlock + selection are handled inside the dialog.
              // This callback: save name to BLoC + clear errors.
              onConfirm: () async {
                final bloc = context.read<SupporterBloc>();
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  bloc.add(SaveGoldSupporterName(name));
                }
                await getService<SupporterPetService>().unlockPetFeature();
                if (!context.mounted) return;
                bloc.add(ClearSupporterError());
              },
            )
          : SupporterPurchaseDialog(
              tier: tier,
              dialogContext: dialogContext,
              // Business logic only — no Navigator.pop, no navigation.
              // The widget handles pop + go_to_progress internally.
              onConfirm: () async {
                final bloc = context.read<SupporterBloc>();
                await _unlockSupporterBadge(tier.level);
                if (!context.mounted) return;
                bloc.add(ClearSupporterError());
              },
            ),
    );
  }

  void _showBillingUnavailableDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('supporter.billing_unavailable_title'.tr()),
        content: Text('supporter.billing_unavailable_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('app.ok'.tr()),
          ),
        ],
      ),
    );
  }

  /// Opens the edit-name dialog for Gold supporters who want to set or update
  /// their display name.  Sends [AcknowledgeGoldNameEdit] before the dialog so
  /// the BLoC signal is consumed and won't re-open on state rebuilds.
  void _showEditNameDialog() {
    final bloc = context.read<SupporterBloc>();
    // Consume the signal immediately to prevent re-entry on rebuild.
    bloc.add(AcknowledgeGoldNameEdit());

    final currentName = (bloc.state is SupporterLoaded)
        ? (bloc.state as SupporterLoaded).goldSupporterName ?? ''
        : '';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => _GoldNameEditDialog(
        currentName: currentName,
        onSave: (name) {
          context.read<SupporterBloc>().add(SaveGoldSupporterName(name));
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
    context.read<SupporterBloc>().add(ClearSupporterError());
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: BlocListener<SupporterBloc, SupporterState>(
        listener: (context, state) {
          // Log key state transitions for easier debugging of spinner/infinite loops
          debugPrint(
              '🔔 [SupporterPage] SupporterBloc state -> ${state.runtimeType}');
          if (state is SupporterLoaded) {
            debugPrint(
                '📦 [SupporterPage] purchasedLevels=${state.purchasedLevels}, purchasingProductId=${state.purchasingProductId}, isRestoring=${state.isRestoring}, error=${state.errorMessage}');
            // Handle successful delivery
            if (state.justDeliveredTier != null) {
              setState(() => _showConfetti = true);
              _confettiController.forward();
              _showSuccessDialog(state.justDeliveredTier!);
            }

            // Handle Gold supporter edit-name request
            if (state.isEditingGoldName) {
              _showEditNameDialog();
            }

            // Handle errors
            if (state.errorMessage != null) {
              if (state.errorMessage == 'billing_unavailable') {
                _showBillingUnavailableDialog();
                context.read<SupporterBloc>().add(ClearSupporterError());
              } else {
                _showErrorSnackBar('supporter.purchase_error'.tr());
              }
            }
          }
        },
        child: Scaffold(
          appBar: CustomAppBar(titleText: 'supporter.page_title'.tr()),
          body: Stack(
            children: [
              FadeTransition(
                opacity: _headerFadeIn,
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: BlocBuilder<SupporterBloc, SupporterState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            _buildMissionHeader(colorScheme, textTheme),
                            const SizedBox(height: 24),
                            _buildMinistryMessage(colorScheme, textTheme),
                            const SizedBox(height: 32),
                            if (state is SupporterLoading)
                              _buildLoadingState()
                            else if (state is SupporterLoaded)
                              _buildTiersList(state, colorScheme, textTheme)
                            else
                              _buildLoadingState(),
                            const SizedBox(height: 24),
                            _buildRestorePurchases(
                                state, colorScheme, textTheme),
                            const SizedBox(height: 16),
                            _buildDisclaimerText(colorScheme, textTheme),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (_showConfetti)
                IgnorePointer(
                  child: Lottie.asset(
                    'assets/lottie/confetti.json',
                    controller: _confettiController,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_showScrollHint)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _showScrollHint ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer
                                .withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: colorScheme.onPrimaryContainer,
                                size: 28,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'discovery.read'.tr(),
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────

  Widget _buildMissionHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset(
              'assets/lottie/hands_heart.json',
              height: 60,
              width: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'supporter.header_title'.tr(),
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'supporter.header_subtitle'.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMinistryMessage(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        'supporter.ministry_message'.tr(),
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(60.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildTiersList(
    SupporterLoaded state,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    const goldColor = Color(0xFFFFD700);
    final isGoldPurchased = state.isPurchased(SupporterTierLevel.gold);
    final petService = getService<SupporterPetService>();
    final showPendingBanner = isGoldPurchased && petService.isGoldSetupPending;

    return Column(
      children: [
        // ── Pending Gold setup banner ─────────────────────────────────────
        if (showPendingBanner) ...[
          _GoldSetupPendingBanner(
            onTap: () async {
              await petService.clearGoldSetupPending();
              if (!mounted) return;
              final nameController = TextEditingController(
                text: state.goldSupporterName ?? '',
              );
              _showSuccessDialog(
                SupporterTier.fromLevel(SupporterTierLevel.gold),
                existingNameController: nameController,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'supporter.choose_tier'.tr(),
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        ...SupporterTier.tiers.map(
          (tier) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: TierCard(
              tier: tier,
              storePrice: state.storePrices[tier.productId],
              isPurchased: state.isPurchased(tier.level),
              isLoading: state.purchasingProductId == tier.productId,
              onPurchase: () => _onPurchaseTier(tier),
            ),
          ),
        ),
        // Gold supporter: show edit-name button when Gold is purchased.
        if (isGoldPurchased) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('gold_edit_name_button'),
            onPressed: () =>
                context.read<SupporterBloc>().add(EditGoldSupporterName()),
            icon: const Icon(Icons.edit_rounded, color: goldColor, size: 18),
            label: Text(
              state.goldSupporterName != null
                  ? 'supporter.gold_edit_name_button'.tr()
                  : 'supporter.gold_set_name_button'.tr(),
              style: const TextStyle(
                  color: goldColor, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: goldColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildRestorePurchases(
    SupporterState state,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isLoading = state is SupporterLoading;
    return TextButton.icon(
      onPressed: isLoading ? null : _onRestorePurchases,
      icon: const Icon(Icons.restore, size: 18),
      label: Text(
        'supporter.restore_purchases'.tr(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDisclaimerText(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'supporter.disclaimer'.tr(),
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Gold pending-setup banner ─────────────────────────────────────────────────

/// Shown on the supporter page when gold was purchased but the user dismissed
/// the setup dialog before choosing a name/pet (crash-recovery fallback).
class _GoldSetupPendingBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _GoldSetupPendingBanner({required this.onTap});

  static const _gold = Color(0xFFFFD700);
  static const _goldDark = Color(0xFFB8860B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: _gold, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'supporter.gold_setup_pending_banner'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_goldDark, _gold],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'supporter.gold_setup_complete_now'.tr(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _gold, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gold name edit dialog ─────────────────────────────────────────────────────

/// A [StatefulWidget] dialog for editing the Gold supporter display name.
///
/// Owns its [TextEditingController] so it is properly disposed when the dialog
/// is dismissed — prevents the "A TextEditingController was garbage collected
/// while still attached to a TextField" warning.
class _GoldNameEditDialog extends StatefulWidget {
  const _GoldNameEditDialog({
    required this.currentName,
    required this.onSave,
  });

  final String currentName;
  final void Function(String name) onSave;

  @override
  State<_GoldNameEditDialog> createState() => _GoldNameEditDialogState();
}

class _GoldNameEditDialogState extends State<_GoldNameEditDialog> {
  late final TextEditingController _controller;

  static const _goldColor = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.person_pin_rounded, color: _goldColor),
          const SizedBox(width: 8),
          Text('supporter.gold_edit_name_title'.tr()),
        ],
      ),
      content: TextField(
        key: const ValueKey('gold_name_text_field'),
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'supporter.gold_name_hint'.tr(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _goldColor, width: 2),
          ),
          helperText: 'supporter.gold_name_helper'.tr(),
          prefixIcon: const Icon(Icons.person, color: _goldColor),
        ),
        maxLength: 40,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('app.cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              widget.onSave(name);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _goldColor,
            foregroundColor: Colors.black87,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text('app.save'.tr()),
        ),
      ],
    );
  }
}
