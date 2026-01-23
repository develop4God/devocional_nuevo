// lib/pages/discovery_detail_page.dart

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/models/discovery_section_model.dart';
import 'package:devocional_nuevo/services/analytics_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
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
  bool _isCelebrating = false;
  bool _hasTriggeredCompletion = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCompleteStudy() {
    if (_hasTriggeredCompletion) return;

    // Log analytics event
    getService<AnalyticsService>().logDiscoveryAction(
      action: 'study_completed',
      studyId: widget.studyId,
    );

    setState(() {
      _isCelebrating = true;
      _hasTriggeredCompletion = true;
    });

    context.read<DiscoveryBloc>().add(CompleteDiscoveryStudy(widget.studyId));
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(seconds: 5), () {
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Lottie.asset('assets/lottie/book_stars.json'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'discovery.loading_studies'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }

            if (state is DiscoveryError) {
              return Center(child: Text(state.message));
            }

            if (state is DiscoveryLoaded) {
              final study = state.getStudy(widget.studyId);

              if (study == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Lottie.asset('assets/lottie/book_stars.json'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'discovery.loading_studies'.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }

              // Check if study is already marked as completed in the state
              final bool isAlreadyCompleted =
                  state.isStudyCompleted(widget.studyId) ||
                      _hasTriggeredCompletion;

              return Stack(
                children: [
                  Column(
                    children: [
                      _buildStudyHeader(study, theme),
                      _buildProgressIndicator(study, theme),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) =>
                              setState(() => _currentSectionIndex = index),
                          itemCount: study.totalSections,
                          itemBuilder: (context, index) {
                            final isLast = index == study.totalSections - 1;
                            return _buildAnimatedCard(study, index, isDark,
                                isLast, isAlreadyCompleted);
                          },
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 20),
                    ],
                  ),

                  // Bottom Scrim Overlay
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
                              theme.scaffoldBackgroundColor
                                  .withValues(alpha: 0),
                              theme.scaffoldBackgroundColor
                                  .withValues(alpha: 0.8),
                              theme.scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 🎊 CELEBRATION OVERLAY
                  if (_isCelebrating)
                    IgnorePointer(
                      child: Center(
                        child: Lottie.asset(
                          'assets/lottie/kudos_birdie.json',
                          repeat: false,
                          height: 350,
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

  Widget _buildAnimatedCard(DiscoveryDevotional study, int index, bool isDark,
      bool isLast, bool isAlreadyCompleted) {
    final isFirst = index == 0;

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
        child: study.cards.isNotEmpty
            ? _buildCardContent(study.cards[index], study, isDark, isLast,
                isAlreadyCompleted, isFirst)
            : study.secciones != null && study.secciones!.isNotEmpty
                ? _buildSectionCardWithButtons(
                    study, study.secciones![index], isDark, isFirst, isLast)
                : const SizedBox.shrink(),
      ),
    );
  }

  /// Wrapper for DiscoverySectionCard with navigation buttons at bottom
  Widget _buildSectionCardWithButtons(DiscoveryDevotional study,
      DiscoverySection section, bool isDark, bool isFirst, bool isLast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section content - expand to fill space
        Expanded(
          child: DiscoverySectionCard(
            section: section,
            studyId: widget.studyId,
            sectionIndex: _currentSectionIndex,
            isDark: isDark,
            versiculoClave: study.versiculoClave,
          ),
        ),

        // Navigation buttons at bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: _buildNavigationButtons(isFirst, isLast),
        ),
      ],
    );
  }

  /// Builds minimalistic navigation buttons at the end of content
  /// - Previous button: appears from 2nd slice onwards (left side)
  /// - Next button: appears on all slices except last (right side)
  /// - Exit button: appears on last slice (right side, replaces Next)
  Widget _buildNavigationButtons(bool isFirst, bool isLast) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // Previous button (left side) - shown from 2nd slice onwards
          if (!isFirst)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(
                  height: 44,
                  child: TextButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    label: Text(
                      'discovery.previous'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
            )
          else
            // Empty space to balance layout when there's no Previous button
            const Expanded(child: SizedBox.shrink()),

          // Next button (right side) - shown on all slices except last
          // Exit button (right side) - shown ONLY on last slice
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: SizedBox(
                height: 44,
                child: isLast
                    ? TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        label: Text(
                          'discovery.exit'.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        label: Text(
                          'discovery.next'.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                        iconAlignment: IconAlignment.end,
                        style: TextButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(DiscoveryCard card, DiscoveryDevotional study,
      bool isDark, bool isLast, bool isAlreadyCompleted, bool isFirst) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ...existing card content...
          if (card.icon != null) ...[
            Text(card.icon!, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 20),
          ],

          Text(
            card.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
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
              style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9)),
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
                  const Icon(Icons.lightbulb_rounded,
                      size: 28, color: Colors.white),
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
            ...card.scriptureConnections!
                .map((scripture) => _buildScriptureTile(scripture, theme)),
          ],

          if (card.greekWords != null) ...[
            const SizedBox(height: 32),
            ...card.greekWords!.map((word) => _buildGreekWordTile(word, theme)),
          ],

          if (card.discoveryQuestions != null) ...[
            const SizedBox(height: 32),
            Text('discovery.reflection_questions'.tr(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ...card.discoveryQuestions!
                .map((q) => _buildQuestionTile(q, theme)),
          ],

          if (card.prayer != null) ...[
            const SizedBox(height: 32),
            _buildPrayerTile(card.prayer!, theme),
          ],

          // ✨ MODERN MINIMALIST COMPLETE BUTTON
          if (isLast) ...[
            const SizedBox(height: 48),
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isAlreadyCompleted ? 0.6 : 1.0,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton.icon(
                    onPressed: isAlreadyCompleted ? null : _onCompleteStudy,
                    icon: Icon(
                      isAlreadyCompleted
                          ? Icons.verified_rounded
                          : Icons.check_circle_outline_rounded,
                      color: isAlreadyCompleted ? Colors.green : Colors.white,
                    ),
                    label: Text(
                      isAlreadyCompleted
                          ? 'discovery.completed_study'.tr()
                          : 'discovery.mark_completed'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: isAlreadyCompleted
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.primary,
                      foregroundColor: isAlreadyCompleted
                          ? theme.colorScheme.primary
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // 📜 COPYRIGHT DISCLAIMER - only show on last section
          if (isLast) ...[
            const SizedBox(height: 48),
            _buildCopyrightDisclaimer(study, theme),
          ],

          // Navigation buttons at the bottom of content
          const SizedBox(height: 32),
          _buildNavigationButtons(isFirst, isLast),

          const SizedBox(height: 20),
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
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.reference,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Text(s.text,
              style: const TextStyle(fontStyle: FontStyle.italic, height: 1.5)),
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
              Text(word.word,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSecondaryContainer,
                  )),
              if (word.transliteration != null) ...[
                const SizedBox(width: 8),
                Text('(${word.transliteration})',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text('${'discovery.meaning'.tr()}: ${word.meaning}',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          Text('${'discovery.revelation'.tr()}: ${word.revelation}',
              style: const TextStyle(fontStyle: FontStyle.italic)),
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
          Text(q.category.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1)),
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
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('discovery.activation_prayer'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 12),
          Text(p.content,
              style: const TextStyle(fontStyle: FontStyle.italic, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildCopyrightDisclaimer(DiscoveryDevotional study, ThemeData theme) {
    // Use the language and version from the already-fetched study data
    final language = study.language ?? 'en';
    final version = study.version ?? 'KJV';

    // Get copyright text from CopyrightUtils
    final copyrightText = CopyrightUtils.getCopyrightText(language, version);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              copyrightText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
