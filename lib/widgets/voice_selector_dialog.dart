import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceSelectorDialog extends StatefulWidget {
  final String language;
  final String sampleText;
  final Function(String name, String locale) onVoiceSelected;

  const VoiceSelectorDialog({
    super.key,
    required this.language,
    required this.sampleText,
    required this.onVoiceSelected,
  });

  @override
  State<VoiceSelectorDialog> createState() => _VoiceSelectorDialogState();
}

class _VoiceSelectorDialogState extends State<VoiceSelectorDialog> {
  late FlutterTts _flutterTts;
  List<Map<String, String>> _voices = [];
  String? _selectedVoiceName;
  String? _selectedVoiceLocale;
  bool _isLoading = true;
  int? _playingIndex;
  late String _translatedSampleText;

  // Mapeo de voces amigables para español
  static const Map<String, String> spanishVoiceMap = {
    'es-us-x-esd-local': 'Voz Hombre Latino',
    'es-US-language': 'Voz Mujer Latino',
    'es-es-x-eed-local': 'Voz Hombre España',
    'es-ES-language': 'Voz Mujer España',
  };

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _translatedSampleText = _getSampleTextByLanguage(widget.language);
    _loadVoices();
  }

  String _getSampleTextByLanguage(String language) {
    switch (language) {
      case 'es':
        return 'Puede Guardar esta voz o seleccionar otra, de su preferencia';
      case 'en':
        return 'You can keep this voice or select a different one';
      case 'pt':
        return 'Você pode manter esta voz ou selecionar outra diferente';
      case 'fr':
        return 'Vous pouvez garder cette voix ou en choisir une autre';
      case 'ja':
        return 'この声を維持するか、別の声を選択できます';
      default:
        return 'You can keep this voice or select a different one';
    }
  }

  Future<void> _loadVoices() async {
    final voices = await VoiceSettingsService()
        .getAvailableVoicesForLanguage(widget.language);
    List<Map<String, String>> filteredVoices = voices;
    if (widget.language == 'es') {
      filteredVoices = voices
          .where((voice) => spanishVoiceMap.containsKey(voice['name']))
          .toList();
      // Ordenar según el mapa
      filteredVoices.sort((a, b) =>
          spanishVoiceMap.keys.toList().indexOf(a['name']!) -
          spanishVoiceMap.keys.toList().indexOf(b['name']!));
    }
    setState(() {
      _voices = filteredVoices;
      _isLoading = false;
      // Selección por defecto: Voz Hombre Latino
      if (widget.language == 'es' &&
          _voices.isNotEmpty &&
          _selectedVoiceName == null) {
        final defaultVoice = _voices.firstWhere(
            (v) => v['name'] == 'es-us-x-esd-local',
            orElse: () => _voices[0]);
        _selectedVoiceName = defaultVoice['name'];
        _selectedVoiceLocale = defaultVoice['locale'];
      }
    });
  }

  Future<void> _playSample(String name, String locale, int index) async {
    setState(() {
      _playingIndex = index;
    });
    await _flutterTts.setVoice({'name': name, 'locale': locale});
    debugPrint(
        '[VoiceSelectorDialog] sampleText leído: "$_translatedSampleText"');
    await _flutterTts.speak(_translatedSampleText);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _playingIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Stack(
          children: [
            // Botón de cerrar en la esquina superior izquierda (lo más arriba posible)
            Positioned(
              top: -18,
              left: -15,
              child: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Texto de guardar en la esquina superior derecha (lo más arriba posible)
            Positioned(
              top: -6,
              right: 0,
              child: GestureDetector(
                onTap:
                    _selectedVoiceName != null && _selectedVoiceLocale != null
                        ? () async {
                            await VoiceSettingsService().saveVoice(
                              widget.language,
                              _selectedVoiceName!,
                              _selectedVoiceLocale!,
                            );
                            debugPrint(
                                '[VoiceSelectorDialog] Voz guardada: $_selectedVoiceName ($_selectedVoiceLocale) para idioma ${widget.language}');
                            if (!mounted) return;
                            Navigator.of(context).pop();
                          }
                        : null,
                child: Padding(
                  padding: const EdgeInsets.only(top: 0, right: 8),
                  child: Text(
                    'app.save'.tr(),
                    style: TextStyle(
                      // Invertir colores: tema cuando no hay selección, negro cuando sí
                      color: _selectedVoiceName != null &&
                              _selectedVoiceLocale != null
                          ? Colors.black
                          : colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(top: 8.0, left: 0, right: 0, bottom: 0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Selecciona una voz',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _translatedSampleText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 320,
                          child: ListView.separated(
                            itemCount: _voices.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final voice = _voices[index];
                              final isSelected =
                                  _selectedVoiceName == voice['name'] &&
                                      _selectedVoiceLocale == voice['locale'];
                              final isPlaying = _playingIndex == index;
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  setState(() {
                                    _selectedVoiceName = voice['name'];
                                    _selectedVoiceLocale = voice['locale'];
                                  });
                                  widget.onVoiceSelected(
                                      voice['name']!, voice['locale']!);
                                  await _playSample(
                                      voice['name']!, voice['locale']!, index);
                                },
                                onDoubleTap: () async {
                                  await _playSample(
                                      voice['name']!, voice['locale']!, index);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary.withAlpha(60)
                                        : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outline.withAlpha(80),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                                color: colorScheme.primary
                                                    .withAlpha(40),
                                                blurRadius: 8,
                                                offset: Offset(0, 2))
                                          ]
                                        : [],
                                  ),
                                  child: ListTile(
                                    leading: Icon(Icons.record_voice_over,
                                        color: colorScheme.primary),
                                    // En el ListTile, mostrar el nombre amigable si es español
                                    title: Text(
                                        widget.language == 'es'
                                            ? spanishVoiceMap[
                                                    voice['name'] ?? ''] ??
                                                (voice['name'] ?? '')
                                            : (voice['name'] ?? ''),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(voice['locale'] ?? '',
                                        style: TextStyle(fontSize: 13)),
                                    trailing: isPlaying
                                        ? const SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : Icon(Icons.volume_up,
                                            color: colorScheme.primary),
                                    selected: isSelected,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
