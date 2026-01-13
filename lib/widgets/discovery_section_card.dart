// lib/widgets/discovery_section_card.dart

import 'package:devocional_nuevo/models/discovery_section_model.dart';
import 'package:flutter/material.dart';

/// Card widget for displaying a Discovery section.
///
/// Simple card that displays section content (natural or scripture).
class DiscoverySectionCard extends StatelessWidget {
  final DiscoverySection section;
  final String studyId;
  final int sectionIndex;
  final bool isDark;
  final String? versiculoClave;

  const DiscoverySectionCard({
    super.key,
    required this.section,
    required this.studyId,
    required this.sectionIndex,
    required this.isDark,
    this.versiculoClave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (versiculoClave != null && versiculoClave!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.menu_book, color: Colors.blue[700], size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    versiculoClave!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (section.icono != null) ...[
            Center(
              child: Text(
                section.icono!,
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (section.titulo != null) ...[
            Text(
              section.titulo!,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (section.contenido != null) ...[
            Text(
              section.contenido!,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
          if (section.pasajes != null && section.pasajes!.isNotEmpty) ...[
            for (final pasaje in section.pasajes!)
              _ScripturePassageCard(pasaje: pasaje, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _ScripturePassageCard extends StatelessWidget {
  final ScripturePassage pasaje;
  final bool isDark;

  const _ScripturePassageCard({
    required this.pasaje,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? Colors.grey[800] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pasaje.referencia,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pasaje.texto,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (pasaje.aplicacion != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pasaje.aplicacion!,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
