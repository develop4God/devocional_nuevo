import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_event.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_event.dart';
import 'package:devocional_nuevo/blocs/thanksgiving_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:devocional_nuevo/widgets/add_prayer_modal.dart';
import 'package:devocional_nuevo/widgets/add_thanksgiving_modal.dart';
import 'package:devocional_nuevo/widgets/answer_prayer_modal.dart';
import 'package:devocional_nuevo/widgets/edit_answered_comment_modal.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _tabController = TabController(length: 3, vsync: this);

    // Trigger initial loading of prayers and thanksgivings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrayerBloc>().add(LoadPrayers());
      context.read<ThanksgivingBloc>().add(LoadThanksgivings());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Build a modern count badge widget for tab headers
  Widget _buildCountBadge(int count, Color backgroundColor) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: themeState.systemUiOverlayStyle,
        child: Scaffold(
          appBar: CustomAppBar(
            titleText: 'prayer.my_prayers'.tr(),
          ),
          body: Column(
            children: [
              // Container para las tabs en la parte blanca
              Container(
                color: colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: colorScheme.primary,
                        labelColor: colorScheme.primary,
                        unselectedLabelColor:
                            colorScheme.onSurface.withValues(alpha: 0.6),
                        labelPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        tabs: [
                          // Tab 1: Active Prayers with count badge
                          Tab(
                            height: 72,
                            child: BlocBuilder<PrayerBloc, PrayerState>(
                              builder: (context, state) {
                                final count = state is PrayerLoaded
                                    ? state.activePrayersCount
                                    : 0;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.schedule, size: 22),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'prayer.prayers'.tr(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                          ),
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'prayer.active'.tr(),
                                            textAlign: TextAlign.center,
                                            style:
                                                const TextStyle(fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (count > 0)
                                      Positioned(
                                        right: -8,
                                        top: -4,
                                        child: _buildCountBadge(
                                            count,
                                            colorScheme.primary
                                                .withValues(alpha: 0.4)),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          // Tab 2: Answered Prayers with count badge
                          Tab(
                            height: 72,
                            child: BlocBuilder<PrayerBloc, PrayerState>(
                              builder: (context, state) {
                                final count = state is PrayerLoaded
                                    ? state.answeredPrayersCount
                                    : 0;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_outline,
                                            size: 22),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'prayer.prayers'.tr(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                          ),
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'prayer.answered_prayers'.tr(),
                                            textAlign: TextAlign.center,
                                            style:
                                                const TextStyle(fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (count > 0)
                                      Positioned(
                                        right: -8,
                                        top: -4,
                                        child: _buildCountBadge(
                                            count, Colors.green.shade200),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          // Tab 3: Thanksgivings with count badge
                          Tab(
                            height: 72,
                            child: BlocBuilder<ThanksgivingBloc,
                                ThanksgivingState>(
                              builder: (context, state) {
                                final count = state is ThanksgivingLoaded
                                    ? state.thanksgivings.length
                                    : 0;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('☺️',
                                            style: TextStyle(fontSize: 22)),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'thanksgiving.thanksgivings'.tr(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (count > 0)
                                      Positioned(
                                        right: -8,
                                        top: -4,
                                        child: _buildCountBadge(
                                            count, Colors.pink.shade200),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // El contenido expandido
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Active Prayers
                    BlocBuilder<PrayerBloc, PrayerState>(
                      builder: (context, state) {
                        if (state is PrayerLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is PrayerError) {
                          return _buildErrorState(context, state.message, () {
                            context.read<PrayerBloc>().add(RefreshPrayers());
                          });
                        }
                        if (state is PrayerLoaded) {
                          return _buildActivePrayersTab(context, state);
                        }
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                    // Tab 2: Answered Prayers
                    BlocBuilder<PrayerBloc, PrayerState>(
                      builder: (context, state) {
                        if (state is PrayerLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is PrayerError) {
                          return _buildErrorState(context, state.message, () {
                            context.read<PrayerBloc>().add(RefreshPrayers());
                          });
                        }
                        if (state is PrayerLoaded) {
                          return _buildAnsweredPrayersTab(context, state);
                        }
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                    // Tab 3: Thanksgivings
                    BlocBuilder<ThanksgivingBloc, ThanksgivingState>(
                      builder: (context, state) {
                        if (state is ThanksgivingLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is ThanksgivingError) {
                          return _buildErrorState(context, state.message, () {
                            context
                                .read<ThanksgivingBloc>()
                                .add(RefreshThanksgivings());
                          });
                        }
                        if (state is ThanksgivingLoaded) {
                          return _buildThanksgivingsTab(context, state);
                        }
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showAddPrayerOrThanksgivingChoice();
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add),
          ),
        ));
  }

  Widget _buildActivePrayersTab(
    BuildContext context,
    PrayerLoaded state,
  ) {
    final activePrayers = state.activePrayers;

    if (activePrayers.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icon(
          Icons.schedule,
          size: 80,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
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
        icon: Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
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
    required Widget icon,
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
            icon,
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
                            _showAnswerPrayerModal(context, prayer);
                          } else {
                            context
                                .read<PrayerBloc>()
                                .add(MarkPrayerAsActive(prayer.id));
                          }
                          break;
                        case 'edit':
                          _showEditPrayerModal(context, prayer);
                          break;
                        case 'edit_answer':
                          _showEditAnsweredCommentModal(context, prayer);
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
                      // Show "Edit" option for active prayers OR answered prayers WITHOUT comment
                      if (isActive ||
                          (prayer.answeredComment == null ||
                              prayer.answeredComment!.isEmpty))
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
                      // Show "Edit Answer" option for answered prayers WITH comment
                      if (!isActive &&
                          prayer.answeredComment != null &&
                          prayer.answeredComment!.isNotEmpty)
                        PopupMenuItem(
                          value: 'edit_answer',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20, color: Colors.green),
                              const SizedBox(width: 12),
                              Text('prayer.edit_answered_comment'.tr()),
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
            const SizedBox(height: 6), // Reducido para autofit

            // Prayer text
            Text(
              prayer.text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8), // Reducido para autofit

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
                  'prayer.created'.tr({
                    'date': DateFormat('dd/MM/yyyy').format(prayer.createdDate)
                  }),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  prayer.daysOld == 1
                      ? 'prayer.days_old_single'
                          .tr({'days': prayer.daysOld.toString()})
                      : 'prayer.days_old_plural'
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
                    'prayer.answered'.tr({
                      'date':
                          DateFormat('dd/MM/yyyy').format(prayer.answeredDate!)
                    }),
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (prayer.answeredComment != null &&
                  prayer.answeredComment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.comment,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prayer.answeredComment!,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  void _showAnswerPrayerModal(
    BuildContext context,
    Prayer prayer,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnswerPrayerModal(
        prayer: prayer,
      ),
    );
  }

  void _showEditAnsweredCommentModal(
    BuildContext context,
    Prayer prayer,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditAnsweredCommentModal(
        prayer: prayer,
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

  void _showAddThanksgivingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddThanksgivingModal(),
    );
  }

  void _showAddPrayerOrThanksgivingChoice() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'devotionals.choose_option'.tr(),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showAddPrayerModal(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '🙏',
                              style: TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'prayer.prayer'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showAddThanksgivingModal(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '☺️',
                              style: TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'thanksgiving.thanksgiving'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
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
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text('prayer.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildThanksgivingsTab(
    BuildContext context,
    ThanksgivingLoaded state,
  ) {
    final thanksgivings = state.thanksgivings;

    if (thanksgivings.isEmpty) {
      return _buildEmptyState(
        context,
        icon: const Text('☺️', style: TextStyle(fontSize: 60)),
        title: 'thanksgiving.no_thanksgivings_title'.tr(),
        message: 'thanksgiving.no_thanksgivings_description'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ThanksgivingBloc>().add(RefreshThanksgivings());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: thanksgivings.length,
        itemBuilder: (context, index) {
          final thanksgiving = thanksgivings[index];
          return _buildThanksgivingCard(context, thanksgiving);
        },
      ),
    );
  }

  Widget _buildThanksgivingCard(
    BuildContext context,
    Thanksgiving thanksgiving,
  ) {
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
            // Header con acciones (sin emoji por línea)
            Row(
              children: [
                Expanded(
                  child: Text(
                    thanksgiving.text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  child: PopupMenuButton<String>(
                    padding: const EdgeInsets.all(8),
                    iconSize: 24,
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditThanksgivingModal(context, thanksgiving);
                          break;
                        case 'delete':
                          _showDeleteThanksgivingConfirmation(
                              context, thanksgiving);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 12),
                            Text('thanksgiving.edit_thanksgiving'.tr()),
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
            const SizedBox(height: 6),
            // Mostrar el texto completo de thanksgiving debajo del header
            Text(
              thanksgiving.text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),

            // Footer with date
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'thanksgiving.created'.tr({
                    'date': DateFormat('dd/MM/yyyy')
                        .format(thanksgiving.createdDate)
                  }),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  thanksgiving.daysOld == 1
                      ? 'thanksgiving.days_old_single'
                          .tr({'days': thanksgiving.daysOld.toString()})
                      : 'thanksgiving.days_old_plural'
                          .tr({'days': thanksgiving.daysOld.toString()}),
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditThanksgivingModal(
    BuildContext context,
    Thanksgiving thanksgiving,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddThanksgivingModal(
        thanksgivingToEdit: thanksgiving,
      ),
    );
  }

  void _showDeleteThanksgivingConfirmation(
    BuildContext context,
    Thanksgiving thanksgiving,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('thanksgiving.delete_thanksgiving'.tr()),
        content: Text(
          'thanksgiving.delete_confirmation'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('app.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<ThanksgivingBloc>()
                  .add(DeleteThanksgiving(thanksgiving.id));
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
