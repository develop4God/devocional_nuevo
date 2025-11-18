# Firebase Robo Test Script para Devocionales Cristianos

Este archivo JSON contiene un script de prueba automatizada para Firebase Test Lab que cubre de manera exhaustiva toda la funcionalidad de la aplicación Devocionales Cristianos usando claves semánticas.

## Archivo de Prueba

### **robo_test.json**
- **Funcionalidad**: Navegación completa con claves semánticas
- **Acciones**: Prueba todos los componentes de navegación con claves de identificación únicas
- **Duración estimada**: 4-5 minutos
- **Componentes probados**: 
  - Drawer navigation (Bible version, favorites, prayers, dark mode, notifications, download, close button)
  - Bottom navigation bar (previous/next buttons, TTS player)
  - Bottom app bar icons (favorite, prayers, Bible, share, progress, settings)
  - Salvation prayer dialog (checkbox, continue button)

### Claves Semánticas Probadas:
- **Drawer**: `drawer_bible_version_selector`, `drawer_saved_favorites`, `drawer_my_prayers`, `drawer_dark_mode_toggle`, `drawer_notifications_config`, `drawer_share_app`, `drawer_download_devotionals`, `drawer_close_button`
- **Navigation**: `bottom_nav_previous_button`, `bottom_nav_next_button`, `bottom_nav_tts_player`
- **App Bar**: `bottom_appbar_favorite_icon`, `bottom_appbar_prayers_icon`, `bottom_appbar_bible_icon`, `bottom_appbar_share_icon`, `bottom_appbar_progress_icon`, `bottom_appbar_settings_icon`
- **Salvation Dialog**: `salvation_prayer_dialog`, `salvation_prayer_checkbox`, `salvation_prayer_continue_button`

## Instrucciones de Uso

### Subir a Firebase Test Lab
```bash
gcloud firebase test android robo \
  --app path/to/your-app.apk \
  --robo-script robo_test.json \
  --device model=Pixel2,version=28,locale=es,orientation=portrait
```

### Configuración Recomendada
- **Dispositivos**: Pixel 2, Pixel 3, Samsung Galaxy S9
- **Versiones Android**: 28 (Android 9), 29 (Android 10), 30 (Android 11)
- **Orientaciones**: portrait (principal), landscape (pruebas adicionales)
- **Locales**: es (español), en (inglés), pt (portugués), fr (francés)

## Cobertura de Pruebas

### ✅ Funcionalidades Principales Cubiertas:
- [x] Navegación completa con claves semánticas
- [x] Drawer navigation con IDs únicos
- [x] Bottom navigation bar con IDs
- [x] Bottom app bar icons con IDs
- [x] Salvation prayer dialog

### 🎯 Beneficios:
- **Estabilidad**: Las claves no cambian con refactorizaciones o traducciones
- **Cobertura**: Todos los puntos de navegación principales
- **Mantenibilidad**: Scripts fáciles de actualizar
- **Documentación**: Auto-documentado con nombres descriptivos

## Información Técnica

### Package Information:
- **Application ID**: `com.develop4god.devocional_nuevo`
- **Main Activity**: `.MainActivity`
- **Minimum SDK**: 23 (Android 6.0)
- **Target SDK**: 34 (Android 14)

### Timeouts y Delays:
- **App launch**: 8000ms
- **Navigation**: 2000ms
- **UI interactions**: 1000-3000ms

## Documentación Adicional

Ver `SEMANTIC_KEYS.md` para una lista completa de todas las claves semánticas disponibles con sus descripciones y tipos de widgets.

## Resultados Esperados

La prueba debe completarse sin crashes y mostrar:
1. **Navegación fluida** entre todas las pantallas
2. **Interacción exitosa** con todos los elementos identificados por claves
3. **Funcionalidad completa** de drawer, navigation y app bar
4. **Manejo correcto** del salvation prayer dialog si aparece

## Notas Importantes

- La prueba asume que la aplicación tiene conexión a internet
- Algunos delays pueden necesitar ajuste según la velocidad del dispositivo
- Las claves son estables y no cambiarán con actualizaciones de UI
- Recomendado ejecutar en dispositivos con almacenamiento suficiente (>2GB libres)
