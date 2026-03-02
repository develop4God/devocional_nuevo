// lib/pages/encounters_list_page.dart
//
// Grid of encounter tiles with a modern, youthful aesthetic.
// Redesigned for high impact using full-bleed images and complete visibility.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_bloc.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_event.dart';
import 'package:devocional_nuevo/blocs/encounter/encounter_state.dart';
import 'package:devocional_nuevo/models/encounter_index_entry.dart';
import 'package:devocional_nuevo/pages/encounter_intro_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:devocional_nuevo/utils/constants.dart';
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
    final bloc = context.read<EncounterBloc>();
    if (bloc.state is! EncounterLoaded) {
      final lang = context.read<DevocionalProvider>().selectedLanguage;
      bloc.add(LoadEncounterIndex(languageCode: lang));
    }
    getService<AnalyticsService>().logEncounterAction(action: 'index_loaded');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a0e1a) : Colors.grey[50],
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
            return _buildContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(EncounterLoaded state) {
    final lang = context.read<DevocionalProvider>().selectedLanguage;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: state.index.length + 1, // +1 for header
      itemBuilder: (context, i) {
        if (i == 0) return _buildHeader();
        
        final entry = state.index[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _EncounterCard(
            entry: entry,
            lang: lang,
            isCompleted: state.isCompleted(entry.id),
            onTap: entry.isPublished
                ? () => _openEncounter(entry, lang)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dive into the Story',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Experience the Bible like never before.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openEncounter(EncounterIndexEntry entry, String lang) {
    getService<AnalyticsService>().logEncounterAction(
      action: 'encounter_opened',
      encounterId: entry.id,
    );
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EncounterIntroPage(entry: entry, lang: lang),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
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
              final lang = context.read<DevocionalProvider>().selectedLanguage;
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

class _EncounterCard extends StatelessWidget {
  final EncounterIndexEntry entry;
  final String lang;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _EncounterCard({
    required this.entry,
    required this.lang,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublished = entry.isPublished;
    final accentColor = _parseColor(entry.accentColor) ?? Colors.blueAccent;
    
    // For Peter's story, we use the intro image as the card background
    final imageUrl = entry.id == 'peter_water_001' 
        ? Constants.getEncounterImageUrl('peter_intro.jpg')
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: accentColor.withValues(alpha: 0.1),
          boxShadow: isPublished ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image or Fallback Color
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: accentColor),
                  errorWidget: (context, url, error) => Container(color: accentColor),
                )
              else
                Container(color: accentColor),

              // 2. Dynamic Gradient Overlay for impact and readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),

              // 3. Content Area
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            entry.emoji ?? '✨',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const Spacer(),
                        if (isCompleted)
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                      ],
                    ),
                    const Spacer(),
                    // Title
                    Text(
                      entry.titleFor(lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle (NOW COMPLETELY VISIBLE - No maxLines constraint)
                    Text(
                      entry.subtitleFor(lang),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bottom meta row
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          '${entry.readingMinutesFor(lang)} MIN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.auto_stories, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.scriptureFor(lang).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Coming Soon Overlay
              if (!isPublished)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'COMING SOON',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
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
