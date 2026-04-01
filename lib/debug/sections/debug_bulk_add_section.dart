// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:math';

import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/testimony_bloc.dart';
import 'package:devocional_nuevo/blocs/testimony_event.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_event.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/models/testimony_model.dart';
import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug section for bulk adding and clearing test data (prayers, thanksgivings, testimonies).
/// Single Responsibility: only handles test data generation and cleanup.
class DebugBulkAddSection extends StatefulWidget {
  const DebugBulkAddSection({super.key});

  @override
  State<DebugBulkAddSection> createState() => _DebugBulkAddSectionState();
}

class _DebugBulkAddSectionState extends State<DebugBulkAddSection> {
  bool _isAddingPrayers = false;
  bool _isAddingThanksgivings = false;
  bool _isAddingTestimonies = false;
  int _bulkCount = 100;

  static const _prayerSamples = [
    'Please pray for my family',
    'Prayer for health and healing',
    'Prayer for work and provision',
    'Praying for wisdom and guidance',
    'Thank you Lord for another day',
  ];

  static const _thanksgivingSamples = [
    'Gracias por mi familia',
    'Gracias por la salud',
    'Gracias por el trabajo',
    'Gracias por la provisión',
    'Gracias por las bendiciones',
  ];

  static const _testimonySamples = [
    'God answered my prayer',
    'He provided in a big way',
    'I experienced healing',
    'Doors opened for work',
    'A family reconciliation happened',
  ];

  // ── Bloc-driven add (small counts) ──

  Future<void> _addManyPrayers(int count) async {
    if (_isAddingPrayers) return;
    setState(() => _isAddingPrayers = true);
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text('Adding $count prayers...')));
    for (int i = 0; i < count; i++) {
      final text = '${_prayerSamples[i % _prayerSamples.length]} (#${i + 1})';
      try {
        context.read<PrayerBloc>().add(AddPrayer(text));
      } catch (e) {
        debugPrint('Error adding prayer $i: $e');
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
    scaffold.showSnackBar(SnackBar(content: Text('Finished adding $count prayers')));
    setState(() => _isAddingPrayers = false);
  }

  Future<void> _addManyThanksgivings(int count) async {
    if (_isAddingThanksgivings) return;
    setState(() => _isAddingThanksgivings = true);
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text('Adding $count thanksgivings...')));
    for (int i = 0; i < count; i++) {
      final text = '${_thanksgivingSamples[i % _thanksgivingSamples.length]} (#${i + 1})';
      try {
        context.read<ThanksgivingBloc>().add(AddThanksgiving(text));
      } catch (e) {
        debugPrint('Error adding thanksgiving $i: $e');
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
    scaffold.showSnackBar(SnackBar(content: Text('Finished adding $count thanksgivings')));
    setState(() => _isAddingThanksgivings = false);
  }

  Future<void> _addManyTestimonies(int count) async {
    if (_isAddingTestimonies) return;
    setState(() => _isAddingTestimonies = true);
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text('Adding $count testimonies...')));
    for (int i = 0; i < count; i++) {
      final text = '${_testimonySamples[i % _testimonySamples.length]} (#${i + 1})';
      try {
        context.read<TestimonyBloc>().add(AddTestimony(text));
      } catch (e) {
        debugPrint('Error adding testimony $i: $e');
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
    scaffold.showSnackBar(SnackBar(content: Text('Finished adding $count testimonies')));
    setState(() => _isAddingTestimonies = false);
  }

  // ── Fast atomic write (guaranteed count) ──

  Future<void> _fastAddManyPrayers(int count) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text('Fast adding $count prayers...')));
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('prayers');
      List<dynamic> decoded = raw != null && raw.isNotEmpty ? json.decode(raw) as List : [];
      final rnd = Random();
      final now = DateTime.now();
      for (int i = 0; i < count; i++) {
        final text = '${_prayerSamples[i % _prayerSamples.length]} (fast #${i + 1})';
        final id = '${now.millisecondsSinceEpoch}_${rnd.nextInt(100000)}_$i';
        decoded.add(Prayer(id: id, text: text, createdDate: DateTime.now(), status: PrayerStatus.active).toJson());
      }
      await prefs.setString('prayers', json.encode(decoded));
      final saved = json.decode(prefs.getString('prayers') ?? '[]') as List;
      scaffold.showSnackBar(SnackBar(content: Text('Fast add $count prayers — saved: ${saved.length}')));
      if (mounted) context.read<PrayerBloc>().add(RefreshPrayers());
    } catch (e) {
      debugPrint('Error in fastAddManyPrayers: $e');
      scaffold.showSnackBar(SnackBar(content: Text('Error adding prayers: $e')));
    }
  }

  Future<void> _fastAddManyThanksgivings(int count) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text('Fast adding $count thanksgivings...')));
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('thanksgivings');
      List<dynamic> decoded = raw != null && raw.isNotEmpty ? json.decode(raw) as List : [];
      final rnd = Random();
      final now = DateTime.now();
      for (int i = 0; i < count; i++) {
        final text = '${_thanksgivingSamples[i % _thanksgivingSamples.length]} (fast #${i + 1})';
        final id = '${now.millisecondsSinceEpoch}_${rnd.nextInt(100000)}_$i';
        decoded.add(Thanksgiving(id: id, text: text, createdDate: DateTime.now()).toJson());
      }
      await prefs.setString('thanksgivings', json.encode(decoded));
      final saved = json.decode(prefs.getString('thanksgivings') ?? '[]') as List;
      scaffold.showSnackBar(SnackBar(content: Text('Fast add $count thanksgivings — saved: ${saved.length}')));
      if (mounted) context.read<ThanksgivingBloc>().add(RefreshThanksgivings());
    } catch (e) {
      debugPrint('Error in fastAddManyThanksgivings: $e');
      scaffold.showSnackBar(SnackBar(content: Text('Error adding thanksgivings: $e')));
    }
  }

  Future<void> _fastAddManyTestimonies(int count) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text('Fast adding $count testimonies...')));
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('testimonies');
      List<dynamic> decoded = raw != null && raw.isNotEmpty ? json.decode(raw) as List : [];
      final rnd = Random();
      final now = DateTime.now();
      for (int i = 0; i < count; i++) {
        final text = '${_testimonySamples[i % _testimonySamples.length]} (fast #${i + 1})';
        final id = '${now.millisecondsSinceEpoch}_${rnd.nextInt(100000)}_$i';
        decoded.add(Testimony(id: id, text: text, createdDate: DateTime.now()).toJson());
      }
      await prefs.setString('testimonies', json.encode(decoded));
      final saved = json.decode(prefs.getString('testimonies') ?? '[]') as List;
      scaffold.showSnackBar(SnackBar(content: Text('Fast add $count testimonies — saved: ${saved.length}')));
      if (mounted) context.read<TestimonyBloc>().add(RefreshTestimonies());
    } catch (e) {
      debugPrint('Error in fastAddManyTestimonies: $e');
      scaffold.showSnackBar(SnackBar(content: Text('Error adding testimonies: $e')));
    }
  }

  // ── Clear fast entries ──

  Future<void> _clearFast(
    BuildContext context,
    String prefsKey,
    void Function() refresh,
    String label,
  ) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text('Clearing fast $label...')));
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.isEmpty) {
        scaffold.showSnackBar(SnackBar(content: Text('No $label found')));
        return;
      }
      final decoded = json.decode(raw) as List;
      final filtered = decoded.where((item) {
        final text = ((item as Map<String, dynamic>)['text'] as String?) ?? '';
        return !text.contains('(fast #');
      }).toList();
      await prefs.setString(prefsKey, json.encode(filtered));
      if (mounted) refresh();
      scaffold.showSnackBar(SnackBar(content: Text('Cleared fast $label — remaining: ${filtered.length}')));
    } catch (e) {
      debugPrint('Error clearing fast $label: $e');
      scaffold.showSnackBar(SnackBar(content: Text('Error clearing $label: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Bulk Add Card ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              const Icon(Icons.add_task, size: 48, color: Colors.green),
              const SizedBox(height: 8),
              const Text('Bulk Add Entries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Count:'),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: _bulkCount.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(
                          () => _bulkCount = (int.tryParse(v) ?? _bulkCount).clamp(1, 2000)),
                      decoration: const InputDecoration(isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _AddButton(
                    label: 'Add Prayers ($_bulkCount)',
                    icon: Icons.local_fire_department_outlined,
                    color: Colors.green,
                    isLoading: _isAddingPrayers,
                    onPressed: () => _addManyPrayers(_bulkCount),
                  ),
                  _AddButton(
                    label: 'Add Thanksgivings ($_bulkCount)',
                    icon: Icons.emoji_emotions_outlined,
                    color: Colors.teal,
                    isLoading: _isAddingThanksgivings,
                    onPressed: () => _addManyThanksgivings(_bulkCount),
                  ),
                  _AddButton(
                    label: 'Add Testimonies ($_bulkCount)',
                    icon: Icons.volunteer_activism_outlined,
                    color: Colors.indigo,
                    isLoading: _isAddingTestimonies,
                    onPressed: () => _addManyTestimonies(_bulkCount),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _fastAddManyPrayers(_bulkCount),
                    icon: const Icon(Icons.flash_on),
                    label: Text('Fast Add Prayers ($_bulkCount)'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _fastAddManyThanksgivings(_bulkCount),
                    icon: const Icon(Icons.flash_on),
                    label: Text('Fast Add Thanksgivings ($_bulkCount)'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _fastAddManyTestimonies(_bulkCount),
                    icon: const Icon(Icons.flash_on),
                    label: Text('Fast Add Testimonies ($_bulkCount)'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Use these buttons to generate many entries quickly for performance and UI testing.\n'
                'Operations run on the Blocs to persist to storage as normal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Clear fast entries ──
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => _clearFast(context, 'prayers',
                  () => context.read<PrayerBloc>().add(RefreshPrayers()), 'prayers'),
              child: const Text('Clear Fast Prayers'),
            ),
            OutlinedButton(
              onPressed: () => _clearFast(context, 'thanksgivings',
                  () => context.read<ThanksgivingBloc>().add(RefreshThanksgivings()), 'thanksgivings'),
              child: const Text('Clear Fast Thanksgivings'),
            ),
            OutlinedButton(
              onPressed: () => _clearFast(context, 'testimonies',
                  () => context.read<TestimonyBloc>().add(RefreshTestimonies()), 'testimonies'),
              child: const Text('Clear Fast Testimonies'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small helper widget to avoid repeating the loading spinner pattern.
class _AddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _AddButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon),
      label: Text(isLoading ? 'Adding...' : label),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
    );
  }
}

