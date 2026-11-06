import 'package:flutter/material.dart';

/// Height of an encounter card.
const encounterCardHeight = 272.0;

/// Narrowest a card may get: a 360dp phone minus the side padding. Below this
/// the title, badge row and metadata no longer fit comfortably.
const encounterCardMinWidth = 320.0;

/// Scrollable [header] followed by cards laid out in as many columns as fit.
///
/// Cards keep a fixed [cardHeight] and never get narrower than
/// [minCardWidth]: the column count is the most that still respects that
/// minimum, so wider or landscape screens get more columns instead of
/// stretched cards, and phones get one.
class ResponsiveCardGrid extends StatelessWidget {
  static const _spacing = 20.0;
  static const _mainAxisSpacing = 24.0;

  // Extra room under the last card keeps it clear of the gesture bar.
  static const _padding = EdgeInsets.fromLTRB(20, 24, 20, 48);

  final ScrollController controller;
  final Widget header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double cardHeight;
  final double minCardWidth;

  const ResponsiveCardGrid({
    super.key,
    required this.controller,
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.cardHeight = encounterCardHeight,
    this.minCardWidth = encounterCardMinWidth,
  });

  /// Most columns whose cards are still at least [minCardWidth] wide.
  int _columnsFor(double width) =>
      ((width + _spacing) / (minCardWidth + _spacing)).floor().clamp(1, 1000);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: _padding,
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: header),
              SliverLayoutBuilder(
                builder: (context, constraints) => SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _columnsFor(constraints.crossAxisExtent),
                    mainAxisExtent: cardHeight,
                    crossAxisSpacing: _spacing,
                    mainAxisSpacing: _mainAxisSpacing,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    itemBuilder,
                    childCount: itemCount,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
