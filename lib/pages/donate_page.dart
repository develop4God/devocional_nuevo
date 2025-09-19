// lib/pages/donate_page.dart (ACTUALIZADO)
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/donation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/badge_model.dart' as badge_model;
import '../widgets/badge_image_widget.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> with TickerProviderStateMixin {
  final DonationService _donationService = DonationService();
  final TextEditingController _customAmountController = TextEditingController();

  String? _selectedAmount;
  badge_model.Badge? _selectedBadge;
  bool _isProcessing = false;
  bool _showPaymentSuccess = false;
  badge_model.Badge? _unlockedBadge;

  List<badge_model.Badge> _availableBadges = [];

  late AnimationController _successAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBadges();
    _loadProducts();
  }

  void _initializeAnimations() {
    _successAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await _donationService.getAvailableBadges();
      if (mounted) {
        setState(() {
          _availableBadges = badges;
        });
      }
    } catch (e) {
      debugPrint('Error loading badges: $e');
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

  @override
  void dispose() {
    _successAnimationController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  String? _validateCustomAmount(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

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

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _selectCustomAmount() {
    final String customAmount = _customAmountController.text;
    if (_validateCustomAmount(customAmount) == null &&
        customAmount.isNotEmpty) {
      setState(() {
        _selectedAmount = customAmount;
      });

      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _selectBadge(badge_model.Badge badge) {
    setState(() {
      _selectedBadge = badge;
    });

    // Haptic feedback
    HapticFeedback.selectionClick();
  }

  Future<void> _processDonation() async {
    if (_selectedAmount == null || _selectedBadge == null) {
      _showErrorSnackBar('donate.select_amount_and_badge'.tr());
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Map amount to product ID
      String productId;
      final double amount = double.parse(_selectedAmount!);

      if (amount <= 5) {
        productId = 'donation_5_usd';
      } else if (amount <= 10) {
        productId = 'donation_10_usd';
      } else if (amount <= 20) {
        productId = 'donation_20_usd';
      } else {
        productId =
            'donation_20_usd'; // Use highest tier for custom amounts > $20
      }

      final bool success = await _donationService.purchaseProduct(
        productId,
        selectedBadgeId: _selectedBadge!.id,
      );

      if (success) {
        await _showSuccessMessage();
      } else {
        _showErrorSnackBar('donate.payment_failed'.tr());
      }
    } catch (e) {
      debugPrint('Error processing donation: $e');
      _showErrorSnackBar('donate.payment_failed'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _showSuccessMessage() async {
    setState(() {
      _showPaymentSuccess = true;
      _unlockedBadge = _selectedBadge;
    });

    _successAnimationController.forward();

    // Haptic feedback for success
    HapticFeedback.heavyImpact();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_showPaymentSuccess) {
      return _buildSuccessPage(colorScheme, textTheme);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('donate.page_title'.tr()),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              _buildHeaderSection(textTheme, colorScheme),

              const SizedBox(height: 32),

              // Amount Selection
              _buildAmountSelection(textTheme, colorScheme),

              const SizedBox(height: 32),

              // Badge Selection
              if (_selectedAmount != null) ...[
                _buildBadgeSelection(textTheme, colorScheme),
                const SizedBox(height: 32),
              ],

              // Continue Button
              if (_selectedAmount != null && _selectedBadge != null) ...[
                _buildContinueButton(colorScheme, textTheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.secondary.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.favorite,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'donate.gratitude_title'.tr(),
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'donate.description'.tr(),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSelection(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'donate.amount_selection'.tr(),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // Quick amount buttons
        Row(
          children: [
            Expanded(child: _buildAmountButton('5', colorScheme)),
            const SizedBox(width: 8),
            Expanded(child: _buildAmountButton('10', colorScheme)),
            const SizedBox(width: 8),
            Expanded(child: _buildAmountButton('20', colorScheme)),
          ],
        ),

        const SizedBox(height: 16),

        // Custom amount input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedAmount == _customAmountController.text &&
                      _customAmountController.text.isNotEmpty
                  ? colorScheme.primary
                  : colorScheme.outline,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'donate.custom_amount'.tr(),
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _customAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'donate.custom_amount_hint'.tr(),
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator: _validateCustomAmount,
                onChanged: (value) {
                  if (value.isNotEmpty &&
                      _validateCustomAmount(value) == null) {
                    _selectCustomAmount();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountButton(String amount, ColorScheme colorScheme) {
    final bool isSelected = _selectedAmount == amount;

    return InkWell(
      onTap: () => _selectAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '\$$amount',
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBadgeSelection(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'donate.badge_selection'.tr(),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'donate.select_badge_message'.tr(),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        // Badge grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: _availableBadges.length,
          itemBuilder: (context, index) {
            final badge = _availableBadges[index];
            return BadgeImageWidget(
              badge: badge,
              size: 80,
              isSelected: _selectedBadge?.id == badge.id,
              onTap: () => _selectBadge(badge),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContinueButton(ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processDonation,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'donate.processing_payment'.tr(),
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              )
            : Text(
                'donate.continue_to_payment'.tr(),
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSuccessPage(ColorScheme colorScheme, TextTheme textTheme) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Animation
                AnimatedBuilder(
                  animation: _successAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.3 * _glowAnimation.value,
                              ),
                              blurRadius: 20 * _glowAnimation.value,
                              spreadRadius: 5 * _glowAnimation.value,
                            ),
                          ],
                        ),
                        child: _unlockedBadge != null
                            ? BadgeImageWidget(
                                badge: _unlockedBadge!,
                                size: 120,
                                isUnlocked: true,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 60,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Success Text
                Text(
                  'donate.badge_unlocked'.tr(),
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                if (_unlockedBadge != null) ...[
                  Text(
                    _unlockedBadge!.name,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '"${_unlockedBadge!.verse}"',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.9),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '- ${_unlockedBadge!.reference}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  'donate.thank_you_message'.tr(),
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Action Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showSuccessSnackBar('donate.badge_saved'.tr());
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.bookmark_add),
                        label: Text(
                          'donate.save_badge'.tr(),
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/donate');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.favorite),
                        label: Text(
                          'donate.support_again'.tr(),
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
