import 'package:flutter/widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Adapter each TTS-enabled page implements so [TtsAutoScrollDriver] can scroll
/// the page's own scroll view without knowing how it scrolls.
///
/// Pages back this with whatever scroll mechanism they use — a
/// [ScrollController] (pixel offset) or an [ItemScrollController] (item index) —
/// keeping the driver reusable across the devotional reader, the bible reader,
/// and any future TTS page. The two concrete adapters below cover both existing
/// mechanisms; a new page implements this interface directly only if it scrolls
/// some other way.
abstract class TtsScrollTarget {
  /// Scroll so that the given playback [fraction] (0.0..1.0) is in view.
  ///
  /// Implementations decide the pixel-vs-index mapping and must no-op safely
  /// when the scroll view is not attached or not ready.
  void scrollToFraction(double fraction);
}

/// Scrolls a pixel-based scroll view (e.g. a `SingleChildScrollView`) by mapping
/// the playback fraction onto `maxScrollExtent`.
///
/// Yields to the user: while the user is actively dragging (a scroll activity is
/// in progress), auto-scroll is skipped so it does not fight manual reading.
class ScrollControllerTarget implements TtsScrollTarget {
  final ScrollController controller;
  final Duration duration;
  final Curve curve;

  ScrollControllerTarget(
    this.controller, {
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOut,
  });

  @override
  void scrollToFraction(double fraction) {
    if (!controller.hasClients) return;
    final position = controller.position;
    // Skip while the user is dragging so auto-scroll yields to manual reading.
    if (position.isScrollingNotifier.value) return;

    final target = (fraction * position.maxScrollExtent)
        .clamp(0.0, position.maxScrollExtent);
    controller.animateTo(target, duration: duration, curve: curve);
  }
}

/// Scrolls an index-based [ScrollablePositionedList] by mapping the playback
/// fraction onto the item count.
///
/// [itemCount] is the number of *highlightable* items (e.g. verses), read
/// lazily because the list length changes when a new chapter loads. Lists that
/// prepend leading widgets (a chapter title) before the items pass
/// [leadingCount] so the fraction maps to the correct list index.
class ItemScrollControllerTarget implements TtsScrollTarget {
  final ItemScrollController controller;
  final int Function() itemCount;

  /// Number of non-item widgets before the first item (e.g. a title at index 0).
  final int leadingCount;
  final Duration duration;
  final Curve curve;
  final double alignment;

  ItemScrollControllerTarget(
    this.controller, {
    required this.itemCount,
    this.leadingCount = 0,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOut,
    this.alignment = 0.1,
  });

  @override
  void scrollToFraction(double fraction) {
    if (!controller.isAttached) return;
    final count = itemCount();
    if (count <= 0) return;

    final itemIndex = (fraction * count).floor().clamp(0, count - 1);
    controller.scrollTo(
      index: itemIndex + leadingCount,
      duration: duration,
      curve: curve,
      alignment: alignment,
    );
  }
}
