import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/providers/prayer_provider.dart';
import 'package:devocional_nuevo/widgets/add_prayer_modal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Widget personalizado para el AppBar de la aplicación.
/// Utiliza los colores y estilos del tema de la app.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.titleText,
    this.bottom,
  });

  @override
  Size get preferredSize {
    // Calcula la altura total del AppBar con el widget inferior.
    final double appBarHeight =
        kToolbarHeight + (bottom?.preferredSize.height ?? 0);
    return Size.fromHeight(appBarHeight);
  }

  @override
  Widget build(BuildContext context) {
    // Obtiene el tema actual para usar sus colores.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AppBar(
      title: Text(
        titleText,
        style: textTheme.titleLarge?.copyWith(
          // El color del texto se adapta al color de fondo primario.
          color: colorScheme.onPrimary,
        ),
      ),
      // El color de fondo del AppBar es el color primario del tema.
      backgroundColor: colorScheme.primary,
      iconTheme: IconThemeData(
        // El color de los iconos se adapta al color del fondo primario.
        color: colorScheme.onPrimary,
      ),
      // Añade el widget inferior (TabBar) si existe.
      bottom: bottom,
    );
  }
}

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

    return Scaffold(
      appBar: const CustomAppBar(
        titleText: 'Mis Oraciones',
      ),
      body: Column(
        children: [
          // Container para las tabs en la parte blanca
          Container(
            color: colorScheme.surface,
            child: TabBar(
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
              // Cambiar colores para fondo blanco
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              unselectedLabelColor:
                  colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          // El contenido expandido
          Expanded(
            child: Consumer<PrayerProvider>(
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
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
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
          ),
        ],
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
              color: colorScheme.primary.withValues(alpha: 0.5),
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
                color: colorScheme.onSurface.withValues(alpha: 0.7),
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
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
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
                Container(
                  // Dar más área de toque al botón
                  padding: const EdgeInsets.all(4),
                  child: PopupMenuButton<String>(
                    // Aumentar el área de toque
                    padding: const EdgeInsets.all(8),
                    iconSize: 24,
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
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
                          _showDeleteConfirmation(
                              context, prayer, prayerProvider);
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
                              color:
                                  isActive ? Colors.green : colorScheme.primary,
                            ),
                            const SizedBox(width: 12), // Más espacio
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
                            SizedBox(width: 12),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Eliminar',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Creada: ${DateFormat('dd/MM/yyyy').format(prayer.createdDate)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
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
