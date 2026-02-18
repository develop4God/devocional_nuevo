// lib/pages/supporter_page.dart
import 'dart:async';

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lottie/lottie.dart';

import '../models/supporter_tier.dart';
import '../services/iap_service.dart';
import '../widgets/devocionales/app_bar_constants.dart';
import '../widgets/supporter/tier_card.dart';

/// Page that shows the 3 supporter tiers with Google Play Billing integration.
/// Users can purchase a tier to receive a supporter badge (digital item).
class SupporterPage extends StatefulWidget {
  const SupporterPage({super.key});

  @override
  State<SupporterPage> createState() => _SupporterPageState();
}

class _SupporterPageState extends State<SupporterPage>
    with SingleTickerProviderStateMixin {
  final IapService _iapService = IapService();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeIn;

  bool _isLoadingProducts = true;
  bool _isBillingAvailable = false;
  String? _loadingProductId;
  Set<SupporterTierLevel> _purchasedLevels = {};
  bool _showScrollHint = true;

  // Prices from the store (if available)
  final Map<String, String> _storePrices = {};

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

    _initIap();
    _listenToPurchaseStream();
    
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 50 && _showScrollHint) {
        setState(() {
          _showScrollHint = false;
        });
      } else if (_scrollController.offset <= 50 && !_showScrollHint) {
        setState(() {
          _showScrollHint = true;
        });
      }
    }
  }

  Future<void> _initIap() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      await _iapService.initialize();

      if (!mounted) return;

      // Print diagnostics in debug mode
      if (kDebugMode) {
        _iapService.printDiagnostics();
      }

      setState(() {
        _isBillingAvailable = _iapService.isAvailable;
        _purchasedLevels = _iapService.purchasedLevels;

        // Collect store prices
        for (final tier in SupporterTier.tiers) {
          final product = _iapService.getProduct(tier.productId);
          if (product != null) {
            _storePrices[tier.productId] = product.price;
          }
        }

        _isLoadingProducts = false;
      });
    } catch (e) {
      debugPrint('❌ [SupporterPage] IAP init error: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
        _isBillingAvailable = false;
      });
    }
  }

  void _listenToPurchaseStream() {
    _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
      (purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onError: (Object error) {
        debugPrint('❌ [SupporterPage] Purchase stream error: $error');
      },
    );
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (!mounted) return;

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final tier = SupporterTier.fromProductId(purchase.productID);
        if (tier != null) {
          setState(() {
            _purchasedLevels = _iapService.purchasedLevels;
            _loadingProductId = null;
          });
          _showSuccessDialog(tier);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        setState(() => _loadingProductId = null);
        _showErrorSnackBar('supporter.purchase_error'.tr());
      } else if (purchase.status == PurchaseStatus.canceled) {
        setState(() => _loadingProductId = null);
      }
    }
    // Refresh purchased state after stream update
    if (mounted) {
      setState(() {
        _purchasedLevels = _iapService.purchasedLevels;
      });
    }
  }

  Future<void> _onPurchaseTier(SupporterTier tier) async {
    if (_loadingProductId != null) return;

    setState(() => _loadingProductId = tier.productId);

    if (!_isBillingAvailable) {
      setState(() => _loadingProductId = null);
      _showBillingUnavailableDialog();
      return;
    }

    final result = await _iapService.purchaseTier(tier);

    if (!mounted) return;

    if (result == IapResult.error) {
      setState(() => _loadingProductId = null);
      _showErrorSnackBar('supporter.purchase_error'.tr());
    }
    // For IapResult.pending, keep showing loading until stream update
  }

  Future<void> _onRestorePurchases() async {
    setState(() => _isLoadingProducts = true);
    await _iapService.restorePurchases();
    if (!mounted) return;
    setState(() {
      _purchasedLevels = _iapService.purchasedLevels;
      _isLoadingProducts = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('supporter.restore_complete'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessDialog(SupporterTier tier) {
    if (tier.level == SupporterTierLevel.gold) {
      _showGoldSuccessDialog(tier);
    } else {
      _showBasicSuccessDialog(tier);
    }
  }

  void _showBasicSuccessDialog(SupporterTier tier) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              tier.emoji,
              style: const TextStyle(fontSize: 52),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'supporter.purchase_success_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tier.badgeColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'supporter.purchase_success_body'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: tier.badgeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('app.ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showGoldSuccessDialog(SupporterTier tier) {
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                tier.emoji,
                style: const TextStyle(fontSize: 52),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'supporter.purchase_success_title'.tr(),
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tier.badgeColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'supporter.purchase_success_body'.tr(),
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(dialogContext)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'supporter.gold_name_hint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'supporter.gold_name_helper'.tr(),
                  helperMaxLines: 2,
                ),
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                _iapService.saveGoldSupporterName(name);
              }
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tier.badgeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('app.ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showBillingUnavailableDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('supporter.billing_unavailable_title'.tr()),
        content: Text('supporter.billing_unavailable_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _purchaseSubscription?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(titleText: 'supporter.page_title'.tr()),
        body: FadeTransition(
          opacity: _headerFadeIn,
          child: Stack(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  scrollbarTheme: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(colorScheme.primary.withValues(alpha: 0.5)),
                    thickness: WidgetStateProperty.all(6.0),
                    radius: const Radius.circular(10),
                  ),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildMissionHeader(colorScheme, textTheme),
                        const SizedBox(height: 20),
                        _buildMinistryMessage(colorScheme, textTheme),
                        const SizedBox(height: 24),
                        if (_isLoadingProducts)
                          _buildLoadingState()
                        else
                          _buildTiersList(colorScheme, textTheme),
                        const SizedBox(height: 16),
                        _buildRestorePurchases(colorScheme, textTheme),
                        const SizedBox(height: 8),
                        _buildDisclaimerText(colorScheme, textTheme),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              // Intuitive Scroll Hint (Icon only, raised slightly)
              if (_showScrollHint)
                Positioned(
                  bottom: 40, // Raised from 20 to 40 to avoid system navigation
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _showScrollHint ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.primary.withValues(alpha: 0.7),
                        size: 40,
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

  Widget _buildMissionHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.85),
            colorScheme.tertiary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Lottie
          SizedBox(
            height: 64,
            width: 64,
            child: Lottie.asset(
              'assets/lottie/hands_heart.json',
              repeat: true,
              animate: true,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'supporter.header_title'.tr(),
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'supporter.header_subtitle'.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMinistryMessage(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        'supporter.ministry_message'.tr(),
        textAlign: TextAlign.center, // Centered text
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.85),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildTiersList(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Center the title and list
      children: [
        Text(
          'supporter.choose_tier'.tr(),
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...SupporterTier.tiers.map(
          (tier) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: TierCard(
              tier: tier,
              storePrice: _storePrices[tier.productId],
              isPurchased: _purchasedLevels.contains(tier.level),
              isLoading: _loadingProductId == tier.productId,
              onPurchase: () => _onPurchaseTier(tier),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestorePurchases(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: TextButton.icon(
        onPressed: _isLoadingProducts ? null : _onRestorePurchases,
        icon: Icon(
          Icons.restore,
          size: 16,
          color: colorScheme.primary.withValues(alpha: 0.7),
        ),
        label: Text(
          'supporter.restore_purchases'.tr(),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimerText(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'supporter.disclaimer'.tr(),
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.45),
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
