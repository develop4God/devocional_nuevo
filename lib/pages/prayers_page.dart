import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/widgets/add_prayer_modal.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    // Trigger initial loading of prayers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrayerBloc>().add(LoadPrayers());
    });
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
      appBar: CustomAppBar(
        titleText: 'prayer.my_prayers'.tr(),
      ),
      body: Column(
        children: [
          // Container para las tabs en la parte blanca
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.schedule),
                  text: 'prayer.active'.tr(),
                ),
                Tab(
                  icon: const Icon(Icons.check_circle_outline),
                  text: 'prayer.answered'.tr(),
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
            child: BlocBuilder<PrayerBloc, PrayerState>(
              builder: (context, state) {
                if (state is PrayerLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is PrayerError) {
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
                          state.message,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.error,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<PrayerBloc>().add(RefreshPrayers());
                          },
                          child: Text('prayer.retry'.tr()),
                        ),
                      ],
                    ),
                  );
                }

                if (state is PrayerLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActivePrayersTab(context, state),
                      _buildAnsweredPrayersTab(context, state),
                    ],
                  );
                }

                return const Center(
                  child: CircularProgressIndicator(),
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
    PrayerLoaded state,
  ) {
    final activePrayers = state.activePrayers;

    if (activePrayers.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.schedule,
        title: 'prayer.no_active_prayers_title'.tr(),
        message: 'prayer.no_active_prayers_description'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PrayerBloc>().add(RefreshPrayers());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activePrayers.length,
        itemBuilder: (context, index) {
          final prayer = activePrayers[index];
          return _buildPrayerCard(
            context,
            prayer,
            state,
            isActive: true,
          );
        },
      ),
    );
  }

  Widget _buildAnsweredPrayersTab(
    BuildContext context,
    PrayerLoaded state,
  ) {
    final answeredPrayers = state.answeredPrayers;

    if (answeredPrayers.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.check_circle_outline,
        title: 'prayer.no_answered_prayers_title'.tr(),
        message: 'prayer.no_answered_prayers_description'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PrayerBloc>().add(RefreshPrayers());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: answeredPrayers.length,
        itemBuilder: (context, index) {
          final prayer = answeredPrayers[index];
          return _buildPrayerCard(
            context,
            prayer,
            state,
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
    PrayerLoaded state, {
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
                        isActive ? Icons.schedule : Icons.check_circle_outline,
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
                            context
                                .read<PrayerBloc>()
                                .add(MarkPrayerAsAnswered(prayer.id));
                          } else {
                            context
                                .read<PrayerBloc>()
                                .add(MarkPrayerAsActive(prayer.id));
                          }
                          break;
                        case 'edit':
                          _showEditPrayerModal(context, prayer);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context, prayer);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_status',
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.check_circle_outline
                                  : Icons.schedule,
                              size: 20,
                              color:
                                  isActive ? Colors.green : colorScheme.primary,
                            ),
                            const SizedBox(width: 12), // Más espacio
                            Text(isActive
                                ? 'prayer.mark_as_answered'.tr()
                                : 'prayer.mark_as_active'.tr()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 12),
                            Text('prayer.edit_prayer'.tr()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete,
                                size: 20, color: Colors.red),
                            const SizedBox(width: 12),
                            Text('app.delete'.tr(),
                                style: const TextStyle(color: Colors.red)),
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
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'prayers.created'.tr({
                    'date': DateFormat('dd/MM/yyyy').format(prayer.createdDate)
                  }),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  prayer.daysOld == 1
                      ? 'prayers.days_old_single'
                          .tr({'days': prayer.daysOld.toString()})
                      : 'prayers.days_old_plural'
                          .tr({'days': prayer.daysOld.toString()}),
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
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'prayers.answered'.tr({
                      'date':
                          DateFormat('dd/MM/yyyy').format(prayer.answeredDate!)
                    }),
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
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('prayer.delete_prayer'.tr()),
        content: Text(
          'prayer.delete_confirmation'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('app.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PrayerBloc>().add(DeletePrayer(prayer.id));
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('app.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
