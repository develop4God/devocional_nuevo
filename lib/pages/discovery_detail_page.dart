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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../blocs/theme/theme_bloc.dart';
import '../blocs/theme/theme_state.dart';

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
  bool _isCelebrating = false; // Local state for completion celebration

  final List<String> _celebrationLotties = [
    'assets/lottie/confetti.json',
    'assets/lottie/trophy_star.json',
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

  void _onCompleteStudy() {
    setState(() {
      _isCelebrating = true;
    });
    
    context.read<DiscoveryBloc>().add(CompleteDiscoveryStudy(widget.studyId));
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isCelebrating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(
          titleText: 'discovery.discovery_studies'.tr(),
        ),
        body: BlocBuilder<DiscoveryBloc, DiscoveryState>(
          builder: (context, state) {
            if (state is DiscoveryLoading || state is DiscoveryStudyLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DiscoveryError) {
              return Center(child: Text(state.message));
            }

            if (state is DiscoveryLoaded) {
              final study = state.getStudy(widget.studyId);

              if (study == null) {
                return const Center(child: Text('Study not found.'));
              }

              return Stack(
                children: [
                  Column(
                    children: [
                      _buildStudyHeader(study, theme),
                      _buildProgressIndicator(study, theme),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentSectionIndex = index),
                          itemCount: study.totalSections,
                          itemBuilder: (context, index) {
                            final isLast = index == study.totalSections - 1;
                            return _buildAnimatedCard(study, index, isDark, isLast);
                          },
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                    ],
                  ),

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.scaffoldBackgroundColor.withValues(alpha: 0),
                              theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                              theme.scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_isCelebrating)
                    IgnorePointer(
                      child: Center(
                        child: Lottie.asset(
                          _randomCelebrationLottie,
                          repeat: false,
                          height: 300,
                        ),
                      ),
                    ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildStudyHeader(DiscoveryDevotional study, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              study.reflexion,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentSectionIndex + 1}/${study.totalSections}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(DiscoveryDevotional study, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          study.totalSections,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _currentSectionIndex == index ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _currentSectionIndex == index
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(DiscoveryDevotional study, int index, bool isDark, bool isLast) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      margin: EdgeInsets.symmetric(
        horizontal: _currentSectionIndex == index ? 12 : 28,
        vertical: _currentSectionIndex == index ? 4 : 24,
      ),
      child: Material(
        elevation: _currentSectionIndex == index ? 8 : 1,
        borderRadius: BorderRadius.circular(32),
        shadowColor: Colors.black.withValues(alpha: 0.08),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (study.cards.isNotEmpty)
              _buildCardContent(study.cards[index], isDark, isLast)
            else if (study.secciones != null && study.secciones!.isNotEmpty)
              DiscoverySectionCard(
                section: study.secciones![index],
                studyId: widget.studyId,
                sectionIndex: index,
                isDark: isDark,
                versiculoClave: study.versiculoClave,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(DiscoveryCard card, bool isDark, bool isLast) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (card.icon != null) ...[
            Text(card.icon!, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 20),
          ],

          Text(
            card.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),

          if (card.subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              card.subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 24),

          if (card.content != null)
            Text(
              card.content!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, color: theme.colorScheme.onSurface.withValues(alpha: 0.9)),
            ),

          if (card.revelationKey != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, size: 28, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      card.revelationKey!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (card.scriptureConnections != null) ...[
            const SizedBox(height: 32),
            ...card.scriptureConnections!.map((scripture) => _buildScriptureTile(scripture, theme)),
          ],

          if (card.greekWords != null) ...[
            const SizedBox(height: 32),
            ...card.greekWords!.map((word) => _buildGreekWordTile(word, theme)),
          ],

          if (card.discoveryQuestions != null) ...[
            const SizedBox(height: 32),
            const Text('Preguntas de Reflexión', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ...card.discoveryQuestions!.map((q) => _buildQuestionTile(q, theme)),
          ],

          if (card.prayer != null) ...[
            const SizedBox(height: 32),
            _buildPrayerTile(card.prayer!, theme),
          ],
          
          if (isLast) ...[
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isCelebrating ? null : _onCompleteStudy,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  'discovery.study_completed'.tr().toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildScriptureTile(ScriptureConnection s, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.reference, style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Text(s.text, style: const TextStyle(fontStyle: FontStyle.italic, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildGreekWordTile(GreekWord word, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                word.word, 
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.w900, 
                  color: theme.colorScheme.onSecondaryContainer,
                )
              ),
              if (word.transliteration != null) ...[
                const SizedBox(width: 8),
                Text(
                  '(${word.transliteration})', 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary
                  )
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text('Significado: ${word.meaning}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          Text('Revelación: ${word.revelation}', style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildQuestionTile(DiscoveryQuestion q, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.category.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(q.question, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPrayerTile(Prayer p, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4), // Same style as Greek tile
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oración de Activación', 
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w900, // Same weight as Greek titles
            )
          ),
          const SizedBox(height: 12),
          Text(p.content, style: const TextStyle(fontStyle: FontStyle.italic, height: 1.6)),
        ],
      ),
    );
  }
}
