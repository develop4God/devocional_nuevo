// lib/pages/devocionales_page.dart
import 'dart:developer' as developer;
import 'dart:io' show File;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/pages/progress_page.dart';
import 'package:devocional_nuevo/pages/settings_page.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/devocionales_tracking.dart'; // NUEVO IMPORT
import 'package:devocional_nuevo/services/update_service.dart';
import 'package:devocional_nuevo/utils/bubble_constants.dart';
import 'package:devocional_nuevo/widgets/devocionales_page_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevocionalesPage extends StatefulWidget {
  final String? initialDevocionalId;

  const DevocionalesPage({super.key, this.initialDevocionalId});

  @override
  State<DevocionalesPage> createState() => _DevocionalesPageState();
}

class _DevocionalesPageState extends State<DevocionalesPage>
    with WidgetsBindingObserver {
  final ScreenshotController screenshotController = ScreenshotController();
  final ScrollController _scrollController = ScrollController();
  int _currentDevocionalIndex = 0;
  static const String _lastDevocionalIndexKey = 'lastDevocionalIndex';

  // NUEVA PROPIEDAD: Servicio de tracking
  final DevocionalesTracking _tracking = DevocionalesTracking();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // NUEVA LÍNEA: Inicializar tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tracking.initialize(context);
      _tracking.startCriteriaCheckTimer();
    });

    _loadInitialData();

    // Verificar actualizaciones al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // MODIFICADO: Usar el servicio de tracking
      _tracking.pauseTracking();
      debugPrint('🔄 App paused - tracking and criteria timer paused');
    } else if (state == AppLifecycleState.resumed) {
      // MODIFICADO: Usar el servicio de tracking
      _tracking.resumeTracking();
      debugPrint('🔄 App resumed - tracking and criteria timer resumed');

      // Verificar actualizaciones cuando la app vuelve del background
      UpdateService.checkForUpdate();
    }
  }

  Future<void> _loadInitialData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final devocionalProvider = Provider.of<DevocionalProvider>(
        context,
        listen: false,
      );

      if (!devocionalProvider.isLoading &&
          devocionalProvider.devocionales.isEmpty) {
        await devocionalProvider.initializeData();
        if (!mounted) return;
      }

      if (devocionalProvider.devocionales.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final int? savedIndex = prefs.getInt(_lastDevocionalIndexKey);

        if (mounted) {
          setState(() {
            if (savedIndex != null) {
              _currentDevocionalIndex =
                  (savedIndex + 1) % devocionalProvider.devocionales.length;
              developer.log(
                'Devocional cargado al inicio (índice siguiente): $_currentDevocionalIndex',
              );
            } else {
              _currentDevocionalIndex = 0;
              developer.log(
                'No hay índice guardado. Iniciando en el primer devocional (índice 0).',
              );
            }
          });

          // INICIAR TRACKING PARA EL DEVOCIONAL INICIAL
          _startTrackingCurrentDevocional();
        }
      } else {
        if (mounted) {
          setState(() {
            _currentDevocionalIndex = 0;
          });
        }
        developer.log('No hay devocionales disponibles para cargar el índice.');
      }

      if (widget.initialDevocionalId != null &&
          devocionalProvider.devocionales.isNotEmpty) {
        final index = devocionalProvider.devocionales.indexWhere(
          (d) => d.id == widget.initialDevocionalId,
        );
        if (index != -1) {
          if (mounted) {
            setState(() {
              _currentDevocionalIndex = index;
            });
            // INICIAR TRACKING PARA EL DEVOCIONAL ESPECÍFICO
            _startTrackingCurrentDevocional();
          }
        }
      }
    });
  }

  /// Inicia el tracking para el devocional actual
  void _startTrackingCurrentDevocional() {
    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );

    if (devocionalProvider.devocionales.isNotEmpty &&
        _currentDevocionalIndex < devocionalProvider.devocionales.length) {
      final currentDevocional =
          devocionalProvider.devocionales[_currentDevocionalIndex];

      // MODIFICADO: Usar el servicio de tracking
      _tracking.clearAutoCompletedExcept(currentDevocional.id);
      _tracking.startDevocionalTracking(
          currentDevocional.id, _scrollController);
    }
  }

  void _goToNextDevocional() {
    if (!mounted) return;

    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );
    final List<Devocional> devocionales = devocionalProvider.devocionales;

    if (_currentDevocionalIndex < devocionales.length - 1) {
      // Stop audio if playing
      if (devocionalProvider.isAudioPlaying) {
        devocionalProvider.stopAudio();
      }

      // Record that the current devotional was read before moving to the next one
      final currentDevocional = devocionales[_currentDevocionalIndex];

      // MODIFICADO: Usar el servicio de tracking
      _tracking.recordDevocionalRead(currentDevocional.id);

      setState(() {
        _currentDevocionalIndex++;
      });
      _scrollToTop();

      // INICIAR TRACKING PARA EL NUEVO DEVOCIONAL
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTrackingCurrentDevocional();
      });

      // Vibración táctil suave para feedback
      HapticFeedback.lightImpact();

      if (devocionalProvider.showInvitationDialog) {
        if (mounted) {
          _showInvitation(context);
        }
      }
      _saveCurrentDevocionalIndex();
    }
  }

  void _goToPreviousDevocional() {
    if (_currentDevocionalIndex > 0) {
      // Stop audio if playing
      final devocionalProvider =
          Provider.of<DevocionalProvider>(context, listen: false);
      if (devocionalProvider.isAudioPlaying) {
        devocionalProvider.stopAudio();
      }

      setState(() {
        _currentDevocionalIndex--;
      });
      _scrollToTop();

      // INICIAR TRACKING PARA EL NUEVO DEVOCIONAL
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTrackingCurrentDevocional();
      });

      // Vibración táctil suave para feedback
      HapticFeedback.lightImpact();
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  Future<void> _saveCurrentDevocionalIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastDevocionalIndexKey, _currentDevocionalIndex);
    developer.log('Índice de devocional guardado: $_currentDevocionalIndex');
  }

  void _showInvitation(BuildContext context) {
    if (!mounted) return;

    final devocionalProvider = Provider.of<DevocionalProvider>(
      context,
      listen: false,
    );

    bool doNotShowAgainChecked = !devocionalProvider.showInvitationDialog;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            "¡Oración de fe, para vida eterna!",
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Repite esta oración en voz alta, con fe y creyendo con todo el corazón:\n",
                  textAlign: TextAlign.justify,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "Jesucristo, creo que moriste en la cruz por mi, te pido perdón y me arrepiento de corazón por mis pecados. Te pido seas mi Salvador y el señor de vida. Líbrame de la muerte eterna y escribe mi nombre en el libro de la vida.\nEn el poderoso nombre de Jesús, amén.\n",
                  textAlign: TextAlign.justify,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "Si hiciste esta oración y lo crees:\nSerás salvo tu y tu casa (Hch 16:31)\nVivirás eternamente (Jn 11:25-26)\nNunca más tendrás sed (Jn 4:14)\nEstarás con Cristo en los cielos (Ap 19:9)\nHay gozo en los cielos cuando un pecador se arrepiente (Luc 15:10)\nEscrito está y Dios es fiel (Dt 7:9)\n\nDesde ya tienes salvación y vida nueva en Jesucristo.",
                  textAlign: TextAlign.justify,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Checkbox(
                  value: doNotShowAgainChecked,
                  onChanged: (val) {
                    setDialogState(() {
                      doNotShowAgainChecked = val ?? false;
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
                Expanded(
                  child: Text(
                    'Ya la hice 🙏\nNo mostrar nuevamente',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {
                  devocionalProvider.setInvitationDialogVisibility(
                    !doNotShowAgainChecked,
                  );
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  "Continuar",
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAsText(Devocional devocional) async {
    final text =
        "Devocional del día:\n\nVersículo: ${devocional.versiculo}\n\nReflexión: ${devocional.reflexion}\n\nPara Meditar:\n${devocional.paraMeditar.map((p) => '${p.cita}: ${p.texto}').join('\n')}\n\nOración: ${devocional.oracion}";

    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _shareAsImage(Devocional devocional) async {
    final image = await screenshotController.capture();
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/devocional.png').create();
      await imagePath.writeAsBytes(image);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath.path)],
          text: 'Devocional del día',
          subject: 'Devocional',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const DevocionalesDrawer(),
      appBar: AppBar(
        title: Text(
          'Mi espacio íntimo con Dios',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor ??
                colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<DevocionalProvider>(
        builder: (context, devocionalProvider, child) {
          final List<Devocional> devocionales = devocionalProvider.devocionales;

          if (devocionales.isEmpty) {
            return Center(
              child: Text(
                'No hay devocionales disponibles para el idioma/versión seleccionados.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            );
          }

          if (_currentDevocionalIndex >= devocionales.length ||
              _currentDevocionalIndex < 0) {
            _currentDevocionalIndex = 0;
          }

          final Devocional currentDevocional =
              devocionales[_currentDevocionalIndex];

          return Column(
            children: [
              // Header con fecha (sin indicador de progreso)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),

              // Contenido principal
              Expanded(
                child: Screenshot(
                  controller: screenshotController,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(
                                (0.1 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.primary.withAlpha(
                                  (0.3 * 255).round(),
                                ),
                              ),
                            ),
                            child: AutoSizeText(
                              currentDevocional.versiculo,
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Reflexión:',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentDevocional.reflexion,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Para Meditar:',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...currentDevocional.paraMeditar.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${item.cita}: ',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: item.texto,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                          Text(
                            'Oración:',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentDevocional.oracion,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (currentDevocional.version != null ||
                              currentDevocional.language != null ||
                              currentDevocional.tags != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detalles:',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (currentDevocional.tags != null &&
                                    currentDevocional.tags!.isNotEmpty)
                                  Text(
                                    'Temas: ${currentDevocional.tags!.join(', ')}',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                if (currentDevocional.version != null)
                                  Text(
                                    'Versión: ${currentDevocional.version}',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Text(
                                      'El texto bíblico Reina-Valera 1960® Sociedades Bíblicas en América Latina, 1960. Derechos renovados 1988, Sociedades Bíblicas Unidas.',
                                      style: textTheme.bodySmall?.copyWith(
                                        fontSize: 12,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Consumer<DevocionalProvider>(
                builder: (context, devocionalProvider, child) {
                  final List<Devocional> devocionales =
                      devocionalProvider.devocionales;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: 'Devocional anterior',
                          onPressed: _currentDevocionalIndex > 0
                              ? _goToPreviousDevocional
                              : null,
                          icon: Icon(
                            Icons.arrow_back,
                            color: _currentDevocionalIndex > 0
                                ? colorScheme.primary
                                : colorScheme.primary
                                    .withAlpha((0.3 * 255).round()),
                            size: 35,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Siguiente devocional',
                          onPressed:
                              _currentDevocionalIndex < devocionales.length - 1
                                  ? _goToNextDevocional
                                  : null,
                          icon: Icon(
                            Icons.arrow_forward,
                            color: _currentDevocionalIndex <
                                    devocionales.length - 1
                                ? colorScheme.primary
                                : colorScheme.primary
                                    .withAlpha((0.3 * 255).round()),
                            size: 35,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<DevocionalProvider>(
        builder: (context, devocionalProvider, child) {
          final List<Devocional> devocionales = devocionalProvider.devocionales;
          final Devocional? currentDevocional = devocionales.isNotEmpty
              ? devocionales[_currentDevocionalIndex]
              : null;
          final bool isFavorite = currentDevocional != null
              ? devocionalProvider.isFavorite(currentDevocional)
              : false;

          final Color appBarForegroundColor =
              Theme.of(context).appBarTheme.foregroundColor ??
                  colorScheme.onPrimary;
          final Color? appBarBackgroundColor =
              Theme.of(context).appBarTheme.backgroundColor;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // BARRA DE NAVEGACIÓN CON BOTONES SEPARADOS
              Container(
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withAlpha((0.2 * 255).round()),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      // Botón Anterior
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton.icon(
                            onPressed: _currentDevocionalIndex > 0
                                ? _goToPreviousDevocional
                                : null,
                            icon: Icon(Icons.arrow_back_ios, size: 16),
                            label: Text(
                              'Anterior',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentDevocionalIndex > 0
                                  ? colorScheme.primary
                                  : colorScheme.outline.withAlpha(
                                      (0.3 * 255).round(),
                                    ),
                              foregroundColor: _currentDevocionalIndex > 0
                                  ? Colors.white
                                  : colorScheme.outline,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              elevation: _currentDevocionalIndex > 0 ? 2 : 0,
                            ),
                          ),
                        ),
                      ),

                      // ESPACIO LIBRE EN EL CENTRO
                      Expanded(
                        flex: 1,
                        child: SizedBox.shrink(), // Espacio vacío
                      ),

                      // Botón Siguiente
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton.icon(
                            onPressed: _currentDevocionalIndex <
                                    devocionales.length - 1
                                ? _goToNextDevocional
                                : null,
                            label: Icon(Icons.arrow_forward_ios, size: 16),
                            icon: Text(
                              'Siguiente',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentDevocionalIndex <
                                      devocionales.length - 1
                                  ? colorScheme.primary
                                  : colorScheme.outline.withAlpha(
                                      (0.3 * 255).round(),
                                    ),
                              foregroundColor: _currentDevocionalIndex <
                                      devocionales.length - 1
                                  ? Colors.white
                                  : colorScheme.outline,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              elevation: _currentDevocionalIndex <
                                      devocionales.length - 1
                                  ? 2
                                  : 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // BARRA DE ACCIONES EXISTENTE (favoritos, compartir, etc.)
              BottomAppBar(
                height: 70,
                color: appBarBackgroundColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      tooltip: isFavorite
                          ? 'Quitar de favoritos'
                          : 'Guardar como favorito',
                      onPressed: currentDevocional != null
                          ? () => devocionalProvider.toggleFavorite(
                                currentDevocional,
                                context,
                              )
                          : null,
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.white : Colors.black,
                            size: 32,
                          ),
                          Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Compartir como texto',
                      onPressed: currentDevocional != null
                          ? () => _shareAsText(currentDevocional)
                          : null,
                      icon: Icon(
                        Icons.share,
                        color: appBarForegroundColor,
                        size: 30,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Compartir como imagen (screenshot)',
                      onPressed: currentDevocional != null
                          ? () => _shareAsImage(currentDevocional)
                          : null,
                      icon: Icon(
                        Icons.image,
                        color: appBarForegroundColor,
                        size: 30,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ver progreso y logros',
                      onPressed: () async {
                        // Marcar como visto - badge desaparece
                        await BubbleUtils.markAsShown(
                            BubbleUtils.getIconBubbleId(
                                Icons.emoji_events_outlined, 'new'));

                        // Verificar que el context sigue siendo válido
                        if (!context.mounted) return;

                        // Navegar
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProgressPage(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.emoji_events_outlined,
                        color: appBarForegroundColor,
                        size: 30,
                      ).newIconBadge,
                    ),
                    IconButton(
                      tooltip: 'Configuración',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.app_settings_alt_outlined,
                        color: appBarForegroundColor,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();

    // Stop audio and dispose resources
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    devocionalProvider.stopAudio();


    // NUEVA LÍNEA: Limpiar tracking
    _tracking.dispose();

    super.dispose();
  }
}
