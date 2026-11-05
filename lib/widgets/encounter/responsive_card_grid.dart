import 'package:flutter/material.dart';

/// Height of an encounter card.
const encounterCardHeight = 272.0;

/// Aspect ratio (width / height) of the encounter cover artwork (1024x559).
const encounterArtworkAspectRatio = 1024 / 559;

/// Widest a card gets: the width at which the artwork fills the card exactly,
/// so a wider card would only crop it into a thin strip.
const encounterCardMaxWidth = encounterCardHeight * encounterArtworkAspectRatio;

/// Scrollable [header] followed by cards laid out in as many columns as fit.
///
/// Cards keep a fixed [cardHeight] and never grow wider than [maxCardWidth];
/// extra horizontal space becomes extra columns instead of stretched cards,
/// so phones get one column and larger or landscape screens get more.
class ResponsiveCardGrid extends StatelessWidget {
  static const _spacing = 20.0;
  static const _mainAxisSpacing = 24.0;
  static const _padding = EdgeInsets.symmetric(horizontal: 20, vertical: 24);

  final ScrollController controller;
  final Widget header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double cardHeight;
  final double maxCardWidth;

  const ResponsiveCardGrid({
    super.key,
    required this.controller,
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.cardHeight = encounterCardHeight,
    this.maxCardWidth = encounterCardMaxWidth,
  });

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
              SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxCardWidth,
                  mainAxisExtent: cardHeight,
                  crossAxisSpacing: _spacing,
                  mainAxisSpacing: _mainAxisSpacing,
                ),
                delegate: SliverChildBuilderDelegate(
                  itemBuilder,
                  childCount: itemCount,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
