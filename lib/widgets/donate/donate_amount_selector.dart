// lib/widgets/donate/donate_amount_selector.dart
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

class DonateAmountSelector extends StatelessWidget {
  final String? selectedAmount;
  final TextEditingController customAmountController;
  final Function(String) onAmountSelected;
  final Function() onCustomAmountSelected;
  final String? Function(String?) validator;

  const DonateAmountSelector({
    required this.selectedAmount,
    required this.customAmountController,
    required this.onAmountSelected,
    required this.onCustomAmountSelected,
    required this.validator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

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
            Expanded(child: _buildAmountButton('5', colorScheme, context)),
            const SizedBox(width: 8),
            Expanded(child: _buildAmountButton('10', colorScheme, context)),
            const SizedBox(width: 8),
            Expanded(child: _buildAmountButton('20', colorScheme, context)),
          ],
        ),

        const SizedBox(height: 16),

        // Custom amount input
        _buildCustomAmountInput(colorScheme, textTheme),
      ],
    );
  }

  Widget _buildAmountButton(
      String amount, ColorScheme colorScheme, BuildContext context) {
    final bool isSelected = selectedAmount == amount;

    return InkWell(
      onTap: () => onAmountSelected(amount),
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

  Widget _buildCustomAmountInput(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: selectedAmount == customAmountController.text &&
                  customAmountController.text.isNotEmpty
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
            controller: customAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            validator: validator,
            onChanged: (value) {
              if (value.isNotEmpty && validator(value) == null) {
                onCustomAmountSelected();
              }
            },
          ),
        ],
      ),
    );
  }
}
