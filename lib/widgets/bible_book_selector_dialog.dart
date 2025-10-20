// Modified to be full-screen friendly for ModalBottomSheet and improved affordance for scrolling
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

class BibleBookSelectorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> books;
  final String? selectedBookName;
  final void Function(Map<String, dynamic> book) onBookSelected;

  const BibleBookSelectorDialog({
    super.key,
    required this.books,
    required this.selectedBookName,
    required this.onBookSelected,
  });

  @override
  State<BibleBookSelectorDialog> createState() =>
      _BibleBookSelectorDialogState();
}

class _BibleBookSelectorDialogState extends State<BibleBookSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredBooks = [];

  @override
  void initState() {
    super.initState();
    _filteredBooks = List.from(widget.books);
    _searchController.addListener(() {
      _filterBooks(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBooks(String query) {
    setState(() {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        _filteredBooks = List.from(widget.books);
      } else {
        _filteredBooks = widget.books.where((book) {
          final longName = book['long_name'].toString().toLowerCase();
          final shortName = book['short_name'].toString().toLowerCase();
          final searchLower = trimmed.toLowerCase();
          return longName.contains(searchLower) ||
              shortName.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'bible.search_book'.tr(),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      tooltip: 'bible.close'.tr(),
                    ),
                  ],
                ),
              ),

              // Search input
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'bible.search_book_placeholder'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterBooks('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF232232)
                        : colorScheme.surfaceContainerHighest,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onChanged: _filterBooks,
                ),
              ),

              // Small affordance hint to indicate scrollability
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.drag_handle,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 8),
                    Text(
                      'Desplaza para ver más',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // List
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredBooks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      final isSelected =
                          book['short_name'] == widget.selectedBookName;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        title: Text(
                          book['long_name'],
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: colorScheme.primaryContainer
                            .withValues(alpha: 0.18),
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onBookSelected(book);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
