# Instrucciones para completar la migración a Android Embedding v2

Hemos realizado varios cambios para migrar la aplicación al embedding v2 de Android, pero todavía hay algunos problemas que deben resolverse. A continuación, se detallan los pasos que debes seguir para completar la migración:

## 1. Actualizar el plugin android_alarm_manager_plus

El plugin `android_alarm_manager_plus` está causando problemas con el embedding v2. Debes actualizar a la última versión compatible:

1. Abre el archivo `pubspec.yaml` y actualiza la versión:

```yaml
android_alarm_manager_plus: ^4.0.7
```

2. Ejecuta `flutter pub get` para actualizar las dependencias.

## 2. Verificar la configuración de la clase Application

Asegúrate de que la clase `Application` esté correctamente configurada:

1. Abre el archivo `android/app/src/main/kotlin/com/develop4god/devocional_nuevo/FlutterApplication.kt`
2. Verifica que la clase extienda de `MultiDexApplication` y no de `FlutterApplication`
3. Asegúrate de que el método `onCreate()` inicialice el motor de Flutter y registre los plugins

## 3. Verificar el archivo AndroidManifest.xml

Asegúrate de que el archivo `AndroidManifest.xml` esté correctamente configurado:

1. Abre el archivo `android/app/src/main/AndroidManifest.xml`
2. Verifica que la aplicación use la clase `Application` correcta:

```xml
<application
    android:name=".Application"
    ...>
```

3. Verifica que tenga la metadata para el embedding v2:

```xml
<meta-data
    android:name="flutterEmbedding"
    android:value="2" />
```

## 4. Configurar el plugin android_alarm_manager_plus

El plugin `android_alarm_manager_plus` requiere una configuración especial para funcionar con el embedding v2:

1. Abre el archivo `android/app/src/main/kotlin/com/develop4god/devocional_nuevo/AppRegistrant.kt`
2. Verifica que el método `registerWith` registre correctamente el plugin `AndroidAlarmManagerPlugin`
3. Verifica que el método `setUpAlarmManager` configure correctamente el servicio de alarma

## 5. Configurar el archivo build.gradle.kts

Asegúrate de que el archivo `build.gradle.kts` esté correctamente configurado:

1. Abre el archivo `android/app/build.gradle.kts`
2. Verifica que tenga las dependencias necesarias para el embedding v2:

```kotlin
dependencies {
    // Flutter embedding v2 dependencies
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
    
    // Asegurarse de que android_alarm_manager_plus esté correctamente configurado
    implementation("dev.fluttercommunity.plus:android_alarm_manager_plus:+")
}
```

## 6. Ejecutar la aplicación con el archivo main_temp.dart

Si todavía tienes problemas con el embedding v2, puedes ejecutar la aplicación con el archivo `main_temp.dart` que no utiliza las dependencias problemáticas:

```bash
flutter run -t lib/main_temp.dart
```

## 7. Contactar al equipo de desarrollo de android_alarm_manager_plus

Si después de seguir todos estos pasos todavía tienes problemas con el embedding v2, puedes contactar al equipo de desarrollo del plugin `android_alarm_manager_plus` para obtener ayuda:

- [Repositorio de android_alarm_manager_plus](https://github.com/fluttercommunity/plus_plugins/tree/main/packages/android_alarm_manager_plus)
- [Página de issues](https://github.com/fluttercommunity/plus_plugins/issues)

## 8. Alternativas a android_alarm_manager_plus

Si no puedes resolver los problemas con `android_alarm_manager_plus`, puedes considerar usar alternativas:

- [workmanager](https://pub.dev/packages/workmanager)
- [flutter_background_service](https://pub.dev/packages/flutter_background_service)
- [background_fetch](https://pub.dev/packages/background_fetch)

Estas alternativas pueden ser más compatibles con el embedding v2 de Android.