// lib/pages/donate_page.dart - AJUSTADO con feedback
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/donation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/badge_model.dart' as badge_model;
import '../widgets/donate/animated_donation_header.dart';
import '../widgets/donate/badge_preview_dialog.dart';
import '../widgets/donate/donate_success_page.dart';

// Estados del flujo discovery
enum DonationFlowState {
  selecting, // Usuario seleccionando
  ready, // Listo para procesar
  processing, // Procesando pago
  success, // Éxito mostrado
}

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

  // Estado principal del flujo
  DonationFlowState _currentState = DonationFlowState.selecting;

  // State variables
  String? _selectedAmount;
  badge_model.Badge? _selectedBadge;
  badge_model.Badge? _unlockedBadge;
  bool _isLoadingBadges = true;
  List<badge_model.Badge> _availableBadges = [];

  // Montos predefinidos
  final List<String> _predefinedAmounts = ['5', '10', '15', '25', '50'];

  // Configuration
  bool get _isTestMode => kDebugMode;

  bool get _isProcessing => _currentState == DonationFlowState.processing;

  bool get _showPaymentSuccess => _currentState == DonationFlowState.success;

  bool get _canProceed => _selectedAmount != null && _selectedBadge != null;

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
      duration: const Duration(milliseconds: 400),
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
            parent: _buttonAnimationController, curve: Curves.easeOutBack));
  }

  void _resetDonationState() {
    debugPrint('🔄 [DonatePage] Resetting donation state - fresh start');

    setState(() {
      _currentState = DonationFlowState.selecting;
      _selectedAmount = null;
      _selectedBadge = null;
      _unlockedBadge = null;
    });

    _customAmountController.clear();
    _successAnimationController.reset();
    _buttonAnimationController.reset();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic);
    }

    debugPrint('✅ [DonatePage] State reset completed');
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

  void _selectAmount(String amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmountController.clear();
    });

    _checkAndShowButton();
    HapticFeedback.lightImpact();

    debugPrint('💰 Amount selected: $amount');
  }

  void _selectCustomAmount() {
    final customAmount = _customAmountController.text;
    if (_validateCustomAmount(customAmount) == null &&
        customAmount.isNotEmpty) {
      setState(() => _selectedAmount = customAmount);
      _checkAndShowButton();
      HapticFeedback.lightImpact();

      debugPrint('💰 Custom amount selected: $customAmount');
    }
  }

  void _selectBadge(badge_model.Badge badge) {
    setState(() => _selectedBadge = badge);
    _checkAndShowButton();
    HapticFeedback.selectionClick();
    _showBadgeDetails(badge);

    debugPrint('🏆 Badge selected: ${badge.name}');
  }

  void _checkAndShowButton() {
    if (_canProceed) {
      _buttonAnimationController.forward();
    } else {
      _buttonAnimationController.reverse();
    }
  }

  String? _validateCustomAmount(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!_donationService.validateDonationAmount(value)) {
      return 'donate.invalid_amount_error'.tr();
    }
    return null;
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
      _showErrorSnackBar('Por favor completa la selección');
      return;
    }

    setState(() => _currentState = DonationFlowState.processing);

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

        success = await _donationService.purchaseProduct(productId,
            selectedBadgeId: _selectedBadge!.id);
      }

      if (success) {
        await _showSuccessMessage();
      } else {
        setState(() => _currentState = DonationFlowState.ready);
        _showErrorSnackBar('donate.payment_failed'.tr());
      }
    } catch (e) {
      debugPrint('Error processing donation: $e');
      setState(() => _currentState = DonationFlowState.ready);
      _showErrorSnackBar('donate.payment_failed'.tr());
    }
  }

  Future<void> _showSuccessMessage() async {
    setState(() {
      _currentState = DonationFlowState.success;
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_showPaymentSuccess) {
      return DonateSuccessPage(
        unlockedBadge: _unlockedBadge,
        successAnimationController: _successAnimationController,
        scaleAnimation: _scaleAnimation,
        glowAnimation: _glowAnimation,
        showSuccessSnackBar: _showSuccessSnackBar,
        onDonateAgain: _resetDonationState,
        onSaveBadge: () =>
            setState(() => _currentState = DonationFlowState.selecting),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20.0).copyWith(
              bottom: _canProceed ? 140 : 20, // Espacio dinámico para el botón
            ),
            child: Column(
              children: [
                // Header hermoso existente
                AnimatedDonationHeader(
                  height: 200,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),

                const SizedBox(height: 32),

                // TEXTO RESTAURADO: Descripción del propósito espiritual
                Text(
                  'donate.description'.tr(),
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // NUEVO: Texto sobre las insignias como agradecimiento
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '✨ Las insignias son nuestro agradecimiento por tu generosidad y apoyo al ministerio. Cada una representa una virtud espiritual para tu colección.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary.withValues(alpha: 0.9),
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                // Selección de Monto - CENTRADO
                _buildAmountSelectionSection(colorScheme, textTheme),

                const SizedBox(height: 40),

                // Grid completo de Badges - SIEMPRE VISIBLE
                _buildBadgeGridSection(colorScheme, textTheme),
              ],
            ),
          ),

          // Botón que NO interfiere - solo aparece cuando está listo
          if (_canProceed) _buildNonIntrusiveButton(colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildAmountSelectionSection(
      ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        // Título centrado
        Text(
          'Selecciona el monto de tu donación',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Grid de círculos CENTRADO
        Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _predefinedAmounts.map((amount) {
              final isSelected = _selectedAmount == amount;
              return GestureDetector(
                onTap: () => _selectAmount(amount),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected ? colorScheme.primary : colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ]
                        : [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      '\$$amount',
                      style: textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Monto personalizado CENTRADO
        Center(
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Monto personalizado',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customAmountController,
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface.withValues(alpha: 0.8),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateCustomAmount,
                  onFieldSubmitted: (_) => _selectCustomAmount(),
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeGridSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        // Título centrado
        Text(
          'Elige tu insignia espiritual',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Grid completo - SIEMPRE HABILITADO
        if (_isLoadingBadges)
          const Center(child: CircularProgressIndicator())
        else
          Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _availableBadges.map((badge) {
                final isSelected = _selectedBadge?.id == badge.id;
                return GestureDetector(
                  onTap: () => _selectBadge(badge),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 120,
                    height: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.2)
                              : colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge real con tu widget existente
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.secondary.withValues(alpha: 0.8),
                                colorScheme.primary.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            Icons.military_tech,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badge.name,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildNonIntrusiveButton(
      ColorScheme colorScheme, TextTheme textTheme) {
    return AnimatedBuilder(
      animation: _buttonSlideAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _isProcessing ? null : _processDonation,
                child: Container(
                  alignment: Alignment.center,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isTestMode
                                  ? 'Donar (PRUEBA)'
                                  : 'Continuar donación',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PRUEBA',
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
