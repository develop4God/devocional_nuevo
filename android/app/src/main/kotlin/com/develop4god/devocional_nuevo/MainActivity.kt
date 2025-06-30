package com.develop4god.devocional_nuevo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // No es necesario registrar los plugins aquí, ya que se hace en Application
    }
    
    override fun provideFlutterEngine(): FlutterEngine? {
        // Usar el motor cacheado si está disponible
        return FlutterEngineCache.getInstance().get("cached_engine")
            ?: super.provideFlutterEngine()
    }
    
    override fun getCachedEngineId(): String? {
        return "cached_engine"
    }
}
