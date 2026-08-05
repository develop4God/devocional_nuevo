package com.develop4god.devocional_nuevo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.view.WindowCompat
import com.google.firebase.crashlytics.FirebaseCrashlytics // ¡Añade esta importación!

class MainActivity : FlutterActivity() {

    // Mirrors resume-watchdog breadcrumbs to logcat in addition to Crashlytics.
    // Crashlytics.log() only uploads with the next crash/non-fatal report, so it's
    // invisible in a live `flutter run`/logcat session — this makes the watchdog's
    // otherwise-silent trigger/outcome observable while testing on a real device.
    private fun logWatchdog(message: String) {
        Log.d("ResumeWatchdog", message)
        FirebaseCrashlytics.getInstance().log(message)
    }

    // Method channels
    private val CRASHLYTICS_CHANNEL = "com.develop4god.devocional_nuevo/crashlytics"
    private val GENERAL_CHANNEL = "com.devocional_nuevo.test_channel"
    private val DEEP_LINK_CHANNEL = "com.develop4god.devocional/deeplink"
    private val RESUME_WATCHDOG_CHANNEL = "com.develop4god.devocional_nuevo/resume_watchdog"

    // Store initial deep link (cold-start, read via getInitialLink channel call)
    private var initialLink: String? = null

    // Deep link received during a warm start (onNewIntent) that must be
    // dispatched to Flutter only after the activity is fully resumed, so that
    // the Flutter engine is in "resumed" state when Navigator.push() fires.
    private var pendingWarmLink: String? = null

    // Store FlutterEngine reference for sending deep links while app is running
    private var deepLinkChannel: MethodChannel? = null

    // Reference to the engine's actual rendering surface, needed to apply the
    // resume nudge directly on it (see onResume). Set via the
    // onFlutterSurfaceViewCreated callback, which fires before onResume.
    private var flutterSurfaceView: FlutterSurfaceView? = null

    // ---- Black-screen-on-resume telemetry ----
    // Added 2026-07-22. Some Android OEM builds (observed: MIUI/Xiaomi, also
    // reported upstream on stock Android 14/15 — flutter/flutter#147849, #139630)
    // can leave the Flutter engine's raster/UI thread silently unresponsive after
    // a background->foreground resume, producing a black screen with no Dart-side
    // signal (confirmed: zero Dart log output, unresponsive to input, even the
    // Flutter debugger can't attach).
    //
    // The freeze itself is in Flutter's raster/UI thread, which can't detect or act on
    // its own hang — but this activity's Android platform thread is separate and stays
    // responsive, which is what the "Live auto-recovery" block below uses to recover
    // live (see that comment for the active mitigation). This block instead records
    // whether a resume was ever confirmed as actually drawn, for the case where the
    // live recovery attempt doesn't help and the app is later killed while still stuck
    // (as users do today via force-close) and relaunched: the next cold start checks
    // ApplicationExitInfo (API 30+) to see if the previous exit actually looks like
    // this bug (ANR/crash/signal) rather than an ordinary OS-reaped background kill
    // or the user just closing the app normally, and reports it to Crashlytics as a
    // non-fatal event if so — this remains the production signal for how often live
    // recovery isn't enough.
    private val watchdogPrefs: SharedPreferences by lazy {
        getSharedPreferences("resume_watchdog", MODE_PRIVATE)
    }
    private val prefKeyPending = "resume_pending"
    private val prefKeyPendingSince = "resume_pending_since_ms"

    // ---- Live auto-recovery ----
    // Added 2026-08-05, after production telemetry (573+ affected users, spanning
    // Android 8-16 and all major OEMs, correlated with low free RAM) confirmed this
    // is a real, frequent failure rather than a rare edge case. The freeze itself
    // (Flutter's raster/UI thread stuck, per the diagnostic above) can't detect or
    // fix itself — but this timer runs on the Android platform main thread, which is
    // separate from Flutter's engine threads, so it keeps running even while Flutter
    // is frozen. If no confirmResumeDrawn() call arrives within resumeConfirmTimeoutMs,
    // this activity is recreated once to force the engine's surface to reattach
    // cleanly.
    //
    // recreate() can destroy this Activity instance and create a fresh one, so the
    // one-attempt guard is persisted in prefs (survives instance recreation) rather
    // than kept as a plain field. It's cleared on a confirmed-drawn resume or a fresh
    // cold start; if recreate() doesn't fix it, the guard stays set so this fires at
    // most once per stuck cycle, and onCreate()'s reportStaleResumeMarkerIfAny() still
    // reports to Crashlytics on the next cold start instead of looping.
    private val prefKeyRecreateAttempted = "resume_recreate_attempted"
    private val resumeConfirmTimeoutMs = 3000L
    private var resumeConfirmed = false
    private val resumeWatchdogHandler = Handler(Looper.getMainLooper())
    private val resumeTimeoutRunnable = Runnable {
        if (resumeConfirmed) return@Runnable
        if (watchdogPrefs.getBoolean(prefKeyRecreateAttempted, false)) {
            logWatchdog("resume_watchdog: timeout fired again but recreate() already attempted this cycle — not looping")
            return@Runnable
        }
        watchdogPrefs.edit().putBoolean(prefKeyRecreateAttempted, true).apply()
        logWatchdog(
            "resume_watchdog: triggered, resume not confirmed within ${resumeConfirmTimeoutMs}ms, calling recreate()"
        )
        // recreate() can throw if the activity is already finishing/destroyed by
        // the time this delayed callback fires (e.g. user navigated away in the
        // interim). Never let a failed recovery attempt crash the app outright —
        // the existing reportStaleResumeMarkerIfAny() path still catches this case
        // via ApplicationExitInfo on the next cold start if recovery didn't work.
        try {
            recreate()
            logWatchdog("resume_watchdog: recreate() call returned normally")
        } catch (e: Exception) {
            logWatchdog("resume_watchdog: recreate() threw: ${e.javaClass.simpleName}: ${e.message}")
            FirebaseCrashlytics.getInstance().recordException(e)
        }
    }

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

        reportStaleResumeMarkerIfAny()

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

    override fun onFlutterSurfaceViewCreated(surfaceView: FlutterSurfaceView) {
        super.onFlutterSurfaceViewCreated(surfaceView)
        flutterSurfaceView = surfaceView
    }

    // If a resume was left unconfirmed (app was killed while stuck, per the
    // black-screen-on-resume issue), report it once via Crashlytics on this
    // fresh cold start, then clear the marker so it isn't reported again.
    //
    // An unconfirmed marker alone isn't enough signal: onPause() sets it on
    // EVERY backgrounding, including ones that end in a completely ordinary
    // OS-reaped low-memory kill or the user just closing the app normally —
    // neither of which is the bug being measured here. ApplicationExitInfo
    // (API 30+) lets us check the actual reason the previous process exited
    // and only report the cases that plausibly match a genuine freeze.
    private fun reportStaleResumeMarkerIfAny() {
        if (!watchdogPrefs.getBoolean(prefKeyPending, false)) return

        val pendingSinceMs = watchdogPrefs.getLong(prefKeyPendingSince, 0L)
        val staleForMs = if (pendingSinceMs > 0) System.currentTimeMillis() - pendingSinceMs else -1L
        // Clear only the staleness-tracking keys, not prefKeyRecreateAttempted: this
        // runs on every cold start, including the one recreate() itself triggers when
        // the live-recovery timeout fires. Wiping the whole prefs file here would erase
        // the one-attempt guard on that exact cold start, letting onResume() re-arm the
        // timeout and call recreate() again if the underlying freeze persists — an
        // unbounded recreate loop instead of a single bounded attempt.
        watchdogPrefs.edit()
            .remove(prefKeyPending)
            .remove(prefKeyPendingSince)
            .apply()

        if (!likelyMatchesBlackScreenExit()) return

        FirebaseCrashlytics.getInstance().recordException(
            Exception("Resume never confirmed drawn before app restart (possible black-screen-on-resume)")
        )
        logWatchdog("resume_watchdog: unconfirmed resume detected on cold start, staleForMs=$staleForMs")
    }

    // Returns true only if the most recent process exit reason plausibly
    // matches a genuine freeze (ANR, crash, or the process being killed by a
    // signal — e.g. Force Stop / SIGKILL, which is what a stuck user's
    // manual force-close produces). Explicitly excludes REASON_LOW_MEMORY
    // (ordinary OS background reaping) and REASON_USER_REQUESTED (the user
    // just closed the app normally), which are common and unrelated to this
    // bug. Returns true (fail open) if the reason can't be determined, e.g.
    // on API < 30, so the signal defaults to reporting rather than silently
    // under-counting on older devices.
    //
    // getHistoricalProcessExitReasons() is a documented AOSP API but reads
    // OEM-maintained process-death bookkeeping, which several other checks
    // in this investigation found to be inconsistently implemented (e.g.
    // MIUI's own ANR-suppression layer) — wrapped defensively so a failure
    // here can never crash onCreate() or block app startup.
    private fun likelyMatchesBlackScreenExit(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return true

        return try {
            val activityManager = getSystemService(ACTIVITY_SERVICE) as? android.app.ActivityManager
                ?: return true
            val reasons = activityManager.getHistoricalProcessExitReasons(packageName, 0, 1)
            val lastReason = reasons.firstOrNull()?.reason ?: return true

            when (lastReason) {
                android.app.ApplicationExitInfo.REASON_ANR,
                android.app.ApplicationExitInfo.REASON_CRASH,
                android.app.ApplicationExitInfo.REASON_CRASH_NATIVE,
                android.app.ApplicationExitInfo.REASON_SIGNALED -> true
                android.app.ApplicationExitInfo.REASON_LOW_MEMORY,
                android.app.ApplicationExitInfo.REASON_USER_REQUESTED -> false
                else -> {
                    // Not one of the reasons we explicitly recognize either
                    // way (e.g. REASON_OTHER, REASON_UNKNOWN, or a new
                    // constant added in a future Android version). Log it
                    // verbatim instead of silently lumping it in with the
                    // known-excluded cases, so an unexpected pattern is
                    // visible if it starts showing up in Crashlytics.
                    logWatchdog("resume_watchdog: unrecognized exit reason code=$lastReason")
                    false
                }
            }
        } catch (e: Exception) {
            // Never let a telemetry read failure affect startup; fail open
            // so the underlying signal still gets reported rather than lost.
            logWatchdog("resume_watchdog: error reading exit reason: ${e.message}")
            true
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

        // Resume watchdog channel — Dart calls confirmResumeDrawn() once a frame has
        // actually rendered after resume, clearing the pending marker set in onPause().
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RESUME_WATCHDOG_CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "confirmResumeDrawn") {
                if (watchdogPrefs.getBoolean(prefKeyRecreateAttempted, false)) {
                    logWatchdog("resume_watchdog: resume confirmed after recreate() — recovery succeeded")
                }
                watchdogPrefs.edit().clear().apply()
                resumeConfirmed = true
                resumeWatchdogHandler.removeCallbacks(resumeTimeoutRunnable)
                result.success(null)
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

    override fun onPause() {
        super.onPause()
        // Mark this resume cycle as unconfirmed. Cleared either by Dart calling
        // confirmResumeDrawn() after the next resume actually renders a frame, or
        // by reportStaleResumeMarkerIfAny() on the next cold start if it wasn't.
        watchdogPrefs.edit()
            .putBoolean(prefKeyPending, true)
            .putLong(prefKeyPendingSince, System.currentTimeMillis())
            .apply()

        resumeWatchdogHandler.removeCallbacks(resumeTimeoutRunnable)
    }

    override fun onResume() {
        super.onResume()

        // Nudge the rendering surface on resume. Some OEM Android builds (and
        // stock Android 14/15 per flutter/flutter#139630, #147849) can leave
        // the Flutter engine's surface desynced after a background->foreground
        // resume, producing a black screen. Forcing a layout pass directly on
        // the surface view is a known, low-cost mitigation from the Flutter
        // engine team — see the linked issue for the source of this approach.
        // Safe to call unconditionally: it's a no-op cost when the engine is
        // already rendering correctly.
        Handler(Looper.getMainLooper()).postDelayed({
            flutterSurfaceView?.requestLayout()
        }, 1)

        // Arm the live auto-recovery timeout for this resume cycle. Cancelled by
        // confirmResumeDrawn() if a frame actually renders in time; otherwise fires
        // recreate() once. See the "Live auto-recovery" comment above for context.
        resumeConfirmed = false
        resumeWatchdogHandler.postDelayed(resumeTimeoutRunnable, resumeConfirmTimeoutMs)

        // Dispatch any warm-start deep link now that the Flutter engine is in
        // "resumed" state and Navigator transitions will render correctly.
        val link = pendingWarmLink ?: return
        pendingWarmLink = null
        deepLinkChannel?.invokeMethod("onDeepLinkReceived", link)
    }
}