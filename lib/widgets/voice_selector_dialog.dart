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
    'es-us-x-esd-local': '🇲🇽',
    'es-US-language': '🇲🇽',
    'es-es-x-eed-local': '🇪🇸',
    'es-ES-language': '🇪🇸',
  };

  // Mapeo de voces amigables para inglés
  static const Map<String, String> englishVoiceMap = {
    'en-us-x-tpd-network': 'US',
    'en-us-x-tpf-local': 'US',
    'en-gb-x-gbb-local': 'UK',
    'en-GB-language': 'UK',
  };

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _translatedSampleText = _getSampleTextByLanguage(widget.language);
    _loadVoices();
  }

  String _getSampleTextByLanguage(String language) {
    // Plantilla base tomada de español
    const template =
        'Puede guardar esta voz o seleccionar otra, de su preferencia';
    switch (language) {
      case 'es':
        return template;
      case 'en':
        return 'You can save this voice or select another, as you prefer';
      case 'pt':
        return 'Você pode salvar esta voz ou selecionar outra, de sua preferência';
      case 'fr':
        return 'Vous pouvez enregistrer cette voix ou en choisir une autre, selon votre préférence';
      case 'ja':
        return 'この声を保存するか、別の声を選択することができます。お好みに合わせて';
      default:
        return template;
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
      filteredVoices.sort((a, b) =>
          spanishVoiceMap.keys.toList().indexOf(a['name']!) -
          spanishVoiceMap.keys.toList().indexOf(b['name']!));
    } else if (widget.language == 'en') {
      filteredVoices = voices
          .where((voice) => englishVoiceMap.containsKey(voice['name']))
          .toList();
      filteredVoices.sort((a, b) =>
          englishVoiceMap.keys.toList().indexOf(a['name']!) -
          englishVoiceMap.keys.toList().indexOf(b['name']!));
    }
    setState(() {
      _voices = filteredVoices;
      _isLoading = false;
      // Selección por defecto: Voz Hombre Latino para español, Voice Male US para inglés
      if (widget.language == 'es' &&
          _voices.isNotEmpty &&
          _selectedVoiceName == null) {
        final defaultVoice = _voices.firstWhere(
            (v) => v['name'] == 'es-us-x-esd-local',
            orElse: () => _voices[0]);
        _selectedVoiceName = defaultVoice['name'];
        _selectedVoiceLocale = defaultVoice['locale'];
      } else if (widget.language == 'en' &&
          _voices.isNotEmpty &&
          _selectedVoiceName == null) {
        final defaultVoice = _voices.firstWhere(
            (v) => v['name'] == 'en-us-x-tpd-network',
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
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
                top: -5,
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
                padding: const EdgeInsets.only(
                    top: 15.0, left: 0, right: 0, bottom: 0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'settings.voice_sample_text'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 420,
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
                                    await _playSample(voice['name']!,
                                        voice['locale']!, index);
                                  },
                                  onDoubleTap: () async {
                                    await _playSample(voice['name']!,
                                        voice['locale']!, index);
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
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              // Icono según género de la voz
                                              if (widget.language == 'es') ...[
                                                if (voice['name'] ==
                                                        'es-us-x-esd-local' ||
                                                    voice['name'] ==
                                                        'es-es-x-eed-local')
                                                  Icon(Icons.man_3_outlined,
                                                      color:
                                                          colorScheme.primary,
                                                      size: 38),
                                                if (voice['name'] ==
                                                        'es-US-language' ||
                                                    voice['name'] ==
                                                        'es-ES-language')
                                                  Icon(Icons.woman_outlined,
                                                      color:
                                                          colorScheme.primary,
                                                      size: 38),
                                              ] else if (widget.language ==
                                                  'en') ...[
                                                if (voice['name'] ==
                                                        'en-us-x-tpd-network' ||
                                                    voice['name'] ==
                                                        'en-gb-x-gbb-local')
                                                  Icon(Icons.man_3_outlined,
                                                      color:
                                                          colorScheme.primary,
                                                      size: 38),
                                                if (voice['name'] ==
                                                        'en-us-x-tpf-local' ||
                                                    voice['name'] ==
                                                        'en-GB-language')
                                                  Icon(Icons.woman_outlined,
                                                      color:
                                                          colorScheme.primary,
                                                      size: 38),
                                              ] else ...[
                                                // Otros idiomas: mostrar solo el nombre
                                              ],
                                              const SizedBox(width: 10),
                                              Text(
                                                widget.language == 'es'
                                                    ? spanishVoiceMap[
                                                            voice['name'] ??
                                                                ''] ??
                                                        (voice['name'] ?? '')
                                                    : widget.language == 'en'
                                                        ? englishVoiceMap[
                                                                voice['name'] ??
                                                                    ''] ??
                                                            (voice['name'] ??
                                                                '')
                                                        : (voice['name'] ?? ''),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 32,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Explicación debajo de cada voz
                                          if (widget.language == 'es') ...[
                                            if (voice['name'] ==
                                                'es-us-x-esd-local')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 36, top: 2),
                                                child: Text('Hombre Latino',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: colorScheme
                                                            .onSurface)),
                                              ),
                                            if (voice['name'] ==
                                                'es-US-language')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 36, top: 2),
                                                child: Text('Mujer Latina',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: colorScheme
                                                            .onSurface)),
                                              ),
                                            if (voice['name'] ==
                                                'es-es-x-eed-local')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 36, top: 2),
                                                child: Text('Hombre Español',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: colorScheme
                                                            .onSurface)),
                                              ),
                                            if (voice['name'] ==
                                                'es-ES-language')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 36, top: 2),
                                                child: Text('Mujer Española',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: colorScheme
                                                            .onSurface)),
                                              ),
                                          ] else if (widget.language ==
                                              'en') ...[
                                            if (voice['name'] ==
                                                'en-us-x-tpd-network')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 36, top: 2),
                                                child: Text('US Male',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: colorScheme
                                                            .onSurface)),
                                              ),
                                            if (voice['name'] ==
                                                'en-us-x-tpf-local')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 36, top: 2),
                                                child: Text('US Female',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: colorScheme
                                                            .onSurface)),
                                              ),
                                            if (voice['name'] ==
                                                'en-gb-x-gbb-local')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 36, top: 2),
                                                child: Text('UK Male',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: colorScheme
                                                            .onSurface)),
                                              ),
                                            if (voice['name'] ==
                                                'en-GB-language')
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 36, top: 2),
                                                child: Text('UK Female',
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: colorScheme
                                                            .onSurface)),
                                              ),
                                          ]
                                        ],
                                      ),
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
                          const SizedBox(height: 32),
                          // Espacio extra entre lista y texto
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
