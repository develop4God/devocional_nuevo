// lib/app_initializer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart'; // Importa tu página principal
import 'package:devocional_nuevo/providers/devocional_provider.dart'; // Importa tu provider

/// Un widget que se encarga de inicializar los datos de la aplicación
/// y luego, una vez listos, navega a la página principal (DevocionalesPage).
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Se utiliza addPostFrameCallback para asegurar que la inicialización
    // se realice después de que el primer frame del widget haya sido construido,
    // evitando el error de setState/notifyListeners durante la fase de build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppData(); // Aquí se llama a la función de inicialización
    });
  }

  Future<void> _initializeAppData() async {
    // Asegurarse de que el contexto sea válido antes de usar Provider.of
    if (!mounted) return;

    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    await devocionalProvider.initializeData(); // Carga los datos del devocional

    // Una vez que los datos están cargados, navega a la página principal.
    // Se verifica 'mounted' nuevamente antes de navegar para evitar errores
    // si el widget ya no está en el árbol de widgets.
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DevocionalesPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation, // Esto hace que la nueva página se desvanezca
              child: child,
            );
          },
          transitionDuration: const Duration(
              milliseconds:
                  700), // La duración del desvanecimiento (puedes ajustar este valor)
        ),
      );
    }
  } // Cierre correcto de _initializeAppData

  @override
  Widget build(BuildContext context) {
    // Mientras los datos se cargan, este widget muestra un indicador de carga.
    // En la práctica, el usuario solo verá el SplashScreen hasta que termine
    // la navegación a AppInitializer, por lo que este indicador es un fallback
    // para asegurar que algo se muestra si la carga es muy larga o hay un delay.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} // Cierre correcto de _AppInitializerState
