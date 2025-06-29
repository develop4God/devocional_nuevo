# Configuración de Firebase para Notificaciones Push

Este documento proporciona instrucciones para completar la configuración de Firebase Cloud Messaging (FCM) en la aplicación Devocionales Cristianos.

## Requisitos previos

1. Tener una cuenta de Google
2. Acceso a [Firebase Console](https://console.firebase.google.com/)

## Pasos para configurar Firebase

### 1. Crear un proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Añadir proyecto"
3. Ingresa "Devocionales Cristianos" como nombre del proyecto
4. Sigue los pasos para crear el proyecto (puedes habilitar Google Analytics si lo deseas)

### 2. Configurar Firebase para Android

1. En la consola de Firebase, selecciona tu proyecto
2. Haz clic en el ícono de Android para añadir una aplicación Android
3. Ingresa el paquete de la aplicación: `com.develop4god.devocional_nuevo` (o el que corresponda)
4. Ingresa un apodo para la aplicación: "Devocionales Cristianos"
5. Descarga el archivo `google-services.json`
6. Coloca el archivo `google-services.json` en la carpeta `android/app/` de tu proyecto Flutter

### 3. Configurar Firebase para iOS

1. En la consola de Firebase, selecciona tu proyecto
2. Haz clic en el ícono de iOS para añadir una aplicación iOS
3. Ingresa el Bundle ID de la aplicación (lo encuentras en Xcode)
4. Ingresa un apodo para la aplicación: "Devocionales Cristianos"
5. Descarga el archivo `GoogleService-Info.plist`
6. Abre Xcode, selecciona el proyecto Runner y arrastra el archivo `GoogleService-Info.plist` a la carpeta Runner (asegúrate de seleccionar "Copy items if needed")

### 4. Configurar Firebase Cloud Messaging

1. En la consola de Firebase, ve a "Engagement" > "Cloud Messaging"
2. Configura los canales de notificación según sea necesario
3. Para enviar notificaciones de prueba, puedes usar la sección "Enviar tu primera notificación"

## Envío de notificaciones

### Enviar notificaciones desde la consola de Firebase

1. Ve a "Engagement" > "Cloud Messaging" en la consola de Firebase
2. Haz clic en "Crear tu primera campaña" o "Nueva campaña"
3. Selecciona "Notification" como tipo de campaña
4. Configura el título, mensaje y otros detalles de la notificación
5. En "Target", puedes seleccionar todos los usuarios o segmentar por temas
6. Programa la notificación para enviarla inmediatamente o en una fecha futura
7. Revisa y publica la campaña

### Enviar notificaciones mediante API REST

También puedes enviar notificaciones programáticamente utilizando la API REST de Firebase Cloud Messaging. Aquí hay un ejemplo de cómo hacerlo:

```bash
curl -X POST -H "Authorization: key=TU_CLAVE_DE_SERVIDOR" -H "Content-Type: application/json" -d '{
  "to": "/topics/general",
  "notification": {
    "title": "🙏 Devocional de Hoy",
    "body": "Tu momento de reflexión diaria te está esperando"
  },
  "data": {
    "screen": "devotional",
    "id": "123"
  }
}' https://fcm.googleapis.com/fcm/send
```

Reemplaza `TU_CLAVE_DE_SERVIDOR` con la clave de servidor que encuentras en la configuración del proyecto de Firebase.

## Solución de problemas

### Las notificaciones no se reciben

1. Verifica que el dispositivo tenga conexión a Internet
2. Asegúrate de que las notificaciones estén habilitadas en la configuración del dispositivo
3. Verifica que el token FCM se esté generando correctamente (puedes ver los logs en la consola)
4. Comprueba que el archivo de configuración de Firebase esté correctamente ubicado

### Error al enviar notificaciones

1. Verifica que la clave de servidor sea correcta
2. Asegúrate de que el formato de la solicitud sea válido
3. Comprueba los logs en la consola de Firebase para ver si hay errores

## Recursos adicionales

- [Documentación oficial de Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Guía de Flutter para FCM](https://firebase.flutter.dev/docs/messaging/overview)