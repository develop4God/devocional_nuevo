// lib/pages/discovery_detail_page.dart

import 'dart:math';

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:devocional_nuevo/widgets/discovery_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

/// Detail page for viewing a specific Discovery study
class DiscoveryDetailPage extends StatefulWidget {
  final String studyId;

  const DiscoveryDetailPage({
    required this.studyId,
    super.key,
  });

  @override
  State<DiscoveryDetailPage> createState() => _DiscoveryDetailPageState();
}

class _DiscoveryDetailPageState extends State<DiscoveryDetailPage> {
  int _currentSectionIndex = 0;
  final PageController _pageController = PageController();

  // List of celebratory Lottie assets
  final List<String> _celebrationLotties = [
    'assets/lottie/confetti.json',
    'assets/lottie/trophy_star.json',
    // Add more assets here as needed
  ];

  String get _randomCelebrationLottie {
    final rand = Random();
    return _celebrationLotties[rand.nextInt(_celebrationLotties.length)];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        titleText: 'discovery.discovery_studies'.tr(),
      ),
      body: BlocBuilder<DiscoveryBloc, DiscoveryState>(
        builder: (context, state) {
          if (state is DiscoveryLoading || state is DiscoveryStudyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DiscoveryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<DiscoveryBloc>().add(
                              LoadDiscoveryStudy(widget.studyId,
                                  languageCode: 'es'),
                            );
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text('app.retry'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is DiscoveryLoaded) {
            final study = state.getStudy(widget.studyId);

            if (study == null) {
              debugPrint(
                  '❌ [DiscoveryDetailPage] Study not found for id: \\${widget.studyId} (fallback or missing)');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64),
                    const SizedBox(height: 16),
                    Text('discovery.no_studies_available'.tr()),
                  ],
                ),
              );
            } else {
              debugPrint(
                  '🌐 [DiscoveryDetailPage] Study loaded for id: \\${widget.studyId} (likely from network or updated cache)');
            }

            return Column(
              children: [
                // Study header
                _buildStudyHeader(study, theme, isDark),
                // Progress dots for sections/cards
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      study.totalSections,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentSectionIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentSectionIndex == index
                              ? theme.colorScheme.primary
                              : Colors.grey.withAlpha(128),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                // Swipeable carousel for sections/cards
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentSectionIndex = index;
                      });
                    },
                    itemCount: study.totalSections,
                    itemBuilder: (context, index) {
                      final isLast = index == study.totalSections - 1;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        margin: EdgeInsets.symmetric(
                          horizontal: _currentSectionIndex == index ? 8 : 24,
                          vertical: _currentSectionIndex == index ? 0 : 24,
                        ),
                        child: Material(
                          elevation: _currentSectionIndex == index ? 8 : 2,
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              // Render based on format (cards vs secciones)
                              if (study.cards.isNotEmpty)
                                _buildCardContent(study.cards[index], isDark)
                              else if (study.secciones != null &&
                                  study.secciones!.isNotEmpty)
                                DiscoverySectionCard(
                                  section: study.secciones![index],
                                  studyId: widget.studyId,
                                  sectionIndex: index,
                                  isDark: isDark,
                                  versiculoClave: study.versiculoClave,
                                ),
                              if (isLast)
                                Positioned.fill(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Show a random Lottie animation from the list
                                      SizedBox(
                                        height: 120,
                                        child: Lottie.asset(
                                          _randomCelebrationLottie,
                                          repeat: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStudyHeader(
    DiscoveryDevotional study,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.grey[850] : theme.colorScheme.primary.withAlpha(26),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            study.reflexion,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              Chip(
                label: Text(
                  '${'Section'.tr()} ${_currentSectionIndex + 1}/${study.totalSections}',
                  style: const TextStyle(fontSize: 12),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build card content based on card type
  Widget _buildCardContent(DiscoveryCard card, bool isDark) {
    // For now, render a simple card view
    // TODO: Create specialized card widgets for each type
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          if (card.icon != null) ...[
            Text(
              card.icon!,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
          ],

          // Title
          Text(
            card.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          // Subtitle
          if (card.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              card.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],

          const SizedBox(height: 24),

          // Content
          if (card.content != null)
            Text(
              card.content!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

          // Revelation Key
          if (card.revelationKey != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      card.revelationKey!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Scripture Connections
          if (card.scriptureConnections != null) ...[
            const SizedBox(height: 24),
            ...card.scriptureConnections!.map(
              (scripture) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scripture.reference,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scripture.text,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Greek Words
          if (card.greekWords != null) ...[
            const SizedBox(height: 24),
            ...card.greekWords!.map(
              (word) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          word.word,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (word.transliteration != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${word.transliteration})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      word.reference,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Significado: ${word.meaning}'),
                    const SizedBox(height: 8),
                    Text(
                      'Revelación: ${word.revelation}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    Text('Aplicación: ${word.application}'),
                  ],
                ),
              ),
            ),
          ],

          // Discovery Questions
          if (card.discoveryQuestions != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Preguntas de Descubrimiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...card.discoveryQuestions!.map(
              (question) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(question.question),
                  ],
                ),
              ),
            ),
          ],

          // Prayer
          if (card.prayer != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (card.prayer!.title != null) ...[
                    Text(
                      card.prayer!.title!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    card.prayer!.content,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
