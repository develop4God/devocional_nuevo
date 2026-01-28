# Bug Fix: Missing [TRACKING] Logs and Devotional Read Stats Not Saving

**Date:** January 28, 2026  
**Issue:** Devotional reading tracking was not showing any logs and devotional read stats were not
being saved

## Problem Description

User reported that tracking service logs were missing:

- No `[TRACKING]` debug prints appearing every 5 seconds
- Devotional IDs not being saved to stats
- No information about read time tracking
- Users could navigate between devotionals but nothing was being recorded

## Root Cause Analysis

The tracking system had several silent failure points where early returns prevented any debug
logging:

1. **`_checkReadingCriteria()` method** - Had 4 early return points before any logging:
    - Context null or not mounted → silent return
    - Devotionals list empty → silent return
    - No currentTrackedDevocionalId → silent return
    - Devotional already auto-completed → silent return

2. **Timer lifecycle not visible** - No debug logging to confirm:
    - Timer was actually created
    - Timer was firing periodically
    - Timer tick count

3. **ReadingTracker timer** - No logging to show:
    - When tracking was initialized
    - When timer started
    - Current tracking state during operation

4. **BlocListener not verified** - No way to confirm:
    - NavigationReady state was being emitted
    - startDevocionalTracking was being called

## Solution Implemented

### 1. Enhanced Debug Logging in `devocionales_tracking.dart`

#### Added logs to `initialize()`:

```dart
void initialize(BuildContext context) {
  _context = context;
  debugPrint('[TRACKING] 🔄 DevocionalesTracking inicializando...');

  // Test timer system
  Timer(const Duration(seconds: 2), () {
    debugPrint('[TRACKING] ✅ Timer de prueba funcionó - sistema de timers OK');
  });

  debugPrint('[TRACKING] ✅ DevocionalesTracking inicializado correctamente');
}
```

#### Added logs to `startCriteriaCheckTimer()`:

```dart
void startCriteriaCheckTimer() {
  _criteriaCheckTimer?.cancel();
  debugPrint('[TRACKING] 🔄 Creando timer de evaluación de criterios...');
  _criteriaCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    debugPrint('[TRACKING] ⏲️ Timer tick #${timer.tick} - evaluando criterios...');
    _checkReadingCriteria();
  });
  final isActive = _criteriaCheckTimer?.isActive ?? false;
  debugPrint(
      '[TRACKING] 🔄 Timer de evaluación de criterios CREADO - isActive: $isActive (cada 5s)');
}
```

#### Added early-return logging to `_checkReadingCriteria()`:

```dart
void _checkReadingCriteria() {
  debugPrint('[TRACKING] 🔄 _checkReadingCriteria() ejecutándose...');

  if (_context == null || !_context!.mounted) {
    debugPrint('[TRACKING] ❌ Context null o no mounted');
    return;
  }

  final devocionales = devocionalProvider.devocionales;
  if (devocionales.isEmpty) {
    debugPrint('[TRACKING] ❌ Lista de devocionales vacía');
    return;
  }

  final currentDevocionalId = devocionalProvider.currentTrackedDevocionalId;
  if (currentDevocionalId == null) {
    debugPrint('[TRACKING] ❌ No hay devocional siendo trackeado');
    return;
  }

  if (_autoCompletedDevocionals.contains(currentDevocional.id)) {
    debugPrint('[TRACKING] ⏭️ Devocional ${currentDevocional
        .id} ya fue auto-completado, saltando evaluación');
    return;
  }

  // Enhanced criteria evaluation logging
  debugPrint('[TRACKING] 📖 Evaluando devocional: ${currentDevocional.id}');
  debugPrint('[TRACKING] ⏱️ Tiempo de lectura: ${readingTime}s, Scroll: ${(scrollPercentage * 100)
      .toStringAsFixed(1)}%');
  debugPrint('[TRACKING] ✔️ ¿Cumple criterios?: $meetsCriteria');

  if (meetsCriteria) {
    debugPrint(
        '[TRACKING] ✅ Criterios cumplidos automáticamente - actualizando stats inmediatamente');
    _updateReadingStats(currentDevocional.id);
  } else {
    debugPrint('[TRACKING] ⏳ Criterios aún no cumplidos (necesita: 40s y 60% scroll)');
  }
}
```

#### Enhanced `startDevocionalTracking()` logging:

```dart
void startDevocionalTracking(String devocionalId, ScrollController scrollController) {
  debugPrint('[TRACKING] 🚀 startDevocionalTracking() llamado para $devocionalId');

  if (_context == null) {
    debugPrint('[TRACKING] ❌ DevocionalesTracking no inicializado (context null)');
    return;
  }

  debugPrint('[TRACKING] 📊 Antes de start: trackedId=${devocionalProvider
      .currentTrackedDevocionalId}, segundos=${devocionalProvider.currentReadingSeconds}');

  devocionalProvider.startDevocionalTracking(devocionalId, scrollController: scrollController);
  startCriteriaCheckTimer();

  debugPrint('[TRACKING] 📖 Tracking iniciado para devocional: $devocionalId');
  debugPrint('[TRACKING] 📊 Después de start: trackedId=${devocionalProvider
      .currentTrackedDevocionalId}, segundos=${devocionalProvider.currentReadingSeconds}');
}
```

### 2. Enhanced Debug Logging in `devocional_provider.dart` (ReadingTracker)

#### Added logs to `startTracking()`:

```dart
void startTracking(String devocionalId, {ScrollController? scrollController}) {
  debugPrint(
      '[TRACKER] startTracking() llamado para $devocionalId (current: $_currentDevocionalId)');

  if (_currentDevocionalId == devocionalId) {
    debugPrint('[TRACKER] Mismo devocional, solo resumiendo timer');
    _resumeTimer();
    return;
  }

  if (_currentDevocionalId != null) {
    debugPrint('[TRACKER] Finalizando tracking anterior: $_currentDevocionalId');
    _finalizeCurrentTracking();
  }

  debugPrint('[TRACKER] Inicializando nuevo tracking para: $devocionalId');
  _initializeTracking(devocionalId, scrollController);
}
```

#### Added logs to `_initializeTracking()`:

```dart
void _initializeTracking(String devocionalId, ScrollController? scrollController) {
  _currentDevocionalId = devocionalId;
  _startTime = DateTime.now();
  _pausedTime = null;
  _accumulatedSeconds = 0;
  _maxScrollPercentage = 0.0;

  debugPrint('[TRACKER] Tracking inicializado - ID: $devocionalId, startTime: $_startTime');

  _setupScrollController(scrollController);
  _startTimer();
}
```

#### Added periodic logging to `_startTimer()`:

```dart
void _startTimer() {
  _timer?.cancel();
  int tickCount = 0;
  _timer = Timer.periodic(const Duration(seconds: 1), (_) {
    tickCount++;
    // Log every 5 seconds for debugging
    if (tickCount % 5 == 0) {
      debugPrint(
          '[TRACKER] ⏲️ Timer activo - ID: $_currentDevocionalId, tiempo: ${currentReadingSeconds}s, scroll: ${(_maxScrollPercentage *
              100).toStringAsFixed(1)}%');
    }
  });
  debugPrint('[TRACKER] ⏱️ Timer de lectura INICIADO');
}
```

### 3. Enhanced Debug Logging in `devocionales_page.dart`

#### Added BlocListener state logging:

```dart
listener: (context, state) {debugPrint
('[DEVOCIONALES_PAGE] 🔔 BlocListener triggered - state: 
${state.runtimeType}');
if (state is NavigationReady) {
debugPrint('[DEVOCIONALES_PAGE] ✅ NavigationReady - starting tracking for: ${state.currentDevocional.id}');
_tracking.clearAutoCompletedExcept(state.currentDevocional.id);
_tracking.startDevocionalTracking(state.currentDevocional.id, _scrollController);
} else {
debugPrint('[DEVOCIONALES_PAGE] ⏭️ State is not NavigationReady, skipping tracking');
}
}
,
```

## Expected Behavior After Fix

Users should now see comprehensive tracking logs:

### On App Start:

```
[TRACKING] 🔄 DevocionalesTracking inicializando...
[TRACKING] ✅ DevocionalesTracking inicializado correctamente
[TRACKING] ✅ Timer de prueba funcionó - sistema de timers OK  (after 2 seconds)
```

### On Devotional Navigation:

```
[DEVOCIONALES_PAGE] 🔔 BlocListener triggered - state: NavigationReady
[DEVOCIONALES_PAGE] ✅ NavigationReady - starting tracking for: filipenses2_3-4RVR1960
[TRACKING] 🚀 startDevocionalTracking() llamado para filipenses2_3-4RVR1960
[TRACKING] 📊 Antes de start: trackedId=null, segundos=0
[TRACKER] startTracking() llamado para filipenses2_3-4RVR1960 (current: null)
[TRACKER] Inicializando nuevo tracking para: filipenses2_3-4RVR1960
[TRACKER] Tracking inicializado - ID: filipenses2_3-4RVR1960, startTime: 2026-01-28...
[TRACKER] ⏱️ Timer de lectura INICIADO
[TRACKING] 🔄 Creando timer de evaluación de criterios...
[TRACKING] 🔄 Timer de evaluación de criterios CREADO - isActive: true (cada 5s)
[TRACKING] 📖 Tracking iniciado para devocional: filipenses2_3-4RVR1960
[TRACKING] 📊 Después de start: trackedId=filipenses2_3-4RVR1960, segundos=0
```

### Every 5 Seconds (Tracker):

```
[TRACKER] ⏲️ Timer activo - ID: filipenses2_3-4RVR1960, tiempo: 5s, scroll: 0.0%
[TRACKER] ⏲️ Timer activo - ID: filipenses2_3-4RVR1960, tiempo: 10s, scroll: 12.5%
[TRACKER] ⏲️ Timer activo - ID: filipenses2_3-4RVR1960, tiempo: 15s, scroll: 25.3%
```

### Every 5 Seconds (Criteria Check):

```
[TRACKING] ⏲️ Timer tick #1 - evaluando criterios...
[TRACKING] 🔄 _checkReadingCriteria() ejecutándose...
[TRACKING] 📖 Evaluando devocional: filipenses2_3-4RVR1960
[TRACKING] ⏱️ Tiempo de lectura: 5s, Scroll: 10.5%
[TRACKING] ✔️ ¿Cumple criterios?: false
[TRACKING] ⏳ Criterios aún no cumplidos (necesita: 40s y 60% scroll)
```

### When Criteria Met:

```
[TRACKING] ⏲️ Timer tick #8 - evaluando criterios...
[TRACKING] 🔄 _checkReadingCriteria() ejecutándose...
[TRACKING] 📖 Evaluando devocional: filipenses2_3-4RVR1960
[TRACKING] ⏱️ Tiempo de lectura: 42s, Scroll: 65.8%
[TRACKING] ✔️ ¿Cumple criterios?: true
[TRACKING] ✅ Criterios cumplidos automáticamente - actualizando stats inmediatamente
[TRACKING] Criterio cumplido, actualizando stats para: filipenses2_3-4RVR1960
📊 [TRACKING] Stats actualizados para filipenses2_3-4RVR1960 (source: read)
```

### When Already Completed:

```
[TRACKING] ⏲️ Timer tick #9 - evaluando criterios...
[TRACKING] 🔄 _checkReadingCriteria() ejecutándose...
[TRACKING] ⏭️ Devocional filipenses2_3-4RVR1960 ya fue auto-completado, saltando evaluación
```

## Diagnostic Benefits

With these enhanced logs, we can now diagnose:

1. **Timer Issues**: Confirm timers are created and firing
2. **Context Issues**: See when context becomes null/unmounted
3. **State Issues**: Verify BLoC states are emitting correctly
4. **Tracking Logic**: Follow the complete tracking lifecycle
5. **Criteria Evaluation**: See real-time progress toward completion
6. **Early Returns**: Understand why tracking might stop silently

## Testing

Run the app and navigate to a devotional. You should see:

1. Initialization logs
2. Timer creation logs
3. Periodic tick logs every 5 seconds
4. Criteria evaluation logs every 5 seconds
5. Stats update logs when criteria met

## Files Modified

- `lib/services/devocionales_tracking.dart` - Enhanced logging throughout
- `lib/providers/devocional_provider.dart` - Enhanced ReadingTracker logging
- `lib/pages/devocionales_page.dart` - Enhanced BlocListener logging

## Follow-up Actions

1. Run app in debug mode
2. Navigate to a devotional
3. Verify logs appear as expected
4. Test that devotional read stats are being saved
5. Verify criteria checking happens every 5 seconds
6. Confirm stats are updated when criteria met

## Notes

- All logs use `[TRACKING]` or `[TRACKER]` prefix for easy filtering
- Emoji icons help visual parsing of log streams
- Early returns now explain WHY tracking stopped
- Timer tick count helps verify continuous operation
