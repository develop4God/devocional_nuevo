import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TTSTestPage extends StatefulWidget {
  const TTSTestPage({super.key});

  @override
  State<TTSTestPage> createState() => _TTSTestPageState();
}

class _TTSTestPageState extends State<TTSTestPage> {
  int _currentDevocionalIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    debugPrint("🟢 TTSTestPage INIT");
  }

  Future<void> _leerDevocionalActual() async {
    final devocionalProvider =
        Provider.of<DevocionalProvider>(context, listen: false);
    final devocionales = devocionalProvider.devocionales;

    if (devocionales.isEmpty) {
      debugPrint("❌ No hay devocionales disponibles.");
      return;
    }

    if (_currentDevocionalIndex < 0 ||
        _currentDevocionalIndex >= devocionales.length) {
      debugPrint("❌ Índice fuera de rango, ajustando a 0.");
      _currentDevocionalIndex = 0;
    }

    final devocional = devocionales[_currentDevocionalIndex];

    debugPrint(
        "📢 Reproduciendo devocional: ${devocional.id} (índice: $_currentDevocionalIndex)");
    setState(() => _isPlaying = true);

    await TtsService().speakDevotional(devocional);

    debugPrint("🔵 Lectura TTS finalizada.");
    setState(() => _isPlaying = false);
  }

  Future<void> _stopTTS() async {
    debugPrint("⏹️ Deteniendo TTS");
    await TtsService().stop();
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    debugPrint("🔴 TTSTestPage DISPOSE - Deteniendo TTS...");
    TtsService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devocionalProvider = Provider.of<DevocionalProvider>(context);
    final devocionales = devocionalProvider.devocionales;

    final tieneDevocional = devocionales.isNotEmpty;
    final devocionalActual =
        tieneDevocional ? devocionales[_currentDevocionalIndex] : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Prueba TTS Directo al Servicio")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tieneDevocional)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Devocional actual:\n${devocionalActual!.versiculo}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: tieneDevocional && _currentDevocionalIndex > 0
                      ? () {
                          setState(() => _currentDevocionalIndex--);
                          debugPrint(
                              "⬅️ Devocional anterior, índice: $_currentDevocionalIndex");
                        }
                      : null,
                  child: const Text("Anterior"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: tieneDevocional &&
                          _currentDevocionalIndex < devocionales.length - 1
                      ? () {
                          setState(() => _currentDevocionalIndex++);
                          debugPrint(
                              "➡️ Devocional siguiente, índice: $_currentDevocionalIndex");
                        }
                      : null,
                  child: const Text("Siguiente"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  tieneDevocional && !_isPlaying ? _leerDevocionalActual : null,
              child: const Text("📖 Leer devocional actual (TTSService)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isPlaying ? _stopTTS : null,
              child: const Text("⏹️ Detener lectura TTS"),
            ),
            const SizedBox(height: 30),
            Text(
              _isPlaying ? "🔊 Reproduciendo TTS..." : "⏹️ TTS detenido",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
