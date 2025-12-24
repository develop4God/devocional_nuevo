import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  List<Map<String, String>> _voices = [];
  String? _selectedVoiceName;
  String? _selectedVoiceLocale;
  bool _isLoading = true;
  int? _playingIndex;
  late String _translatedSampleText;

  late final VoiceSettingsService _voiceSettingsService =
      getService<VoiceSettingsService>();

  String? _initialVoiceName;
  String? _initialVoiceLocale;

  // Flag para forzar fallback en testing (SOLO activo en debug mode)
  static const bool _forceFallbackForTesting =
      false; // ← Cambiar a true para probar fallback

  // Getter seguro: solo funciona en debug mode
  bool get _shouldForceFallback => kDebugMode && _forceFallbackForTesting;

  // Mapeo de voces premium (con género conocido)
  static const Map<String, String> spanishVoiceMap = {
    'es-us-x-esd-local': '🌎',
    'es-US-language': '🌎',
    'es-es-x-eed-local': '🇪🇸',
    'es-ES-language': '🇪🇸',
  };

  static const Map<String, String> englishVoiceMap = {
    'en-us-x-tpd-network': '🇺🇸',
    'en-us-x-tpf-local': '🇺🇸',
    'en-us-x-iob-local': '🇺🇸',
    'en-US-language': '🇺🇸',
    'en-gb-x-gbb-local': '🇬🇧',
    'en-GB-language': '🇬🇧',
  };

  static const Map<String, String> portugueseVoiceMap = {
    'pt-br-x-ptd-network': '🇧🇷',
    'pt-br-x-afs-network': '🇧🇷',
    'pt-pt-x-pmj-local': '🇵🇹',
    'pt-PT-language': '🇵🇹',
  };

  static const Map<String, String> japaneseVoiceMap = {
    'ja-jp-x-jac-local': '🇯🇵',
    'ja-jp-x-jab-local': '🇯🇵',
    'ja-jp-x-jad-local': '🇯🇵',
    'ja-jp-x-htm-local': '🇯🇵',
  };

  static const Map<String, String> frenchVoiceMap = {
    'fr-fr-x-frd-network': '🇫🇷',
    'fr-FR-language': '🇫🇷',
    'fr-ca-x-cab-network': '🇨🇦',
    'fr-CA-language': '🇨🇦',
  };

  static const Map<String, String> chineseVoiceMap = {
    'cmn-cn-x-cce-local': '🇨🇳', // Hombre China
    'cmn-cn-x-ccc-local': '🇨🇳', // Mujer China
    'cmn-tw-x-cte-network': '🇹🇼', // Hombre 2 Taiwán
    'cmn-tw-x-ctc-network': '🇹🇼', // Mujer 2 Taiwán
  };

  @override
  void initState() {
    super.initState();
    _translatedSampleText = _getSampleTextByLanguage(widget.language);
    _loadVoices();
  }

  String _getSampleTextByLanguage(String language) {
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
      case 'zh':
        return '您可以保存此语音或选择其他语音，按您的喜好';
      default:
        return template;
    }
  }

  String _getCountryFlag(String locale) {
    // Normalizar locale a formato xx-XX (tomar solo primeros 5 caracteres)
    final normalizedLocale =
        locale.length >= 5 ? locale.substring(0, 5) : locale;

    // Extrae los últimos 2 caracteres del locale normalizado
    final parts = normalizedLocale.split('-');
    if (parts.length >= 2) {
      final countryCode = parts[1].toUpperCase();
      // Validar que sea código de país de 2 letras
      if (countryCode.length == 2 &&
          RegExp(r'^[A-Z]{2}\$').hasMatch(countryCode)) {
        // Conversión de código de país a emoji de bandera
        final flag = countryCode.codeUnits
            .map((c) => String.fromCharCode(0x1F1E6 + c - 0x41))
            .join();
        return flag;
      }
    }
    return '🌐'; // Fallback global
  }

  String _normalizeLocale(String locale) {
    // Normalizar locale a formato xx-XX (5 caracteres)

    if (locale.length >= 5) {
      return locale.substring(0, 5);
    }
    return locale;
  }

  bool _isPremiumVoice(String voiceName, String language) {
    switch (language) {
      case 'es':
        return spanishVoiceMap.containsKey(voiceName);
      case 'en':
        return englishVoiceMap.containsKey(voiceName);
      case 'pt':
        return portugueseVoiceMap.containsKey(voiceName);
      case 'ja':
        return japaneseVoiceMap.containsKey(voiceName);
      case 'fr':
        return frenchVoiceMap.containsKey(voiceName);
      case 'zh':
        return chineseVoiceMap.containsKey(voiceName);
      default:
        return false;
    }
  }

  String _getVoiceEmoji(String voiceName, String locale, String language) {
    // Si es voz premium, usa el mapa correspondiente
    switch (language) {
      case 'es':
        if (spanishVoiceMap.containsKey(voiceName)) {
          return spanishVoiceMap[voiceName]!;
        }
        break;
      case 'en':
        if (englishVoiceMap.containsKey(voiceName)) {
          return englishVoiceMap[voiceName]!;
        }
        break;
      case 'pt':
        if (portugueseVoiceMap.containsKey(voiceName)) {
          return portugueseVoiceMap[voiceName]!;
        }
        break;
      case 'ja':
        if (japaneseVoiceMap.containsKey(voiceName)) {
          return japaneseVoiceMap[voiceName]!;
        }
        break;
      case 'fr':
        if (frenchVoiceMap.containsKey(voiceName)) {
          return frenchVoiceMap[voiceName]!;
        }
        break;
      case 'zh':
        if (chineseVoiceMap.containsKey(voiceName)) {
          return chineseVoiceMap[voiceName]!;
        }
        break;
    }
    // Si es fallback, extrae la bandera del locale
    return _getCountryFlag(locale);
  }

  Future<void> _loadVoices() async {
    final voices = await _voiceSettingsService
        .getAvailableVoicesForLanguage(widget.language);

    List<Map<String, String>> premiumVoices = [];
    List<Map<String, String>> fallbackVoices = [];

    // Seleccionar mapa premium según idioma
    Map<String, String>? premiumMap;
    switch (widget.language) {
      case 'es':
        premiumMap = spanishVoiceMap;
        break;
      case 'en':
        premiumMap = englishVoiceMap;
        break;
      case 'pt':
        premiumMap = portugueseVoiceMap;
        break;
      case 'ja':
        premiumMap = japaneseVoiceMap;
        break;
      case 'fr':
        premiumMap = frenchVoiceMap;
        break;
      case 'zh':
        premiumMap = chineseVoiceMap;
        break;
    }

    if (premiumMap != null) {
      // Filtrar voces premium
      premiumVoices = voices
          .where((voice) => premiumMap!.containsKey(voice['name']))
          .toList();

      // Ordenar según el orden del mapa
      premiumVoices.sort((a, b) =>
          premiumMap!.keys.toList().indexOf(a['name']!) -
          premiumMap.keys.toList().indexOf(b['name']!));

      // Si no hay suficientes voces premium (menos de 2), agregar fallback
      if (premiumVoices.length < 2 || _shouldForceFallback) {
        debugPrint(
            '[VoiceSelector] 🔄 Activando fallback para \\${widget.language}: '
            'premium=\${premiumVoices.length}, forced=\$_shouldForceFallback');

        // Definir locales prioritarios por idioma (los más comunes)
        final priorityLocales = <String, List<String>>{
          'es': ['es-ES', 'es-MX', 'es-US', 'es-AR'],
          'en': ['en-US', 'en-GB', 'en-AU', 'en-CA'],
          'pt': ['pt-BR', 'pt-PT'],
          'fr': ['fr-FR', 'fr-CA'],
          'ja': ['ja-JP'],
          'zh': ['zh-CN', 'zh-TW'],
        };

        final priorities = priorityLocales[widget.language] ?? [];

        // Agrupar voces por locale y limitar a 2 por locale
        final voicesByLocale = <String, List<Map<String, String>>>{};

        for (final voice in voices) {
          final name = voice['name'] ?? '';
          final locale = voice['locale'] ?? '';

          // No incluir voces que ya están en premium
          if (premiumMap.containsKey(name)) continue;

          // Normalizar locale a formato xx-XX
          final normalizedLocale = _normalizeLocale(locale);

          // Solo incluir si el locale normalizado está en la lista prioritaria
          final matchingPriority = priorities.firstWhere(
            (priority) =>
                normalizedLocale.toLowerCase() == priority.toLowerCase(),
            orElse: () => '',
          );

          if (matchingPriority.isNotEmpty) {
            voicesByLocale.putIfAbsent(matchingPriority, () => []);
            // Limitar a 2 voces por locale
            if (voicesByLocale[matchingPriority]!.length < 2) {
              voicesByLocale[matchingPriority]!.add(voice);
            }
          }
        }

        // Aplanar el mapa manteniendo el orden de prioridad
        for (final priority in priorities) {
          if (voicesByLocale.containsKey(priority)) {
            fallbackVoices.addAll(voicesByLocale[priority]!);
          }
        }

        debugPrint(
            '[VoiceSelector] ✅ Fallback encontró \${fallbackVoices.length} voces '
            'distribuidas en \${voicesByLocale.length} locales (máx 2 por locale)');
      }
    }

    setState(() {
      _voices = [...premiumVoices, ...fallbackVoices];
      _isLoading = false;
      _selectedVoiceName = null;
      _selectedVoiceLocale = null;
      _initialVoiceName = null;
      _initialVoiceLocale = null;

      debugPrint('[VoiceSelector] 📋 Total voces cargadas: \${_voices.length} '
          '(premium: \${premiumVoices.length}, fallback: \${fallbackVoices.length})');
    });
  }

  Future<void> _playSample(String name, String locale, int index) async {
    setState(() {
      _playingIndex = index;
    });
    await _voiceSettingsService.playVoiceSample(
        name, locale, _translatedSampleText);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _playingIndex = null;
    });
  }

  @override
  void dispose() {
    _voiceSettingsService.stopVoiceSample();
    super.dispose();
  }

  Widget _buildVoiceIcon(
      String voiceName, String language, ColorScheme colorScheme) {
    final isPremium = _isPremiumVoice(voiceName, language);

    if (!isPremium) {
      return Icon(Icons.person, color: colorScheme.primary, size: 38);
    }

    // Lógica para voces premium con género conocido
    switch (language) {
      case 'es':
        if (voiceName == 'es-us-x-esd-local' ||
            voiceName == 'es-es-x-eed-local') {
          return Icon(Icons.man_3_outlined,
              color: colorScheme.primary, size: 38);
        } else {
          return Icon(Icons.woman_outlined,
              color: colorScheme.primary, size: 38);
        }
      case 'en':
        if (voiceName == 'en-us-x-tpd-network' ||
            voiceName == 'en-gb-x-gbb-local') {
          return Icon(Icons.man_3_outlined,
              color: colorScheme.primary, size: 38);
        } else {
          return Icon(Icons.woman_outlined,
              color: colorScheme.primary, size: 38);
        }
      case 'pt':
        if (voiceName == 'pt-br-x-ptd-network' ||
            voiceName == 'pt-pt-x-pmj-local') {
          return Icon(Icons.man_3_outlined,
              color: colorScheme.primary, size: 38);
        } else {
          return Icon(Icons.woman_outlined,
              color: colorScheme.primary, size: 38);
        }
      case 'ja':
        if (voiceName == 'ja-jp-x-jac-local' ||
            voiceName == 'ja-jp-x-jad-local') {
          return Icon(Icons.man_3_outlined,
              color: colorScheme.primary, size: 38);
        } else {
          return Icon(Icons.woman_outlined,
              color: colorScheme.primary, size: 38);
        }
      case 'fr':
        if (voiceName == 'fr-fr-x-frd-network' ||
            voiceName == 'fr-ca-x-cab-network') {
          return Icon(Icons.man_3_outlined,
              color: colorScheme.primary, size: 38);
        } else {
          return Icon(Icons.woman_outlined,
              color: colorScheme.primary, size: 38);
        }
      case 'zh':
        if (voiceName == 'cmn-cn-x-cce-local' ||
            voiceName == 'cmn-tw-x-cte-network') {
          return Icon(Icons.man_3_outlined,
              color: colorScheme.primary, size: 38);
        }
        if (voiceName == 'cmn-cn-x-ccc-local' ||
            voiceName == 'cmn-tw-x-ctc-network') {
          return Icon(Icons.woman_outlined,
              color: colorScheme.primary, size: 38);
        }
        break;
      default:
        return Icon(Icons.person, color: colorScheme.primary, size: 38);
    }
    // Always return a Widget
    return Icon(Icons.person, color: colorScheme.primary, size: 38);
  }

  String _getVoiceDescription(
      String voiceName, String locale, String language) {
    final isPremium = _isPremiumVoice(voiceName, language);

    if (!isPremium) {
      // Para fallback: mostrar solo el locale normalizado (xx-XX)
      return _normalizeLocale(locale);
    }

    // Descripciones para voces premium
    switch (language) {
      case 'es':
        switch (voiceName) {
          case 'es-us-x-esd-local':
            return 'Hombre Latinoamérica';
          case 'es-US-language':
            return 'Mujer Latinoamérica';
          case 'es-es-x-eed-local':
            return 'Hombre España';
          case 'es-ES-language':
            return 'Mujer España';
        }
        break;
      case 'en':
        switch (voiceName) {
          case 'en-us-x-tpd-network':
            return 'Male United States';
          case 'en-us-x-tpf-local':
          case 'en-us-x-iob-local':
          case 'en-US-language':
            return 'Female United States';
          case 'en-gb-x-gbb-local':
            return 'Male United Kingdom';
          case 'en-GB-language':
            return 'Female United Kingdom';
        }
        break;
      case 'pt':
        switch (voiceName) {
          case 'pt-br-x-ptd-network':
            return 'Homem Brasil';
          case 'pt-br-x-afs-network':
            return 'Mulher Brasil';
          case 'pt-pt-x-pmj-local':
            return 'Homem Portugal';
          case 'pt-PT-language':
            return 'Mulher Portugal';
        }
        break;
      case 'ja':
        switch (voiceName) {
          case 'ja-jp-x-jac-local':
            return '男性 声 1';
          case 'ja-jp-x-jad-local':
            return '男性 声 2';
          case 'ja-jp-x-jab-local':
            return '女性 声 1';
          case 'ja-jp-x-htm-local':
            return '女性 声 2';
        }
        break;
      case 'fr':
        switch (voiceName) {
          case 'fr-fr-x-frd-network':
            return 'Homme France';
          case 'fr-FR-language':
            return 'Femme France';
          case 'fr-ca-x-cab-network':
            return 'Homme Canada';
          case 'fr-CA-language':
            return 'Femme Canada';
        }
        break;
      case 'zh':
        switch (voiceName) {
          case 'cmn-cn-x-cce-local':
            return '男性 声 1'; // Hombre China
          case 'cmn-cn-x-ccc-local':
            return '女性 声 1'; // Mujer China
          case 'cmn-tw-x-cte-network':
            return '男性 声 2'; // Hombre 2 Taiwán
          case 'cmn-tw-x-ctc-network':
            return '女性 声 2'; // Mujer 2 Taiwán
        }
        break;
    }

    return locale; // Fallback genérico
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
                      angle: 3.92699,
                      child: Lottie.asset(
                        'assets/lottie/tap_screen.json',
                        repeat: true,
                        animate: true,
                      ),
                    ),
                  ),
                ),
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
                        await _voiceSettingsService.stopVoiceSample();
                        await _voiceSettingsService.saveVoice(
                          widget.language,
                          _selectedVoiceName!,
                          _selectedVoiceLocale!,
                        );
                        await _voiceSettingsService
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
                                                    _buildVoiceIcon(
                                                        voice['name']!,
                                                        widget.language,
                                                        colorScheme),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      _getVoiceEmoji(
                                                          voice['name']!,
                                                          voice['locale']!,
                                                          widget.language),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontSize: 32,
                                                          color: colorScheme
                                                              .primary),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 36, top: 2),
                                                  child: Text(
                                                    _getVoiceDescription(
                                                        voice['name']!,
                                                        voice['locale']!,
                                                        widget.language),
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: colorScheme
                                                            .onSurface),
                                                  ),
                                                ),
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
                                                            .speaker_phone_outlined,
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
