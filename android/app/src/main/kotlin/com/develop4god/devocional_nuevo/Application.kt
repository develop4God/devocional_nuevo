package com.develop4god.devocional_nuevo

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant
import androidx.multidex.MultiDexApplication

class Application : MultiDexApplication() {
    lateinit var flutterEngine: FlutterEngine

    override fun onCreate() {
        super.onCreate()
        
        // Inicializar el motor de Flutter
        flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        
        // Registrar los plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Cachear el motor para que pueda ser usado por otros componentes
        FlutterEngineCache.getInstance().put("cached_engine", flutterEngine)
    }
}