import 'package:auto_size_text/auto_size_text.dart';
import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/blocs/bible_version/bible_version_bloc.dart';
import 'package:devocional_nuevo/blocs/bible_version/bible_version_event.dart';
import 'package:devocional_nuevo/blocs/bible_version/bible_version_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/providers/bible_selected_version_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

/// Modern and intuitive drawer for Bible Reader with version selection and downloads.
/// Versions are dynamically loaded from GitHub - new versions uploaded to the repository
/// automatically appear in the drawer without app changes.
class BibleReaderDrawer extends StatelessWidget {
  final List<BibleVersion> availableVersions;
  final BibleVersion? selectedVersion;
  final Function(BibleVersion) onVersionSelected;

  const BibleReaderDrawer({
    super.key,
    required this.availableVersions,
    this.selectedVersion,
    required this.onVersionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLanguage =
        Provider.of<BibleSelectedVersionProvider>(context, listen: false)
            .selectedLanguage;
    return BlocProvider(
      create: (context) => BibleVersionBloc(
        repository: getService<BibleVersionRepository>(),
      )..add(LoadBibleVersionsEvent(languageCode: selectedLanguage)),
      child: _BibleReaderDrawerContent(
        availableVersions: availableVersions,
        selectedVersion: selectedVersion,
        onVersionSelected: onVersionSelected,
      ),
    );
  }
}

class _BibleReaderDrawerContent extends StatefulWidget {
  final List<BibleVersion> availableVersions;
  final BibleVersion? selectedVersion;
  final Function(BibleVersion) onVersionSelected;

  const _BibleReaderDrawerContent({
    required this.availableVersions,
    this.selectedVersion,
    required this.onVersionSelected,
  });

  @override
  State<_BibleReaderDrawerContent> createState() =>
      _BibleReaderDrawerContentState();
}

class _BibleReaderDrawerContentState extends State<_BibleReaderDrawerContent> {
  String? _pendingDownloadVersionId;
  bool _isBlocking = false;

  void _setBlocking(bool value) {
    if (_isBlocking != value) {
      setState(() {
        _isBlocking = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    double? downloadProgress;
    String? downloadVersionName;

    // Obtener progreso real si hay descarga activa
    final blocState = context.watch<BibleVersionBloc>().state;
    if (_isBlocking &&
        _pendingDownloadVersionId != null &&
        blocState is BibleVersionLoaded) {
      final targetVersion = blocState.versions.firstWhere(
        (v) => v.metadata.id == _pendingDownloadVersionId,
        orElse: () => blocState.versions.first,
      );
      downloadProgress = targetVersion.progress;
      downloadVersionName = targetVersion.metadata.name;
    }

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: BlocListener<BibleVersionBloc, BibleVersionState>(
          listener: (context, state) {
            // Detectar si hay descarga activa
            bool downloading = false;
            if (state is BibleVersionLoaded &&
                _pendingDownloadVersionId != null) {
              final targetVersion = state.versions.firstWhere(
                (v) => v.metadata.id == _pendingDownloadVersionId,
                orElse: () => state.versions.first,
              );
              if (targetVersion.state == DownloadState.downloaded) {
                _switchToVersion(context, targetVersion);
                _pendingDownloadVersionId = null;
                downloading = false;
              } else if (targetVersion.state == DownloadState.downloading ||
                  targetVersion.state == DownloadState.queued) {
                downloading = true;
              }
            }
            // Si hay error, desbloquear
            if (state is BibleVersionError) {
              downloading = false;
              _pendingDownloadVersionId = null;
            }
            _setBlocking(downloading);
          },
          child: Stack(
            children: [
              AbsorbPointer(
                absorbing: _isBlocking,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      height: 56,
                      width: double.infinity,
                      color: colorScheme.primary,
                      child: Stack(
                        children: [
                          Center(
                            child: AutoSizeText(
                              'bible.drawer_title'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close_outlined,
                                  color: Colors.white),
                              onPressed: _isBlocking
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              tooltip: 'drawer.close'.tr(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: BlocBuilder<BibleVersionBloc, BibleVersionState>(
                        builder: (context, state) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: ListView(
                              children: [
                                const SizedBox(height: 15),
                                // Selected version section
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    'bible.current_version'.tr(),
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Current version chip
                                if (widget.selectedVersion != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            colorScheme.primary.withAlpha(100),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: colorScheme.primary,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: AutoSizeText(
                                            '${widget.selectedVersion!.name} (${widget.selectedVersion!.language})',
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 20),

                                // Available versions grouped by language
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    'bible.available_versions'.tr(),
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // Show loading indicator if bloc is still loading
                                if (state is BibleVersionLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (state is BibleVersionLoaded)
                                  _buildVersionsList(context, state)
                                else if (state is BibleVersionError)
                                  _buildLocalVersionsList(context)
                                else
                                  _buildLocalVersionsList(context),

                                Divider(
                                  height: 32,
                                  color: colorScheme.outline.withAlpha(100),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_isBlocking)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withAlpha(89), // 0.35 * 255 ≈ 89
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: (downloadProgress != null &&
                                          downloadProgress > 0 &&
                                          downloadProgress <= 1)
                                      ? downloadProgress
                                      : null,
                                  strokeWidth: 5,
                                  color: Colors.white,
                                ),
                                if (downloadProgress != null &&
                                    downloadProgress > 0 &&
                                    downloadProgress <= 1)
                                  Text(
                                    '${(downloadProgress * 100).toStringAsFixed(0)}%',
                                    style: textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            downloadVersionName != null
                                ? 'Descargando "$downloadVersionName"...'
                                : 'Descargando versión bíblica... Por favor espera.',
                            style: textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ); // closes Drawer
  }

  /// Build versions list from BLoC state (dynamic from GitHub)
  Widget _buildVersionsList(BuildContext context, BibleVersionLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bibleProvider =
        Provider.of<BibleSelectedVersionProvider>(context, listen: false);

    // Agrupar versiones por idioma
    final versionsByLanguage = <String, List<BibleVersionWithState>>{};
    for (final version in state.versions) {
      final lang = version.metadata.language;
      versionsByLanguage.putIfAbsent(lang, () => []).add(version);
    }

    // Solo mostrar el idioma actual
    final currentLanguage = bibleProvider.selectedLanguage;
    var versions = versionsByLanguage[currentLanguage] ?? [];
    final languageName =
        BibleVersionRepository.languageNames[currentLanguage] ??
            currentLanguage;

    // Ordenar: la versión seleccionada primero
    final selectedVersionId = bibleProvider.selectedVersion;
    // Filtrar la versión seleccionada para que NO aparezca en la lista de disponibles
    versions =
        versions.where((v) => v.metadata.id != selectedVersionId).toList();

    // Contar cuántas versiones descargadas hay
    final downloaded =
        versions.where((v) => v.state == DownloadState.downloaded).toList();
    final isOnlyOneDownloaded = downloaded.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de idioma
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            languageName,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Mostrar solo versiones válidas (descartando corruptas)
        ...versions
            .where((version) =>
                version.errorCode != BibleVersionErrorCode.corrupted)
            .map((version) {
          final isSelected = version.metadata.id == selectedVersionId;
          final isDownloaded = version.state == DownloadState.downloaded;
          final isDownloading = version.state == DownloadState.downloading;
          final isQueued = version.state == DownloadState.queued;
          final isLastDownloaded = isDownloaded && isOnlyOneDownloaded;

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isDownloading || isQueued
                ? null
                : () => _handleVersionTap(
                      context,
                      version,
                      isDownloaded,
                      isDownloading,
                    ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: isSelected
                  ? BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(80),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.menu_book_outlined,
                    color:
                        isSelected ? colorScheme.primary : colorScheme.outline,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          CopyrightUtils.getBibleVersionDisplayName(
                            version.metadata.language,
                            version.metadata.name,
                          ),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                        ),
                        AutoSizeText(
                          version.metadata.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withAlpha(180),
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                        ),
                        AutoSizeText(
                          version.metadata.languageName,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withAlpha(150),
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  // Trailing icon: descarga, progreso, check, basurero
                  if (isDownloading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: version.progress > 0 ? version.progress : null,
                        color: colorScheme.primary,
                      ),
                    )
                  else if (isQueued)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  else if (isDownloaded)
                    isLastDownloaded
                        ? Tooltip(
                            message: 'bible_version.cannot_delete_last'.tr(),
                            child: Icon(Icons.file_download_done_rounded,
                                color: colorScheme.primary, size: 22),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.file_download_done_rounded,
                                  color: colorScheme.primary, size: 22),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: colorScheme.error, size: 22),
                                onPressed: () {
                                  _showDeleteConfirmation(context, version);
                                },
                                tooltip: 'bible_version.delete'.tr(),
                              ),
                            ],
                          )
                  else
                    IconButton(
                      icon: Icon(Icons.file_download_outlined,
                          color: colorScheme.primary, size: 22),
                      onPressed: () {
                        context
                            .read<BibleVersionBloc>()
                            .add(DownloadVersionEvent(version.metadata.id));
                        setState(() {
                          _pendingDownloadVersionId = version.metadata.id;
                        });
                      },
                      tooltip: 'bible_version.download'.tr(),
                    ),
                ],
              ),
            ),
          );
        }),
        // Mostrar mensaje en versiones corruptas
        ...versions
            .where((version) =>
                version.errorCode == BibleVersionErrorCode.corrupted)
            .map((version) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: AutoSizeText(
                    '${version.metadata.name} - ${'bible.version_corrupted'.tr()}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, BibleVersionWithState version) {
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

  /// Fallback: show local versions if BLoC fails
  Widget _buildLocalVersionsList(BuildContext context) {
    // Filtrar la versión seleccionada para que NO aparezca en la lista de disponibles
    final selectedVersionId = widget.selectedVersion?.name;
    final filteredVersions = widget.availableVersions
        .where((v) => v.name != selectedVersionId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filteredVersions.map((version) {
        final isSelected = version.name == widget.selectedVersion?.name;
        return _VersionTile(
          version: version,
          isSelected: isSelected,
          onTap: () {
            Navigator.of(context).pop();
            widget.onVersionSelected(version);
          },
        );
      }).toList(),
    );
  }

  void _handleVersionTap(
    BuildContext context,
    BibleVersionWithState version,
    bool isDownloaded,
    bool isDownloading,
  ) async {
    if (isDownloading) return; // Already downloading, ignore tap

    final bloc = context.read<BibleVersionBloc>();
    final bibleProvider =
        Provider.of<BibleSelectedVersionProvider>(context, listen: false);

    if (isDownloaded) {
      // Version is downloaded, just switch to it
      Navigator.of(context).pop();

      // Update provider and trigger rebuild
      await bibleProvider.setVersion(version.metadata.name);
      // Call onVersionSelected to update the controller
      final bibleVersion = BibleVersion(
        name: version.metadata.name,
        language: version.metadata.languageName,
        languageCode: version.metadata.language,
        dbFileName: 'bibles/${version.metadata.filename}',
        isDownloaded: true,
      );
      widget.onVersionSelected(bibleVersion);
    } else {
      // Store the pending download version ID for BlocListener
      setState(() {
        _pendingDownloadVersionId = version.metadata.id;
      });
      // Start download with high priority
      bloc.add(DownloadVersionEvent(
        version.metadata.id,
        priority: DownloadPriority.high,
      ));
      // Download completion is handled by BlocListener in the drawer content
    }
  }

  void _switchToVersion(
      BuildContext context, BibleVersionWithState version) async {
    if (!mounted) return;

    Navigator.of(context).pop();

    final bibleProvider =
        Provider.of<BibleSelectedVersionProvider>(context, listen: false);
    await bibleProvider.setVersion(version.metadata.name);

    final bibleVersion = BibleVersion(
      name: version.metadata.name,
      language: version.metadata.languageName,
      languageCode: version.metadata.language,
      dbFileName: 'bibles/${version.metadata.filename}',
      isDownloaded: true,
    );
    widget.onVersionSelected(bibleVersion);
  }
}

class _VersionTile extends StatelessWidget {
  final BibleVersion version;
  final bool isSelected;
  final VoidCallback onTap;

  const _VersionTile({
    required this.version,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Obtener nombre amigable
    final displayName = CopyrightUtils.getBibleVersionDisplayName(
      version.language,
      version.name,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.menu_book_outlined,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    displayName,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                  ),
                  AutoSizeText(
                    version.language,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (version.isDownloaded)
              Icon(
                Icons.offline_pin,
                color: colorScheme.primary.withAlpha(150),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
