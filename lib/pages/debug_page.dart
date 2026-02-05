import 'dart:convert';

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/pages/backup_settings_page.dart';
import 'package:devocional_nuevo/services/in_app_review_service.dart';
import 'package:devocional_nuevo/utils/constants.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

/// Página de debug solo visible en modo desarrollo.
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  List<String> _branches = ['main', 'dev'];
  bool _loadingBranches = false;

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
                            setState(() => Constants.debugBranch = newBranch!);
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
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          debugPrint('🟣 [Debug] Botón de evaluación presionado.');
          // Llama al método real para mostrar el diálogo de reseña
          await InAppReviewService.requestInAppReview(context);
        },
        backgroundColor: Colors.deepPurple,
        tooltip: 'Abrir diálogo de evaluación',
        child: const Icon(Icons.reviews_rounded),
      ),
    );
  }
}
