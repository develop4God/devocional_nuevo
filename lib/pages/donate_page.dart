// lib/pages/donate_page.dart (MEJORADA)
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/donation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/badge_model.dart' as badge_model;
import '../widgets/animated_donation_header.dart';
import '../widgets/badge_image_widget.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> with TickerProviderStateMixin {
  final DonationService _donationService = DonationService();
  final TextEditingController _customAmountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedAmount;
  badge_model.Badge? _selectedBadge;
  bool _isProcessing = false;
  bool _showPaymentSuccess = false;
  badge_model.Badge? _unlockedBadge;
  bool _isLoadingBadges = true;

  List<badge_model.Badge> _availableBadges = [];

  // Modo test para desarrollo
  bool get _isTestMode => kDebugMode;

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
    if (!_isTestMode) {
      _loadProducts();
    }
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

    _buttonSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadBadges() async {
    try {
      setState(() {
        _isLoadingBadges = true;
      });

      final badges = await _donationService.getAvailableBadges();
      if (mounted) {
        setState(() {
          _availableBadges = badges;
          _isLoadingBadges = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading badges: $e');
      if (mounted) {
        setState(() {
          _isLoadingBadges = false;
        });
      }
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
    _buttonAnimationController.dispose();
    _customAmountController.dispose();
    _scrollController.dispose();
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

    // Mostrar botón si se seleccionaron ambos
    _checkAndShowButton();

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

      _checkAndShowButton();
      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _selectBadge(badge_model.Badge badge) {
    setState(() {
      _selectedBadge = badge;
    });

    _checkAndShowButton();

    // Haptic feedback
    HapticFeedback.selectionClick();

    // Mostrar detalles del badge
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
      builder: (context) => _BadgePreviewDialog(
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
      _showErrorSnackBar('donate.select_amount_and_badge'.tr());
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      bool success = false;

      if (_isTestMode) {
        // MODO TEST - Simular compra exitosa
        debugPrint('🧪 TEST MODE: Simulating successful purchase');
        await Future.delayed(const Duration(seconds: 2)); // Simular delay
        await _donationService.unlockBadge(_selectedBadge!.id);
        success = true;
      } else {
        // MODO PRODUCCIÓN - Google Play Billing real
        String productId;
        final double amount = double.parse(_selectedAmount!);

        if (amount <= 5) {
          productId = 'donation_5_usd';
        } else if (amount <= 10) {
          productId = 'donation_10_usd';
        } else if (amount <= 20) {
          productId = 'donation_20_usd';
        } else {
          productId = 'donation_20_usd';
        }

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
          behavior: SnackBarBehavior.floating,
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
          behavior: SnackBarBehavior.floating,
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
                child: Text(
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
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 140),
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
                _buildBadgeSelection(textTheme, colorScheme),
              ],
            ),
          ),

          // Floating Continue Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _buttonAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 100 * (1 - _buttonSlideAnimation.value)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.0),
                          colorScheme.surface.withValues(alpha: 0.8),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SafeArea(
                      top: false,
                      child: _buildContinueButton(colorScheme, textTheme),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(TextTheme textTheme, ColorScheme colorScheme) {
    return AnimatedDonationHeader(
      height: 240,
      textTheme: textTheme,
      colorScheme: colorScheme,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
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
        if (_isLoadingBadges)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_availableBadges.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No hay insignias disponibles',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: _availableBadges.length,
            itemBuilder: (context, index) {
              final badge = _availableBadges[index];
              final isSelected = _selectedBadge?.id == badge.id;

              return Column(
                children: [
                  BadgeImageWidget(
                    badge: badge,
                    size: 80,
                    isSelected: isSelected,
                    onTap: () => _selectBadge(badge),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.name,
                    style: textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
          elevation: 8,
          shadowColor: colorScheme.primary.withValues(alpha: 0.4),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isTestMode ? Icons.science : Icons.payment,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isTestMode
                        ? 'TEST: Simular Donación'
                        : 'donate.continue_to_payment'.tr(),
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Success page remains the same...
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

// Diálogo de preview de badge con versículo
class _BadgePreviewDialog extends StatelessWidget {
  final badge_model.Badge badge;
  final bool isSelected;
  final VoidCallback onSelect;

  const _BadgePreviewDialog({
    required this.badge,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge preview
              BadgeImageWidget(
                badge: badge,
                size: 100,
                isUnlocked: true,
                isSelected: isSelected,
              ),

              const SizedBox(height: 16),

              // Badge name
              Text(
                badge.name,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Badge description
              Text(
                badge.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Bible verse section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${badge.verse}"',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge.reference,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('app.close'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? colorScheme.secondary
                            : colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        isSelected ? Icons.check : Icons.add,
                        size: 16,
                      ),
                      label: Text(
                        isSelected ? 'Seleccionada' : 'Seleccionar',
                        style: textTheme.bodyMedium?.copyWith(
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
    );
  }
}
