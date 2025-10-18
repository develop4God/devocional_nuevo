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
        // Enable edge-to-edge display BEFORE calling super.onCreate()
        // This is required for Android 15+ (API 35) to avoid deprecated API warnings
        // and ensure proper edge-to-edge display behavior
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }

        // Importante: inicializa Flutter después de configurar edge-to-edge
        super.onCreate(savedInstanceState)

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