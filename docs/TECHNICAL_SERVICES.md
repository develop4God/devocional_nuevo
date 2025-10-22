# Servicios Técnicos - Documentación

## Índice de Servicios

- [Servicio de Localización](#servicio-de-localización)
- [Servicio TTS (Text-to-Speech)](#servicio-tts-text-to-speech)
- [Controlador de Audio](#controlador-de-audio)
- [Proveedor de Devocionales](#proveedor-de-devocionales)
- [Proveedor de Oraciones](#proveedor-de-oraciones)
- [Servicio de Estadísticas Espirituales](#servicio-de-estadísticas-espirituales)
- [Cobertura de Testing](#cobertura-de-testing)

---

## Servicio de Localización

### Archivo: `lib/services/localization_service.dart`

### Propósito
Gestiona la configuración de idiomas y traduciones multilingües para la aplicación.

### Características Principales
- **Soporte para 4 idiomas**: Español (es), Inglés (en), Portugués (pt), Francés (fr)
- **Traducciones dinámicas**: Sistema de carga de archivos JSON por idioma
- **Singleton Pattern**: Una sola instancia global para consistencia
- **Persistencia**: Guarda el idioma seleccionado en SharedPreferences
- **Fallback**: Manejo graceful de claves de traducción faltantes

### Funciones Clave

```dart
// Cambiar idioma de la aplicación
Future<void> changeLocale(Locale locale)

// Traducir una clave específica
String translate(String key, [Map<String, dynamic>? params])

// Obtener idioma actual
Locale get currentLocale

// Obtener idiomas soportados
static List<Locale> get supportedLocales

// Reinicializar el servicio
static void resetInstance()
```

### Testing Coverage: 95%+
- ✅ Cambio de idioma en tiempo real
- ✅ Traducción de claves básicas de la app
- ✅ Manejo de claves faltantes
- ✅ Persistencia de configuración
- ✅ Rendimiento con 1000+ traducciones

---

## Servicio TTS (Text-to-Speech)

### Archivo: `lib/services/tts_service.dart`

### Propósito
Maneja la conversión de texto a voz para los devocionales, incluyendo fragmentación de contenido y control de reproducción.

### Características Principales
- **Soporte Multilingüe**: Compatible con es-ES, en-US, pt-BR, fr-FR
- **Fragmentación Inteligente**: Divide devocionales en chunks para mejor rendimiento
- **Control de Estado**: Estados claros (idle, playing, paused, error)
- **Gestión de Errores**: Manejo robusto de excepciones de plataforma
- **Timer de Emergencia**: Prevención de estados colgados

### Estados del Servicio

```dart
enum TtsState {
  idle,        // Inactivo, listo para uso
  initializing,// Inicializando servicio
  playing,     // Reproduciendo audio
  paused,      // Pausado
  error        // Error en operación
}
```

### Funciones Clave

```dart
// Configurar contexto de idioma
void setLanguageContext(String language, String version)

// Reproducir devocional completo
Future<void> speakDevotional(String devocionalId, String fullText)

// Control de reproducción
Future<void> pause()
Future<void> resume()
Future<void> stop()

// Estado actual
TtsState get currentState
Stream<TtsState> get stateStream
Stream<double> get progressStream

// Cleanup
void dispose()
```

### Testing Coverage: 95%+
- ✅ Inicialización y configuración
- ✅ Cambios de contexto de idioma
- ✅ Manejo de estados (13 tests)
- ✅ Gestión de errores de plataforma
- ✅ Operaciones concurrentes
- ✅ Disposal y cleanup

---

## Controlador de Audio

### Archivo: `lib/controllers/audio_controller.dart`

### Propósito
Proxy reactivo entre la UI y el servicio TTS, proporcionando una interfaz simplificada para control de audio.

### Características Principales
- **Proxy Reactivo**: Sincronización automática con TtsService
- **Estado Simplificado**: Interfaz unificada para la UI
- **Gestión de Operaciones**: Prevención de operaciones conflictivas
- **Notificaciones**: ChangeNotifier para actualizaciones de UI

### Funciones Clave

```dart
// Control de reproducción
Future<void> playDevotional(Devocional devotional)
Future<void> togglePlayPause(Devocional devotional)
void pause()
void resume()
void stop()

// Estado actual
bool get isPlaying
bool get isPaused
bool get isActive
bool get isLoading
bool get hasError
double get progress

// Información actual
String? get currentDevocionalId
TtsState get currentState

// Navegación de chunks
int? get currentChunkIndex
int? get totalChunks
VoidCallback? get previousChunk
VoidCallback? get nextChunk
```

### Testing Coverage: 75%+
- ✅ Inicialización y estado básico
- ✅ Control de reproducción
- ✅ Manejo de operaciones concurrentes
- ✅ Gestión de datos inválidos
- ✅ Testing de rendimiento

---

## Proveedor de Devocionales

### Archivo: `lib/providers/devocional_provider.dart`

### Propósito
Controlador principal de la aplicación que gestiona devocionales, idiomas, versiones y funcionalidad offline.

### Características Principales
- **Soporte Multilingüe**: 4 idiomas con múltiples versiones bíblicas
- **Gestión Offline**: Descarga y almacenamiento local de contenido
- **Control de Audio**: Integración con AudioController
- **Favoritos**: Gestión de devocionales favoritos
- **Tracking**: Seguimiento de lectura y progreso

### Idiomas y Versiones Soportadas

```dart
final Map<String, List<String>> languageVersions = {
  'es': ['RVR1960', 'NVI'],      // Español
  'en': ['KJV', 'NIV'],          // Inglés  
  'pt': ['ARC'],                 // Portugués
  'fr': ['LSG1910']              // Francés
};
```

### Funciones Clave

```dart
// Gestión de idioma y versión
void setSelectedLanguage(String language)
void setSelectedVersion(String version)
List<String> getVersionsForLanguage(String language)
bool isLanguageSupported(String language)

// Gestión offline
Future<bool> downloadCurrentYearDevocionales()
Future<bool> hasCurrentYearLocalData()
Future<bool> hasTargetYearsLocalData()
void clearDownloadStatus()

// Control de audio
Future<void> playDevotional(Devocional devotional)
void pauseAudio()
void resumeAudio()
void stopAudio()

// Favoritos y tracking
void toggleFavorite(Devocional devotional, BuildContext context)
bool isFavorite(Devocional devotional)
void startDevocionalTracking(String id)
void recordDevocionalRead({required String devocionalId, required int readingTimeSeconds, required double scrollPercentage})
```

### Testing Coverage: 90%+
- ✅ Inicialización con valores por defecto
- ✅ Cambio de idiomas y versiones
- ✅ Validación de idiomas soportados
- ✅ Gestión de estado offline
- ✅ Control de audio integrado
- ✅ Manejo de favoritos
- ✅ Tracking de lectura

---

## Proveedor de Oraciones

### Archivo: `lib/providers/prayer_provider.dart`

### Propósito
Gestiona las oraciones personales del usuario, incluyendo estados, estadísticas y persistencia.

### Características Principales
- **Estados de Oración**: Activa, Respondida con fechas
- **Persistencia**: Almacenamiento local con backup automático
- **Estadísticas**: Métricas de oraciones activas y respondidas
- **Ordenamiento**: Oraciones activas primero, respondidas por fecha

### Funciones Clave

```dart
// Gestión de oraciones
Future<void> addPrayer(String text)
Future<void> markPrayerAsAnswered(String prayerId)
Future<void> markPrayerAsActive(String prayerId)
Future<void> editPrayer(String prayerId, String newText)
Future<void> deletePrayer(String prayerId)

// Consultas
List<Prayer> get prayers
List<Prayer> get activePrayers
List<Prayer> get answeredPrayers
Map<String, dynamic> getStats()

// Estado
bool get isLoading
String? get errorMessage
```

### Modelo de Oración

```dart
class Prayer {
  final String id;
  final String text;
  final DateTime createdDate;
  final PrayerStatus status;
  final DateTime? answeredDate;
  
  // Métodos
  bool get isActive
  bool get isAnswered
  int get daysOld
  Prayer copyWith({...})
}

enum PrayerStatus { active, answered }
```

### Testing Coverage: 95%+
- ✅ Creación y validación de oraciones
- ✅ Cambio de estados (activa ↔ respondida)
- ✅ Edición y eliminación
- ✅ Cálculo de estadísticas
- ✅ Persistencia y backup
- ✅ Manejo de errores

---

## Cobertura de Testing

### Resumen General
- **Total de Tests**: 80+ tests unitarios y de integración
- **Servicios Críticos**: 95%+ cobertura
- **Proveedores**: 90%+ cobertura
- **Controladores**: 75%+ cobertura

### Infraestructura de Testing
- **Mock Setup**: Configuración común para plugins de Flutter
- **Generated Mocks**: Mockito con @GenerateMocks para type safety
- **Plugin Mocking**: path_provider, shared_preferences, flutter_tts
- **Performance**: Todos los tests < 30 segundos

### Tests por Componente

| Componente | Tests | Cobertura | Estado |
|------------|-------|-----------|--------|
| PrayerProvider | 15 | 95%+ | ✅ Passing |
| TtsService | 13 | 95%+ | ✅ Passing |
| LocalizationService | 4 | 95%+ | ✅ Passing |
| DevocionalProvider | 15 | 90%+ | ✅ Passing |
| AudioController | 11 | 75%+ | ✅ Passing |
| Models (Prayer) | 5 | 100% | ✅ Passing |

### Tipos de Tests Implementados
- **Unit Tests**: Funcionalidad aislada de servicios
- **State Management**: Verificación de cambios de estado
- **Error Handling**: Manejo de excepciones y casos edge
- **Performance**: Tests de estrés y concurrencia
- **Integration**: Interacción entre componentes

### Versiones de Biblia por Idioma
- **Español**: RVR1960 (principal)
- **Inglés**: KJV (fallback desde NIV)
- **Portugués**: ARC (fallback desde NVI) 
- **Francés**: LSG (principal)

---

## Servicio TTS (Text-to-Speech)

### Archivos: 
- `lib/services/tts_service.dart`
- `lib/services/tts/bible_text_formatter.dart`
- `lib/services/tts/language_text_normalizer.dart`
- `lib/services/tts/specialized_text_normalizer.dart`

### Propósito
Proporciona funcionalidad de síntesis de voz para la lectura de devocionales con soporte multilingüe avanzado.

### Características Principales
- Selección automática de voces por idioma
- Normalización de texto específica por idioma
- Formateo especializado para textos bíblicos
- Controles de reproducción (play, pause, stop)
- Ajuste de velocidad y pitch

### Componentes

#### TTS Service Principal
```dart
class TtsService {
  // Reproducir texto con normalización automática
  Future<void> speak(String text, String language)
  
  // Controles de reproducción
  Future<void> pause()
  Future<void> resume()
  Future<void> stop()
  
  // Configuración de voz
  Future<void> setVoice(String voiceId)
  Future<List<Voice>> getAvailableVoices(String language)
}
```

#### Normalizador de Texto por Idioma
- **Español**: Expansión de abreviaciones bíblicas (Mt → Mateo)
- **Inglés**: Normalización de ordinales (1st → first)
- **Portugués**: Adaptación de acentos y contracciones
- **Francés**: Manejo de liaison y pronunciación especial

#### Formateador de Texto Bíblico
- Expansión de referencias bíblicas
- Normalización de números de versículos
- Manejo de citas y comillas especiales
- Pausas apropiadas para puntuación

### Flujo de TTS

```
Texto de entrada → Normalización por idioma → 
Formateo bíblico → Selección de voz → 
Configuración de parámetros → Síntesis de voz → 
Reproducción con controles
```

---

## Servicio de Notificaciones

### Archivo: `lib/services/notification_service.dart`

### Propósito
Gestiona notificaciones locales y push notifications para recordatorios de devocionales.

### Características Principales
- Notificaciones diarias programables
- Soporte para múltiples zonas horarias
- Integración con Firebase Cloud Messaging
- Notificaciones personalizables por idioma

### Funciones Clave

```dart
class NotificationService {
  // Configurar notificaciones diarias
  Future<void> scheduleDailyNotification(TimeOfDay time)
  
  // Cancelar notificaciones
  Future<void> cancelAllNotifications()
  
  // Verificar permisos
  Future<bool> checkPermissions()
  
  // Manejar notificaciones push
  Future<void> setupFirebaseMessaging()
}
```

### Tipos de Notificaciones
1. **Recordatorio Diario**: Notificación para leer el devocional del día
2. **Notificaciones Push**: Contenido especial y actualizaciones
3. **Notificaciones de Progreso**: Logros y estadísticas espirituales

---

## Servicio de Estadísticas Espirituales

### Archivo: `lib/services/spiritual_stats_service.dart`

### Propósito
Rastrea y gestiona el progreso espiritual del usuario, incluyendo lectura de devocionales, oraciones guardadas y logros.

### Características Principales
- Seguimiento de devocionales leídos
- Sistema de logros/achievements
- Estadísticas de progreso
- Respaldos automáticos de datos

### Funciones Clave

```dart
class SpiritualStatsService {
  // Registrar lectura de devocional
  Future<void> recordDevocionalRead(String devocionalId)
  
  // Verificar si se completó la lectura
  bool hasDevocionalBeenRead(String devocionalId)
  
  // Obtener estadísticas del usuario
  Future<Map<String, dynamic>> getUserStats()
  
  // Gestionar logros
  Future<void> checkAndUnlockAchievements()
}
```

### Métricas Rastreadas
- Devocionales leídos consecutivos
- Total de devocionales completados
- Oraciones guardadas como favoritas
- Tiempo promedio de lectura
- Días de uso consecutivos

---

## Servicio de Seguimiento de Devocionales

### Archivo: `lib/services/devocionales_tracking.dart`

### Propósito
Gestiona el seguimiento detallado de la interacción del usuario con cada devocional.

### Características Principales
- Registro de tiempo de lectura
- Seguimiento de scroll/progreso
- Detección de lectura completa
- Análisis de patrones de uso

### Criterios de Lectura Completa
- Tiempo mínimo de lectura: 60 segundos
- Scroll mínimo: 80% del contenido
- Interacción activa con la aplicación

---

## Servicio de Actualizaciones

### Archivo: `lib/services/update_service.dart`

### Propósito
Gestiona las actualizaciones de la aplicación y verifica disponibilidad de nuevo contenido.

### Características Principales
- Verificación automática de actualizaciones
- Descarga de contenido incremental
- Notificación de nuevas versiones
- Actualización en segundo plano

### Flujo de Actualización

```
Inicio de app → Verificar versión → 
Comparar con servidor → 
Si hay actualización → Notificar usuario → 
Descargar en segundo plano → 
Aplicar actualización → Reiniciar si necesario
```

---

## Interacción Entre Servicios

Los servicios están diseñados para trabajar de manera independiente pero coordinada:

1. **LocalizationService** ↔ **TtsService**: Coordinación para voces por idioma
2. **SpiritualStatsService** ↔ **DevocionalTrackingService**: Registro de progreso
3. **NotificationService** ↔ **UpdateService**: Notificaciones de actualizaciones
4. **Todos los servicios** → **LocalStorage**: Persistencia de datos

## Gestión de Errores

Todos los servicios implementan:
- Try-catch comprehensivo
- Logging detallado para debug
- Fallbacks gracioso para errores de red
- Recuperación automática cuando es posible

## Consideraciones de Rendimiento

- Servicios cargados de manera lazy
- Caché inteligente de datos frecuentemente usados
- Limpieza automática de datos antiguos
- Operaciones asíncronas para UI no bloqueante