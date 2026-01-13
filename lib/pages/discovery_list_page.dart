// lib/pages/discovery_list_page.dart

import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/discovery_detail_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Page that displays a list of available Discovery studies in a grid layout.
class DiscoveryListPage extends StatefulWidget {
  const DiscoveryListPage({super.key});

  @override
  State<DiscoveryListPage> createState() => _DiscoveryListPageState();
}

class _DiscoveryListPageState extends State<DiscoveryListPage> {
  @override
  void initState() {
    super.initState();
    // Load available studies when page initializes
    context.read<DiscoveryBloc>().add(LoadDiscoveryStudies());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleText: 'discovery.discovery_studies'.tr()),
      body: BlocBuilder<DiscoveryBloc, DiscoveryState>(
        builder: (context, state) {
          if (state is DiscoveryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DiscoveryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<DiscoveryBloc>()
                            .add(LoadDiscoveryStudies());
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text('app.retry'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is DiscoveryLoaded) {
            if (state.availableStudyIds.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.explore_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'discovery.no_studies_available'.tr(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: state.availableStudyIds.length,
              itemBuilder: (context, index) {
                final studyId = state.availableStudyIds[index];
                return _StudyCard(studyId: studyId);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Card widget for displaying a single Discovery study in the grid.
class _StudyCard extends StatelessWidget {
  final String studyId;

  const _StudyCard({required this.studyId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Get current language from provider
          final languageCode =
              context.read<DevocionalProvider>().selectedLanguage;

          // Load the study
          context.read<DiscoveryBloc>().add(
                LoadDiscoveryStudy(studyId, languageCode: languageCode),
              );

          // Navigate to detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DiscoveryDetailPage(studyId: studyId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Study image placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(51),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.explore,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            // Study title and info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatStudyTitle(studyId),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Discovery',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format study ID into a readable title
  String _formatStudyTitle(String studyId) {
    // Convert "morning_star_001" to "Morning Star 001"
    return studyId
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
