# Devocionales Cristianos / Christian Devotionals

[![Flutter](https://img.shields.io/badge/Flutter-3.32.8-blue.svg)](https://flutter.dev/)
[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)
[![Tests](https://img.shields.io/badge/Tests-1298+-brightgreen.svg)](#-testing--pruebas)
[![Coverage](https://img.shields.io/badge/Coverage-48.6%25-red.svg)](#-testing--pruebas)
[![Build](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](#)

---

**[English](#english)** | **[Español](#español)**

---

<a name="english"></a>

## 🇺🇸 English

Multilingual mobile application for reading daily devotionals with advanced audio features,
favorites, spiritual tracking, and intelligent review system.

### ✨ Main Features

- **📖 Daily Devotionals**: Updated spiritual content
- **🔍 Discovery Studies**: Interactive learning studies with progress tracking (NEW!)
- **🤝 Encounters**: Connect with testimonies and spiritual experiences (NEW!)
- **📖 Integrated Bible**: Complete offline Bible access with search and share functionality
- **🌍 Multilingual Support**: Spanish, English, Portuguese, French, Japanese, Chinese, German, Hindi with complete localization
- **🔊 Audio TTS**: Text-to-speech reading of devotionals
- **⭐ Favorites**: Save your favorite devotionals
- **📊 Spiritual Tracking**: Reading statistics and progress
- **🙏 Prayer Management**: Personal prayer tracking
- **📴 Offline Mode**: Access without internet connection
- **🔔 Notifications**: Customizable reminders
- **📱 Share**: Share inspiring content with optimized format
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

| Metric              | Value                        |
|---------------------|------------------------------|
| Source Files (lib/) | 145 Dart files               |
| Test Files          | 142 test files               |
| Total Tests         | 1,318 tests (100% passing ✅) |
| Test Coverage       | 44.06% (3,455/7,841 lines)   |
| Supported Languages | 8 (es, en, pt, fr, ja, zh, de, hi) |
| Static Analysis     | ✅ All checks passing         |

### 🏗️ Architecture

The application follows a **hybrid Provider + BLoC Pattern** architecture with clear separation of
concerns:

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

The project has comprehensive test coverage across multiple layers with a clean, organized
structure:

**Test Statistics:**

- **142 test files** (100% passing ✅)
- **1,318 tests** with full pass rate
- **44.06% code coverage** (3,455 of 7,841 lines)
- Multiple test types: Unit, Widget, Integration, Behavioral
- All tests properly tagged for selective execution

```bash
# Run all tests
flutter test

# Run by performance tier (fast feedback)
flutter test --tags=critical        # Fast: ~1-2 min (29 critical tests)
flutter test --tags=unit           # Medium: ~5-10 min (121 unit tests)
flutter test --exclude-tags=slow   # Skip slow tests

# Run by category
flutter test --tags=blocs          # All BLoC tests (19 tests)
flutter test --tags=services       # All service tests (33 tests)
flutter test --tags=models         # All model tests (10 tests)
flutter test --tags=widgets        # All widget tests (12 tests)
flutter test --tags=pages          # All page tests (16 tests)
flutter test --tags=integration    # Integration tests (9 tests)
flutter test --tags=behavioral     # Behavioral tests (5 tests)

# Combine tags
flutter test --tags=critical,blocs # Critical BLoC tests only

# Run tests with coverage
flutter test --coverage

# Run static analysis
flutter analyze --fatal-infos

# Format code
dart format .

# Apply fixes
dart fix --apply
```

**Test Structure (Reorganized Feb 2025):**

```
test/
├── behavioral/              (5 tests)  - Real user behavior & journey tests
├── integration/             (8 tests)  - Cross-component integration tests
├── migration/               (1 test)   - Code migration validation
├── helpers/                 (6 files)  - Shared test utilities & mocks
└── unit/                    (116 tests) - All unit tests, organized by type
    ├── blocs/              (19 tests) - BLoC & state management
    ├── services/           (28 tests) - Service layer tests
    ├── models/             (10 tests) - Data model tests
    ├── widgets/            (12 tests) - Widget component tests
    ├── pages/              (16 tests) - Full page/screen tests
    ├── controllers/         (4 tests) - Controllers (audio, TTS)
    ├── providers/           (4 tests) - Provider tests
    ├── features/            (4 tests) - User flow tests
    ├── utils/              (13 tests) - Utility & helper tests
    ├── repositories/        (1 test)  - Repository tests
    ├── extensions/          (1 test)  - Extension tests
    ├── translations/        (1 test)  - i18n tests
    └── android/             (1 test)  - Android-specific tests

patrol_test/                 # 🆕 Patrol framework tests (native automation)
├── devotional_reading_workflow_test.dart  # ✅ 13 tests
├── tts_audio_test.dart                    # ⚠️ 6/10 tests
├── offline_mode_test.dart                 # 🔧 In progress
└── README.md                              # Patrol documentation
```

**🆕 Test Organization Features:**

- ✅ Clean directory structure (19 directories, down from 24)
- ✅ All tests properly tagged for selective execution
- ✅ Fast critical tests for quick feedback (~1-2 minutes)
- ✅ Organized by type (BLoCs, Services, Models, Widgets, etc.)
- ✅ Easy to find where to add new tests
- ✅ No duplicate or scattered tests
- 📄 See [TEST_REORGANIZATION_SUMMARY.md](docs/testing/TEST_REORGANIZATION_SUMMARY.md) for details

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
- ✅ Service layer comprehensively tested
- ✅ Model validation and business logic

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

Aplicación móvil multilingüe para leer devocionales diarios con funcionalidades avanzadas de audio,
favoritos, tracking espiritual y sistema inteligente de reseñas.

### ✨ Características Principales

- **📖 Devocionales Diarios**: Contenido espiritual actualizado
- **🔍 Estudios Discovery**: Estudios interactivos con seguimiento de progreso (¡NUEVO!)
- **🤝 Encuentros**: Conecta con testimonios y experiencias espirituales (¡NUEVO!)
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

| Métrica                | Valor                              |
|------------------------|------------------------------------|
| Archivos Fuente (lib/) | 145 archivos Dart                  |
| Archivos de Test       | 142 archivos                       |
| Total de Tests         | 1,318 tests (100% aprobados ✅)     |
| Cobertura de Tests     | 44.06% (3,455/7,841 líneas)        |
| Idiomas Soportados     | 8 (es, en, pt, fr, ja, zh, de, hi) |
| Análisis Estático      | ✅ Todas las verificaciones pasando |

### 🏗️ Arquitectura

La aplicación sigue una arquitectura **híbrida Provider + Patrón BLoC** con clara separación de
responsabilidades:

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

El proyecto cuenta con cobertura completa de pruebas en múltiples capas con una estructura limpia y
organizada:

**Estadísticas de Pruebas:**

- **142 archivos de prueba** (100% aprobados ✅)
- **1,318 tests** con 100% de tasa de aprobación
- **44.06% de cobertura** (3,455 de 7,841 líneas)
- Múltiples tipos de tests: Unitarios, Widgets, Integración, Comportamentales
- Todos los tests etiquetados para ejecución selectiva

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar por nivel de rendimiento (retroalimentación rápida)
flutter test --tags=critical        # Rápido: ~1-2 min (29 tests críticos)
flutter test --tags=unit           # Medio: ~5-10 min (121 tests unitarios)
flutter test --exclude-tags=slow   # Omitir tests lentos

# Ejecutar por categoría
flutter test --tags=blocs          # Todos los tests BLoC (19 tests)
flutter test --tags=services       # Todos los tests de servicios (33 tests)
flutter test --tags=models         # Todos los tests de modelos (10 tests)
flutter test --tags=widgets        # Todos los tests de widgets (12 tests)
flutter test --tags=pages          # Todos los tests de páginas (16 tests)
flutter test --tags=integration    # Tests de integración (9 tests)
flutter test --tags=behavioral     # Tests comportamentales (5 tests)

# Combinar etiquetas
flutter test --tags=critical,blocs # Solo tests BLoC críticos

# Ejecutar tests con cobertura
flutter test --coverage

# Ejecutar análisis estático
flutter analyze --fatal-infos

# Formatear código
dart format .

# Aplicar correcciones
dart fix --apply
```

**Estructura de Tests (Reorganizada Feb 2025):**

```
test/
├── behavioral/              (5 tests)  - Tests de comportamiento real del usuario
├── integration/             (8 tests)  - Tests de integración entre componentes
├── migration/               (1 test)   - Validación de migración de código
├── helpers/                 (6 files)  - Utilidades compartidas & mocks
└── unit/                    (116 tests) - Todos los tests unitarios, organizados por tipo
    ├── blocs/              (19 tests) - BLoC & gestión de estado
    ├── services/           (28 tests) - Tests de capa de servicios
    ├── models/             (10 tests) - Tests de modelos de datos
    ├── widgets/            (12 tests) - Tests de componentes widget
    ├── pages/              (16 tests) - Tests de pantallas completas
    ├── controllers/         (4 tests) - Controladores (audio, TTS)
    ├── providers/           (4 tests) - Tests de providers
    ├── features/            (4 tests) - Tests de flujos de usuario
    ├── utils/              (13 tests) - Tests de utilidades
    ├── repositories/        (1 test)  - Tests de repositorios
    ├── extensions/          (1 test)  - Tests de extensiones
    ├── translations/        (1 test)  - Tests de i18n
    └── android/             (1 test)  - Tests específicos de Android

patrol_test/                 # 🆕 Tests del framework Patrol (automatización nativa)
├── devotional_reading_workflow_test.dart  # ✅ 13 tests
├── tts_audio_test.dart                    # ⚠️ 6/10 tests
├── offline_mode_test.dart                 # 🔧 En progreso
└── README.md                              # Documentación de Patrol
```

**🆕 Características de Organización de Tests:**

- ✅ Estructura de directorios limpia (19 directorios, reducido de 24)
- ✅ Todos los tests etiquetados para ejecución selectiva
- ✅ Tests críticos rápidos para retroalimentación rápida (~1-2 minutos)
- ✅ Organizados por tipo (BLoCs, Services, Models, Widgets, etc.)
- ✅ Fácil encontrar dónde añadir nuevos tests
- ✅ Sin tests duplicados o dispersos
- 📄 Ver [TEST_REORGANIZATION_SUMMARY.md](docs/testing/TEST_REORGANIZATION_SUMMARY.md) para detalles

**🆕 Tests de Integración con Patrol:**

- Framework de testing moderno con automatización nativa
- Soporta permisos, notificaciones, botón atrás
- Sintaxis más limpia con shorthand `$`
- Ver [`patrol_test/README.md`](./patrol_test/README.md) para detalles

**Áreas Cubiertas:**

- ✅ Lógica central de lectura de devocionales
- ✅ Funcionalidad TTS (Text-to-Speech)
- ✅ Modo offline y persistencia de datos
- ✅ Tracking de usuario y analytics
- ✅ Soporte multiidioma
- ✅ Gestión de estado BLoC
- ✅ Escenarios de comportamiento real de usuario
- ✅ Capa de servicios completamente probada
- ✅ Validación de modelos y lógica de negocio


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

## 🌍 Multi-Language Support / Soporte Multi-idioma

### Supported Languages / Idiomas Soportados

The application currently supports **8 languages** with complete localization:

| Language | Code | Bible Versions | Status |
|----------|------|----------------|--------|
| Español | `es` | RVR1960, NVI | ✅ Complete |
| English | `en` | KJV, NIV | ✅ Complete |
| Português | `pt` | ARC, NVI | ✅ Complete |
| Français | `fr` | LSG1910, BDS | ✅ Complete |
| 日本語 | `ja` | 新改訳2003, リビングバイブル | ✅ Complete |
| 中文 | `zh` | 和合本1919, 新译本 | ✅ Complete |
| Deutsch | `de` | Elberfelder, Schlachter | 🆕 **NEW!** |
| हिन्दी | `hi` | पवित्र बाइबिल (ओ.वी.), पवित्र बाइबिल | ✅ Complete |

### 🆕 German Language Support (NEW!)

German language support has been added with:

- **Master Language (MASTER_LANG)**: `de` (German)
- **Master Version (MASTER_VERSION)**: `Elberfelder` (Elberfelder Bible)
- **Secondary Version**: `Schlachter` (Schlachter Bible)
- **TTS Locale**: `de-DE` (German - Germany)
- **Translation File**: `i18n/de.json`

**Features:**
- ✅ Complete UI localization support
- ✅ Text-to-Speech (TTS) in German
- ✅ Bible version switching
- ✅ Devotionals support (requires JSON files in separate repository)
- ✅ Offline mode support
- ✅ Copyright information for Bible versions

### 🆕 Hindi Language Support (NEW!)

Hindi language support has been added with:

- **Master Language (MASTER_LANG)**: `hi` (Hindi)
- **Master Version (MASTER_VERSION)**: `पवित्र बाइबिल (ओ.वी.)` (Easy-to-Read Version - ERV)
- **Secondary Version**: `पवित्र बाइबिल` (Bible Society version - BDS)
- **TTS Locale**: `hi-IN` (Hindi - India)
- **Translation File**: `i18n/hi.json`

**Features:**
- ✅ Complete UI localization support
- ✅ Text-to-Speech (TTS) in Hindi
- ✅ Bible version switching
- ✅ Devotionals support (requires JSON files in separate repository)
- ✅ Offline mode support
- ✅ Copyright information for Bible versions

**Note**: For any language, Bible database files need to be added manually. See [docs/ADDING_NEW_LANGUAGE_GUIDE.md](./docs/ADDING_NEW_LANGUAGE_GUIDE.md) for detailed instructions on preparing and adding Bible database files.

### Adding a New Language / Agregar un Nuevo Idioma

Want to add support for another language? We've created a comprehensive guide!

📚 **See**: [docs/ADDING_NEW_LANGUAGE_GUIDE.md](./docs/ADDING_NEW_LANGUAGE_GUIDE.md)

This guide includes:
- ✅ Complete step-by-step instructions
- ✅ Configuration checklist
- ✅ Bible database preparation
- ✅ Localization setup
- ✅ TTS configuration
- ✅ Copyright information requirements
- ✅ Testing procedures
- ✅ Example implementations

**Quick Overview**:
1. Add language to `Constants` and `BibleVersionRegistry`
2. Create translation file in `i18n/{lang}.json`
3. Prepare and add Bible database files
4. Configure TTS locale
5. Add copyright information
6. Create devotional JSON files
7. Test thoroughly

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

This work is licensed under
the [Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/).

You are free to:

- **Share** — copy and redistribute the material in any medium or format
- **Adapt** — remix, transform, and build upon the material

Under the following terms:

- **Attribution (BY)** — You must give appropriate credit, provide a link to the license, and
  indicate if changes were made.
- **NonCommercial (NC)** — You may not use the material for commercial purposes.

For the full license text, see the [LICENSE](./LICENSE) file or visit:

- Summary: https://creativecommons.org/licenses/by-nc/4.0/
- Legal Code: https://creativecommons.org/licenses/by-nc/4.0/legalcode

### Español

Este trabajo está licenciado bajo
la [Licencia Creative Commons Atribución-NoComercial 4.0 Internacional (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/deed.es).

Puedes:

- **Compartir** — copiar y redistribuir el material en cualquier medio o formato
- **Adaptar** — remezclar, transformar y construir sobre el material

Bajo las siguientes condiciones:

- **Atribución (BY)** — Debes dar crédito adecuado, proporcionar un enlace a la licencia e indicar
  si se realizaron cambios.
- **NoComercial (NC)** — No puedes utilizar el material con fines comerciales.

Para el texto completo de la licencia, ver el archivo [LICENSE](./LICENSE) o visitar:

- Resumen: https://creativecommons.org/licenses/by-nc/4.0/deed.es
- Código Legal: https://creativecommons.org/licenses/by-nc/4.0/legalcode.es

---

© 2026 develop4God
