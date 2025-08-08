import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importación agregada

import 'package:devocional_nuevo/app_initializer.dart'; // Importa el nuevo AppInitializer

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 1500), // Duración de la animación del fade
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward(); // Inicia la animación visual
    _navigateToNextScreen(); // Llama al método para manejar la navegación
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 5000));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AppInitializer(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Intenta obtener el estilo del tema definido en main.dart
    final splashTextStyle = Theme.of(context).textTheme.displaySmall;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand, // Asegura que el Stack ocupe toda la pantalla
        children: [
          // 1. Capa de la imagen de fondo
          FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/splash_background.png', // Asegúrate de que esta ruta sea correcta
              fit: BoxFit.cover, // Cubre todo el espacio
              alignment: Alignment.center,
            ),
          ),
          // 2. Capa del texto superpuesto
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SizedBox para empujar el texto hacia abajo
                  const SizedBox(
                    height: 150,
                  ),
                  Text(
                    'Preparando tu espacio con Dios...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dancingScript(
                      fontSize: 22, // Igual que tu valor actual
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple, // Deep purple para contraste
                      shadows: [
                        Shadow(
                          offset: Offset(2.0, 2.0),
                          blurRadius: 5.0,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
