import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';

import 'app_gradient_bottom_sheet.dart';

class AddEntryChoiceModal extends StatelessWidget {
  final VoidCallback onAddPrayer;
  final VoidCallback onAddThanksgiving;
  final VoidCallback onAddTestimony;
  final String source; // 'devocionales_page' or 'prayers_page'

  const AddEntryChoiceModal({
    super.key,
    required this.onAddPrayer,
    required this.onAddThanksgiving,
    required this.onAddTestimony,
    this.source = 'unknown',
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppGradientBottomSheet(
      padding: const EdgeInsets.all(20.0),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'devotionals.choose_option'.tr(),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildChoiceItem(
                context,
                icon: '🙏',
                label: 'prayer.prayer'.tr(),
                choice: 'prayer',
                onTap: onAddPrayer,
              ),
              const SizedBox(width: 12),
              _buildChoiceItem(
                context,
                icon: '☺️',
                label: 'thanksgiving.thanksgiving'.tr(),
                choice: 'thanksgiving',
                onTap: onAddThanksgiving,
              ),
              const SizedBox(width: 12),
              _buildChoiceItem(
                context,
                icon: '✨',
                label: 'testimony.testimony'.tr(),
                choice: 'testimony',
                onTap: onAddTestimony,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildChoiceItem(
    BuildContext context, {
    required String icon,
    required String label,
    required String choice,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: InkWell(
        onTap: () {
          // Log analytics event
          getService<AnalyticsService>().logFabChoiceSelected(
            source: source,
            choice: choice,
          );
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline.withAlpha(80)),
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surface.withAlpha(100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 48),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(icon, style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: Center(
                  child: AutoSizeText(
                    label,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
