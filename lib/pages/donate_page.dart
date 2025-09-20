// lib/pages/donate_page.dart - VERSIÓN REFACTORIZADA (~300 líneas vs 1000+)
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/donation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/badge_model.dart' as badge_model;
import '../widgets/donate/animated_donation_header.dart';
import '../widgets/donate/badge_preview_dialog.dart';
import '../widgets/donate/donate_amount_selector.dart';
import '../widgets/donate/donate_badge_grid.dart';
import '../widgets/donate/donate_success_page.dart';
import '../widgets/donate/floating_continue_button.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> with TickerProviderStateMixin {
  // Services & Controllers
  final DonationService _donationService = DonationService();
  final TextEditingController _customAmountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State variables
  String? _selectedAmount;
  badge_model.Badge? _selectedBadge;
  bool _isProcessing = false;
  bool _showPaymentSuccess = false;
  badge_model.Badge? _unlockedBadge;
  bool _isLoadingBadges = true;
  List<badge_model.Badge> _availableBadges = [];

  // Configuration
  bool get _isTestMode => kDebugMode;

  // Animation controllers
  late AnimationController _successAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBadges();
    if (!_isTestMode) _loadProducts();
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    _buttonAnimationController.dispose();
    _customAmountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _successAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _successAnimationController, curve: Curves.elasticOut));

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _successAnimationController, curve: Curves.easeInOut));

    _buttonSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _buttonAnimationController, curve: Curves.easeOutCubic));
  }

  Future<void> _loadBadges() async {
    try {
      setState(() => _isLoadingBadges = true);
      final badges = await _donationService.getAvailableBadges();
      if (mounted) {
        setState(() {
          _availableBadges = badges;
          _isLoadingBadges = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading badges: $e');
      if (mounted) setState(() => _isLoadingBadges = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      await _donationService.initialize();
      final products = await _donationService.getAvailableProducts();
      debugPrint('Loaded ${products.length} products');
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  String? _validateCustomAmount(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!_donationService.validateDonationAmount(value)) {
      return 'donate.invalid_amount_error'.tr();
    }
    return null;
  }

  void _selectAmount(String amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmountController.clear();
    });
    _checkAndShowButton();
    HapticFeedback.lightImpact();
  }

  void _selectCustomAmount() {
    final customAmount = _customAmountController.text;
    if (_validateCustomAmount(customAmount) == null &&
        customAmount.isNotEmpty) {
      setState(() => _selectedAmount = customAmount);
      _checkAndShowButton();
      HapticFeedback.lightImpact();
    }
  }

  void _selectBadge(badge_model.Badge badge) {
    setState(() => _selectedBadge = badge);
    _checkAndShowButton();
    HapticFeedback.selectionClick();
    _showBadgeDetails(badge);
  }

  void _checkAndShowButton() {
    if (_selectedAmount != null && _selectedBadge != null) {
      _buttonAnimationController.forward();
    } else {
      _buttonAnimationController.reverse();
    }
  }

  void _showBadgeDetails(badge_model.Badge badge) {
    showDialog(
      context: context,
      builder: (context) => BadgePreviewDialog(
        badge: badge,
        isSelected: _selectedBadge?.id == badge.id,
        onSelect: () {
          Navigator.pop(context);
          if (_selectedBadge?.id != badge.id) {
            _selectBadge(badge);
          }
        },
      ),
    );
  }

  Future<void> _processDonation() async {
    if (_selectedAmount == null || _selectedBadge == null) {
      _showErrorSnackBar('Por favor selecciona un monto y una insignia');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      bool success = false;

      if (_isTestMode) {
        debugPrint('🧪 TEST MODE: Simulating successful purchase');
        await Future.delayed(const Duration(seconds: 2));
        await _donationService.unlockBadge(_selectedBadge!.id);
        success = true;
      } else {
        final amount = double.parse(_selectedAmount!);
        String productId = amount <= 5
            ? 'donation_5_usd'
            : amount <= 10
                ? 'donation_10_usd'
                : 'donation_20_usd';

        success = await _donationService.purchaseProduct(
          productId,
          selectedBadgeId: _selectedBadge!.id,
        );
      }

      if (success) {
        await _showSuccessMessage();
      } else {
        _showErrorSnackBar('donate.payment_failed'.tr());
      }
    } catch (e) {
      debugPrint('Error processing donation: $e');
      _showErrorSnackBar('donate.payment_failed'.tr());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showSuccessMessage() async {
    setState(() {
      _showPaymentSuccess = true;
      _unlockedBadge = _selectedBadge;
    });
    _successAnimationController.forward();
    HapticFeedback.heavyImpact();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showPaymentSuccess) {
      return DonateSuccessPage(
        unlockedBadge: _unlockedBadge,
        successAnimationController: _successAnimationController,
        scaleAnimation: _scaleAnimation,
        glowAnimation: _glowAnimation,
        showSuccessSnackBar: _showSuccessSnackBar,
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                AnimatedDonationHeader(
                  height: 200,
                  textTheme: Theme.of(context).textTheme,
                  colorScheme: Theme.of(context).colorScheme,
                ),

                const SizedBox(height: 32),

                // Amount Selection Widget
                DonateAmountSelector(
                  selectedAmount: _selectedAmount,
                  customAmountController: _customAmountController,
                  onAmountSelected: _selectAmount,
                  onCustomAmountSelected: _selectCustomAmount,
                  validator: _validateCustomAmount,
                ),

                const SizedBox(height: 32),

                // Badge Selection Widget
                DonateBadgeGrid(
                  availableBadges: _availableBadges,
                  selectedBadge: _selectedBadge,
                  onBadgeSelected: _selectBadge,
                  isLoading: _isLoadingBadges,
                ),
              ],
            ),
          ),

          // Floating Continue Button Widget
          FloatingContinueButton(
            animationController: _buttonAnimationController,
            buttonSlideAnimation: _buttonSlideAnimation,
            isProcessing: _isProcessing,
            isTestMode: _isTestMode,
            onPressed: _processDonation,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Text('donate.page_title'.tr()),
          if (_isTestMode) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'TEST',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
    );
  }
}
