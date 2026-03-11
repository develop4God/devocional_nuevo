// lib/widgets/prayer_wall/pastoral_support_sheet.dart

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet shown when a prayer is flagged for pastoral support (self-harm).
///
/// The user is NOT told their prayer was flagged. The message is purely supportive.
/// Prayer is never shown on the public wall (AC-005).
class PastoralSupportSheet extends StatelessWidget {
  const PastoralSupportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PastoralSupportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💙', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            'prayer_wall.pastoral_title'.tr(),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'prayer_wall.pastoral_message'.tr(),
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _CrisisResourcesList(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('app.close'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrisisResourcesList extends StatelessWidget {
  static const _resources = [
    _CrisisResource(
      name: 'Crisis Text Line',
      description: 'Text HOME to 741741',
      urlScheme: 'sms:741741',
    ),
    _CrisisResource(
      name: 'International Association for Suicide Prevention',
      description: 'https://www.iasp.info/resources/Crisis_Centres/',
      urlScheme: 'https://www.iasp.info/resources/Crisis_Centres/',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'prayer_wall.pastoral_resources'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ..._resources.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(r.urlScheme);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    r.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CrisisResource {
  final String name;
  final String description;
  final String urlScheme;
  const _CrisisResource(
      {required this.name, required this.description, required this.urlScheme});
}
