import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_data_registry.dart';
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
  String? _translatedSampleText;

  late final VoiceSettingsService _voiceSettingsService =
      getService<VoiceSettingsService>();

  String? _initialVoiceName;
  String? _initialVoiceLocale;

  // Flag para forzar fallback en testing (SOLO activo en debug mode)
  static const bool _forceFallbackForTesting =
      false; // ← Cambiado a false para desactivar fallback en pruebas

  // Getter seguro: solo funciona en debug mode
  bool get _shouldForceFallback => kDebugMode && _forceFallbackForTesting;

  @override
  void initState() {
    super.initState();
    _translatedSampleText = _getSampleTextByLanguage(widget.language);
    _loadVoices();
  }

  String _getSampleTextByLanguage(String language) {
    return VoiceDataRegistry.getSampleText(language);
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

  String _getVoiceEmoji(String voiceName, String locale, String language) {
    final metadata = VoiceDataRegistry.getVoiceMetadata(voiceName, language);
    if (metadata != null) return metadata.emoji;
    return _getCountryFlag(locale);
  }

  Future<void> _loadVoices() async {
    debugPrint(
        '[VoiceSelector] 🎤 Loading voices for language: ${widget.language}');
    final voices = await _voiceSettingsService.getAvailableVoicesForLanguage(
      widget.language,
    );
    debugPrint('[VoiceSelector] 📋 Raw voices from service: ${voices.length}');

    List<Map<String, String>> premiumVoices = [];
    List<Map<String, String>> fallbackVoices = [];

    // Get premium voice map from registry
    final premiumMap = VoiceDataRegistry.getVoiceMap(widget.language);

    if (premiumMap != null) {
      // Filter premium voices
      premiumVoices = voices
          .where((voice) => premiumMap.containsKey(voice['name']))
          .toList();

      // Sort by registry order
      final keyOrder = premiumMap.keys.toList();
      premiumVoices.sort(
        (a, b) => keyOrder.indexOf(a['name']!) - keyOrder.indexOf(b['name']!),
      );

      // If not enough premium voices, add fallback
      if (premiumVoices.length < 2 || _shouldForceFallback) {
        debugPrint(
          '[VoiceSelector] 🔄 Activating fallback for ${widget.language}: '
          'premium=${premiumVoices.length}, forced=$_shouldForceFallback',
        );

        final priorities =
            VoiceDataRegistry.getPriorityLocales(widget.language);

        // Group voices by locale, limit to 2 per locale
        final voicesByLocale = <String, List<Map<String, String>>>{};

        for (final voice in voices) {
          final name = voice['name'] ?? '';
          final locale = voice['locale'] ?? '';

          if (premiumMap.containsKey(name)) continue;

          final normalizedLocale = _normalizeLocale(locale);

          final matchingPriority = priorities.firstWhere(
            (priority) =>
                normalizedLocale.toLowerCase() == priority.toLowerCase(),
            orElse: () => '',
          );

          if (matchingPriority.isNotEmpty) {
            voicesByLocale.putIfAbsent(matchingPriority, () => []);
            if (voicesByLocale[matchingPriority]!.length < 2) {
              voicesByLocale[matchingPriority]!.add(voice);
            }
          }
        }

        for (final priority in priorities) {
          if (voicesByLocale.containsKey(priority)) {
            fallbackVoices.addAll(voicesByLocale[priority]!);
          }
        }

        debugPrint(
          '[VoiceSelector] ✅ Fallback found ${fallbackVoices.length} voices '
          'across ${voicesByLocale.length} locales (max 2 per locale)',
        );
      }
    } else {
      // NO PREMIUM MAP - show all available voices
      debugPrint(
          '[VoiceSelector] 🌐 No premium map - showing ALL ${voices.length} available voices');
      fallbackVoices = voices;
    }

    setState(() {
      _voices = [...premiumVoices, ...fallbackVoices];
      _isLoading = false;
      _selectedVoiceName = null;
      _selectedVoiceLocale = null;
      _initialVoiceName = null;
      _initialVoiceLocale = null;

      debugPrint(
        '[VoiceSelector] 📋 Total voices loaded: ${_voices.length} '
        '(premium: ${premiumVoices.length}, fallback: ${fallbackVoices.length})',
      );

      if (_voices.isEmpty) {
        debugPrint(
            '[VoiceSelector] ⚠️ WARNING: No voices loaded! This will show empty list to user.');
      }
    });
  }

  Future<void> _playSample(String name, String locale, int index) async {
    // Defensive check: ensure widget is still mounted before setState
    if (!mounted) {
      debugPrint(
        '[VoiceSelector] ⚠️ Widget not mounted, skipping _playSample',
      );
      return;
    }

    // ✅ VALIDATION: Prevent null voice crashes (Crashlytics fix)
    if (name.trim().isEmpty || locale.trim().isEmpty) {
      debugPrint(
        '[VoiceSelector] ⚠️ Invalid voice data (name: "$name", locale: "$locale"), skipping sample',
      );
      return;
    }

    setState(() {
      _playingIndex = index;
    });

    try {
      // Defensive check: ensure _translatedSampleText is not null
      final sampleText = _translatedSampleText ?? widget.sampleText;
      debugPrint(
        '[VoiceSelector] 🔊 Playing sample: name=$name, locale=$locale, text length=${sampleText.length}',
      );

      await _voiceSettingsService.playVoiceSample(
        name,
        locale,
        sampleText,
      );
      await Future.delayed(const Duration(seconds: 2));
    } catch (e, stackTrace) {
      debugPrint('[VoiceSelector] ❌ Error playing sample: $e');
      debugPrint('[VoiceSelector] Stack trace: $stackTrace');
    } finally {
      // Defensive check: ensure widget is still mounted before final setState
      if (mounted) {
        setState(() {
          _playingIndex = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _voiceSettingsService.stopVoiceSample();
    super.dispose();
  }

  Widget _buildVoiceIcon(
    String voiceName,
    String language,
    ColorScheme colorScheme,
  ) {
    final metadata = VoiceDataRegistry.getVoiceMetadata(voiceName, language);
    final icon = metadata?.genderIcon ?? Icons.person;
    return Icon(icon, color: colorScheme.primary, size: 38);
  }

  String _getVoiceDescription(
    String voiceName,
    String locale,
    String language,
  ) {
    final metadata = VoiceDataRegistry.getVoiceMetadata(voiceName, language);
    if (metadata != null) return metadata.description;
    // For non-premium voices: show normalized locale (xx-XX)
    return _normalizeLocale(locale);
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
                        await _voiceSettingsService.setUserSavedVoice(
                          widget.language,
                        );
                        debugPrint(
                          '[VoiceSelectorDialog] Voz guardada: $_selectedVoiceName ($_selectedVoiceLocale) para idioma ${widget.language}',
                        );
                        if (!mounted) return;
                        navigator.pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                  top: 70.0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                ),
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                                            voice['name']!,
                                            voice['locale']!,
                                          );
                                          await _playSample(
                                            voice['name']!,
                                            voice['locale']!,
                                            index,
                                          );
                                        },
                                        onDoubleTap: () async {
                                          await _playSample(
                                            voice['name']!,
                                            voice['locale']!,
                                            index,
                                          );
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          curve: Curves.easeInOut,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? colorScheme.primary.withAlpha(
                                                    60,
                                                  )
                                                : colorScheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
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
                                                      color: colorScheme.primary
                                                          .withAlpha(40),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
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
                                                      colorScheme,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      _getVoiceEmoji(
                                                        voice['name']!,
                                                        voice['locale']!,
                                                        widget.language,
                                                      ),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 32,
                                                        color:
                                                            colorScheme.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 36,
                                                    top: 2,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        _getVoiceDescription(
                                                          voice['name']!,
                                                          voice['locale']!,
                                                          widget.language,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: colorScheme
                                                              .onSurface,
                                                        ),
                                                      ),
                                                      if (kDebugMode)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 4),
                                                          child: Text(
                                                            // Show technical name and locale for debug
                                                            ' 0${voice['name']} (${voice['locale']})',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: colorScheme
                                                                  .onSurface
                                                                  .withValues(
                                                                      alpha:
                                                                          0.6),
                                                              fontFamily:
                                                                  'monospace',
                                                            ),
                                                          ),
                                                        ),
                                                    ],
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
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : isSelected
                                                    ? Icon(
                                                        Icons
                                                            .speaker_phone_outlined,
                                                        color:
                                                            colorScheme.primary,
                                                        size: 32,
                                                      )
                                                    : Icon(
                                                        Icons.volume_up,
                                                        color:
                                                            colorScheme.primary,
                                                        size: 32,
                                                      ),
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
