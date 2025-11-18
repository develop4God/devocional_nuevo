# Firebase Robo Test Scripts para Devocionales Cristianos

Este conjunto de archivos JSON contiene scripts de prueba automatizada para Firebase Test Lab que cubren de manera exhaustiva toda la funcionalidad de la aplicación Devocionales Cristianos.

## Descripción de Archivos de Prueba

### 1. **01_basic_app_navigation.json**
- **Funcionalidad**: Navegación básica de la aplicación
- **Acciones**: Lanza la app, navega por el menú lateral, visita todas las páginas principales
- **Duración estimada**: 2-3 minutos
- **Componentes probados**: Splash screen, menu drawer, Settings, About, Contact, Favorites, Prayers

### 2. **02_language_download_test.json**
- **Funcionalidad**: Descarga de contenido multiidioma
- **Acciones**: Cambia entre todos los idiomas disponibles (Español, English, Português, Français)
- **Duración estimada**: 4-5 minutos
- **Componentes probados**: Application Language page, download progress, fallback logic

### 3. **03_devotional_reading_test.json**
- **Funcionalidad**: Lectura y navegación de devocionales
- **Acciones**: Navega entre devocionales, añade favoritos, usa calendario, comparte contenido
- **Duración estimada**: 3-4 minutos
- **Componentes probados**: PageView, favorites, calendar picker, share functionality

### 4. **04_tts_functionality_test.json**
- **Funcionalidad**: Sistema de texto a voz (TTS)
- **Acciones**: Configura voces, ajusta velocidad, reproduce/pausa/detiene audio
- **Duración estimada**: 3-4 minutos
- **Componentes probados**: TTS player, voice selection, speed control

### 5. **05_prayer_management_test.json**
- **Funcionalidad**: Gestión de oraciones
- **Acciones**: Añade, edita y elimina oraciones personales
- **Duración estimada**: 3-4 minutos
- **Componentes probados**: Prayer CRUD operations, modal forms

### 6. **06_settings_configuration_test.json**
- **Funcionalidad**: Configuración de la aplicación
- **Acciones**: Cambia notificaciones, tema, tamaño de fuente, donaciones
- **Duración estimada**: 3-4 minutos
- **Componentes probados**: Settings switches, dropdowns, PayPal integration

### 7. **07_favorites_management_test.json**
- **Funcionalidad**: Gestión de favoritos
- **Acciones**: Añade favoritos, los visualiza, navega a devocionales guardados, elimina favoritos
- **Duración estimada**: 3-4 minutos
- **Componentes probados**: Favorites page, long press actions

### 8. **08_share_functionality_test.json**
- **Funcionalidad**: Funciones de compartir
- **Acciones**: Comparte texto, imágenes, copia al portapapeles
- **Duración estimada**: 2-3 minutos
- **Componentes probados**: Share sheet, screenshot sharing, text selection

### 9. **09_progress_tracking_test.json**
- **Funcionalidad**: Seguimiento de progreso espiritual
- **Acciones**: Visualiza estadísticas, cambia vistas temporales
- **Duración estimada**: 2-3 minutos
- **Componentes probados**: Progress page, statistics visualization

### 10. **10_multilingual_functionality_test.json**
- **Funcionalidad**: Funcionalidad multiidioma completa
- **Acciones**: Cambia idioma y prueba funcionalidades en inglés
- **Duración estimada**: 4-5 minutos
- **Componentes probados**: Language switching, UI translation, TTS in different languages

### 11. **11_date_navigation_test.json**
- **Funcionalidad**: Navegación por fechas
- **Acciones**: Navega a diferentes fechas, usa calendario, retorna al día actual
- **Duración estimada**: 3-4 minutos
- **Componentes probados**: Calendar picker, date navigation, "Today" button

### 12. **12_notification_settings_test.json**
- **Funcionalidad**: Configuración de notificaciones
- **Acciones**: Configura horarios, sonidos, frecuencia, prueba notificaciones
- **Duración estimada**: 2-3 minutos
- **Componentes probados**: Notification settings, permission handling

### 13. **13_comprehensive_workflow_test.json**
- **Funcionalidad**: Flujo de trabajo completo
- **Acciones**: Simula un usuario real usando múltiples funciones en secuencia
- **Duración estimada**: 5-6 minutos
- **Componentes probados**: End-to-end user workflow

### 14. **14_offline_functionality_test.json**
- **Funcionalidad**: Funcionalidad offline
- **Acciones**: Descarga contenido, prueba modo offline
- **Duración estimada**: 4-5 minutos
- **Componentes probados**: Offline mode, local storage

### 15. **15_critical_download_validation.json**
- **Funcionalidad**: Validación crítica de descargas
- **Acciones**: Verifica integridad de descargas
- **Duración estimada**: 3-4 minutos
- **Componentes probados**: Download validation

### 16. **16_comprehensive_navigation_with_keys.json** ✨ NEW
- **Funcionalidad**: Navegación completa con claves semánticas
- **Acciones**: Prueba todos los componentes con claves de identificación únicas
- **Duración estimada**: 4-5 minutos
- **Componentes probados**: 
  - Drawer navigation (Bible version, favorites, prayers, dark mode, notifications, download, close button)
  - Bottom navigation bar (previous/next buttons, TTS player)
  - Bottom app bar icons (favorite, prayers, Bible, share, progress, settings)
  - Salvation prayer dialog (checkbox, continue button)
- **Claves probadas**:
  - `drawer_bible_version_selector`
  - `drawer_saved_favorites`
  - `drawer_my_prayers`
  - `drawer_dark_mode_toggle`
  - `drawer_notifications_config`
  - `drawer_share_app`
  - `drawer_download_devotionals`
  - `drawer_close_button`
  - `bottom_nav_previous_button`
  - `bottom_nav_next_button`
  - `bottom_nav_tts_player`
  - `bottom_appbar_favorite_icon`
  - `bottom_appbar_prayers_icon`
  - `bottom_appbar_bible_icon`
  - `bottom_appbar_share_icon`
  - `bottom_appbar_progress_icon`
  - `bottom_appbar_settings_icon`
  - `salvation_prayer_dialog`
  - `salvation_prayer_checkbox`
  - `salvation_prayer_continue_button`

## Instrucciones de Uso

### 1. Subir a Firebase Test Lab
```bash
# Sube cada archivo individualmente
gcloud firebase test android robo \
  --app path/to/your-app.apk \
  --robo-script 01_basic_app_navigation.json \
  --device model=Pixel2,version=28,locale=es,orientation=portrait
```

### 2. Ejecutar Pruebas Batch
```bash
# Ejecuta múltiples pruebas
for script in *.json; do
  gcloud firebase test android robo \
    --app your-app.apk \
    --robo-script "$script" \
    --device model=Pixel2,version=28,locale=es,orientation=portrait
done
```

### 3. Configuración Recomendada
- **Dispositivos**: Pixel 2, Pixel 3, Samsung Galaxy S9
- **Versiones Android**: 28 (Android 9), 29 (Android 10), 30 (Android 11)
- **Orientaciones**: portrait (principal), landscape (pruebas adicionales)
- **Locales**: es (español), en (inglés), pt (portugués), fr (francés)

## Cobertura de Pruebas

### ✅ Funcionalidades Principales Cubiertas:
- [x] Navegación básica de la aplicación
- [x] Descarga de contenido multiidioma (4 idiomas)
- [x] Lectura y navegación de devocionales
- [x] Sistema completo de TTS
- [x] Gestión de oraciones (CRUD)
- [x] Configuración de aplicación
- [x] Gestión de favoritos
- [x] Funciones de compartir
- [x] Seguimiento de progreso
- [x] Navegación por fechas
- [x] Configuración de notificaciones
- [x] Flujos de trabajo complejos
- [x] **Navegación con claves semánticas (NEW)**
- [x] **Drawer completo con IDs (NEW)**
- [x] **Bottom navigation con IDs (NEW)**
- [x] **Salvación prayer dialog (NEW)**

### 🎯 Escenarios de Prueba:
- **Funcionalidad básica**: Todos los componentes principales
- **Casos límite**: Fechas extremas, múltiples cambios de idioma
- **Interrupciones**: Cancelar acciones, navegación hacia atrás
- **Performance**: Descargas largas, reproducción TTS
- **UI/UX**: Interacciones táctiles, scroll, swipe
- **Persistencia**: Favoritos, configuraciones, oraciones

## Información Técnica

### Package Information:
- **Application ID**: `com.develop4god.devocional_nuevo`
- **Main Activity**: `.MainActivity`
- **Minimum SDK**: 23 (Android 6.0)
- **Target SDK**: 34 (Android 14)

### Resource IDs Principales:
- `drawer_button` - Botón del menú lateral
- `page_view` - Vista principal de devocionales
- `favorite_button` - Botón de favoritos
- `tts_play_button` - Reproducir TTS
- `calendar_button` - Selector de fecha
- `share_button` - Compartir contenido

### Timeouts y Delays:
- **App launch**: 8000ms
- **Language downloads**: 15000ms
- **TTS playback**: 5000ms
- **Navigation**: 2000ms
- **UI interactions**: 1000-2000ms

## Resultados Esperados

Todas las pruebas deben completarse sin crashes y mostrar:
1. **Navegación fluida** entre todas las pantallas
2. **Descarga exitosa** de contenido multiidioma con fallback
3. **Reproducción correcta** de TTS en todos los idiomas
4. **Persistencia** de favoritos y configuraciones
5. **Funcionalidad offline** después de descargas
6. **Interfaz responsiva** en diferentes orientaciones

## Notas Importantes

- Las pruebas asumen que la aplicación tiene conexión a internet para descargas
- Algunos delays pueden necesitar ajuste según la velocidad del dispositivo
- Los resource IDs pueden cambiar con actualizaciones de la aplicación
- Recomendado ejecutar en dispositivos con almacenamiento suficiente (>2GB libres)