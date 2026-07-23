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

<!-- README-STATS:test-tree-en -->
```
test/
├── behavioral/  (7 tests)
├── helpers/  (10 files)
├── integration/  (9 tests)
├── migration/  (2 tests)
├── models/  (1 tests)
└── unit/  (221 tests)
```
<!-- /README-STATS:test-tree-en -->

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

See the Architecture section above (folder structure is language-agnostic).

### 🧪 Testing / Pruebas

See the Testing section above (folder structure is language-agnostic).

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

📖 **Bible versions per language**: https://github.com/develop4God/bible_versions/blob/main/README.md

---

## 🔧 Development / Desarrollo

### Code Quality / Calidad de Código

The project maintains high code quality standards:

- ✅ **Static Analysis**: `flutter analyze --fatal-infos` with zero issues
- ✅ **Code Formatting**: All code formatted with `dart format`
- ✅ **Linting**: All lint rules passing
- ✅ **Tests & Coverage**: see badges at the top of this README

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

## 📬 Contact / Contacto

Questions or support / Preguntas o soporte: develop4god@gmail.com
Website / Sitio web: https://www.develop4God.com

---

App Version: 1.12.6+108

© 2026 develop4God
