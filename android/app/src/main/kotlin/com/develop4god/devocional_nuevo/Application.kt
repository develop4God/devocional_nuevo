package com.develop4god.devocional_nuevo

// Importar FlutterApplication para una correcta inicialización del motor de Flutter
import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant
// La importación de MultiDexApplication ya no es necesaria si heredas de FlutterApplication
// import androidx.multidex.MultiDexApplication

// La clase Application ahora hereda de FlutterApplication.
// Este cambio es crucial para asegurar que el FlutterEngine se inicialice de forma única
// y que los plugins se registren correctamente para tareas en segundo plano.
class Application : FlutterApplication() {
    lateinit var flutterEngine: FlutterEngine

    override fun onCreate() {
        super.onCreate()
        
        // Inicializar el motor de Flutter.
        // Este motor será cacheado y reutilizado por la MainActivity y por las tareas en segundo plano.
        flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        
        // Registrar los plugins con el motor de Flutter.
        // Al heredar de FlutterApplication, el registro automático es más robusto,
        // pero esta línea asegura que se haga explícitamente con el motor que estamos cacheando.
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Cachear el motor para que pueda ser usado por otros componentes (como MainActivity),
        // asegurando que no se cree un nuevo motor y se dupliquen los registros de plugins.
        FlutterEngineCache.getInstance().put("cached_engine", flutterEngine)
    }

    // Nota sobre MultiDex:
    // Si tu minSdkVersion es 21 o superior, FlutterApplication generalmente maneja MultiDex
    // automáticamente. Si tienes problemas relacionados con MultiDex después de este cambio
    // y tu minSdkVersion es inferior a 21, podrías necesitar descomentar el siguiente bloque
    // y asegurarte de tener la dependencia 'androidx.multidex:multidex' en tu build.gradle.
    /*
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
    */
}
