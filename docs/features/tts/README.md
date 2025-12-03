Arquitectura del Sistema de Audio y TTS 🎧🗣️

1. AudioController (Controller/Proxy reactivo) 🕹️
   Actúa como un proxy entre la UI y el servicio TTS 🔄

Maneja el estado de la interfaz de usuario de forma reactiva ✨

Estado clave: mantiene el estado local sincronizado con TtsService 🔗

Operaciones: Play ▶️, pause ⏸️, resume, stop ⏹️ con manejo de timeouts ⏳

Mejoras implementadas: Sistema de timeout de operaciones (5 segundos), sincronización forzada
periódica cada 200ms y estado _operationInProgress para UX de loading 🔄

2.TtsService (Servicio núcleo) 🧠
Singleton que maneja la reproducción TTS real usando FlutterTts 🤖

Características avanzadas: Divide el texto en chunks para mejor manejo 🧩, normalización de texto (
versículos bíblicos, años, abreviaciones) 📝, timer de emergencia para manejar fallos del handler
nativo 🚨, navegación por chunks (anterior/siguiente) ⏭️ y progreso en tiempo real 📈

3.TtsPlayerWidget (UI Component) 🎨
Widget reactivo que escucha cambios del AudioController 👂

Estados visuales: Play ▶️, Pause ⏸️, Loading 🔄, Error ❌

Layout adaptativo (compacto vs normal) 📱💻

Manejo inteligente de estados de transición 💡

Flujo de funcionamiento 🌊
Inicialización: TtsService configura FlutterTts con idioma y velocidad ⚙️

Reproducción: Convierte el devocional en chunks de texto optimizados 📚

Control: AudioController coordina las operaciones asíncronas 🤝

Sincronización: Múltiples mecanismos para mantener consistencia de estado 🎛️

Navegación: Permite saltar entre chunks del devocional ➡️

Elementos destacados ✨
Normalización de texto: Maneja referencias bíblicas ("1 Corintios" → "Primera de Corintios") 📖

Timeouts de seguridad: Emergency timers para chunks que no completan ⏳

Estado reactivo: Streams para estado y progreso 📡

Persistencia: Guarda configuración TTS en SharedPreferences 💾

Estadísticas: Registra devocionales escuchados en 80%+ de progreso 📊

# 📁 Devocional TTS App Structure

```
lib/
├── 📱 widgets/
│   └── tts_player_widget.dart          # Widget reproductor TTS
│       ├── 🎵 Play/Pause controls
│       ├── 📊 State visualization  
│       ├── 📱 Responsive layout
│       └── 🔄 Real-time updates
│
├── 🎛️ controllers/
│   └── audio_controller.dart            # Provider - Estado global
│       ├── 🔄 TTS state management
│       ├── 📋 Current devocional tracking
│       ├── ⏯️ Playback controls
│       └── 🐛 Error handling
│
├── 🔧 services/
│   └── tts_service.dart                 # Motor Text-to-Speech
│       ├── 🗣️ Text synthesis
│       ├── ⚙️ TTS configuration
│       ├── 🎵 Audio playback
│       └── 📱 Platform integration
│
└── 📦 models/
    └── devocional_model.dart           # Modelo de datos
        ├── 📋 Devocional structure
        ├── 📝 Content fields
        └── 🔗 Serialization

---

## 🔄 Flujo de Datos

1. **User Input** 👆
   └── TtsPlayerWidget detects tap

2. **State Management** 🎛️
   └── AudioController receives action

3. **Service Call** 🔧
   └── TtsService processes text

4. **Audio Output** 🔊
   └── Device speakers play audio

5. **UI Update** 📱
   └── Widget rebuilds with new state

---

## 🏗️ Arquitectura

```

┌─────────────────┐
│ UI LAYER │ ← TtsPlayerWidget
├─────────────────┤
│ CONTROLLER │ ← AudioController (Provider)
├─────────────────┤
│ SERVICES │ ← TtsService
├─────────────────┤
│ MODELS │ ← DevocionalModel
└─────────────────┘

```

### 📋 Estados TTS
- `idle` - Sin actividad
- `initializing` - Preparando TTS
- `playing` - Reproduciendo audio
- `paused` - Pausado
- `stopping` - Deteniendo
- `error` - Error en reproducción

### 🎯 Características Clave
- ✅ Múltiples devocionales simultáneos
- ✅ Estados visuales claros
- ✅ Layout responsivo
- ✅ Manejo robusto de errores
- ✅ Callbacks de finalización




