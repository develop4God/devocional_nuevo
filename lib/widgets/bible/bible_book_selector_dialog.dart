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
  final ScrollController _listScrollController = ScrollController();
  List<Map<String, dynamic>> _filteredBooks = [];

  @override
  void initState() {
    super.initState();
    _filteredBooks = List.from(widget.books);

    // Scroll to selected book after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedBook();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _filterBooks(String query) {
    setState(() {
      if (query.length < 2) {
        _filteredBooks = List.from(widget.books);
      } else {
        _filteredBooks = widget.books.where((book) {
          final longName = book['long_name'].toString().toLowerCase();
          final shortName = book['short_name'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return longName.contains(searchLower) ||
              shortName.contains(searchLower);
        }).toList();
      }
    });
  }

  void _scrollToSelectedBook() {
    if (widget.selectedBookName == null || _filteredBooks.isEmpty) return;

    final index = _filteredBooks.indexWhere(
      (book) => book['short_name'] == widget.selectedBookName,
    );

    if (index != -1 && _listScrollController.hasClients) {
      _listScrollController.animateTo(
        index * 56.0, // Altura aproximada de cada ListTile
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'bible.search_book'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'bible.close'.tr(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF232232)
                      : Colors.white,
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                onChanged: _filterBooks,
              ),
            ),
            // Books list with scrollbar
            Expanded(
              child: Scrollbar(
                controller: _listScrollController,
                thumbVisibility: true,
                thickness: 8,
                radius: const Radius.circular(10),
                child: ListView.builder(
                  controller: _listScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = _filteredBooks[index];
                    final isSelected =
                        book['short_name'] == widget.selectedBookName;
                    return ListTile(
                      title: Text(
                        book['long_name'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onBookSelected(book);
                      },
                    );
                  },
                ),
              ),
            ),
            // Bottom padding
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
