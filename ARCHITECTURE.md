# Arquitectura de la Aplicación Devocional Cristiano

## Resumen Arquitectónico

La aplicación Devocionales Cristianos sigue una arquitectura **Provider Pattern** con Flutter, implementando separación clara de responsabilidades entre UI, lógica de negocio y servicios externos.

### Principios Arquitectónicos

- **Separación de Responsabilidades**: Cada capa tiene responsabilidades específicas y bien definidas
- **Inyección de Dependencias**: Uso de Provider para gestión de estado y dependencias
- **Offline First**: Capacidad de funcionar sin conexión a internet
- **Multilingual Support**: Soporte completo para 4 idiomas (ES, EN, PT, FR)
- **Modularidad**: Componentes reutilizables y servicios independientes

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

### 2. Capa de Gestión de Estado
- **Ubicación**: `lib/providers/`
- **Responsabilidad**: Gestión de estado de la aplicación
- **Tecnología**: Provider Pattern, ChangeNotifier

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

Los servicios están diseñados como singletons reutilizables que encapsulan lógica específica de dominio.