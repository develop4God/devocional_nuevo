# Devocionales Cristianos / Christian Devotionals

[![Flutter](https://img.shields.io/badge/Flutter-3.41.9-blue.svg)](https://flutter.dev/)
[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)
[![Tests](https://img.shields.io/badge/Tests-3157+-brightgreen.svg)](#-testing--pruebas)
[![Coverage](https://img.shields.io/badge/Coverage-51.9%25-yellow.svg)](#-testing--pruebas)
[![Build](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](#)

---

**[English](#english)** | **[Español](#español)**

---

<a name="english"></a>

## 🇺🇸 English

Multilingual mobile application for reading daily devotionals with advanced audio features,
favorites, spiritual tracking, and intelligent review system.

### ✨ Main Features

**📚 Content & Study**
- **Daily or On-Demand Devotionals**: Updated spiritual content in multiple Bible versions
- **Discovery Studies**: Learning from the Word of God
- **Encounters**: Connect with Jesus Christ as never before
- **Integrated Bible**: Complete offline Bible access with search, share, and save functionality
- **Audio TTS**: Text-to-speech reading of devotionals and Bible reader

**🙏 Personal Journey**
- **Favorites**: Save your favorite devotionals, Bible studies, Encounters, and Bible verses
- **Spiritual Tracking**: Reading statistics and progress
- **Prayer, Thanksgiving & Testimony**: Your personal journey

**☁️ Sync & Access**
- **Offline Mode**: Access without internet connection
- **Google Drive Backup**: Never lose your spiritual progress
- **Notifications**: Customizable reminders

**🎨 Experience**
- **Multiple Themes**: Light and dark mode, plus additional theme options
- **Multilingual Support**: Complete localization per language
- **Share**: Share inspiring content with optimized format

**💛 Community & Support**
- **Support Our Ministry**: Optional in-app support to help sustain the app and keep it free for all
- **Smart Review System**: Requests reviews at optimal moments

### 🛠️ Technologies

- **Flutter 3.41.9**: Main framework
- **Flutter BLoC**: Complex state management
- **Provider**: Simple state management
- **Firebase**: Notifications, auth, and analytics
- **SQLite**: Local database for Bible
- **flutter_tts**: Multilingual text-to-speech synthesis
- **Mockito & mocktail**: Testing frameworks

### 📊 Project Statistics

| Metric              | Value                        |
|---------------------|------------------------------|
| Source Files (lib/) | 242 Dart files               |
| Test Files          | 241 test files               |
| Total Tests         | 3,157 tests (100% passing ✅) |
| Test Coverage       | 51.9% (10,725/20,666 lines)   |
| Supported Languages | 10 (es, en, pt, fr, ja, zh, de, hi, ar, fil) |
| Static Analysis     | ✅ All checks passing         |

### 🏗️ Architecture

The application follows a **hybrid Provider + BLoC Pattern** architecture with clear separation of
concerns:

<!-- README-STATS:lib-tree-en -->
```
lib/
├── blocs/  (38 files)
├── controllers/  (4 files)
├── debug/  (11 files)
├── extensions/  (1 files)
├── helpers/  (1 files)
├── models/  (17 files)
├── pages/  (28 files)
├── providers/  (2 files)
├── repositories/  (10 files)
├── services/  (52 files)
├── utils/  (18 files)
└── widgets/  (58 files)
```
<!-- /README-STATS:lib-tree-en -->

### 🧪 Testing

The project has comprehensive test coverage across multiple layers with a clean, organized
structure:

**Test Statistics:**

- **241 test files** (100% passing ✅)
- **3,157 tests** with full pass rate
- **51.9% code coverage** (10,725 of 20,666 lines)
- Multiple test types: Unit, Widget, Integration, Behavioral
- All tests properly tagged for selective execution

```bash
# Run all tests
flutter test

# Run by performance tier (fast feedback)
flutter test --tags=critical        # Fast critical tests
flutter test --tags=unit           # All unit tests
flutter test --exclude-tags=slow   # Skip slow tests

# Run by category
flutter test --tags=blocs          # All BLoC tests
flutter test --tags=services       # All service tests
flutter test --tags=models         # All model tests
flutter test --tags=widgets        # All widget tests
flutter test --tags=pages          # All page tests
flutter test --tags=integration    # Integration tests
flutter test --tags=behavioral     # Behavioral tests

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

**Test Structure:**

<!-- README-STATS:test-tree-en -->
```
test/
├── behavioral/  (7 tests)
├── helpers/  (0 tests)
├── integration/  (9 tests)
├── migration/  (2 tests)
├── models/  (1 tests)
└── unit/  (221 tests)
```
<!-- /README-STATS:test-tree-en -->

**Test Organization Features:**

- ✅ All tests properly tagged for selective execution
- ✅ Fast critical tests for quick feedback (~1-2 minutes)
- ✅ Organized by type (BLoCs, Services, Models, Widgets, etc.)
- ✅ Easy to find where to add new tests
- ✅ No duplicate or scattered tests

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

- Flutter 3.41.9 or higher
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

**📚 Contenido y Estudio**
- **Devocionales Diarios o Bajo Demanda**: Contenido espiritual actualizado en múltiples versiones de la Biblia
- **Estudios Discovery**: Aprendiendo de la Palabra de Dios
- **Encuentros**: Conecta con Jesucristo como nunca antes
- **Biblia Integrada**: Acceso completo a la Biblia offline con búsqueda, compartir y guardar
- **Audio TTS**: Lectura de devocionales y Biblia con síntesis de voz

**🙏 Journey Personal**
- **Favoritos**: Guarda tus devocionales, estudios bíblicos, Encuentros y versículos favoritos
- **Tracking Espiritual**: Estadísticas de lectura y progreso
- **Oración, Acción de Gracias y Testimonio**: Tu journey personal

**☁️ Sincronización y Acceso**
- **Modo Offline**: Acceso sin conexión a internet
- **Respaldo en Google Drive**: Nunca pierdas tu progreso espiritual
- **Notificaciones**: Recordatorios personalizables

**🎨 Experiencia**
- **Múltiples Temas**: Modo claro y oscuro, más opciones de tema adicionales
- **Soporte Multilingüe**: Localización completa por idioma
- **Compartir**: Comparte contenido inspirador con formato optimizado

**💛 Comunidad y Apoyo**
- **Apoya Nuestro Ministerio**: Soporte opcional dentro de la app para sostenerla y mantenerla gratuita para todos
- **Sistema de Reseñas Inteligente**: Solicita reseñas en momentos óptimos

### 🛠️ Tecnologías

- **Flutter 3.41.9**: Framework principal
- **Flutter BLoC**: Gestión de estado complejo
- **Provider**: Gestión de estado simple
- **Firebase**: Notificaciones, autenticación y analytics
- **SQLite**: Base de datos local para Biblia
- **flutter_tts**: Síntesis de voz multilingüe
- **Mockito & mocktail**: Frameworks de testing

### 📊 Estadísticas del Proyecto

| Métrica                | Valor                              |
|------------------------|------------------------------------|
| Archivos Fuente (lib/) | 242 archivos Dart                  |
| Archivos de Test       | 241 archivos                       |
| Total de Tests         | 3,157 tests (100% aprobados ✅)     |
| Cobertura de Tests     | 51.9% (10,725/20,666 líneas)        |
| Idiomas Soportados     | 10 (es, en, pt, fr, ja, zh, de, hi, ar, fil) |
| Análisis Estático      | ✅ Todas las verificaciones pasando |

### 🏗️ Arquitectura

La aplicación sigue una arquitectura **híbrida Provider + Patrón BLoC** con clara separación de
responsabilidades:

See [Architecture](#-architecture) above (folder structure is language-agnostic).

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
flutter test --tags=critical        # Tests críticos rápidos
flutter test --tags=unit           # Todos los tests unitarios
flutter test --exclude-tags=slow   # Omitir tests lentos

# Ejecutar por categoría
flutter test --tags=blocs          # Todos los tests BLoC
flutter test --tags=services       # Todos los tests de servicios
flutter test --tags=models         # Todos los tests de modelos
flutter test --tags=widgets        # Todos los tests de widgets
flutter test --tags=pages          # Todos los tests de páginas
flutter test --tags=integration    # Tests de integración
flutter test --tags=behavioral     # Tests comportamentales

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

**Estructura de Tests:**

See [Test Structure](#-testing) above (folder structure is language-agnostic).

**Características de Organización de Tests:**

- ✅ Todos los tests etiquetados para ejecución selectiva
- ✅ Tests críticos rápidos para retroalimentación rápida (~1-2 minutos)
- ✅ Organizados por tipo (BLoCs, Services, Models, Widgets, etc.)
- ✅ Fácil encontrar dónde añadir nuevos tests
- ✅ Sin tests duplicados o dispersos

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

- Flutter 3.41.9 o superior
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

App Version: 1.12.6+108

© 2026 develop4God
