# Devocionales Cristianos

Aplicación móvil para leer devocionales diarios y recibir notificaciones inspiradoras.

## Características

- Lectura de devocionales diarios
- Guardado de favoritos
- Compartir devocionales
- Sistema completo de notificaciones push
- Soporte para múltiples idiomas (español e inglés)

## Sistema de Notificaciones

La aplicación cuenta con un sistema completo de notificaciones push que incluye:

- **Notificaciones locales programadas**: Recordatorios diarios para leer el devocional
- **Notificaciones remotas**: Recibe mensajes importantes a través de Firebase Cloud Messaging
- **Notificaciones con contenido dinámico**: Muestra el título del devocional del día
- **Notificaciones con imágenes**: Soporte para notificaciones con imágenes grandes
- **Gestión de permisos**: Solicitud y verificación de permisos de notificaciones
- **Tareas en segundo plano**: Actualización de contenido incluso cuando la app está cerrada

### Configuración de Firebase

Para completar la configuración de Firebase Cloud Messaging, consulta el archivo [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

## Requisitos

- Flutter 3.0.0 o superior
- Dart 3.0.0 o superior
- Android SDK 21+ (Android 5.0+)
- iOS 11.0+

## Instalación

1. Clona este repositorio
2. Ejecuta `flutter pub get` para instalar las dependencias
3. Configura Firebase siguiendo las instrucciones en [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
4. Ejecuta `flutter run` para iniciar la aplicación

## Estructura del Proyecto

- `lib/main.dart`: Punto de entrada de la aplicación
- `lib/services/`: Servicios para notificaciones, API, etc.
- `lib/pages/`: Pantallas de la aplicación
- `lib/providers/`: Proveedores de estado (usando Provider)
- `lib/models/`: Modelos de datos
- `lib/widgets/`: Widgets reutilizables

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo LICENSE para más detalles.
