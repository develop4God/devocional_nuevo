package com.develop4god.devocional_nuevo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.os.Build
import androidx.core.view.WindowCompat
import com.google.firebase.crashlytics.FirebaseCrashlytics // ¡Añade esta importación!

class MainActivity : FlutterActivity() {

    // Cambiamos el nombre del canal para que sea específico de Crashlytics
    // y coincida con el que usaremos en Flutter.
    private val CRASHLYTICS_CHANNEL = "com.develop4god.devocional_nuevo/crashlytics"
    private val GENERAL_CHANNEL = "com.devocional_nuevo.test_channel" // Tu canal existente

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

        // Tu MethodChannel existente
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GENERAL_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInitialIntentAction") {
                val action = intent.action
                result.success(action)
            } else {
                result.notImplemented()
            }
        }

        // ¡NUEVO MethodChannel para Crashlytics!
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CRASHLYTICS_CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "forceCrash") {
                // Opcional: Puedes registrar un mensaje que aparecerá en el informe de Crashlytics
                FirebaseCrashlytics.getInstance().log("Fallo forzado desde Flutter a través del canal de métodos.")
                throw RuntimeException("¡Este es un fallo de prueba forzado de Crashlytics desde Flutter!")
                // Nota: La línea de abajo (result.success) no se alcanzará debido al throw.
                // Sin embargo, se mantiene por si decides cambiar la lógica y no lanzar una excepción.
                // result.success(true)
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