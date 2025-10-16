import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

/// A modern search overlay for Bible search functionality
/// Shows as a modal overlay that can be dismissed via back button, close button, or tap outside
class BibleSearchOverlay extends StatefulWidget {
  final BibleReaderController controller;
  final Function(int verseNumber) onScrollToVerse;
  final String Function(dynamic text) cleanVerseText;

  const BibleSearchOverlay({
    super.key,
    required this.controller,
    required this.onScrollToVerse,
    required this.cleanVerseText,
  });

  @override
  State<BibleSearchOverlay> createState() => _BibleSearchOverlayState();
}

class _BibleSearchOverlayState extends State<BibleSearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus on the search field when overlay opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleClose() {
    // Clear search and unfocus before closing
    widget.controller.clearSearch();
    _searchController.clear();
    _searchFocusNode.unfocus();
    Navigator.of(context).pop();
  }

  Future<void> _handleSearchResultTap(Map<String, dynamic> result) async {
    // Capture FocusScope BEFORE async operation
    final focusScope = FocusScope.of(context);

    await widget.controller.jumpToSearchResult(result);
    _searchController.clear();
    if (!mounted) return;

    _searchFocusNode.unfocus();
    focusScope.unfocus();

    // Close the overlay
    Navigator.of(context).pop();

    // Wait for navigation to complete, then scroll to verse
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final verse = result['verse'];
        widget.onScrollToVerse(verse);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Clean up when back button is pressed
        _searchFocusNode.unfocus();
        if (FocusScope.of(context).hasFocus) {
          FocusScope.of(context).unfocus();
        }
        widget.controller.clearSearch();
        _searchController.clear();
      },
      child: GestureDetector(
        onTap: _handleClose,
        child: Material(
          color: Colors.black.withValues(alpha: 0.5),
          child: SafeArea(
            child: GestureDetector(
              onTap: () {}, // Prevent tap from propagating to background
              child: Center(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                  constraints:
                      const BoxConstraints(maxWidth: 600, maxHeight: 700),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with close button
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'bible.search'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _handleClose,
                              tooltip: 'bible.close'.tr(),
                            ),
                          ],
                        ),
                      ),
                      // Search input field
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'bible.search_placeholder'.tr(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      widget.controller.clearSearch();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (query) async {
                            await widget.controller.performSearch(query);
                          },
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      // Search results
                      Expanded(
                        child: StreamBuilder<BibleReaderState>(
                          stream: widget.controller.stateStream,
                          initialData: widget.controller.state,
                          builder: (context, snapshot) {
                            final state =
                                snapshot.data ?? widget.controller.state;

                            if (!state.isSearching) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'bible.search_placeholder'.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (state.searchResults.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'bible.no_matches_retry'.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.searchResults.length,
                              itemBuilder: (context, idx) {
                                final result = state.searchResults[idx];
                                final bookName =
                                    result['long_name'] ?? result['short_name'];
                                final chapter = result['chapter'];
                                final verse = result['verse'];
                                final text =
                                    widget.cleanVerseText(result['text']);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () => _handleSearchResultTap(result),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$bookName $chapter:$verse',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(
                                              children:
                                                  _buildHighlightedTextSpans(
                                                text,
                                                state.searchQuery,
                                                colorScheme,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedTextSpans(
    String text,
    String query,
    ColorScheme colorScheme,
  ) {
    if (query.trim().isEmpty) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
            height: 1.4,
          ),
        ),
      ];
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final queryWords = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    int lastIndex = 0;

    while (lastIndex < text.length) {
      int matchIndex = -1;
      int matchLength = 0;

      for (final word in queryWords) {
        if (word.isEmpty) continue;
        final index = lowerText.indexOf(word, lastIndex);
        if (index != -1 && (matchIndex == -1 || index < matchIndex)) {
          matchIndex = index;
          matchLength = word.length;
        }
      }

      if (matchIndex == -1) {
        spans.add(TextSpan(
          text: text.substring(lastIndex),
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
            height: 1.4,
          ),
        ));
        break;
      }

      if (matchIndex > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, matchIndex),
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
            height: 1.4,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + matchLength),
        style: TextStyle(
          fontSize: 15,
          color: colorScheme.onSurface,
          height: 1.4,
          fontWeight: FontWeight.bold,
          backgroundColor: colorScheme.primaryContainer,
          decoration: TextDecoration.underline,
          decorationColor: colorScheme.primary,
        ),
      ));

      lastIndex = matchIndex + matchLength;
    }

    return spans;
  }
}
