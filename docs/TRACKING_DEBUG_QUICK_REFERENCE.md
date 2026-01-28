# Tracking Debug Quick Reference

## How to Debug Devotional Reading Tracking

### Filter Logs for Tracking

Use these commands to filter tracking-related logs:

```bash
# All tracking logs
adb logcat | grep "\[TRACKING\]"

# All tracker (ReadingTracker) logs  
adb logcat | grep "\[TRACKER\]"

# All devotional page logs
adb logcat | grep "\[DEVOCIONALES_PAGE\]"

# Combined tracking logs
adb logcat | grep -E "\[TRACKING\]|\[TRACKER\]"

# Show only timer-related logs
adb logcat | grep "Timer"
```

### Expected Log Flow

#### 1. App Initialization

```
[TRACKING] 🔄 DevocionalesTracking inicializando...
[TRACKING] ✅ DevocionalesTracking inicializado correctamente
```

After 2 seconds:

```
[TRACKING] ✅ Timer de prueba funcionó - sistema de timers OK
```

#### 2. Navigate to Devotional

```
[DEVOCIONALES_PAGE] 🔔 BlocListener triggered - state: NavigationReady
[DEVOCIONALES_PAGE] ✅ NavigationReady - starting tracking for: [devotional_id]
[TRACKING] 🚀 startDevocionalTracking() llamado para [devotional_id]
[TRACKER] startTracking() llamado para [devotional_id]
[TRACKER] Tracking inicializado - ID: [devotional_id], startTime: [timestamp]
[TRACKER] ⏱️ Timer de lectura INICIADO
[TRACKING] 🔄 Timer de evaluación de criterios CREADO - isActive: true
```

#### 3. Every 5 Seconds (While Reading)

```
[TRACKER] ⏲️ Timer activo - ID: [devotional_id], tiempo: Xs, scroll: Y%
[TRACKING] ⏲️ Timer tick #N - evaluando criterios...
[TRACKING] 🔄 _checkReadingCriteria() ejecutándose...
[TRACKING] 📖 Evaluando devocional: [devotional_id]
[TRACKING] ⏱️ Tiempo de lectura: Xs, Scroll: Y%
[TRACKING] ✔️ ¿Cumple criterios?: false
[TRACKING] ⏳ Criterios aún no cumplidos (necesita: 40s y 60% scroll)
```

#### 4. When Criteria Met (40s + 60% scroll)

```
[TRACKING] ✔️ ¿Cumple criterios?: true
[TRACKING] ✅ Criterios cumplidos automáticamente - actualizando stats inmediatamente
📊 [TRACKING] Stats actualizados para [devotional_id] (source: read)
```

#### 5. After Completion

```
[TRACKING] ⏭️ Devocional [devotional_id] ya fue auto-completado, saltando evaluación
```

### Common Issues and What to Look For

#### No Tracking Logs at All

**Problem:** Context might be null or not initialized  
**Look for:**

```
[TRACKING] ❌ DevocionalesTracking no inicializado (context null)
```

**Solution:** Verify `_tracking.initialize(context)` is called in initState

#### Timer Ticks Not Appearing

**Problem:** Timer not being created or stopped  
**Look for:**

```
[TRACKING] 🔄 Timer de evaluación de criterios CREADO - isActive: false
```

**Solution:** Check if timer is being cancelled prematurely

#### Criteria Check Stops Early

**Possible reasons:**

- Context became null: `[TRACKING] ❌ Context null o no mounted`
- No devotionals loaded: `[TRACKING] ❌ Lista de devocionales vacía`
- Not tracking anything: `[TRACKING] ❌ No hay devocional siendo trackeado`
- Already completed: `[TRACKING] ⏭️ Devocional X ya fue auto-completado`

#### Stats Not Saving

**Problem:** Criteria never met or stats service failing  
**Look for:**

- Time and scroll values in logs
- Check if both reach thresholds (40s + 60%)
- Look for error messages in stats update

### Reading Criteria

A devotional is marked as "read" when:

- **Reading time:** >= 40 seconds
- **Scroll percentage:** >= 60% (0.6)

### Quick Commands

```bash
# Start tracking a specific devotional (look for its logs)
adb logcat | grep "filipenses2_3-4RVR1960"

# Check if timer is active
adb logcat | grep "Timer.*activo"

# See when criteria are met
adb logcat | grep "Criterios cumplidos"

# Check stats updates
adb logcat | grep "Stats actualizados"

# See all timer ticks
adb logcat | grep "Timer tick"

# Check BLoC state emissions
adb logcat | grep "BlocListener triggered"
```

### Debugging Checklist

- [ ] Tracking initialized: See initialization logs
- [ ] Timer test passed: See "Timer de prueba funcionó"
- [ ] BLoC listener triggered: See "BlocListener triggered"
- [ ] Tracking started: See "startDevocionalTracking() llamado"
- [ ] ReadingTracker initialized: See "Tracking inicializado"
- [ ] Criteria timer created: See "Timer de evaluación de criterios CREADO"
- [ ] Timer is active: See "isActive: true"
- [ ] Periodic ticks: See timer ticks every 5 seconds
- [ ] Criteria evaluated: See "Evaluando devocional" logs
- [ ] Progress tracking: Time and scroll increasing
- [ ] Criteria met: Eventually see "Criterios cumplidos"
- [ ] Stats updated: See "Stats actualizados"

### Performance Notes

- ReadingTracker timer ticks every **1 second**
- Criteria check timer ticks every **5 seconds**
- Timer logs appear every **5 seconds** (reduces log spam)
- Stats are saved **immediately** when criteria met (no delay)
