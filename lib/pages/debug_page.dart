// ignore_for_file: public_member_api_docs, prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_final_locals, use_build_context_synchronously, unnecessary_this, avoid_print

import 'dart:convert';
import 'dart:math';

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/testimony_bloc.dart';
import 'package:devocional_nuevo/blocs/testimony_event.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_event.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/models/testimony_model.dart';
import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:devocional_nuevo/pages/backup_settings_page.dart';
import 'package:devocional_nuevo/services/in_app_review_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Página de debug solo visible en modo desarrollo.
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  List<String> _branches = ['main', 'dev'];
  bool _loadingBranches = false;

  // --- New debug runners state ---
  bool _isAddingPrayers = false;
  bool _isAddingThanksgivings = false;
  bool _isAddingTestimonies = false;
  int _bulkCount = 100; // default bulk count

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => _loadingBranches = true);
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.github.com/repos/develop4God/Devocionales-json/branches'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final List branches = jsonDecode(response.body);
        setState(() {
          _branches = branches.map((b) => b['name'] as String).toList();
        });
      } else if (response.statusCode == 403) {
        debugPrint('⚠️ GitHub rate limit hit, using fallback branches');
        // Keep the default fallback branches ['main', 'dev']
      } else {
        debugPrint('⚠️ GitHub API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching branches: $e');
    }
    setState(() => _loadingBranches = false);
  }

  // MethodChannel para Crashlytics nativo
  static const platform = MethodChannel(
    'com.develop4god.devocional_nuevo/crashlytics',
  );

  Future<void> _forceCrash(BuildContext context) async {
    try {
      // Intenta forzar el crash desde el lado nativo (Android/iOS)
      await platform.invokeMethod('forceCrash');
      // Si llega aquí, la excepción no se lanzó como se esperaba
      debugPrint('❌ La app no crasheó como se esperaba desde el lado nativo.');

      // Fallback: usar el metodo de Crashlytics de Flutter
      debugPrint(
        '⚠️ Intentando forzar crash desde Flutter con FirebaseCrashlytics.instance.crash()',
      );
      FirebaseCrashlytics.instance.crash();
    } on PlatformException catch (e) {
      // Este error significa que el canal no está configurado o falló
      debugPrint('❌ Error de plataforma al invocar forceCrash: ${e.message}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error de plataforma: ${e.message}\nIntentando método alternativo...',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Fallback: usar el metodo de Crashlytics de Flutter
      await Future.delayed(const Duration(seconds: 2));
      debugPrint(
        '⚠️ Forzando crash desde Flutter con FirebaseCrashlytics.instance.crash()',
      );
      FirebaseCrashlytics.instance.crash();
    } catch (e) {
      // Cualquier otro error
      debugPrint('❌ Error inesperado: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
      }
    }
  }

  Future<void> _addManyPrayers(int count) async {
    if (_isAddingPrayers) return;
    setState(() => _isAddingPrayers = true);

    final samples = [
      'Please pray for my family',
      'Prayer for health and healing',
      'Prayer for work and provision',
      'Praying for wisdom and guidance',
      'Thank you Lord for another day',
    ];

    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text('Adding $count prayers...')));

    for (int i = 0; i < count; i++) {
      final text = '${samples[i % samples.length]} (#${i + 1})';
      try {
        // Add via bloc event so storage/backups behave as in production
        context.read<PrayerBloc>().add(AddPrayer(text));
      } catch (e) {
        debugPrint('Error adding prayer $i: $e');
      }
      // Small delay so UI keeps responsive and storage can keep up
      await Future.delayed(const Duration(milliseconds: 10));
    }

    scaffold.showSnackBar(
        SnackBar(content: Text('Finished adding $count prayers')));
    setState(() => _isAddingPrayers = false);
  }

  Future<void> _addManyThanksgivings(int count) async {
    if (_isAddingThanksgivings) return;
    setState(() => _isAddingThanksgivings = true);

    final samples = [
      'Gracias por mi familia',
      'Gracias por la salud',
      'Gracias por el trabajo',
      'Gracias por la provisión',
      'Gracias por las bendiciones',
    ];

    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
        SnackBar(content: Text('Adding $count thanksgivings...')));

    for (int i = 0; i < count; i++) {
      final text = '${samples[i % samples.length]} (#${i + 1})';
      try {
        context.read<ThanksgivingBloc>().add(AddThanksgiving(text));
      } catch (e) {
        debugPrint('Error adding thanksgiving $i: $e');
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }

    scaffold.showSnackBar(
        SnackBar(content: Text('Finished adding $count thanksgivings')));
    setState(() => _isAddingThanksgivings = false);
  }

  Future<void> _addManyTestimonies(int count) async {
    if (_isAddingTestimonies) return;
    setState(() => _isAddingTestimonies = true);

    final samples = [
      'God answered my prayer',
      'He provided in a big way',
      'I experienced healing',
      'Doors opened for work',
      'A family reconciliation happened',
    ];

    final scaffold = ScaffoldMessenger.of(context);
    scaffold
        .showSnackBar(SnackBar(content: Text('Adding $count testimonies...')));

    for (int i = 0; i < count; i++) {
      final text = '${samples[i % samples.length]} (#${i + 1})';
      try {
        context.read<TestimonyBloc>().add(AddTestimony(text));
      } catch (e) {
        debugPrint('Error adding testimony $i: $e');
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }

    scaffold.showSnackBar(
        SnackBar(content: Text('Finished adding $count testimonies')));
    setState(() => _isAddingTestimonies = false);
  }

  Future<void> _fastAddManyPrayers(int count) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold
        .showSnackBar(SnackBar(content: Text('Fast adding $count prayers...')));

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? prayersJson = prefs.getString('prayers');
      List<dynamic> decoded = [];
      if (prayersJson != null && prayersJson.isNotEmpty) {
        decoded = json.decode(prayersJson) as List<dynamic>;
      }

      final samples = [
        'Please pray for my family',
        'Prayer for health and healing',
        'Prayer for work and provision',
        'Praying for wisdom and guidance',
        'Thank you Lord for another day',
      ];

      final rnd = Random();
      final now = DateTime.now();

      for (int i = 0; i < count; i++) {
        final text = '${samples[i % samples.length]} (fast #${i + 1})';
        // Use a safer unique id: timestamp + random suffix
        final id = '${now.millisecondsSinceEpoch}_${rnd.nextInt(100000)}_$i';
        final prayer = Prayer(
          id: id,
          text: text,
          createdDate: DateTime.now(),
          status: PrayerStatus.active,
        );
        decoded.add(prayer.toJson());
      }

      await prefs.setString('prayers', json.encode(decoded));

      // Verify saved count
      final String? saved = prefs.getString('prayers');
      final List<dynamic> savedList = saved != null && saved.isNotEmpty
          ? json.decode(saved) as List<dynamic>
          : <dynamic>[];
      scaffold.showSnackBar(SnackBar(
          content: Text(
              'Finished fast adding $count prayers — saved: ${savedList.length}')));
      debugPrint('Fast add prayers expected $count, saved ${savedList.length}');

      // Notify bloc to refresh from storage
      if (mounted) context.read<PrayerBloc>().add(RefreshPrayers());
    } catch (e) {
      debugPrint('Error in fastAddManyPrayers: $e');
      scaffold
          .showSnackBar(SnackBar(content: Text('Error adding prayers: $e')));
    }
  }

  Future<void> _fastAddManyThanksgivings(int count) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
        SnackBar(content: Text('Fast adding $count thanksgivings...')));

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? thanksgivingsJson = prefs.getString('thanksgivings');
      List<dynamic> decoded = [];
      if (thanksgivingsJson != null && thanksgivingsJson.isNotEmpty) {
        decoded = json.decode(thanksgivingsJson) as List<dynamic>;
      }

      final samples = [
        'Gracias por mi familia',
        'Gracias por la salud',
        'Gracias por el trabajo',
        'Gracias por la provisión',
        'Gracias por las bendiciones',
      ];

      final rnd = Random();
      final now = DateTime.now();

      for (int i = 0; i < count; i++) {
        final text = '${samples[i % samples.length]} (fast #${i + 1})';
        final id = '${now.millisecondsSinceEpoch}_${rnd.nextInt(100000)}_$i';
        final thanksgiving = Thanksgiving(
          id: id,
          text: text,
          createdDate: DateTime.now(),
        );
        decoded.add(thanksgiving.toJson());
      }

      await prefs.setString('thanksgivings', json.encode(decoded));
      final String? savedT = prefs.getString('thanksgivings');
      final List<dynamic> savedTList = savedT != null && savedT.isNotEmpty
          ? json.decode(savedT) as List<dynamic>
          : <dynamic>[];
      scaffold.showSnackBar(SnackBar(
          content: Text(
              'Finished fast adding $count thanksgivings — saved: ${savedTList.length}')));
      debugPrint(
          'Fast add thanksgivings expected $count, saved ${savedTList.length}');
      if (mounted) context.read<ThanksgivingBloc>().add(RefreshThanksgivings());
    } catch (e) {
      debugPrint('Error in fastAddManyThanksgivings: $e');
      scaffold.showSnackBar(
          SnackBar(content: Text('Error adding thanksgivings: $e')));
    }
  }

  Future<void> _fastAddManyTestimonies(int count) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
        SnackBar(content: Text('Fast adding $count testimonies...')));

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? testimoniesJson = prefs.getString('testimonies');
      List<dynamic> decoded = [];
      if (testimoniesJson != null && testimoniesJson.isNotEmpty) {
        decoded = json.decode(testimoniesJson) as List<dynamic>;
      }

      final samples = [
        'God answered my prayer',
        'He provided in a big way',
        'I experienced healing',
        'Doors opened for work',
        'A family reconciliation happened',
      ];

      final rnd = Random();
      final now = DateTime.now();

      for (int i = 0; i < count; i++) {
        final text = '${samples[i % samples.length]} (fast #${i + 1})';
        final id = '${now.millisecondsSinceEpoch}_${rnd.nextInt(100000)}_$i';
        final testimony = Testimony(
          id: id,
          text: text,
          createdDate: DateTime.now(),
        );
        decoded.add(testimony.toJson());
      }

      await prefs.setString('testimonies', json.encode(decoded));
      final String? savedTest = prefs.getString('testimonies');
      final List<dynamic> savedTestList =
          savedTest != null && savedTest.isNotEmpty
              ? json.decode(savedTest) as List<dynamic>
              : <dynamic>[];
      scaffold.showSnackBar(SnackBar(
          content: Text(
              'Finished fast adding $count testimonies — saved: ${savedTestList.length}')));
      debugPrint(
          'Fast add testimonies expected $count, saved ${savedTestList.length}');
      if (mounted) context.read<TestimonyBloc>().add(RefreshTestimonies());
    } catch (e) {
      debugPrint('Error in fastAddManyTestimonies: $e');
      scaffold.showSnackBar(
          SnackBar(content: Text('Error adding testimonies: $e')));
    }
  }

  Future<void> _clearFastPrayers() async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text('Clearing fast prayers...')));
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? prayersJson = prefs.getString('prayers');
      if (prayersJson == null || prayersJson.isEmpty) {
        scaffold.showSnackBar(SnackBar(content: Text('No prayers found')));
        return;
      }
      final List<dynamic> decoded = json.decode(prayersJson) as List<dynamic>;
      final filtered = decoded.where((item) {
        final Map<String, dynamic> m = item as Map<String, dynamic>;
        final text = (m['text'] as String?) ?? '';
        return !text.contains('(fast #');
      }).toList();
      await prefs.setString('prayers', json.encode(filtered));
      if (mounted) context.read<PrayerBloc>().add(RefreshPrayers());
      scaffold.showSnackBar(SnackBar(
          content:
              Text('Cleared fast prayers — remaining: ${filtered.length}')));
    } catch (e) {
      debugPrint('Error clearing fast prayers: $e');
      scaffold
          .showSnackBar(SnackBar(content: Text('Error clearing prayers: $e')));
    }
  }

  Future<void> _clearFastThanksgivings() async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
        SnackBar(content: Text('Clearing fast thanksgivings...')));
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('thanksgivings');
      if (jsonStr == null || jsonStr.isEmpty) {
        scaffold
            .showSnackBar(SnackBar(content: Text('No thanksgivings found')));
        return;
      }
      final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
      final filtered = decoded.where((item) {
        final Map<String, dynamic> m = item as Map<String, dynamic>;
        final text = (m['text'] as String?) ?? '';
        return !text.contains('(fast #');
      }).toList();
      await prefs.setString('thanksgivings', json.encode(filtered));
      if (mounted) context.read<ThanksgivingBloc>().add(RefreshThanksgivings());
      scaffold.showSnackBar(SnackBar(
          content: Text(
              'Cleared fast thanksgivings — remaining: ${filtered.length}')));
    } catch (e) {
      debugPrint('Error clearing fast thanksgivings: $e');
      scaffold.showSnackBar(
          SnackBar(content: Text('Error clearing thanksgivings: $e')));
    }
  }

  Future<void> _clearFastTestimonies() async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold
        .showSnackBar(SnackBar(content: Text('Clearing fast testimonies...')));
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('testimonies');
      if (jsonStr == null || jsonStr.isEmpty) {
        scaffold.showSnackBar(SnackBar(content: Text('No testimonies found')));
        return;
      }
      final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
      final filtered = decoded.where((item) {
        final Map<String, dynamic> m = item as Map<String, dynamic>;
        final text = (m['text'] as String?) ?? '';
        return !text.contains('(fast #');
      }).toList();
      await prefs.setString('testimonies', json.encode(filtered));
      if (mounted) context.read<TestimonyBloc>().add(RefreshTestimonies());
      scaffold.showSnackBar(SnackBar(
          content: Text(
              'Cleared fast testimonies — remaining: ${filtered.length}')));
    } catch (e) {
      debugPrint('Error clearing fast testimonies: $e');
      scaffold.showSnackBar(
          SnackBar(content: Text('Error clearing testimonies: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      // Ocultar la página en release
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branch Selector
                if (Constants.enableDiscoveryFeature) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.deepOrange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.fork_right,
                            size: 48, color: Colors.deepOrange),
                        const SizedBox(height: 8),
                        const Text(
                          'Discovery Branch',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (_loadingBranches)
                          const CircularProgressIndicator()
                        else
                          DropdownButton<String>(
                            // CRITICAL: Prevent crash if debugBranch not in fetched list
                            value: _branches.contains(Constants.debugBranch)
                                ? Constants.debugBranch
                                : _branches.first,
                            isExpanded: true,
                            items: _branches
                                .map((branch) => DropdownMenuItem(
                                    value: branch, child: Text(branch)))
                                .toList(),
                            onChanged: (newBranch) {
                              setState(
                                  () => Constants.debugBranch = newBranch!);
                              // Trigger refresh
                              if (mounted && context.mounted) {
                                context
                                    .read<DiscoveryBloc>()
                                    .add(RefreshDiscoveryStudies());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Cambiado a: $newBranch')),
                                );
                              }
                            },
                          ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _fetchBranches,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Branches'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Crashlytics test
                const Text(
                  'Presiona el botón para forzar un fallo de Crashlytics:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _forceCrash(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('FORZAR FALLO AHORA'),
                ),

                const SizedBox(height: 32),

                // Backup Settings Test Button (Debug Mode Only)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.backup, size: 48, color: Colors.blue),
                      const SizedBox(height: 8),
                      const Text(
                        'Test Backup Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BackupSettingsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_backup_restore),
                        label: const Text('Open Backup Page'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Debug mode only - not visible in production',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // --- Bulk Insert Section ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.add_task, size: 48, color: Colors.green),
                      const SizedBox(height: 8),
                      const Text(
                        'Bulk Add Entries',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Count input
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
                              onChanged: (v) {
                                final parsed = int.tryParse(v) ?? _bulkCount;
                                setState(
                                    () => _bulkCount = parsed.clamp(1, 2000));
                              },
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
                          ElevatedButton.icon(
                            onPressed: _isAddingPrayers
                                ? null
                                : () => _addManyPrayers(_bulkCount),
                            icon: _isAddingPrayers
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.local_fire_department_outlined),
                            label: Text(_isAddingPrayers
                                ? 'Adding...'
                                : 'Add Prayers ($_bulkCount)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isAddingThanksgivings
                                ? null
                                : () => _addManyThanksgivings(_bulkCount),
                            icon: _isAddingThanksgivings
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.emoji_emotions_outlined),
                            label: Text(_isAddingThanksgivings
                                ? 'Adding...'
                                : 'Add Thanksgivings ($_bulkCount)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isAddingTestimonies
                                ? null
                                : () => _addManyTestimonies(_bulkCount),
                            icon: _isAddingTestimonies
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.volunteer_activism_outlined),
                            label: Text(_isAddingTestimonies
                                ? 'Adding...'
                                : 'Add Testimonies ($_bulkCount)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                          ),

                          // Fast/direct atomic write buttons (guarantee exact count)
                          ElevatedButton.icon(
                            onPressed: () => _fastAddManyPrayers(_bulkCount),
                            icon: const Icon(Icons.flash_on),
                            label: Text('Fast Add Prayers ($_bulkCount)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () =>
                                _fastAddManyThanksgivings(_bulkCount),
                            icon: const Icon(Icons.flash_on),
                            label: Text('Fast Add Thanksgivings ($_bulkCount)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () =>
                                _fastAddManyTestimonies(_bulkCount),
                            icon: const Icon(Icons.flash_on),
                            label: Text('Fast Add Testimonies ($_bulkCount)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        'Use these buttons to generate many entries quickly for performance and UI testing.\nOperations run on the Blocs to persist to storage as normal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Clear fast entries
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _clearFastPrayers,
                      child: const Text('Clear Fast Prayers'),
                    ),
                    OutlinedButton(
                      onPressed: _clearFastThanksgivings,
                      child: const Text('Clear Fast Thanksgivings'),
                    ),
                    OutlinedButton(
                      onPressed: _clearFastTestimonies,
                      child: const Text('Clear Fast Testimonies'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Floating action button for review
                FloatingActionButton(
                  onPressed: () async {
                    debugPrint('🟣 [Debug] Botón de evaluación presionado.');
                    // Llama al metodo real para mostrar el diálogo de reseña
                    await InAppReviewService.requestInAppReview(context);
                  },
                  backgroundColor: Colors.deepPurple,
                  tooltip: 'Abrir diálogo de evaluación',
                  child: const Icon(Icons.reviews_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
