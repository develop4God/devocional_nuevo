import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

class BibleSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final List<Map<String, dynamic>> searchResults;
  final ColorScheme colorScheme;
  final void Function(String) onSubmitted;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final void Function(Map<String, dynamic>) onResultTap;
  final List<TextSpan> Function(String, String, ColorScheme)
      buildHighlightedTextSpans;

  const BibleSearchBar({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.searchResults,
    required this.colorScheme,
    required this.onSubmitted,
    required this.onChanged,
    required this.onClear,
    required this.onResultTap,
    required this.buildHighlightedTextSpans,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar (EXACT extraction)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'bible.search_placeholder'.tr(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
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
            onSubmitted: onSubmitted,
            onChanged: onChanged,
          ),
        ),
        // Search results (EXACT extraction)
        if (isSearching)
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'bible.no_matches_retry'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: searchResults.length,
                    itemBuilder: (context, idx) {
                      final result = searchResults[idx];
                      final bookName =
                          result['long_name'] ?? result['short_name'];
                      final chapter = result['chapter'];
                      final verse = result['verse'];
                      final text = result['text'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => onResultTap(result),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    children: buildHighlightedTextSpans(
                                      text,
                                      searchController.text,
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
                  ),
          ),
      ],
    );
  }
}
