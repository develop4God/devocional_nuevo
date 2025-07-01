package com.develop4god.devocional_nuevo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine // Asegúrate de que esta línea esté presente y sin comentar

class MainActivity : FlutterActivity() {
    // Este método es necesario si necesitas registrar plugins manualmente
    // o realizar configuraciones específicas del motor de Flutter al inicio.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Si tienes plugins que necesitan ser registrados manualmente, hazlo aquí.
        // Por ejemplo:
        // GeneratedPluginRegistrant.registerWith(flutterEngine)
        // El comentario original indicaba que no era necesario, lo cual es común
        // si Application.kt o una clase similar lo maneja.
    }

    // Los métodos provideFlutterEngine y getCachedEngineId ya no se sobrescriben
    // en la mayoría de los casos de uso con las versiones recientes de Flutter.
    // FlutterActivity maneja el motor de Flutter y el cacheo por defecto.
    // Si los tenías comentados, asegúrate de que sigan así o elimínalos.
}
