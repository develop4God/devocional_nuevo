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
import 'package:devocional_nuevo/models/supporter_tier.dart';
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

    // Kick off IAP initialization.
    context.read<SupporterBloc>().add(InitializeSupporter());
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
    context.read<SupporterBloc>().add(PurchaseTier(tier));
  }

  void _onRestorePurchases() {
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
                      'assets/lottie/success_check_celebration.json',
                      width: 180,
                      height: 180,
                      repeat: false,
                    ),
                    Positioned(
                      bottom: 40,
                      child: Text(
                        tier.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'supporter.purchase_success_title'.tr(),
                  style:
                      Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: tier.badgeColor,
                          ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'supporter.purchase_success_subtitle'.tr(),
                  style:
                      Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(dialogContext).colorScheme.primary,
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
                    onPressed: () {
                      if (isGold) {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          context
                              .read<SupporterBloc>()
                              .add(SaveGoldSupporterName(name));
                        }
                      }
                      // Clear the just-delivered tier from state
                      context.read<SupporterBloc>().add(ClearSupporterError());
                      Navigator.pop(dialogContext);
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
                      'supporter.purchase_success_button'.tr(),
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
          if (state is SupporterLoaded) {
            // Handle successful delivery
            if (state.justDeliveredTier != null) {
              setState(() => _showConfetti = true);
              _confettiController.forward();
              _showSuccessDialog(state.justDeliveredTier!);
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
