// lib/widgets/prayer_wall/submit_prayer_modal.dart

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

/// Bottom sheet modal for submitting a new prayer to the Prayer Wall.
///
/// - Text input limited to 500 characters (respects CJK density).
/// - Anonymous toggle.
/// - Submit button with loading state.
/// - Double-tap guard: submit button disabled immediately on first tap (EC-007).
class SubmitPrayerModal extends StatefulWidget {
  final bool isSubmitting;
  final void Function(String text, bool isAnonymous) onSubmit;

  const SubmitPrayerModal({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  State<SubmitPrayerModal> createState() => _SubmitPrayerModalState();
}

class _SubmitPrayerModalState extends State<SubmitPrayerModal> {
  final TextEditingController _textController = TextEditingController();
  bool _isAnonymous = true;
  bool _submitted = false;

  static const int _maxLength = 500;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (text.characters.length > _maxLength) return;
    if (_submitted) return; // double-tap guard

    setState(() => _submitted = true);
    widget.onSubmit(text, _isAnonymous);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final characterCount = _textController.text.characters.length;
    final isOverLimit = characterCount > _maxLength;
    final canSubmit = characterCount > 0 &&
        !isOverLimit &&
        !_submitted &&
        !widget.isSubmitting;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'prayer_wall.submit_title'.tr(),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Prayer input
          TextField(
            controller: _textController,
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'prayer_wall.submit_placeholder'.tr(),
              border: const OutlineInputBorder(),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),

          // Character counter
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$characterCount/$_maxLength',
                style: textTheme.bodySmall?.copyWith(
                  color: isOverLimit
                      ? colorScheme.error
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Anonymous toggle
          Row(
            children: [
              Switch(
                value: _isAnonymous,
                onChanged: widget.isSubmitting
                    ? null
                    : (v) => setState(() => _isAnonymous = v),
              ),
              const SizedBox(width: 8),
              Text(
                'prayer_wall.anonymous'.tr(),
                style: textTheme.bodyMedium,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canSubmit ? _handleSubmit : null,
              child: widget.isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text('prayer_wall.submit'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
