# Servicios Técnicos - Documentación

## Índice de Servicios

- [Servicio de Localización](#servicio-de-localización)
- [Servicio TTS (Text-to-Speech)](#servicio-tts-text-to-speech)
- [Servicio de Notificaciones](#servicio-de-notificaciones)
- [Servicio de Estadísticas Espirituales](#servicio-de-estadísticas-espirituales)
- [Servicio de Seguimiento de Devocionales](#servicio-de-seguimiento-de-devocionales)
- [Servicio de Actualizaciones](#servicio-de-actualizaciones)

---

## Servicio de Localización

### Archivo: `lib/services/localization_service.dart`

### Propósito
Gestiona la configuración de idiomas y descarga de contenido multilingüe para la aplicación.

### Características Principales
- Soporte para 4 idiomas: Español, Inglés, Portugués, Francés
- Descarga automática de contenido por idioma
- Fallback inteligente cuando versiones específicas no están disponibles
- Detección automática de idioma del sistema

### Funciones Clave

```dart
// Cambiar idioma de la aplicación
Future<bool> changeLanguage(String languageCode)

// Descargar contenido para un idioma específico
Future<bool> downloadLanguageContent(String languageCode)

// Verificar si un idioma tiene contenido descargado
Future<bool> hasLanguageContent(String languageCode)

// Obtener idiomas disponibles
List<String> getAvailableLanguages()
```

### Flujo de Descarga de Idioma

```
Usuario selecciona idioma → Verificar contenido local → 
Si no existe → Descargar desde servidor →
Aplicar fallback si falla → Guardar localmente → 
Actualizar UI → Navegar de vuelta
```

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