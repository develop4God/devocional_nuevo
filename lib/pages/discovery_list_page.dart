// lib/pages/discovery_list_page.dart

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/discovery_study_viewer.dart';
import 'package:devocional_nuevo/services/discovery_progress_tracker.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Page that displays the list of available Discovery studies.
///
/// Follows the pattern from prayers_page.dart with BLoC integration.
class DiscoveryListPage extends StatefulWidget {
  const DiscoveryListPage({super.key});

  @override
  State<DiscoveryListPage> createState() => _DiscoveryListPageState();
}

class _DiscoveryListPageState extends State<DiscoveryListPage> {
  @override
  void initState() {
    super.initState();
    // Load available studies on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryBloc>().add(LoadDiscoveryStudies());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.themeMode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text('discovery.title'.tr()),
            backgroundColor: AppBarConstants.getAppBarBackgroundColor(context),
            foregroundColor: AppBarConstants.getAppBarForegroundColor(context),
            elevation: AppBarConstants.elevation,
          ),
          body: BlocBuilder<DiscoveryBloc, DiscoveryState>(
            builder: (context, state) {
              if (state is DiscoveryLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is DiscoveryError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<DiscoveryBloc>()
                              .add(LoadDiscoveryStudies());
                        },
                        child: Text('common.retry'.tr()),
                      ),
                    ],
                  ),
                );
              }

              if (state is DiscoveryLoaded) {
                if (state.availableStudyIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('discovery.no_studies'.tr()),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.availableStudyIds.length,
                  itemBuilder: (context, index) {
                    final studyId = state.availableStudyIds[index];
                    return _DiscoveryStudyCard(
                      studyId: studyId,
                      isDark: isDark,
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}

/// Card widget for displaying a Discovery study in the list.
class _DiscoveryStudyCard extends StatefulWidget {
  final String studyId;
  final bool isDark;

  const _DiscoveryStudyCard({
    required this.studyId,
    required this.isDark,
  });

  @override
  State<_DiscoveryStudyCard> createState() => _DiscoveryStudyCardState();
}

class _DiscoveryStudyCardState extends State<_DiscoveryStudyCard> {
  DiscoveryProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final tracker = getService<DiscoveryProgressTracker>();
    final progress = await tracker.getProgress(widget.studyId);
    if (mounted) {
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark ? Colors.grey[850] : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: cardColor,
      child: InkWell(
        onTap: () {
          // Load the study and navigate to viewer
          context.read<DiscoveryBloc>().add(LoadDiscoveryStudy(widget.studyId));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiscoveryStudyViewer(studyId: widget.studyId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.explore, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              // Study info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.studyId.replaceAll('-', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_progress != null && _progress!.isCompleted)
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            'discovery.completed'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'discovery.in_progress'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
