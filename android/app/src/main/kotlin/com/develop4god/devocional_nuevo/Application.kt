package com.develop4god.devocional_nuevo

import android.app.Application as AndroidApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant
// La importación de MultiDexApplication ya no es necesaria si heredas de FlutterApplication
// import androidx.multidex.MultiDexApplication

// La clase Application hereda de android.app.Application (FlutterApplication está deprecado).
// El FlutterEngine se inicializa y cachea manualmente abajo, replicando lo que
// FlutterApplication hacía automáticamente.
class Application : AndroidApplication() {
    lateinit var flutterEngine: FlutterEngine

    override fun onCreate() {
        super.onCreate()
        
        // Inicializar el motor de Flutter.
        // Este motor será cacheado y reutilizado por la MainActivity y por las tareas en segundo plano.
        flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        
        // Registrar los plugins con el motor de Flutter explícitamente,
        // ya que no heredamos de FlutterApplication.
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
