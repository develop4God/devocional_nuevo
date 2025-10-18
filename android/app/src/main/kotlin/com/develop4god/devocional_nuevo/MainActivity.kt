package com.develop4god.devocional_nuevo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.os.Build
import androidx.core.view.WindowCompat

class MainActivity : FlutterActivity() {

    private val channel = "com.devocional_nuevo.test_channel"

    // --- INICIO: Soporte para Firebase Test Lab Game Loop y Edge-to-Edge ---
    override fun onCreate(savedInstanceState: Bundle?) {
        // Importante: inicializa Flutter primero
        super.onCreate(savedInstanceState)

        // Enable edge-to-edge display for Android 15+ compatibility
        // This ensures the app displays properly on Android 15 (API 35+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }

        // Si la app fue lanzada por un intent de Test Lab Game Loop, aplicar un pequeño retraso
        if (intent.action != null && intent.action == "com.google.intent.action.TEST_LOOP") {
            try {
                // Espera 5 segundos para asegurar que la UI de Flutter se vea correctamente en el video de Test Lab
                Thread.sleep(5000)
                println("Firebase Test Lab: Retraso de 5 segundos aplicado para la prueba de Game Loop.")
            } catch (e: InterruptedException) {
                e.printStackTrace()
            }
        }
    }
    // --- FIN: Soporte para Firebase Test Lab Game Loop y Edge-to-Edge ---

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            if (call.method == "getInitialIntentAction") {
                val action = intent.action
                result.success(action)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}