// lib/pages/encounters_list_page.dart
//
// Grid of encounter tiles.
// published  → full opacity, tappable → navigates to EncounterIntroPage
// coming_soon → 0.45 opacity, badge, not tappable

import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/pages/encounter_intro_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EncountersListPage extends StatefulWidget {
  const EncountersListPage({super.key});

  @override
  State<EncountersListPage> createState() => _EncountersListPageState();
}

class _EncountersListPageState extends State<EncountersListPage> {
  @override
  void initState() {
    super.initState();
    final lang = context.read<DevocionalProvider>().selectedLanguage;
    context.read<EncounterBloc>().add(LoadEncounterIndex(languageCode: lang));
    getService<AnalyticsService>()
        .logEncounterAction(action: 'index_loaded');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(titleText: 'Encounters'),
      body: BlocBuilder<EncounterBloc, EncounterState>(
        builder: (context, state) {
          if (state is EncounterLoading || state is EncounterInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EncounterError) {
            return _buildError(state.message);
          }

          if (state is EncounterLoaded) {
            if (state.index.isEmpty) {
              return _buildEmpty();
            }
            return _buildGrid(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGrid(EncounterLoaded state) {
    final lang = context.read<DevocionalProvider>().selectedLanguage;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: state.index.length,
      itemBuilder: (context, i) {
        final entry = state.index[i];
        return _EncounterTile(
          entry: entry,
          lang: lang,
          isCompleted: state.isCompleted(entry.id),
          onTap: entry.isPublished
              ? () => _openEncounter(entry, lang)
              : null,
        );
      },
    );
  }

  void _openEncounter(EncounterIndexEntry entry, String lang) {
    getService<AnalyticsService>().logEncounterAction(
      action: 'encounter_opened',
      encounterId: entry.id,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EncounterIntroPage(entry: entry, lang: lang),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No encounters available yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final lang =
                  context.read<DevocionalProvider>().selectedLanguage;
              context
                  .read<EncounterBloc>()
                  .add(LoadEncounterIndex(languageCode: lang));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single encounter tile
// ---------------------------------------------------------------------------

class _EncounterTile extends StatelessWidget {
  final EncounterIndexEntry entry;
  final String lang;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _EncounterTile({
    required this.entry,
    required this.lang,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublished = entry.isPublished;
    final accentColor = _parseColor(entry.accentColor) ??
        theme.colorScheme.primaryContainer;

    return Opacity(
      opacity: isPublished ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor,
                accentColor.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.emoji ?? '✨',
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.titleFor(lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitleFor(lang),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.readingMinutesFor(lang)} min',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.scriptureFor(lang),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Coming soon badge
              if (!isPublished)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Soon',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              // Completed badge
              if (isCompleted && isPublished)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return null;
  }
}
