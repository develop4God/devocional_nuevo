// lib/debug/sections/debug_onboarding_section.dart
import 'package:devocional_nuevo/pages/onboarding/onboarding_flow.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter/material.dart';

/// Debug section to preview and reset the onboarding flow without
/// reinstalling the app or clearing app data.
///
/// Single Responsibility: only handles onboarding debug actions.
/// The [OnboardingService] is injected via constructor (DI compliant).
class DebugOnboardingSection extends StatefulWidget {
  final OnboardingService onboardingService;

  const DebugOnboardingSection({super.key, required this.onboardingService});

  @override
  State<DebugOnboardingSection> createState() => _DebugOnboardingSectionState();
}

class _DebugOnboardingSectionState extends State<DebugOnboardingSection> {
  bool _loading = false;
  bool? _isComplete;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final isComplete = await widget.onboardingService.isOnboardingComplete();
    if (mounted) setState(() => _isComplete = isComplete);
  }

  Future<void> _resetOnboarding() async {
    setState(() => _loading = true);
    try {
      await widget.onboardingService.resetOnboarding();
      await _loadStatus();
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Onboarding reset — next app launch will show it'),
            backgroundColor: Colors.purple,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] resetOnboarding error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _previewOnboarding() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OnboardingFlow(onComplete: () => Navigator.of(context).pop()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch, color: Colors.purple, size: 28),
              const SizedBox(width: 8),
              Text(
                'Onboarding Debug',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Complete: ${_isComplete ?? '…'}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.purple.shade900),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _previewOnboarding,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Preview Onboarding Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _resetOnboarding,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restart_alt),
              label: Text(_loading ? 'Resetting...' : 'Reset Onboarding State'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"Preview" pushes the flow directly (no state change).\n'
            '"Reset" clears completion so the flow shows again on next app launch.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.purple.shade900,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
