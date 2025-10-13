import 'package:flutter/material.dart';

class BibleReaderActionModal extends StatelessWidget {
  final String selectedVersesText;
  final String selectedVersesReference;
  final VoidCallback onSave;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onImage;

  const BibleReaderActionModal({
    super.key,
    required this.selectedVersesText,
    required this.selectedVersesReference,
    required this.onSave,
    required this.onCopy,
    required this.onShare,
    required this.onImage,
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
                  icon: Icons.bookmark_outline,
                  label: 'Guardar', // Replace with tr() if needed
                  onTap: onSave,
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.content_copy,
                  label: 'Copiar',
                  onTap: onCopy,
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.share,
                  label: 'Compartir',
                  onTap: onShare,
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.image_outlined,
                  label: 'Imagen',
                  onTap: onImage,
                ),
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
