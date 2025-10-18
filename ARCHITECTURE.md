# Arquitectura de la Aplicación Devocional Cristiano

## Resumen Arquitectónico

La aplicación Devocionales Cristianos sigue una arquitectura **híbrida Provider Pattern + BLoC** con Flutter, implementando separación clara de responsabilidades entre UI, lógica de negocio y servicios externos.

### Principios Arquitectónicos

- **Separación de Responsabilidades**: Cada capa tiene responsabilidades específicas y bien definidas
- **Patrones Híbridos**: Provider Pattern para estado global, BLoC Pattern para flujos complejos
- **Inyección de Dependencias**: Uso de Provider y BlocProvider para gestión de estado y dependencias
- **Offline First**: Capacidad de funcionar sin conexión a internet
- **Multilingual Support**: Soporte completo para 5 idiomas con localización jerárquica (es, en, pt, fr, ja)
- **Modularidad**: Componentes reutilizables y servicios independientes
- **Schema Versioning**: Migración automática de datos con versionado
- **Race Condition Protection**: Protección contra operaciones concurrentes
- **Android 15+ Compatibility**: Soporte para edge-to-edge display y APIs modernas

## Estructura de Carpetas

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── app_initializer.dart         # Configuración inicial de la app
├── splash_screen.dart          # Pantalla de carga inicial
├── models/                     # Modelos de datos
├── providers/                  # Gestión de estado (Provider Pattern)
├── services/                   # Servicios de negocio
├── pages/                      # Páginas/Pantallas de la UI
├── widgets/                    # Widgets reutilizables
├── controllers/                # Controladores específicos
├── utils/                      # Utilidades y helpers
├── blocs/                      # Lógica de negocio (BLoC pattern)
└── extensions/                 # Extensiones de Dart
```

## Capas de la Aplicación

### 1. Capa de Presentación (UI)
- **Ubicación**: `lib/pages/`, `lib/widgets/`
- **Responsabilidad**: Interfaz de usuario y experiencia del usuario
- **Tecnología**: Flutter Widgets, Material Design

#### Características de DevocionalesPage
- **Navegación de Devocionales**: Sistema de índices con guardado de progreso
- **Audio TTS**: Lectura automática con control de reproducción
- **Sistema de Compartir Dual**:
  - **Compartir Devocional**: Formato de texto limpio sin duplicación
  - **Compartir como Imagen**: Captura de screenshot del devocional
- **Tracking de Lectura**: Monitoreo automático de tiempo y scroll
- **Favoritos**: Sistema de guardado rápido con feedback visual
- **Integración con Biblia**: Acceso directo a lecturas bíblicas relacionadas
- **Responsive Design**: Adaptación a diferentes tamaños de pantalla

### 2. Capa de Gestión de Estado
- **Ubicación**: `lib/providers/`, `lib/blocs/`
- **Responsabilidad**: Gestión de estado de la aplicación
- **Tecnología**: Provider Pattern para estado global, BLoC Pattern para flujos complejos
- **Patrones Implementados**:
  - **Provider Pattern**: DevocionalProvider, ThemeProvider, estado compartido
  - **BLoC Pattern**: OnboardingBloc, BackupBloc, flujos con lógica compleja
  - **State Management**: Estados inmutables con Equatable

### 3. Capa de Servicios
- **Ubicación**: `lib/services/`
- **Responsabilidad**: Lógica de negocio y comunicación con APIs
- **Tecnología**: HTTP requests, Local storage, Firebase

### 4. Capa de Modelos
- **Ubicación**: `lib/models/`
- **Responsabilidad**: Definición de estructuras de datos
- **Tecnología**: Dart classes, JSON serialization

## Flujo de Datos

```
UI Widget → Provider → Service → External API/Local Storage
    ↑                    ↓
    ←── ChangeNotifier ←── ←
```

## Gestión de Estado Global

La aplicación utiliza múltiples providers para gestionar diferentes aspectos del estado:

- **DevocionalProvider**: Gestión de devocionales y contenido offline
- **LocalizationProvider**: Gestión de idiomas y localización
- **ThemeProvider**: Gestión de temas y apariencia
- **PrayerProvider**: Gestión de oraciones personales

## Capacidades Offline

- **Descarga completa**: Todo el contenido del año se puede descargar
- **Almacenamiento local**: SharedPreferences para configuración, archivos JSON para contenido
- **Sincronización inteligente**: Verificación automática de actualizaciones
- **Fallback gracioso**: Funcionamiento completo sin conexión

## Arquitectura de Servicios

## Patrón BLoC - OnboardingBloc Architecture

### Visión General
El OnboardingBloc implementa una arquitectura BLoC completa siguiendo los patrones establecidos por BackupBloc, proporcionando gestión centralizada de estado para el flujo de onboarding de la aplicación.

### Estructura del OnboardingBloc

```
lib/blocs/onboarding/
├── onboarding_bloc.dart      # BLoC principal con lógica de negocio
├── onboarding_event.dart     # Eventos definidos para todas las acciones del usuario
├── onboarding_state.dart     # Estados inmutables para la UI
└── onboarding_models.dart    # Modelos de datos con serialización JSON
```

### Eventos Implementados
- **InitializeOnboarding**: Determina punto de inicio basado en estado de completitud
- **ProgressToStep**: Avanza con validación de prerrequisitos
- **SelectTheme**: Aplica selección de tema con preview inmediato
- **ConfigureBackupOption**: Integra con BackupBloc para configuración de respaldo
- **CompleteOnboarding**: Finaliza configuraciones y marca como completo
- **ResetOnboarding**: Utilidad de desarrollo para reiniciar estado
- **UpdateStepConfiguration**: Maneja cambios de configuración en pasos
- **UpdatePreview**: Actualiza preview de configuraciones
- **SkipCurrentStep**: Salta paso actual si es salteable
- **GoToPreviousStep**: Navega al paso anterior

### Estados Definidos
- **OnboardingInitial**: Estado inicial que determina si mostrar onboarding
- **OnboardingLoading**: Estado de carga para operaciones asíncronas
- **OnboardingStepActive**: Estado principal con índice de paso actual y configuraciones
- **OnboardingConfiguring**: Estado de transición para operaciones específicas
- **OnboardingCompleted**: Estado final con resumen de configuraciones aplicadas
- **OnboardingError**: Estado de error con categorización para manejo de UI

### Características Técnicas

#### Schema Versioning & Migration
```dart
// Persistencia con versionado
{
  "schemaVersion": 1,
  "payload": {
    "currentStep": 2,
    "configurations": {...}
  }
}
```

#### Race Condition Protection
```dart
bool _isProcessingStep = false;
bool _isCompletingOnboarding = false;
bool _isSavingConfiguration = false;
```

#### Service Integration
- **OnboardingService**: Gestión de estado de completitud
- **ThemeProvider**: Aplicación de temas con coordinación BLoC
- **BackupBloc**: Coordinación sin conflictos para configuración de respaldo
- **SharedPreferences**: Persistencia incremental con recuperación

#### Error Handling
- Categorización de errores por tipo (validation, service, persistence)
- Logging detallado con debugPrint siguiendo patrones BackupBloc
- Fallback a valores por defecto en casos de corrupción de datos
- Recovery automático de configuraciones malformadas

### Testing Architecture
- **16 Unit Tests**: Cobertura completa de lógica OnboardingBloc
- **9 Integration Tests**: Validación de integración con servicios
- **9 Persistence Tests**: Serialización JSON y manejo de errores
- **10 Migration Tests**: Migración de esquemas y manejo de datos legacy
- **3 UI Overflow Tests**: Validación de layout responsive

Esta arquitectura BLoC proporciona una base sólida para futuras expansiones del flujo de onboarding manteniendo consistencia con los patrones establecidos en la aplicación.

Los servicios están diseñados como singletons reutilizables que encapsulan lógica específica de dominio.