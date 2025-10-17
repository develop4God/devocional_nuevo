import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

class BibleReaderActionModal extends StatelessWidget {
  final String selectedVersesText;
  final String selectedVersesReference;
  final VoidCallback onSave;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onImage;
  final bool areVersesSaved;
  final VoidCallback? onDeleteSaved;

  const BibleReaderActionModal({
    super.key,
    required this.selectedVersesText,
    required this.selectedVersesReference,
    required this.onSave,
    required this.onCopy,
    required this.onShare,
    required this.onImage,
    this.areVersesSaved = false,
    this.onDeleteSaved,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double maxModalHeight = MediaQuery.of(context).size.height * 0.6;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close (X) button and menu button (if verses are saved), top-right
          Row(
            children: [
              const Spacer(),
              if (areVersesSaved && onDeleteSaved != null)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: colorScheme.onSurfaceVariant, size: 24),
                  tooltip: 'bible.close'.tr(),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDeleteSaved!();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Text('bible.delete_saved_verses'.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close,
                    color: colorScheme.onSurfaceVariant, size: 26),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'bible.close'.tr(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(102),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Selected verses text (scrollable, grows up to 60% of screen)
          Container(
            constraints: BoxConstraints(
              maxHeight: maxModalHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Text(
                selectedVersesText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Reference text
          Text(
            selectedVersesReference,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Action buttons in a grid -- moved further from the bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start, // Move icons up
              children: [
                _buildActionButton(
                  context: context,
                  icon:
                      areVersesSaved ? Icons.bookmark : Icons.bookmark_outline,
                  label: areVersesSaved
                      ? 'bible.saved_verses'.tr()
                      : 'bible.save_verses'.tr(),
                  onTap: () {
                    onSave();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final colorScheme = Theme.of(context).colorScheme;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          areVersesSaved
                              ? 'bible.deleted_marked_verses'.tr()
                              : 'bible.save_marked_verses'.tr(),
                          style: TextStyle(color: colorScheme.onSecondary),
                        ),
                        backgroundColor: colorScheme.secondary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.content_copy,
                  label: 'bible.copy'.tr(),
                  onTap: onCopy,
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.share,
                  label: 'bible.share'.tr(),
                  onTap: onShare,
                ),
                /*_buildActionButton( //Comming soon
          context: context,
          icon: Icons.image_outlined,
          label: 'Imagen',
          onTap: onImage,
        ),*/
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0), // Move icon up a bit
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 4),
          // less bottom padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
