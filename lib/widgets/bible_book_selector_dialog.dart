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
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('bible.search_book'.tr()),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
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
              ),
              onChanged: _filterBooks,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredBooks.length,
                itemBuilder: (context, index) {
                  final book = _filteredBooks[index];
                  final isSelected =
                      book['short_name'] == widget.selectedBookName;
                  return ListTile(
                    title: Text(book['long_name']),
                    subtitle: Text(book['short_name']),
                    selected: isSelected,
                    selectedTileColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onBookSelected(book);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
