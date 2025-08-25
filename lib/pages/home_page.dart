import 'package:devocional_nuevo/pages/devocionales_page.dart'; // Página principal de devocionales
import 'package:devocional_nuevo/pages/favorites_page.dart'; // Página de favoritos
// import 'package:devocional_nuevo/pages/prayers_page.dart'; // Página de oraciones
import 'package:devocional_nuevo/pages/progress_page.dart'; // Página de progreso espiritual
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex =
      0; // Índice de la pestaña seleccionada en la barra de navegación

  // Lista de widgets para las diferentes pestañas
  static const List<Widget> _widgetOptions = <Widget>[
    DevocionalesPage(), // La página principal de devocionales
    FavoritesPage(), // La página de favoritos
    // PrayersPage(), // La página de oraciones - Lógica comentada
    ProgressPage(), // La página de progreso espiritual
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(
            _selectedIndex), // Muestra el widget de la pestaña seleccionada
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // Necesario para 4 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined), // Icono de libro outlined
            label: 'Devocional', // Etiqueta para devocionales
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline), // Icono de marcador outlined
            label: 'Favoritos', // Etiqueta para favoritos
          ),
          BottomNavigationBarItem(
            icon:
                Icon(Icons.favorite_outline), // Icono de corazón para oraciones
            label: 'Oraciones', // Etiqueta para oraciones
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            // Icono de progreso outlined
            label: 'Progreso', // Etiqueta para progreso espiritual
          ),
        ],
        currentIndex: _selectedIndex,
        // Índice actual seleccionado
        selectedItemColor: Theme.of(context).colorScheme.primary,
        // Color principal del tema para el ítem seleccionado
        unselectedItemColor: Colors.grey,
        // Color para los ítems no seleccionados
        onTap: _onItemTapped, // Manejador de tap para cambiar de pestaña
      ),
    );
  }
}
