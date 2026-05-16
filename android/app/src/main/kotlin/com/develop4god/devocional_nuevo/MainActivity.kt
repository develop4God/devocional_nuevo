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

    // Method channels
    private val CRASHLYTICS_CHANNEL = "com.develop4god.devocional_nuevo/crashlytics"
    private val GENERAL_CHANNEL = "com.devocional_nuevo.test_channel"
    private val DEEP_LINK_CHANNEL = "com.develop4god.devocional/deeplink"

    // Store initial deep link (cold-start, read via getInitialLink channel call)
    private var initialLink: String? = null

    // Deep link received during a warm start (onNewIntent) that must be
    // dispatched to Flutter only after the activity is fully resumed, so that
    // the Flutter engine is in "resumed" state when Navigator.push() fires.
    private var pendingWarmLink: String? = null

    // Store FlutterEngine reference for sending deep links while app is running
    private var deepLinkChannel: MethodChannel? = null

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

        // Check if app was launched with a deep link
        handleIntent(intent)

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

    private fun handleIntent(intent: Intent?) {
        val action = intent?.action
        val data = intent?.data

        if ((action == Intent.ACTION_VIEW || action == Intent.ACTION_MAIN) && data != null) {
            initialLink = data.toString()
            println("Deep link received: $initialLink")
        }
    }

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

        // Deep link channel
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
        deepLinkChannel?.setMethodCallHandler {
                call, result ->
            if (call.method == "getInitialLink") {
                result.success(initialLink)
                initialLink = null // Clear after reading
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)

        // Save the warm-start link as pending instead of dispatching immediately.
        // When onNewIntent fires the activity (and Flutter engine) are still in
        // "paused" state — e.g. the FIAM overlay is in the process of closing.
        // Dispatching here means Navigator.push() runs while Flutter cannot
        // render frames, which causes the pushed page to be invisible until the
        // next full rebuild overwrites it.
        // Dispatch in onResume() instead, where Flutter is guaranteed to be in
        // "resumed" state and frames are active.
        if (initialLink != null) {
            pendingWarmLink = initialLink
            initialLink = null
        }
    }

    override fun onResume() {
        super.onResume()
        // Dispatch any warm-start deep link now that the Flutter engine is in
        // "resumed" state and Navigator transitions will render correctly.
        val link = pendingWarmLink ?: return
        pendingWarmLink = null
        deepLinkChannel?.invokeMethod("onDeepLinkReceived", link)
    }
}