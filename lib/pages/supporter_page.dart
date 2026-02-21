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
import 'package:devocional_nuevo/models/supporter_pet.dart';
import 'package:devocional_nuevo/models/supporter_tier.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
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

  void _showSuccessDialog(SupporterTier tier) {
    final nameController = TextEditingController();
    final isGold = tier.level == SupporterTierLevel.gold;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Lottie.asset(
                      'assets/lottie/confetti.json',
                      width: 200,
                      height: 200,
                      repeat: false,
                    ),
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.green,
                      size: 100,
                    ),
                  ],
                ),
                Text(
                  tier.emoji,
                  style: const TextStyle(fontSize: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  'supporter.purchase_success_title'.tr(),
                  style:
                      Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: tier.badgeColor,
                          ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'supporter.purchase_success_body'.tr(),
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(dialogContext)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: tier.badgeColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'supporter.purchase_success_verse'.tr(),
                        style: Theme.of(dialogContext)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(dialogContext).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'supporter.purchase_success_verse_ref'.tr(),
                        style: Theme.of(dialogContext)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: tier.badgeColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isGold) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'supporter.gold_name_hint'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: tier.badgeColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: tier.badgeColor, width: 2),
                      ),
                      helperText: 'supporter.gold_name_helper'.tr(),
                      prefixIcon: Icon(Icons.person, color: tier.badgeColor),
                    ),
                    maxLength: 40,
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Capture the bloc reference before any async gaps.
                      final bloc = context.read<SupporterBloc>();

                      if (isGold) {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          bloc.add(SaveGoldSupporterName(name));
                        }

                        // Unlock pet feature and show selection
                        await getService<SupporterPetService>()
                            .unlockPetFeature();

                        // Guard against widget being unmounted during await
                        if (!context.mounted) return;
                      }

                      // Clear the just-delivered tier from state
                      bloc.add(ClearSupporterError());

                      if (isGold) {
                        Navigator.pop(dialogContext);
                        _showPetSelectionDialog();
                      } else {
                        Navigator.pop(dialogContext);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tier.badgeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      shadowColor: tier.badgeColor.withValues(alpha: 0.5),
                    ),
                    child: Text(
                      isGold
                          ? 'supporter.select_pet_button'.tr()
                          : 'supporter.purchase_success_button'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 18),
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

  void _showPetSelectionDialog() {
    final petService = getService<SupporterPetService>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              Text(
                '¡Regalo Desbloqueado!',
                style:
                    Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.amber.shade900,
                        ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige el compañero que te acompañará en tu devocional diario.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: SupporterPet.allPets.length,
                  itemBuilder: (context, index) {
                    final pet = SupporterPet.allPets[index];
                    return InkWell(
                      onTap: () async {
                        await petService.setSelectedPet(pet.id);
                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        _showFinalCelebration(pet);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 80,
                              width: 80,
                              child: Lottie.asset(pet.lottieAsset),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pet.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinalCelebration(SupporterPet pet) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/lottie/success_check_celebration.json',
                repeat: false),
            const SizedBox(height: 16),
            Text(
              'supporter.pet_selection_title'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'supporter.pet_selection_message'.tr({'petName': pet.name}),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('¡A EMPEZAR! 🚀',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
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

    return Column(
      children: [
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
