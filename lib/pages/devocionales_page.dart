// lib/pages/devocionales_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha
//import 'package:devocional_nuevo/pages/favorites_page.dart';
import 'package:flutter/cupertino.dart'; // NECESARIO para CupertinoIcons
import 'package:shared_preferences/shared_preferences.dart';

// Importa tus propios modelos y providers
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
// Importa la página de configuración
import 'package:devocional_nuevo/pages/settings_page.dart';

// --- DevocionalesPage (Página principal de devocionales) ---
class DevocionalesPage extends StatefulWidget {
  final String? initialDevocionalId;

  const DevocionalesPage({super.key, this.initialDevocionalId});

  @override
  State<DevocionalesPage> createState() => _DevocionalesPageState();
}

class _DevocionalesPageState extends State<DevocionalesPage> {
  final ScreenshotController screenshotController = ScreenshotController();
  int _currentDevocionalIndex = 0;
// Clave para SharedPreferences
  static const String _lastDevocionalIndexKey = 'lastDevocionalIndex';

  // Métodos para navegar, reutilizando la lógica del BottomAppBar
  void _goToNextDevocional() {
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    final List<Devocional> devocionales = devocionalProvider.devocionales;

    if (_currentDevocionalIndex < devocionales.length - 1) {
      setState(() {
        _currentDevocionalIndex++;
      });
      // Mostrar la oración de fe si showInvitationDialog es true al avanzar
      if (devocionalProvider.showInvitationDialog) {
        _showInvitation(context);
      }
      // ¡IMPORTANTE! Guardar el índice después de avanzar, incluso si se llega al final
      _saveCurrentDevocionalIndex();
    }
  }

  void _goToPreviousDevocional() {
    if (_currentDevocionalIndex > 0) {
      setState(() {
        _currentDevocionalIndex--;
      });
    }
  }
// Método para guardar el índice actual del devocional
  Future<void> _saveCurrentDevocionalIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastDevocionalIndexKey, _currentDevocionalIndex);
    print('Índice de devocional guardado: $_currentDevocionalIndex');
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async { // ¡Ahora es ASYNC!
      final devocionalProvider =
      Provider.of<DevocionalProvider>(context, listen: false);

      // Asegúrate de que los datos del provider estén listos
      if (!devocionalProvider.isLoading &&
          devocionalProvider.devocionales.isEmpty) {
        await devocionalProvider.initializeData(); // Espera a que se inicialicen los datos
      }

      // *** Lógica para cargar el último índice de devocional visto ***
      if (devocionalProvider.devocionales.isNotEmpty) { // Solo si hay devocionales para evitar errores
        final prefs = await SharedPreferences.getInstance();
        final int? savedIndex = prefs.getInt(_lastDevocionalIndexKey);

        if (mounted) {
          setState(() {
            if (savedIndex != null) {
              // Si hay un índice guardado, calculamos el "siguiente" devocional.
              // Asegúrate de no exceder el tamaño de la lista.
              // Si savedIndex es el último, volvemos al principio (0).
              _currentDevocionalIndex = (savedIndex + 1) % devocionalProvider.devocionales.length;
              print('Devocional cargado al inicio (índice siguiente): $_currentDevocionalIndex');
            } else {
              // Si no hay índice guardado (primera vez que se abre la app), empezar en 0.
              _currentDevocionalIndex = 0;
              print('No hay índice guardado. Iniciando en el primer devocional (índice 0).');
            }
          });
        }
      } else {
        // Si no hay devocionales disponibles al inicio, asegura que el índice sea 0
        if (mounted) {
          setState(() {
            _currentDevocionalIndex = 0;
          });
        }
        print('No hay devocionales disponibles para cargar el índice.');
      }

      // Si se pasa un ID inicial, encontrar su índice. Esta lógica DEBE SOBREESCRIBIR el índice guardado.
      // Esto asegura que si el usuario viene de favoritos, se muestre el devocional específico.
      if (widget.initialDevocionalId != null &&
          devocionalProvider.devocionales.isNotEmpty) {
        final index = devocionalProvider.devocionales.indexWhere(
              (d) => d.id == widget.initialDevocionalId,
        );
        if (index != -1) {
          setState(() {
            _currentDevocionalIndex = index;
          });
        }
      }
    });
  }

  /// Muestra el diálogo de la Oración de Fe.
  void _showInvitation(BuildContext context) {
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    bool doNotShowAgainChecked = !devocionalProvider.showInvitationDialog;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            "¡Oración de fe, para vida eterna!",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Repite esta oración en voz alta, con fe y creyendo con todo el corazón:\n",
                  textAlign: TextAlign.justify,
                ),
                Text(
                  "Jesucristo, creo que moriste en la cruz por mi, te pido perdón y me arrepiento de corazón por mis pecados. Te pido seas mi Salvador y el señor de vida. Líbrame de la muerte eterna y escribe mi nombre en el libro de la vida.\nEn el poderoso nombre de Jesús, amén.\n",
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Si hiciste esta oración y lo crees:\nSerás salvo tu y tu casa (Hch 16:31)\nVivirás eternamente (Jn 11:25-26)\nNunca más tendrás sed (Jn 4:14)\nEstarás con Cristo en los cielos (Ap 19:9)\nHay gozo en los cielos cuando un pecador se arrepiente (Luc 15:10)\nEscrito está y Dios es fiel (Dt 7:9)\n\nDesde ya tienes salvación y vida nueva en Jesucristo.",
                  textAlign: TextAlign.justify,
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
                ),
                const Expanded(
                    child: Text('Ya la hice 🙏\nNo mostrar nuevamente')),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {
                  devocionalProvider
                      .setInvitationDialogVisibility(!doNotShowAgainChecked);
                  Navigator.of(context).pop();
                },
                child: const Text("Continuar",
                    style: TextStyle(color: Colors.deepPurple)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Comparte el devocional como texto.
  Future<void> _shareAsText(Devocional devocional) async {
    final text =
        "Devocional del día:\n\nVersículo: ${devocional.versiculo}\n\nReflexión: ${devocional.reflexion}\n\nPara Meditar:\n${devocional.paraMeditar.map((p) => '${p.cita}: ${p.texto}').join('\n')}\n\nOración: ${devocional.oracion}\n\nVersión: ${devocional.version ?? 'N/A'}\nIdioma: ${devocional.language ?? 'N/A'}\nFecha: ${DateFormat('dd/MM/yyyy').format(devocional.date)}";
    await Share.share(text);
  }

  /// Comparte el devocional como imagen (captura de pantalla).
  Future<void> _shareAsImage(Devocional devocional) async {
    final image = await screenshotController.capture();
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/devocional.png').create();
      await imagePath.writeAsBytes(image);
      
      // Compartir el archivo de imagen
      await Share.shareFiles(
        [imagePath.path],
        text: 'Devocional del día',
        subject: 'Devocional',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Remueve backgroundColor y foregroundColor para heredar del tema global
        // backgroundColor: Colors.deepPurple[400], // <-- Comentada o eliminada
        // foregroundColor: Colors.white,            // <-- Comentada o eliminada
        // Título fijo en lugar de la fecha
        title: const Text('Mi espacio íntimo con Dios',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          Consumer<DevocionalProvider>(
            builder: (context, devocionalProvider, child) {
              return Row(
                children: [
                  // Selector de Versión (Mantenido en AppBar)
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: devocionalProvider.selectedVersion,
                      // Icono de libro original
                      icon:
                          const Icon(CupertinoIcons.book, color: Colors.white),
                      dropdownColor: Colors.deepPurple[700],
                      // selectedItemBuilder para mostrar el icono y el texto de la versión en el botón
                      selectedItemBuilder: (BuildContext context) {
                        // Asegúrate que lista coincide con la lista 'items' de abajo.
                        return <String>[
                          'RVR1960'//,
                          //'NTV'
                        ] // Ajusta si tus versiones son diferentes.
                            .map<Widget>((String itemValue) {
                          return SizedBox(
                            width:
                                40.0, // Puedes ajustar este valor si el texto en el menú desplegable sigue cortándose (ej. 90.0, 100.0)
                            child: Text(
                              itemValue, // El texto real de la versión
                              style: const TextStyle(
                                  color: Colors
                                      .transparent), // Hace el texto INVISIBLE en el botón
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          devocionalProvider.setSelectedVersion(newValue);
                          //setState(() {
                            //_currentDevocionalIndex = 0; comentado para que no vuelva al inicio
                          //});
                        }
                      },
                      // 'items' define las opciones que se ven cuando el Dropdown se despliega.
                      items: <String>[
                        'RVR1960'//,
                        //'NTV'
                      ] // Asegúrate que esta sea la lista real de versiones de tu app.
                          .map<DropdownMenuItem<String>>((String itemValue) {
                        return DropdownMenuItem<String>(
                          value: itemValue,
                          // El 'child' del DropdownMenuItem muestra el texto real y completo de la versión aquí.
                          child: Text(
                            itemValue, // Mostrará el texto real y completo de la versión aquí.
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Botón para ir a favoritos REMOVIDO DE AQUÍ
                  // IconButton(
                  //   icon: const Icon(
                  //     CupertinoIcons.square_favorites_alt, // Icono de favoritos
                  //   ),
                  //   tooltip: 'Ver favoritos',
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const FavoritesPage(),
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<DevocionalProvider>(
        builder: (context, devocionalProvider, child) {
          final List<Devocional> devocionales = devocionalProvider.devocionales;

          if (devocionalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (devocionalProvider.errorMessage != null && devocionales.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      devocionalProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => devocionalProvider.initializeData(),
                      child: const Text('Reintentar Carga'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (devocionales.isEmpty) {
            return const Center(
              child: Text(
                'No hay devocionales disponibles para el idioma/versión seleccionados.',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (_currentDevocionalIndex >= devocionales.length) {
            _currentDevocionalIndex = devocionales.length - 1;
            if (_currentDevocionalIndex < 0) _currentDevocionalIndex = 0;
          }

          final Devocional currentDevocional =
              devocionales[_currentDevocionalIndex];
          //final bool isFavorite =
              //devocionalProvider.isFavorite(currentDevocional);

          return Column(
            // Columna principal del body para elementos fijos y desplazables
            children: [
              // --- Fecha del Día Actual (Fija, debajo del AppBar) ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  // Muestra SIEMPRE la fecha actual del sistema
                  DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ),
              // --- Contenido del Devocional (Desplazable) ---
              Expanded(
                child: Screenshot(
                  controller: screenshotController,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Versículo
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      const Color.fromARGB(255, 221, 207, 245)),
                            ),
                            child: AutoSizeText(
                              currentDevocional.versiculo,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple.shade800,
                                  ),
                              maxLines: 12,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Reflexión
                          Text(
                            'Reflexión:',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentDevocional.reflexion,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),

                          // Sección "Para Meditar"
                          Text(
                            'Para Meditar:',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple),
                          ),
                          const SizedBox(height: 10),
                          ...currentDevocional.paraMeditar.map((item) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${item.cita}: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    TextSpan(
                                      text: item.texto,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),

                          // Oración
                          Text(
                            'Oración:',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentDevocional.oracion,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),

                          // Información de Versión y Tags (si existen)
                          if (currentDevocional.version != null ||
                              currentDevocional.language != null ||
                              currentDevocional.tags != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detalles:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple),
                                ),
                                const SizedBox(height: 10),
                                if (currentDevocional.version != null)
                                  Text('Versión: ${currentDevocional.version}',
                                      style: const TextStyle(fontSize: 14)),
                                if (currentDevocional.language != null)
                                  Text('Idioma: ${currentDevocional.language}',
                                      style: const TextStyle(fontSize: 14)),
                                if (currentDevocional.tags != null &&
                                    currentDevocional.tags!.isNotEmpty)
                                  Text(
                                      'Temas: ${currentDevocional.tags!.join(', ')}',
                                      style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 20),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // --- Botones de Navegación (Anterior/Siguiente) ---
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
                        // Botón Devocional anterior (transparente)
                        IconButton(
                          tooltip: 'Devocional anterior',
                          onPressed: _currentDevocionalIndex > 0
                              ? _goToPreviousDevocional
                              : null, // Deshabilitar si es el primero
                          icon: Icon(
                            Icons.arrow_back,
                            color: _currentDevocionalIndex > 0
                                ? Colors.deepPurple // Color cuando está activo
                                : Colors.deepPurple.withOpacity(0.3), // Más transparente
                            size: 35, // Un poco más grandes
                          ),
                        ),
                        // Botón Devocional siguiente (transparente)
                        IconButton(
                          tooltip: 'Siguiente devocional',
                          onPressed:
                              _currentDevocionalIndex < devocionales.length - 1
                                  ? _goToNextDevocional
                                  : null, // Deshabilitar si es el último
                          icon: Icon(
                            Icons.arrow_forward,
                            color: _currentDevocionalIndex <
                                    devocionales.length - 1
                                ? Colors.deepPurple // Color cuando está activo
                                : Colors.deepPurple.withOpacity(0.3), // Más transparente
                            size: 35, // Un poco más grandes
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
      // --- BARRAS DE ACCIÓN INFERIOR (BottomAppBar) ---
      bottomNavigationBar: Consumer<DevocionalProvider>(
        builder: (context, devocionalProvider, child) {
          final List<Devocional> devocionales = devocionalProvider.devocionales;
          // Asegúrate de que haya un devocional seleccionado antes de verificar si es favorito
          final Devocional? currentDevocional = devocionales.isNotEmpty
              ? devocionales[_currentDevocionalIndex]
              : null;
          final bool isFavorite = currentDevocional != null
              ? devocionalProvider.isFavorite(currentDevocional)
              : false;

          return BottomAppBar(
            // Asigna el color de fondo de la AppBar del tema global
            color: Theme.of(context).appBarTheme.backgroundColor, // <-- ¡CAMBIAR A ESTA LÍNEA!
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Botón Favoritos (corazón lleno/vacío)
                IconButton(
                  tooltip: isFavorite
                      ? 'Quitar de favoritos'
                      : 'Guardar como favorito',
                  onPressed: currentDevocional != null
                      ? () => devocionalProvider.toggleFavorite(
                          currentDevocional, context)
                      : null, // Deshabilitar si no hay devocional
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red, // Siempre rojo para favoritos
                    size: 30,
                  ),
                ),
                // Botón Compartir como Texto
                IconButton(
                  tooltip: 'Compartir como texto',
                  onPressed: currentDevocional != null
                      ? () => _shareAsText(currentDevocional)
                      : null,
                  icon: const Icon(Icons.share, color: Colors.white, size: 30),
                ),
                // Botón Compartir como Imagen
                IconButton(
                  tooltip: 'Compartir como imagen (screenshot)',
                  onPressed: currentDevocional != null
                      ? () => _shareAsImage(currentDevocional)
                      : null,
                  icon: const Icon(Icons.image, color: Colors.white, size: 30),
                ),
                // Botón de Configuración
                IconButton(
                  tooltip: 'Configuración',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                  icon: const Icon(CupertinoIcons.text_badge_plus,
                      color: Colors.white, size: 30), // <<-- LÍNEA MODIFICADA
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
