# Flujos Técnicos - Archivos Dart Principales

## main.dart - Punto de Entrada de la Aplicación

### Propósito
Archivo principal que inicializa la aplicación, configura Firebase, y establece la estructura de providers.

### Flujo de Inicialización

```
1. main() → Configuración inicial
2. Firebase.initializeApp() → Inicialización de Firebase
3. Configuración de zona horaria
4. Configuración de providers múltiples
5. MaterialApp con navegación global
6. SplashScreen como pantalla inicial
```

### Providers Configurados
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => DevocionalProvider()),
    ChangeNotifierProvider(create: (_) => LocalizationProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => PrayerProvider()),
  ],
  child: MyApp(),
)
```

### Configuración de Firebase Cloud Messaging
- Handler para mensajes en segundo plano
- Configuración de tokens de dispositivo
- Gestión de notificaciones push

---

## devocional_provider.dart - Gestión de Estado Central

### Propósito
Provider principal que gestiona el estado de devocionales, descargas offline, y sincronización de datos.

### Características Principales
- Gestión de contenido offline
- Descarga de devocionales por año/idioma
- Estado de descarga con progreso
- Fallback automático para versiones de biblia

### Flujo de Descarga de Devocionales

```
downloadCurrentYearDevocionales() →
  ┌─ Verificar conexión a internet
  ├─ Construir URL de descarga
  ├─ Intentar descarga principal
  ├─ Si falla → Intentar versiones fallback
  ├─ Guardar contenido localmente
  ├─ Actualizar estado de descarga
  └─ Notificar listeners (UI)
```

### Estados de Descarga
- `isDownloading`: boolean
- `downloadStatus`: string con mensaje actual
- `downloadProgress`: progreso 0-100%

### Métodos Clave
```dart
// Descarga principal
Future<bool> downloadCurrentYearDevocionales()

// Verificación de datos locales
Future<bool> hasCurrentYearLocalData()

// Fallback para versiones de biblia
Future<bool> _tryVersionFallback(int year)

// Gestión de estado offline
void setOfflineMode(bool offline)
```

---

## application_language_page.dart - Página de Selección de Idioma

### Propósito
Página dedicada para selección y descarga de idiomas con interfaz moderna y seguimiento de progreso.

### Diseño de UI
- Cards para cada idioma disponible
- Indicadores de estado de descarga
- Progress bars durante descarga
- Navegación automática al completar

### Flujo de Cambio de Idioma

```
Usuario selecciona idioma →
  ┌─ Mostrar indicador de progreso
  ├─ Llamar downloadLanguageContent()
  ├─ Actualizar estado visual en tiempo real
  ├─ Si éxito → Cambiar idioma activo
  ├─ Si falla → Mostrar error con retry
  └─ Navegar automáticamente de vuelta
```

### Estados Visuales
1. **Disponible para descarga**: Icono de descarga
2. **Descargando**: Progress indicator circular
3. **Descargado**: Check mark verde
4. **Error**: Icono de error con opción de retry

### Integración con Provider
```dart
Consumer<LocalizationProvider>(
  builder: (context, locProvider, child) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return LanguageCard(
          language: languages[index],
          onTap: () => _downloadLanguage(languages[index]),
          status: locProvider.getLanguageStatus(languages[index]),
        );
      },
    );
  },
)
```

---

## tts_service.dart - Servicio de Síntesis de Voz

### Propósito
Servicio completo de Text-to-Speech con soporte multilingüe, normalización de texto y selección inteligente de voces.

### Arquitectura del Servicio
```
TtsService (principal) →
  ├─ LanguageTextNormalizer (normalización por idioma)
  ├─ BibleTextFormatter (formateo de texto bíblico)
  ├─ SpecializedTextNormalizer (casos especiales)
  └─ Flutter TTS Plugin (síntesis de voz)
```

### Flujo de Síntesis de Voz

```
speak(text, language) →
  ┌─ Normalizar texto por idioma
  ├─ Aplicar formateo bíblico
  ├─ Seleccionar voz apropiada
  ├─ Configurar parámetros (velocidad, pitch)
  ├─ Iniciar síntesis
  └─ Actualizar estado de reproducción
```

### Normalización Multilingüe
- **Español**: Abreviaciones bíblicas, números ordinales
- **Inglés**: Ordinales (1st → first), contracciones
- **Portugués**: Acentos, contracciones específicas
- **Francés**: Liaison, pronunciación especial

### Selección Inteligente de Voces
```dart
Future<String?> _selectBestVoice(String languageCode) {
  final voices = await getAvailableVoices();
  
  // Prioridad: US English → Female voices → Male voices
  return voices
    .where((voice) => voice.locale.startsWith(languageCode))
    .sortedBy((voice) => _calculateVoicePriority(voice))
    .firstOrNull?.name;
}
```

---

## devocionales_page.dart - Página Principal de Devocionales

### Propósito
Página principal donde los usuarios leen devocionales con integración completa de TTS, favoritos, y compartir.

### Componentes Principales
- Contenido del devocional (título, texto, reflexión)
- Controles de TTS (play, pause, stop)
- Botón de favoritos
- Funcionalidad de compartir
- Navegación por fechas

### Flujo de Lectura de Devocional

```
Cargar devocional del día →
  ┌─ Verificar contenido local vs online
  ├─ Cargar desde fuente apropiada
  ├─ Aplicar formateo y styling
  ├─ Inicializar controles TTS
  ├─ Configurar tracking de lectura
  └─ Mostrar UI completa
```

### Integración con TTS
```dart
void _playDevocional() async {
  final fullText = '${widget.devocional.titulo}. ${widget.devocional.contenido}';
  await TtsService.instance.speak(fullText, currentLanguage);
}
```

### Tracking de Progreso
- Tiempo de lectura mínimo (60 segundos)
- Scroll tracking (80% mínimo)
- Registro automático de progreso
- Actualización de estadísticas espirituales

---

## spiritual_stats_service.dart - Servicio de Estadísticas

### Propósito
Servicio que rastrea el progreso espiritual del usuario y gestiona sistema de logros.

### Métricas Rastreadas
```dart
class SpiritualStats {
  int totalDevocionales;
  int diasConsecutivos;
  int oracionesFavoritas;
  List<String> logrosDesbloqueados;
  DateTime ultimaLectura;
  Map<String, int> tiemposPorDevocional;
}
```

### Sistema de Logros
- **Primer Paso**: Primera lectura de devocional
- **Constante**: 7 días consecutivos
- **Devoto**: 30 días consecutivos
- **Primer Favorito**: Primera oración guardada
- **Coleccionista**: 10+ oraciones favoritas

### Flujo de Registro de Progreso

```
recordDevocionalRead(devocionalId) →
  ┌─ Verificar criterios de lectura completa
  ├─ Actualizar estadísticas locales
  ├─ Verificar logros desbloqueables
  ├─ Crear backup automático
  └─ Notificar achievements si corresponde
```

---

## offline_manager_widget.dart - Gestión de Contenido Offline

### Propósito
Widget especializado para gestionar descargas offline con UI intuitiva y feedback visual.

### Modos de Visualización
1. **Compacto**: Solo botón de descarga
2. **Completo**: Botones de descarga y actualización + información

### Estados Visuales
- Indicador de modo offline
- Estado de descarga con progress
- Botones habilitados/deshabilitados según estado
- Información de contenido disponible

### Flujo de Descarga

```
Usuario toca "Descargar" →
  ┌─ Verificar estado de red
  ├─ Mostrar progress indicator
  ├─ Iniciar descarga en background
  ├─ Actualizar UI en tiempo real
  ├─ Mostrar resultado (éxito/error)
  └─ Actualizar estado de botones
```

---

## Patrones de Diseño Utilizados

### 1. Provider Pattern
- Separación clara entre UI y lógica de negocio
- Estado reactivo con ChangeNotifier
- Inyección de dependencias automática

### 2. Service Layer Pattern
- Servicios independientes y reutilizables
- Encapsulación de lógica específica de dominio
- Interfaces consistentes

### 3. Repository Pattern (Implícito)
- DevocionalProvider actúa como repository
- Abstracción de fuentes de datos (local/remoto)
- Caché inteligente y sincronización

### 4. Observer Pattern
- Listeners automáticos en widgets
- Notificaciones de cambio de estado
- UI reactiva a cambios de datos

## Consideraciones de Arquitectura

### Escalabilidad
- Servicios modulares fáciles de extender
- Providers independientes por dominio
- Separación clara de responsabilidades

### Mantenibilidad
- Código bien documentado y estructurado
- Tests unitarios e integración
- Naming conventions consistentes

### Performance
- Lazy loading de servicios
- Caché inteligente de datos
- Operaciones asíncronas no bloqueantes

### Offline-First Design
- Toda la funcionalidad disponible offline
- Sincronización inteligente cuando hay conexión
- Fallbacks graceful para errores de red