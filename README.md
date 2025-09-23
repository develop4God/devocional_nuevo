# Devocionales Cristianos

Aplicación móvil multilingüe para leer devocionales diarios con funcionalidades avanzadas de audio, favoritos, tracking espiritual y sistema inteligente de reseñas.

## ✨ Características Principales

- **📖 Devocionales Diarios**: Contenido espiritual actualizado
- **🌍 Soporte Multilingüe**: Español, Inglés, Portugués, Francés con localización completa
- **🔊 Audio TTS**: Lectura de devocionales con síntesis de voz
- **⭐ Favoritos**: Guarda tus devocionales preferidos
- **📊 Tracking Espiritual**: Estadísticas de lectura y progreso
- **🙏 Gestión de Oraciones**: Seguimiento de oraciones personales
- **📴 Modo Offline**: Acceso sin conexión a internet
- **🔔 Notificaciones**: Recordatorios personalizables
- **📱 Compartir**: Comparte contenido inspirador
- **☁️ Respaldo en la Nube**: Sincronización automática con Google Drive *(ACTUALIZADO)*
- **🚀 Onboarding Inteligente**: Configuración guiada inicial con BLoC architecture *(NUEVO)*
- **⭐ Sistema de Reseñas Inteligente**: Solicita reseñas en momentos óptimos

## 🆕 Actualizaciones Recientes

### 🚀 Sistema de Onboarding con BLoC Architecture
- **Arquitectura BLoC**: Migración completa del onboarding a patrón BLoC para mejor mantenimiento
- **Configuración Guiada**: Flow paso a paso para selección de tema y configuración de respaldo
- **Persistencia Inteligente**: Guardado automático de progreso con recuperación ante interrupciones
- **Localización Completa**: Soporte total en 4 idiomas con keys actualizadas
- **UI Responsiva**: Diseño adaptativo que funciona en todos los tamaños de pantalla
- **Manejo de Errores**: Sistema robusto de recuperación de errores con diálogos informativos
- **Timeout Protection**: Protección de 30 segundos para conexiones Google Drive
- **Testing Exhaustivo**: 45+ tests cubriendo todos los escenarios posibles

### 🌍 Soporte Multilingüe Mejorado
El sistema solicita reseñas automáticamente cuando los usuarios alcanzan hitos significativos:
- **5° devocional** (validación de engagement temprano)
- **25° devocional** (usuario comprometido)
- **50° devocional** (usuario regular)
- **100° devocional** (usuario dedicado)
- **200° devocional** (super usuario)

### 🌍 Soporte Multilingüe Mejorado
- **Onboarding Localizado**: Todas las pantallas de configuración inicial totalmente traducidas
- **Keys Corregidas**: Sistema de localización mejorado con estructura jerárquica (onboarding.*)
- **Mensajes de Error**: Feedback localizado para conexiones y timeouts
- **4 Idiomas Completos**: Español, English, Português, Français

### ☁️ Sistema de Respaldo Mejorado
- **Google Drive Integration**: Conexión segura con timeout protection
- **Manejo de Cancelación**: Recuperación elegante cuando el usuario cancela la autenticación
- **Estado de Conexión**: Indicadores claros de progreso y estado de conexión
- **Auto-configuración**: Configuración automática óptima tras conexión exitosa
- **Tests de Login Flow**: Cobertura completa de flujos de autenticación y cancelación

### 🎯 Momentos Inteligentes para Reseñas
Diálogos de reseña localizados en todos los idiomas:
- **Español**: "Gracias por tu constancia 🙏"
- **English**: "Thank you for your consistency 🙏"
- **Português**: "Obrigado pela sua constância 🙏"
- **Français**: "Merci pour votre constance 🙏"

### ⏰ Sistema de Enfriamiento Inteligente
- **90 días de enfriamiento global**: Previene sobre-solicitud
- **30 días "recordar después"**: Respeta la elección del usuario
- **Preferencias permanentes**: "Ya califiqué" y "No preguntar más"

### 📱 Integración Nativa con Respaldos
- **Primario**: API nativa de Android/iOS
- **Respaldo**: Redirección directa a Play Store/App Store
- **Fallback final**: Lanzador de URL para casos extremos

## 🚀 Estado del Proyecto

### ✅ Testing Coverage - 95%+ en Servicios Críticos
- **130+ Tests Unitarios**: Cobertura completa de funcionalidad incluyendo OnboardingBloc *(ACTUALIZADO)*
- **45+ Tests del Sistema de Onboarding**: Cobertura exhaustiva del nuevo BLoC architecture *(NUEVO)*
- **36 Tests del Sistema de Reseñas**: Cobertura exhaustiva del feature de reseñas
- **Login Flow Tests**: Tests específicos para flujos de autenticación y manejo de cancelación *(NUEVO)*
- **Servicios Críticos**: PrayerProvider, TtsService, LocalizationService, InAppReviewService, OnboardingBloc
- **Providers**: DevocionalProvider, AudioController  
- **Performance**: Todos los tests < 30 segundos
- **CI/CD Ready**: Tests automatizados con mocking robusto

### 🎯 Idiomas y Versiones Bíblicas
- **Español**: RVR1960, NVI
- **Inglés**: KJV, NIV  
- **Portugués**: ARC, NVI
- **Francés**: LSG1910, TOB

## 🛠️ Tecnologías

- **Flutter 3.32.8**: Framework principal
- **Provider**: Gestión de estado
- **Firebase**: Notificaciones y analytics
- **SharedPreferences**: Persistencia local
- **TTS**: Síntesis de voz multilingüe
- **HTTP**: API de contenido
- **Testing**: Mockito, flutter_test
- **in_app_review**: Sistema nativo de reseñas *(NUEVO)*

## 🏗️ Arquitectura

### Arquitectura Limpia
- **Separación de responsabilidades**: Límites claros entre capas
- **Patrón BLoC**: Para gestión de estado compleja (devocionales, oraciones)
- **Patrón Provider**: Para gestión de estado simple (tema, localización)
- **Capa de Servicios**: Servicios dedicados para funcionalidad central
- **Widgets Reutilizables**: Componentes UI en carpeta dedicada

### Estructura de Carpetas
```
lib/
├── blocs/           # Gestión de estado BLoC
├── controllers/     # Controladores de aplicación
├── extensions/      # Extensiones de Dart
├── models/          # Modelos de datos
├── pages/           # Pantallas de la aplicación
├── providers/       # Proveedores de estado
├── services/        # Servicios centrales
│   ├── tts/         # Servicios específicos de TTS
│   └── ...
├── utils/           # Utilidades y constantes
└── widgets/         # Componentes UI reutilizables
```

## Sistema de Notificaciones

La aplicación cuenta con un sistema completo de notificaciones push que incluye:

- **Notificaciones locales programadas**: Recordatorios diarios para leer el devocional
- **Notificaciones remotas**: Recibe mensajes importantes a través de Firebase Cloud Messaging
- **Notificaciones con contenido dinámico**: Muestra el título del devocional del día
- **Notificaciones con imágenes**: Soporte para notificaciones con imágenes grandes
- **Gestión de permisos**: Solicitud y verificación de permisos de notificaciones
- **Tareas en segundo plano**: Actualización de contenido incluso cuando la app está cerrada

## Requisitos

- Flutter 3.32.8 o superior
- Dart 3.8.1 o superior
- Android SDK 21+ (Android 5.0+)
- iOS 11.0+

## 🧪 Testing

### Ejecutar Tests
```bash
# Todos los tests
flutter test

# Tests del sistema de reseñas
flutter test test/in_app_review_service_test.dart

# Tests específicos por categoría
flutter test test/unit/services/
flutter test test/unit/providers/
flutter test test/unit/controllers/

# Con cobertura
flutter test --coverage
```

### Estructura de Tests
```
test/
├── unit/                    # Tests unitarios organizados
│   ├── controllers/         # Tests de controladores
│   ├── extensions/          # Tests de extensiones
│   ├── providers/           # Tests de proveedores
│   ├── services/            # Tests de servicios
│   └── utils/               # Tests de utilidades
├── integration/             # Tests de integración
├── mocks/                   # Mocks para testing
└── *.dart                   # Tests principales y configuración
```

### Cobertura de Tests del Sistema de Reseñas
- ✅ **17 Tests de Funcionalidad Central**: Detección de hitos, validación, preferencias
- ✅ **8 Tests de Usuarios Existentes**: Lógica para usuarios con 5+ devocionales
- ✅ **8 Tests de Integración**: Ciclo de vida de contexto, seguridad async
- ✅ **2 Tests de Modo Debug**: Comportamiento en desarrollo
- ✅ **1 Test de Widget**: Integración UI con gestión apropiada de contexto

## Instalación

1. Clona este repositorio
2. Ejecuta `flutter pub get` para instalar las dependencias
3. Ejecuta `flutter run` para iniciar la aplicación

## 📚 Documentación

### Documentación del Proyecto
- [DEVOCIONAL_NUEVO_LIB_STRUCTURE.md](./DEVOCIONAL_NUEVO_LIB_STRUCTURE.md) - Estructura detallada del código fuente
- [DEVOCIONAL_NUEVO_TEST_STRUCTURE.md](./DEVOCIONAL_NUEVO_TEST_STRUCTURE.md) - Estructura detallada de tests
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Documentación de arquitectura
- [TECHNICAL_SERVICES.md](./TECHNICAL_SERVICES.md) - Documentación de servicios
- [TEST_COVERAGE_REPORT.md](./TEST_COVERAGE_REPORT.md) - Reporte de cobertura de tests

### Características Técnicas
- **44 archivos Dart** en 11 directorios
- **38 archivos de test** con cobertura exhaustiva
- **4 idiomas** completamente soportados
- **Funcionalidad offline** completa
- **Sistema de audio** con configuraciones de voz
- **Tracking de progreso** y estadísticas espirituales
- **Sistema de reseñas inteligente** con timing óptimo

## 🔧 Desarrollo

### Análisis de Código
```bash
dart analyze
```

### Formateo de Código
```bash
dart format .
```

### Generar Documentación
```bash
dart doc
```

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo LICENSE para más detalles
