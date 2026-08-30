import 'package:devocional_nuevo/blocs/supporter/supporter_bloc.dart';
import 'package:devocional_nuevo/blocs/supporter/supporter_state.dart';
import 'package:devocional_nuevo/blocs/note_bloc.dart';
import 'package:devocional_nuevo/blocs/note_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/app_navigation_shell.dart';
import 'package:devocional_nuevo/services/tts/devocional_tts_sections.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/supporter_pet_service.dart';
import 'package:devocional_nuevo/utils/constants/bubble_constants.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:devocional_nuevo/widgets/devotional_note_viewer.dart';
import 'package:devocional_nuevo/widgets/devotional_notes_modal.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:devocional_nuevo/widgets/devocionales/copyable_verse_card.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocional_header_widget.dart';
import 'package:devocional_nuevo/widgets/markdown_emphasis_text.dart';
import 'package:devocional_nuevo/widgets/notes/note_icons.dart';
import 'package:devocional_nuevo/widgets/supporter/pet_hero_section.dart';
import 'package:devocional_nuevo/widgets/tts_highlight_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

/// Widget that displays the content of a devotional.
class DevocionalesContentWidget extends StatelessWidget {
  final Devocional devocional;
  final double fontSize;
  final VoidCallback onStreakBadgeTap;
  final int currentStreak;
  final Future<int> streakFuture;
  final String Function(BuildContext) getLocalizedDateFormat;
  final ScrollController? scrollController;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;

  /// Forwarded to [DevocionalHeaderWidget.showDate]. Defaults to true to
  /// match existing callers.
  final bool showDate;

  /// Whether the date/streak/favorite/share header row renders at all.
  /// Defaults to true. Callers that render their own header elsewhere (e.g.
  /// a full-bleed hero image above this widget) pass false to avoid showing
  /// it twice — the header's own content and callbacks are unaffected.
  final bool showHeader;

  /// Pet service injected by the caller — keeps [build] free of service-locator
  /// calls, which violates the project's DI rules.
  final SupporterPetService petService;

  /// Ordered TTS units for this devotional (verse, reflection sentences,
  /// meditate items, prayer sentences). When provided together with
  /// [currentUnitIndex], the reflection and prayer render per-sentence so the
  /// current sentence highlights. Null disables TTS highlighting.
  final List<DevotionalUnit>? ttsUnits;

  /// Index (into [ttsUnits]) of the unit currently being read by TTS. The
  /// matching unit is shown full-strength (bold); the others dim.
  final ValueListenable<int?>? currentUnitIndex;

  /// Whether this widget wraps its content in its own [SingleChildScrollView].
  /// Defaults to true, matching every existing caller. A caller that hosts
  /// this content inside a [CustomScrollView] alongside a [SliverAppBar] (so
  /// the app bar can pin/collapse) passes false and supplies [scrollController]
  /// to the surrounding sliver scroll view instead — nesting two independent
  /// scrollables would otherwise fight over drag gestures.
  final bool wrapInScrollView;

  const DevocionalesContentWidget({
    super.key,
    required this.devocional,
    required this.fontSize,
    required this.onStreakBadgeTap,
    required this.currentStreak,
    required this.streakFuture,
    required this.getLocalizedDateFormat,
    this.scrollController,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onShare,
    required this.petService,
    this.showDate = true,
    this.showHeader = true,
    this.wrapInScrollView = true,
    this.ttsUnits,
    this.currentUnitIndex,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (petService.showPetHeader && petService.isPetUnlocked)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: BlocBuilder<SupporterBloc, SupporterState>(
              builder: (context, supporterState) {
                final goldName = supporterState is SupporterLoaded
                    ? supporterState.goldSupporterName
                    : null;
                return PetHeroSection(
                  formattedDate: getLocalizedDateFormat(context),
                  showPetHint: false,
                  onTap: () => AppNavigationShell.selectTab(AppTab.settings),
                  selectedPet: petService.selectedPet,
                  selectedTheme: (
                    colors: [colorScheme.primary, colorScheme.tertiary],
                  ),
                  profileName: goldName,
                );
              },
            ),
          ),
        if (showHeader)
          DevocionalHeaderWidget(
            date: getLocalizedDateFormat(context),
            showDate: showDate,
            currentStreak: currentStreak,
            streakFuture: streakFuture,
            isFavorite: isFavorite,
            onFavoriteToggle: onFavoriteToggle,
            onShare: onShare,
            onStreakTap: onStreakBadgeTap,
          ),
        ..._buildTtsContent(context, colorScheme, textTheme),
        const SizedBox(height: 20),
        if (devocional.version != null ||
            devocional.language != null ||
            devocional.tags != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'devotionals.details'.tr(),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              if (devocional.tags != null && devocional.tags!.isNotEmpty)
                Text(
                  'devotionals.topics'.tr({
                    'topics': devocional.tags!.join(', '),
                  }),
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              if (devocional.version != null)
                Text(
                  'devotionals.version'.tr({'version': devocional.version}),
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              const SizedBox(height: 10),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<DevocionalProvider>(
                    builder: (context, provider, child) {
                      return Text(
                        CopyrightUtils.getCopyrightText(
                          provider.selectedLanguage,
                          provider.selectedVersion,
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
      ],
    );

    if (!wrapInScrollView) return content;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      child: content,
    );
  }

  /// Renders the TTS content region (verse → reflection → meditate → prayer)
  /// from [ttsUnits] so each unit — a whole verse, a reflection/prayer
  /// sentence, or a meditate item — highlights independently while spoken.
  /// The devotional note action is emitted right after the verse, preserving
  /// the original layout. Falls back to plain rendering when no units.
  List<Widget> _buildTtsContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final units = ttsUnits;
    if (units == null || units.isEmpty) {
      return _buildPlainContent(context, colorScheme, textTheme);
    }

    final children = <Widget>[];
    for (int i = 0; i < units.length; i++) {
      final unit = units[i];
      children.add(
        _UnitHighlight(
          index: i,
          currentIndex: currentUnitIndex,
          builder: (isCurrent) => _buildUnit(
            context,
            unit,
            colorScheme,
            textTheme,
            isCurrent: isCurrent,
          ),
        ),
      );
      // Keep the note action between the verse and the reflection.
      if (unit.kind == DevotionalUnitKind.verse) {
        children.add(const SizedBox(height: 12));
        children.add(_DevotionalNoteAction(devocional: devocional));
      }
      children.add(SizedBox(height: _unitGap(unit, i, units)));
    }
    return children;
  }

  /// Vertical gap after a unit: a larger gap before a section label, small gaps
  /// between sentences/items so a section reads as one group.
  double _unitGap(DevotionalUnit unit, int i, List<DevotionalUnit> units) {
    final next = i + 1 < units.length ? units[i + 1] : null;
    if (next?.kind == DevotionalUnitKind.label) return 20;
    if (unit.kind == DevotionalUnitKind.label) return 10;
    return 4;
  }

  Widget _buildUnit(
    BuildContext context,
    DevotionalUnit unit,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required bool isCurrent,
  }) {
    switch (unit.kind) {
      case DevotionalUnitKind.label:
        return Text(
          '${unit.text}:',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        );
      case DevotionalUnitKind.verse:
        return CopyableVerseCard(
          text: unit.text,
          textStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
      case DevotionalUnitKind.sentence:
        return buildEmphasisMarkdownText(
          unit.text,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: fontSize,
            color: colorScheme.onSurface,
            // Karaoke highlight: bold the sentence currently being read, same
            // as the Bible reader's per-verse highlight.
            fontWeight: isCurrent ? FontWeight.bold : null,
          ),
        );
      case DevotionalUnitKind.meditateItem:
        return CopyableVerseCard(
          text: unit.text,
          copyText: '${unit.citation}: ${unit.text}',
          textStyle: textTheme.bodyMedium?.copyWith(fontSize: fontSize),
          maxLines: 8,
          prefixSpan: TextSpan(
            text: '${unit.citation}: ',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              color: colorScheme.primary,
            ),
          ),
        );
    }
  }

  /// Non-highlighted fallback (e.g. favorite detail page, or TTS idle) — the
  /// original section layout, unchanged.
  List<Widget> _buildPlainContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    Widget title(String key) => Text(
          key.tr(),
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        );
    Widget body(String text) => buildEmphasisMarkdownText(
          text,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: fontSize,
            color: colorScheme.onSurface,
          ),
        );

    return [
      CopyableVerseCard(
        text: devocional.versiculo,
        textStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      _DevotionalNoteAction(devocional: devocional),
      const SizedBox(height: 20),
      title('devotionals.reflection'),
      const SizedBox(height: 10),
      body(devocional.reflexion),
      const SizedBox(height: 20),
      title('devotionals.to_meditate'),
      const SizedBox(height: 10),
      ...devocional.paraMeditar.map(
        (item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: CopyableVerseCard(
            text: item.texto,
            copyText: '${item.cita}: ${item.texto}',
            textStyle: textTheme.bodyMedium?.copyWith(fontSize: fontSize),
            maxLines: 8,
            prefixSpan: TextSpan(
              text: '${item.cita}: ',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      title('devotionals.prayer'),
      const SizedBox(height: 10),
      body(devocional.oracion),
    ];
  }
}

/// Dims the built child unless its [index] is the unit currently being read
/// by TTS, and lets [builder] bold the current one — same treatment as the
/// Bible reader's per-verse highlight.
///
/// When [currentIndex] is null, or its value is null (nothing playing), the
/// child renders at full strength — so the page looks unchanged when TTS is
/// idle.
class _UnitHighlight extends StatelessWidget {
  final int index;
  final ValueListenable<int?>? currentIndex;
  final Widget Function(bool isCurrent) builder;

  const _UnitHighlight({
    required this.index,
    required this.currentIndex,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (currentIndex == null) return builder(false);
    return ValueListenableBuilder<int?>(
      valueListenable: currentIndex!,
      builder: (context, current, _) {
        final style = TtsHighlightStyle.forIndex(current, index);
        return AnimatedOpacity(
          opacity: style.opacity,
          duration: TtsHighlight.fadeDuration,
          child: builder(style.isCurrent),
        );
      },
    );
  }
}

class _DevotionalNoteAction extends StatelessWidget {
  final Devocional devocional;

  const _DevotionalNoteAction({required this.devocional});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<NoteBloc, NoteState>(
      builder: (context, state) {
        final note = state is NoteLoaded
            ? state.getNoteForDevocional(devocional.id)
            : null;
        final hasNote = note?.isNotEmpty == true;

        return Semantics(
          button: true,
          label: hasNote ? 'notes.view_action'.tr() : 'notes.add_action'.tr(),
          child: Material(
            color: hasNote
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                BubbleUtils.markAsShown('devocionales_note_bubble');
                if (hasNote) {
                  DevotionalNoteViewer.show(
                    context,
                    devocional: devocional,
                    note: note!,
                    onEdit: () => DevotionalNotesModal.show(
                      context,
                      devocional: devocional,
                      initialNote: note,
                    ),
                  );
                } else {
                  DevotionalNotesModal.show(
                    context,
                    devocional: devocional,
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasNote
                        ? colorScheme.primary.withValues(alpha: 0.35)
                        : colorScheme.outline.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      NoteIcons.forState(hasNote),
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasNote
                            ? 'notes.view_action'.tr()
                            : 'notes.add_action'.tr(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ).newBubbleWithId('devocionales_note_bubble'),
                    ),
                    if (hasNote)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
