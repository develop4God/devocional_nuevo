import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';

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

  // Variables para guardar la selección inicial
  String? _initialVoiceName;
  String? _initialVoiceLocale;

  // Mapeo de voces amigables para español
  static const Map<String, String> spanishVoiceMap = {
    'es-us-x-esd-local': '🇲🇽',
    'es-US-language': '🇲🇽',
    'es-es-x-eed-local': '🇪🇸',
    'es-ES-language': '🇪🇸',
  };

  // Mapeo de voces amigables para inglés
  static const Map<String, String> englishVoiceMap = {
    'en-us-x-tpd-network': '🇺🇸',
    'en-us-x-tpf-local': '🇺🇸',
    'en-gb-x-gbb-local': '🇬🇧',
    'en-GB-language': '🇬🇧',
  };

  // Mapeo de voces amigables para portugués
  static const Map<String, String> portugueseVoiceMap = {
    // Brasil
    'pt-br-x-ptd-network': '🇧🇷', // Hombre Brasil
    'pt-br-x-afs-network': '🇧🇷', // Mujer Brasil
    // Portugal
    'pt-pt-x-pmj-local': '🇵🇹', // Hombre Portugal
    'pt-PT-language': '🇵🇹', // Mujer Portugal (solo mayúsculas)
  };

  // Mapeo de voces amigables para japonés
  static const Map<String, String> japaneseVoiceMap = {
    'ja-jp-x-jac-local': '🇯🇵', // Hombre Voz 1
    'ja-jp-x-jab-local': '🇯🇵', // Mujer Voz 1
    'ja-jp-x-jad-local': '🇯🇵', // Hombre Voz 2
    'ja-jp-x-htm-local': '🇯🇵', // Mujer Voz 2
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
    } else if (widget.language == 'pt') {
      filteredVoices = voices
          .where((voice) => portugueseVoiceMap.containsKey(voice['name']))
          .toList();
      filteredVoices.sort((a, b) =>
          portugueseVoiceMap.keys.toList().indexOf(a['name']!) -
          portugueseVoiceMap.keys.toList().indexOf(b['name']!));
    } else if (widget.language == 'ja') {
      filteredVoices = voices
          .where((voice) => japaneseVoiceMap.containsKey(voice['name']))
          .toList();
      filteredVoices.sort((a, b) =>
          japaneseVoiceMap.keys.toList().indexOf(a['name']!) -
          japaneseVoiceMap.keys.toList().indexOf(b['name']!));
    }
    setState(() {
      _voices = filteredVoices;
      _isLoading = false;
      // Elimino la selección por defecto, el usuario debe seleccionar manualmente
      _selectedVoiceName = null;
      _selectedVoiceLocale = null;
      _initialVoiceName = null;
      _initialVoiceLocale = null;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 18,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withAlpha((isDark ? 40 : 24)),
              colorScheme.secondary.withAlpha((isDark ? 60 : 32)),
              colorScheme.surface.withAlpha((isDark ? 80 : 40)),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha((isDark ? 60 : 32)),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Stack(
            children: [
              // Botón de cerrar en la esquina superior izquierda, siempre visible
              Positioned(
                top: 8,
                left: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 32),
                    ),
                  ),
                ),
              ),
              // Mostrar Lottie de tap si no hay selección nueva
              if (!(_selectedVoiceName != null &&
                  _selectedVoiceLocale != null &&
                  (_selectedVoiceName != _initialVoiceName ||
                      _selectedVoiceLocale != _initialVoiceLocale)))
                Positioned(
                  top: 8,
                  right: 8,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Transform.rotate(
                      angle: 3.92699, // 225 grados en radianes
                      child: Lottie.asset(
                        'assets/lottie/tap_screen.json',
                        repeat: true,
                        animate: true,
                      ),
                    ),
                  ),
                ),
              // Botón de guardar en la esquina superior derecha
              if (_selectedVoiceName != null &&
                  _selectedVoiceLocale != null &&
                  (_selectedVoiceName != _initialVoiceName ||
                      _selectedVoiceLocale != _initialVoiceLocale))
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await VoiceSettingsService().saveVoice(
                          widget.language,
                          _selectedVoiceName!,
                          _selectedVoiceLocale!,
                        );
                        await VoiceSettingsService()
                            .setUserSavedVoice(widget.language);
                        debugPrint(
                            '[VoiceSelectorDialog] Voz guardada: $_selectedVoiceName ($_selectedVoiceLocale) para idioma ${widget.language}');
                        if (!mounted) return;
                        navigator.pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(40),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Text(
                          'app.save'.tr(),
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(
                    top: 70.0, left: 0, right: 0, bottom: 0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final maxHeight =
                              MediaQuery.of(context).size.height * 0.8;
                          final maxWidth =
                              MediaQuery.of(context).size.width * 0.95;
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: maxHeight,
                              maxWidth: maxWidth,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  Text(
                                    'settings.voice_sample_text'.tr(),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 18),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _voices.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final voice = _voices[index];
                                      final isSelected =
                                          _selectedVoiceName == voice['name'] &&
                                              _selectedVoiceLocale ==
                                                  voice['locale'];
                                      final isPlaying = _playingIndex == index;
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () async {
                                          setState(() {
                                            _selectedVoiceName = voice['name'];
                                            _selectedVoiceLocale =
                                                voice['locale'];
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
                                          duration:
                                              const Duration(milliseconds: 250),
                                          curve: Curves.easeInOut,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? colorScheme.primary
                                                    .withAlpha(60)
                                                : colorScheme.surface,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isSelected
                                                  ? colorScheme.primary
                                                  : colorScheme.outline
                                                      .withAlpha(80),
                                              width: isSelected ? 2 : 1,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                        color: colorScheme
                                                            .primary
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
                                                    // Icono y emoji para portugués
                                                    if (widget.language ==
                                                        'pt') ...[
                                                      if (voice['name'] ==
                                                              'pt-br-x-ptd-network' ||
                                                          voice['name'] ==
                                                              'pt-pt-x-pmj-local')
                                                        Icon(
                                                            Icons
                                                                .man_3_outlined,
                                                            color: colorScheme
                                                                .primary,
                                                            size: 38),
                                                      if (voice['name'] ==
                                                              'pt-br-x-afs-network' ||
                                                          voice['name'] ==
                                                              'pt-PT-language')
                                                        Icon(
                                                            Icons
                                                                .woman_outlined,
                                                            color: colorScheme
                                                                .primary,
                                                            size: 38),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        portugueseVoiceMap[
                                                                voice['name'] ??
                                                                    ''] ??
                                                            (voice['name'] ??
                                                                ''),
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 32,
                                                            color: colorScheme
                                                                .primary),
                                                      ),
                                                    ]
                                                    // ...existing code para es/en...
                                                    else if (widget.language ==
                                                        'es') ...[
                                                      if (voice['name'] ==
                                                              'es-us-x-esd-local' ||
                                                          voice['name'] ==
                                                              'es-es-x-eed-local')
                                                        Icon(
                                                            Icons
                                                                .man_3_outlined,
                                                            color: colorScheme
                                                                .primary,
                                                            size: 38),
                                                      if (voice['name'] ==
                                                              'es-US-language' ||
                                                          voice['name'] ==
                                                              'es-ES-language')
                                                        Icon(
                                                            Icons
                                                                .woman_outlined,
                                                            color: colorScheme
                                                                .primary,
                                                            size: 38),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        spanishVoiceMap[
                                                                voice['name'] ??
                                                                    ''] ??
                                                            (voice['name'] ??
                                                                ''),
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 32,
                                                            color: colorScheme
                                                                .primary),
                                                      ),
                                                    ] else if (widget
                                                            .language ==
                                                        'en') ...[
                                                      if (voice['name'] ==
                                                              'en-us-x-tpd-network' ||
                                                          voice['name'] ==
                                                              'en-gb-x-gbb-local')
                                                        Icon(
                                                            Icons
                                                                .man_3_outlined,
                                                            color: colorScheme
                                                                .primary,
                                                            size: 38),
                                                      if (voice['name'] ==
                                                              'en-us-x-tpf-local' ||
                                                          voice['name'] ==
                                                              'en-GB-language')
                                                        Icon(
                                                            Icons
                                                                .woman_outlined,
                                                            color: colorScheme
                                                                .primary,
                                                            size: 38),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        englishVoiceMap[
                                                                voice['name'] ??
                                                                    ''] ??
                                                            (voice['name'] ??
                                                                ''),
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 32,
                                                            color: colorScheme
                                                                .primary),
                                                      ),
                                                    ] else if (widget
                                                            .language ==
                                                        'ja') ...[
                                                      if (voice['name'] ==
                                                              'ja-jp-x-jac-local' ||
                                                          voice['name'] ==
                                                              'ja-jp-x-jad-local')
                                                        Icon(
                                                            Icons
                                                                .man_3_outlined,
                                                            color: colorScheme
                                                                .primary,
                                                            size: 38),
                                                      if (voice['name'] ==
                                                              'ja-jp-x-jab-local' ||
                                                          voice['name'] ==
                                                              'ja-jp-x-htm-local')
                                                        Icon(
                                                            Icons
                                                                .woman_outlined,
                                                            color: colorScheme
                                                                .primary,
                                                            size: 38),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        japaneseVoiceMap[
                                                                voice['name'] ??
                                                                    ''] ??
                                                            (voice['name'] ??
                                                                ''),
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 32,
                                                            color: colorScheme
                                                                .primary),
                                                      ),
                                                    ] else if (widget
                                                            .language ==
                                                        'fr') ...[
                                                      Icon(
                                                          Icons
                                                              .record_voice_over,
                                                          color: colorScheme
                                                              .primary,
                                                          size: 38),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        '🇫🇷 ' +
                                                            (voice['name'] ??
                                                                ''),
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 22,
                                                            color: colorScheme
                                                                .primary),
                                                      ),
                                                    ]
                                                  ],
                                                ),
                                                // Explicación debajo de cada voz
                                                if (widget.language ==
                                                    'pt') ...[
                                                  if (voice['name'] ==
                                                      'pt-br-x-ptd-network')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Homem Brasil',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'pt-br-x-afs-network')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Mulher Brasil',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'pt-pt-x-pmj-local')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Homem Portugal',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'pt-PT-language')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Mulher Portugal',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                ]
                                                // ...existing code para es/en...
                                                else if (widget.language ==
                                                    'es') ...[
                                                  if (voice['name'] ==
                                                      'es-us-x-esd-local')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Hombre Latinoamérica',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'es-US-language')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Mujer Latinoamérica',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'es-es-x-eed-local')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Hombre España',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'es-ES-language')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Mujer España',
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Male United States',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'en-us-x-tpf-local')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Female United States',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'en-gb-x-gbb-local')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Male United Kingdom',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'en-GB-language')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text(
                                                          'Female United Kingdom',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                ] else if (widget.language ==
                                                    'ja') ...[
                                                  if (voice['name'] ==
                                                      'ja-jp-x-jac-local')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text('男性 声 1',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'ja-jp-x-jad-local')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text('男性 声 2',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'ja-jp-x-jab-local')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text('女性 声 1',
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurface)),
                                                    ),
                                                  if (voice['name'] ==
                                                      'ja-jp-x-htm-local')
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 36, top: 2),
                                                      child: Text('女性 声 2',
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
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2))
                                                : isSelected
                                                    ? Icon(
                                                        Icons
                                                            .check_circle_outline_outlined,
                                                        color:
                                                            colorScheme.primary,
                                                        size: 32)
                                                    : Icon(Icons.volume_up,
                                                        color:
                                                            colorScheme.primary,
                                                        size: 32),
                                            selected: isSelected,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
