// lib/pages/prayers_page.dart

import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/providers/prayer_provider.dart';
import 'package:devocional_nuevo/widgets/add_prayer_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PrayersPage extends StatefulWidget {
  const PrayersPage({super.key});

  @override
  State<PrayersPage> createState() => _PrayersPageState();
}

class _PrayersPageState extends State<PrayersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Oraciones',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.schedule),
              text: 'Activas',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Respondidas',
            ),
          ],
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      body: Consumer<PrayerProvider>(
        builder: (context, prayerProvider, child) {
          if (prayerProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (prayerProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    prayerProvider.errorMessage!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      prayerProvider.clearError();
                      prayerProvider.refresh();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildActivePrayersTab(context, prayerProvider),
              _buildAnsweredPrayersTab(context, prayerProvider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPrayerModal(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActivePrayersTab(
    BuildContext context,
    PrayerProvider prayerProvider,
  ) {
    final activePrayers = prayerProvider.activePrayers;

    if (activePrayers.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.schedule,
        title: 'No hay oraciones activas',
        message:
            'Crea tu primera oración tocando el botón "+" para comenzar tu viaje de fe.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => prayerProvider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activePrayers.length,
        itemBuilder: (context, index) {
          final prayer = activePrayers[index];
          return _buildPrayerCard(
            context,
            prayer,
            prayerProvider,
            isActive: true,
          );
        },
      ),
    );
  }

  Widget _buildAnsweredPrayersTab(
    BuildContext context,
    PrayerProvider prayerProvider,
  ) {
    final answeredPrayers = prayerProvider.answeredPrayers;

    if (answeredPrayers.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.check_circle_outline,
        title: 'No hay oraciones respondidas',
        message:
            'Cuando una oración sea respondida, aparecerá aquí como testimonio de la fidelidad de Dios.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => prayerProvider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: answeredPrayers.length,
        itemBuilder: (context, index) {
          final prayer = answeredPrayers[index];
          return _buildPrayerCard(
            context,
            prayer,
            prayerProvider,
            isActive: false,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(
    BuildContext context,
    Prayer prayer,
    PrayerProvider prayerProvider, {
    required bool isActive,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badge and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primary.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.schedule : Icons.check_circle,
                        size: 16,
                        color: isActive ? colorScheme.primary : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        prayer.status.displayName,
                        style: textTheme.bodySmall?.copyWith(
                          color: isActive ? colorScheme.primary : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'toggle_status':
                        if (isActive) {
                          prayerProvider.markPrayerAsAnswered(prayer.id);
                        } else {
                          prayerProvider.markPrayerAsActive(prayer.id);
                        }
                        break;
                      case 'edit':
                        _showEditPrayerModal(context, prayer, prayerProvider);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(context, prayer, prayerProvider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.check_circle : Icons.schedule,
                            size: 20,
                            color: isActive ? Colors.green : colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(isActive
                              ? 'Marcar como respondida'
                              : 'Marcar como activa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Prayer text
            Text(
              prayer.text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            
            // Footer with dates
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Creada: ${DateFormat('dd/MM/yyyy').format(prayer.createdDate)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${prayer.daysOld} ${prayer.daysOld == 1 ? 'día' : 'días'})',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            if (prayer.answeredDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Respondida: ${DateFormat('dd/MM/yyyy').format(prayer.answeredDate!)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddPrayerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPrayerModal(),
    );
  }

  void _showEditPrayerModal(
    BuildContext context,
    Prayer prayer,
    PrayerProvider prayerProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPrayerModal(
        prayerToEdit: prayer,
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Prayer prayer,
    PrayerProvider prayerProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar oración'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta oración? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              prayerProvider.deletePrayer(prayer.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}