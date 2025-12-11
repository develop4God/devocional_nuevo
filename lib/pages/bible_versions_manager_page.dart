import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/bible_version/bible_version_bloc.dart';
import '../blocs/bible_version/bible_version_event.dart';
import '../blocs/bible_version/bible_version_state.dart';
import '../extensions/string_extensions.dart';
import '../providers/bible_selected_version_provider.dart';
import '../providers/localization_provider.dart';
import '../services/service_locator.dart';
import '../utils/constants.dart';
import '../widgets/app_bar_constants.dart';

/// Page for managing Bible version downloads.
///
/// Displays available Bible versions organized by language,
/// allows downloading new versions and deleting existing ones.
class BibleVersionsManagerPage extends StatelessWidget {
  const BibleVersionsManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BibleVersionBloc(
        repository: getService<BibleVersionRepository>(),
      )..add(const LoadBibleVersionsEvent()),
      child: const _BibleVersionsManagerView(),
    );
  }
}

class _BibleVersionsManagerView extends StatelessWidget {
  const _BibleVersionsManagerView();

  @override
  Widget build(BuildContext context) {
    final currentLanguageCode =
        context.watch<LocalizationProvider>().currentLocale.languageCode;
    final currentLanguageName =
        Constants.supportedLanguages[currentLanguageCode] ??
            currentLanguageCode;

    return Scaffold(
      appBar: CustomAppBar(
        titleText: 'bible_version.manager_title'.tr(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BibleVersionBloc>().add(
                    const LoadBibleVersionsEvent(forceRefresh: true),
                  );
            },
            tooltip: 'bible_version.retry'.tr(),
          ),
        ],
      ),
      body: BlocBuilder<BibleVersionBloc, BibleVersionState>(
        builder: (context, state) {
          if (state is BibleVersionInitial || state is BibleVersionLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is BibleVersionError) {
            return _ErrorView(
              errorCode: state.errorCode,
              context: state.context,
              onRetry: () {
                context.read<BibleVersionBloc>().add(
                      const LoadBibleVersionsEvent(forceRefresh: true),
                    );
              },
            );
          }

          if (state is BibleVersionLoaded) {
            final filteredVersions = state.versions
                .where((v) => v.metadata.language == currentLanguageCode)
                .toList();
            // Ordenar: la versión seleccionada primero
            final selectedVersion =
                context.read<BibleSelectedVersionProvider>().selectedVersion;
            filteredVersions.sort((a, b) {
              if (a.metadata.id == selectedVersion) return -1;
              if (b.metadata.id == selectedVersion) return 1;
              return 0;
            });
            return _VersionsList(
              versions: filteredVersions,
              languageName: currentLanguageName,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Utility functions for Bible version UI.
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Returns a localized error message for the given error code.
String _getLocalizedError(
    BibleVersionErrorCode errorCode, Map<String, dynamic>? context) {
  switch (errorCode) {
    case BibleVersionErrorCode.network:
      return 'bible_version.error_network'.tr();
    case BibleVersionErrorCode.storage:
      final size = context?['requiredBytes'] as int?;
      if (size != null) {
        return 'bible_version.error_storage'.tr({'size': _formatBytes(size)});
      }
      return 'bible_version.error_storage'.tr({'size': '?'});
    case BibleVersionErrorCode.corrupted:
      return 'bible_version.error_corrupted'.tr();
    case BibleVersionErrorCode.notFound:
      return 'bible_version.error_not_found'.tr();
    case BibleVersionErrorCode.metadataParsing:
      return 'bible_version.error_metadata_parsing'.tr();
    case BibleVersionErrorCode.maxRetriesExceeded:
      final attempts = context?['attempts'] as int?;
      return 'bible_version.error_max_retries'
          .tr({'attempts': attempts?.toString() ?? '3'});
    case BibleVersionErrorCode.decompression:
      return 'bible_version.error_decompression'.tr();
    case BibleVersionErrorCode.metadataValidation:
      return 'bible_version.error_metadata_validation'.tr();
    case BibleVersionErrorCode.unknown:
      return 'bible_version.error_unknown'.tr();
  }
}

class _ErrorView extends StatelessWidget {
  final BibleVersionErrorCode errorCode;
  final Map<String, dynamic>? context;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.errorCode,
    this.context,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _getLocalizedError(errorCode, this.context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('bible_version.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionsList extends StatelessWidget {
  final List<BibleVersionWithState> versions;
  final String languageName;

  const _VersionsList({
    required this.versions,
    required this.languageName,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _LanguageSection(
          language: languageName,
          versions: versions,
        ),
      ],
    );
  }
}

class _LanguageSection extends StatelessWidget {
  final String language;
  final List<BibleVersionWithState> versions;

  const _LanguageSection({
    required this.language,
    required this.versions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            language,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...versions.map((version) => _VersionTile(version: version)),
        const Divider(),
      ],
    );
  }
}

class _VersionTile extends StatelessWidget {
  final BibleVersionWithState version;

  const _VersionTile({required this.version});

  @override
  Widget build(BuildContext context) {
    final metadata = version.metadata;
    final colorScheme = Theme.of(context).colorScheme;
    // Obtener nombre amigable
    final displayName = CopyrightUtils.getBibleVersionDisplayName(
      metadata.language,
      metadata.name,
    );
    return ListTile(
      title: Text(displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata.description.isNotEmpty)
            Text(
              metadata.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            _formatSize(metadata.uncompressedSizeBytes),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          if (version.state == DownloadState.failed &&
              version.errorCode != null)
            Text(
              ('bible_version.${_getErrorKey(version.errorCode!)}')
                  .tr(version.errorContext),
              style: TextStyle(color: colorScheme.error),
            ),
        ],
      ),
      trailing: _buildTrailing(context),
      isThreeLine: true,
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final bloc = context.read<BibleVersionBloc>();
    final colorScheme = Theme.of(context).colorScheme;
    // --- NUEVO: Bloquear eliminación de la última versión bíblica descargada y activa ---
    final versionsList =
        (context.findAncestorWidgetOfExactType<_LanguageSection>()?.versions) ??
            [];
    final downloaded =
        versionsList.where((v) => v.state == DownloadState.downloaded).toList();
    final isLastDownloaded = downloaded.length == 1 &&
        downloaded.first.metadata.id == version.metadata.id;
    // ---
    switch (version.state) {
      case DownloadState.notDownloaded:
        return IconButton(
          icon: Icon(Icons.file_download_outlined, color: colorScheme.primary),
          onPressed: () {
            bloc.add(DownloadVersionEvent(version.metadata.id));
          },
          tooltip: 'bible_version.download'.tr(),
        );

      case DownloadState.queued:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              '# 24{version.queuePosition}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        );

      case DownloadState.downloading:
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: version.progress > 0 ? version.progress : null,
                strokeWidth: 2,
              ),
              Text(
                '${(version.progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        );

      case DownloadState.paused:
        return IconButton(
          icon: Icon(Icons.play_arrow, color: colorScheme.primary),
          onPressed: () {
            bloc.add(DownloadVersionEvent(version.metadata.id));
          },
          tooltip: 'bible_version.download'.tr(),
        );

      case DownloadState.validating:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'bible_version.validating'.tr(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );

      case DownloadState.downloaded:
        // --- UI intuitiva: si es la última versión descargada, solo mostrar el check, sin basurero ---
        if (isLastDownloaded) {
          return Tooltip(
            message: 'bible_version.cannot_delete_last'.tr(),
            child: Icon(Icons.file_download_done_rounded,
                color: colorScheme.primary),
          );
        }
        // Si hay más de una versión descargada, mostrar check y basurero normalmente
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_download_done_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: 'bible_version.delete'.tr(),
            ),
          ],
        );

      case DownloadState.failed:
        return IconButton(
          icon: Icon(Icons.refresh, color: colorScheme.error),
          onPressed: () {
            bloc.add(DownloadVersionEvent(version.metadata.id));
          },
          tooltip: 'bible_version.retry'.tr(),
        );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('bible_version.delete_confirmation'.tr()),
        content: Text(
          CopyrightUtils.getBibleVersionDisplayName(
            version.metadata.language,
            version.metadata.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('app.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<BibleVersionBloc>().add(
                    DeleteVersionEvent(version.metadata.id),
                  );
            },
            child: Text(
              'bible_version.delete'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    return _formatBytes(bytes);
  }

  String _getErrorKey(BibleVersionErrorCode errorCode) {
    switch (errorCode) {
      case BibleVersionErrorCode.network:
        return 'error_network';
      case BibleVersionErrorCode.storage:
        return 'error_storage';
      case BibleVersionErrorCode.corrupted:
        return 'error_corrupted';
      case BibleVersionErrorCode.notFound:
        return 'error_not_found';
      case BibleVersionErrorCode.metadataParsing:
        return 'error_metadata_parsing';
      case BibleVersionErrorCode.maxRetriesExceeded:
        return 'error_max_retries';
      case BibleVersionErrorCode.decompression:
        return 'error_decompression';
      case BibleVersionErrorCode.metadataValidation:
        return 'error_metadata_validation';
      case BibleVersionErrorCode.unknown:
        return 'error_unknown';
    }
  }
}

// Traducciones para el tooltip de eliminación bloqueada
// Español
// i18n/es.json
// "bible_version.cannot_delete_last": "No se puede borrar la última versión bíblica",
// Inglés
// i18n/en.json
// "bible_version.cannot_delete_last": "Cannot delete the last Bible version",
// Francés
// i18n/fr.json
// "bible_version.cannot_delete_last": "Impossible de supprimer la dernière version biblique",
// Portugués
// i18n/pt.json
// "bible_version.cannot_delete_last": "Não é possível excluir a última versão bíblica",
// Japonés
// i18n/ja.json
// "bible_version.cannot_delete_last": "最後の聖書バージョンは削除できません",
