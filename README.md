# Devocionales Cristianos / Christian Devotionals

[![Flutter](https://img.shields.io/badge/Flutter-3.32.8-blue.svg)](https://flutter.dev/)
[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)
[![Tests](https://img.shields.io/badge/Tests-1318-brightgreen.svg)](#-testing--pruebas)
[![Coverage](https://img.shields.io/badge/Coverage-44.06%25-yellow.svg)](#-testing--pruebas)
[![Build](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](#)

---

**[English](#english)** | **[Español](#español)**

---

<a name="english"></a>
## 🇺🇸 English

Multilingual mobile application for reading daily devotionals with advanced audio features, favorites, spiritual tracking, and intelligent review system.

### ✨ Main Features

- **📖 Daily Devotionals**: Updated spiritual content
- **🔍 Discovery Studies**: Interactive learning studies with progress tracking (NEW!)
- **📖 Integrated Bible**: Complete offline Bible access with search and share functionality
- **🌍 Multilingual Support**: Spanish, English, Portuguese, French with complete localization
- **🔊 Audio TTS**: Text-to-speech reading of devotionals
- **⭐ Favorites**: Save your favorite devotionals
- **📊 Spiritual Tracking**: Reading statistics and progress
- **🙏 Prayer Management**: Personal prayer tracking
- **📴 Offline Mode**: Access without internet connection
- **🔔 Notifications**: Customizable reminders
- **📱 Share**: Share inspiring content with optimized format
- **☁️ Cloud Backup**: Automatic sync with Google Drive
- **🚀 Smart Onboarding**: Guided initial setup with BLoC architecture
- **⭐ Smart Review System**: Requests reviews at optimal moments
- **📱 Android 15 Support**: Compatible with edge-to-edge display and modern APIs

### 🛠️ Technologies

- **Flutter 3.32.8**: Main framework
- **Flutter BLoC**: Complex state management
- **Provider**: Simple state management
- **Firebase**: Notifications, auth, and analytics
- **SQLite**: Local database for Bible
- **flutter_tts**: Multilingual text-to-speech synthesis
- **Mockito & mocktail**: Testing frameworks

### 📊 Project Statistics

| Metric | Value |
|--------|-------|
| Source Files (lib/) | 145 Dart files |
| Test Files | 141 test files |
| Total Tests | 1,318 tests (100% passing ✅) |
| Test Coverage | 44.06% (3,455/7,841 lines) |
| Supported Languages | 6 (es, en, pt, fr, ja, zh) |
| Static Analysis | ✅ All checks passing |

### 🏗️ Architecture

The application follows a **hybrid Provider + BLoC Pattern** architecture with clear separation of concerns:

```
lib/
├── blocs/           # BLoC state management (12 files)
│   ├── devocionales/
│   ├── discovery/   # Discovery Studies feature
│   ├── onboarding/
│   └── theme/
├── controllers/     # Application controllers (2 files)
├── extensions/      # Dart extensions (1 file)
├── models/          # Data models (8 files)
│   └── discovery/   # Discovery models
├── pages/           # Application screens (15+ files)
│   ├── devotional_discovery/
│   ├── onboarding/
│   └── discovery/
├── providers/       # State providers (2 files)
├── repositories/    # Data repositories (3 files)
├── services/        # Core services (16 files)
│   └── tts/
├── utils/           # Utilities and constants (8 files)
└── widgets/         # Reusable UI components (22+ files)
    └── donate/
```

### 🧪 Testing

The project has comprehensive test coverage across multiple layers:

**Test Statistics:**
- **1,318 tests** (100% passing ✅)
- **44.06% code coverage** (3,455 of 7,841 lines)
- Multiple test types: Unit, Widget, Integration, Behavioral
- Critical user path coverage for key features

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test categories
flutter test test/unit/services/
flutter test test/unit/providers/
flutter test test/behavioral/
flutter test test/critical_coverage/

# Run static analysis
flutter analyze --fatal-infos

# Format code
dart format .

# Apply fixes
dart fix --apply
```

**Test Structure:**
```
test/
├── behavioral/              # Real user behavior tests
├── critical_coverage/       # Critical path coverage tests
├── integration/             # Integration tests (classic)
├── widget/                  # Widget tests  
├── services/               # Service tests
└── unit/                    # Unit tests organized by feature
    ├── controllers/         # Controller tests
    ├── extensions/          # Extension tests
    ├── models/              # Model tests
    ├── providers/           # Provider tests
    ├── services/            # Service unit tests
    ├── utils/               # Utility tests
    ├── widgets/             # Widget unit tests
    └── features/            # Feature-specific tests

patrol_test/                 # 🆕 Patrol framework tests (native automation)
├── devotional_reading_workflow_test.dart  # ✅ 13 tests
├── tts_audio_test.dart                    # ⚠️ 6/10 tests
├── offline_mode_test.dart                 # 🔧 In progress
└── README.md                              # Patrol documentation
```

**🆕 Patrol Integration Tests:**
- Modern testing framework with native automation
- Supports permissions, notifications, back button
- Cleaner syntax with `$` shorthand  
- See [`patrol_test/README.md`](./patrol_test/README.md) for details

**Coverage Highlights:**
- ✅ Core devotional reading logic
- ✅ TTS (Text-to-Speech) functionality
- ✅ Offline mode and data persistence
- ✅ User tracking and analytics
- ✅ Multi-language support
- ✅ BLoC state management
- ✅ Real user behavioral scenarios

### 📱 Requirements

- Flutter 3.32.8 or higher
- Dart SDK >=3.0.0 <4.0.0
- Android SDK 21+ (Android 5.0+)
- Android compileSdk 34+ (for Android 15 compatibility)
- iOS 11.0+

### 🚀 Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application

### 📚 Documentation

All documentation is organized in the [docs/](./docs/) folder:

📖 **[Documentation Index](./docs/INDEX.md)** - Complete documentation navigation

- [Architecture Documentation](./docs/architecture/) - Technical architecture and decisions
- [Discovery Feature](./docs/discovery/) - Discovery Studies feature documentation
- [Feature Documentation](./docs/features/) - Feature-specific guides
- [Testing Documentation](./docs/testing/) - Test coverage reports
- [Guides](./docs/guides/) - Development and testing guides
- [Security](./docs/security/) - Security policies

---

<a name="español"></a>
## 🇪🇸 Español

Aplicación móvil multilingüe para leer devocionales diarios con funcionalidades avanzadas de audio, favoritos, tracking espiritual y sistema inteligente de reseñas.

### ✨ Características Principales

- **📖 Devocionales Diarios**: Contenido espiritual actualizado
- **🔍 Estudios Discovery**: Estudios interactivos con seguimiento de progreso (¡NUEVO!)
- **📖 Biblia Integrada**: Acceso completo a la Biblia offline con búsqueda y compartir
- **🌍 Soporte Multilingüe**: Español, Inglés, Portugués, Francés con localización completa
- **🔊 Audio TTS**: Lectura de devocionales con síntesis de voz
- **⭐ Favoritos**: Guarda tus devocionales preferidos
- **📊 Tracking Espiritual**: Estadísticas de lectura y progreso
- **🙏 Gestión de Oraciones**: Seguimiento de oraciones personales
- **📴 Modo Offline**: Acceso sin conexión a internet
- **🔔 Notificaciones**: Recordatorios personalizables
- **📱 Compartir**: Comparte contenido inspirador con formato optimizado
- **☁️ Respaldo en la Nube**: Sincronización automática con Google Drive
- **🚀 Onboarding Inteligente**: Configuración guiada inicial con arquitectura BLoC
- **⭐ Sistema de Reseñas Inteligente**: Solicita reseñas en momentos óptimos
- **📱 Soporte Android 15**: Compatible con edge-to-edge display y APIs modernas

### 🛠️ Tecnologías

- **Flutter 3.32.8**: Framework principal
- **Flutter BLoC**: Gestión de estado complejo
- **Provider**: Gestión de estado simple
- **Firebase**: Notificaciones, autenticación y analytics
- **SQLite**: Base de datos local para Biblia
- **flutter_tts**: Síntesis de voz multilingüe
- **Mockito & mocktail**: Frameworks de testing

### 📊 Estadísticas del Proyecto

| Métrica | Valor |
|---------|-------|
| Archivos Fuente (lib/) | 145 archivos Dart |
| Archivos de Test | 141 archivos |
| Total de Tests | 1,318 tests (100% aprobados ✅) |
| Cobertura de Tests | 44.06% (3,455/7,841 líneas) |
| Idiomas Soportados | 6 (es, en, pt, fr, ja, zh) |
| Análisis Estático | ✅ Todas las verificaciones pasando |

### 🏗️ Arquitectura

La aplicación sigue una arquitectura **híbrida Provider + Patrón BLoC** con clara separación de responsabilidades:

```
lib/
├── blocs/           # Gestión de estado BLoC (12 archivos)
│   ├── devocionales/
│   ├── discovery/   # Feature Discovery Studies
│   ├── onboarding/
│   └── theme/
├── controllers/     # Controladores de aplicación (2 archivos)
├── extensions/      # Extensiones de Dart (1 archivo)
├── models/          # Modelos de datos (8 archivos)
│   └── discovery/   # Modelos Discovery
├── pages/           # Pantallas de la aplicación (15+ archivos)
│   ├── devotional_discovery/
│   ├── onboarding/
│   └── discovery/
├── providers/       # Proveedores de estado (2 archivos)
├── repositories/    # Repositorios de datos (3 archivos)
├── services/        # Servicios centrales (16 archivos)
│   └── tts/
├── utils/           # Utilidades y constantes (8 archivos)
└── widgets/         # Componentes UI reutilizables (22+ archivos)
    └── donate/
```

### 🧪 Testing / Pruebas

El proyecto cuenta con cobertura completa de pruebas en múltiples capas:

**Estadísticas de Pruebas:**
- **1,318 tests** (100% aprobados ✅)
- **44.06% de cobertura** (3,455 de 7,841 líneas)
- Múltiples tipos de tests: Unitarios, Widgets, Integración, Comportamentales
- Cobertura de rutas críticas de usuario

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar tests con cobertura
flutter test --coverage

# Ejecutar categorías específicas de tests
flutter test test/unit/services/
flutter test test/unit/providers/
flutter test test/behavioral/
flutter test test/critical_coverage/

# Ejecutar análisis estático
flutter analyze --fatal-infos

# Formatear código
dart format .

# Aplicar correcciones
dart fix --apply
```

**Estructura de Tests:**
```
test/
├── behavioral/              # Tests de comportamiento real de usuario
├── critical_coverage/       # Tests de cobertura de rutas críticas
├── integration/             # Tests de integración (clásicos)
├── widget/                  # Tests de widgets
├── services/               # Tests de servicios
└── unit/                    # Tests unitarios organizados por feature
    ├── controllers/         # Tests de controladores
    ├── extensions/          # Tests de extensiones
    ├── models/              # Tests de modelos
    ├── providers/           # Tests de providers
    ├── services/            # Tests unitarios de servicios
    ├── utils/               # Tests de utilidades
    ├── widgets/             # Tests unitarios de widgets
    └── features/            # Tests específicos de features

patrol_test/                 # 🆕 Tests con framework Patrol (automatización nativa)
├── devotional_reading_workflow_test.dart  # ✅ 13 tests
├── tts_audio_test.dart                    # ⚠️ 6/10 tests
├── offline_mode_test.dart                 # 🔧 En progreso
└── README.md                              # Documentación de Patrol
```

**🆕 Tests de Integración con Patrol:**
- Framework moderno con automatización nativa
- Soporta permisos, notificaciones, botón atrás
- Sintaxis más limpia con atajo `$`
- Ver [`patrol_test/README.md`](./patrol_test/README.md) para detalles

**Aspectos Destacados de Cobertura:**
- ✅ Lógica central de lectura devocional
- ✅ Funcionalidad TTS (Text-to-Speech)
- ✅ Modo offline y persistencia de datos
- ✅ Tracking de usuario y analytics
- ✅ Soporte multilingüe
- ✅ Gestión de estado BLoC
- ✅ Escenarios de comportamiento real de usuario

### 📱 Requisitos

- Flutter 3.32.8 o superior
- Dart SDK >=3.0.0 <4.0.0
- Android SDK 21+ (Android 5.0+)
- Android compileSdk 34+ (para compatibilidad con Android 15)
- iOS 11.0+

### 🚀 Instalación

1. Clona este repositorio
2. Ejecuta `flutter pub get` para instalar las dependencias
3. Ejecuta `flutter run` para iniciar la aplicación

### 📚 Documentación

Toda la documentación está organizada en la carpeta [docs/](./docs/):

📖 **[Índice de Documentación](./docs/INDEX.md)** - Navegación completa de documentación

- [Documentación de Arquitectura](./docs/architecture/) - Arquitectura técnica y decisiones
- [Feature Discovery](./docs/discovery/) - Documentación de la función Discovery Studies
- [Documentación de Features](./docs/features/) - Guías específicas de características
- [Documentación de Testing](./docs/testing/) - Reportes de cobertura de tests
- [Guías](./docs/guides/) - Guías de desarrollo y pruebas
- [Seguridad](./docs/security/) - Políticas de seguridad

---

## 🔧 Development / Desarrollo

### Code Quality / Calidad de Código

The project maintains high code quality standards:

- ✅ **Static Analysis**: `flutter analyze --fatal-infos` with zero issues
- ✅ **Code Formatting**: All code formatted with `dart format`
- ✅ **Linting**: All lint rules passing
- ✅ **Tests**: 1,318 tests (100% passing)
- ✅ **Coverage**: 44.06% and growing

### Development Commands / Comandos de Desarrollo

```bash
# Install dependencies / Instalar dependencias
flutter pub get

# Run the app / Ejecutar la app
flutter run

# Analyze code with strict mode / Analizar código en modo estricto
flutter analyze --fatal-infos

# Format code / Formatear código
dart format .

# Apply automatic fixes / Aplicar correcciones automáticas
dart fix --apply

# Run tests / Ejecutar tests
flutter test

# Run tests with coverage / Ejecutar tests con cobertura
flutter test --coverage

# Build for production / Compilar para producción
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## 🤝 Contributing / Contribuir

1. Fork the project / Fork el proyecto
2. Create your feature branch / Crea tu rama de feature (`git checkout -b feature/AmazingFeature`)
3. Commit your changes / Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch / Push a la rama (`git push origin feature/AmazingFeature`)
5. Open a Pull Request / Abre un Pull Request

---

## 📄 License / Licencia

### English

This work is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/).

You are free to:
- **Share** — copy and redistribute the material in any medium or format
- **Adapt** — remix, transform, and build upon the material

Under the following terms:
- **Attribution (BY)** — You must give appropriate credit, provide a link to the license, and indicate if changes were made.
- **NonCommercial (NC)** — You may not use the material for commercial purposes.

For the full license text, see the [LICENSE](./LICENSE) file or visit:
- Summary: https://creativecommons.org/licenses/by-nc/4.0/
- Legal Code: https://creativecommons.org/licenses/by-nc/4.0/legalcode

### Español

Este trabajo está licenciado bajo la [Licencia Creative Commons Atribución-NoComercial 4.0 Internacional (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/deed.es).

Puedes:
- **Compartir** — copiar y redistribuir el material en cualquier medio o formato
- **Adaptar** — remezclar, transformar y construir sobre el material

Bajo las siguientes condiciones:
- **Atribución (BY)** — Debes dar crédito adecuado, proporcionar un enlace a la licencia e indicar si se realizaron cambios.
- **NoComercial (NC)** — No puedes utilizar el material con fines comerciales.

Para el texto completo de la licencia, ver el archivo [LICENSE](./LICENSE) o visitar:
- Resumen: https://creativecommons.org/licenses/by-nc/4.0/deed.es
- Código Legal: https://creativecommons.org/licenses/by-nc/4.0/legalcode.es

---

© 2024 develop4God
