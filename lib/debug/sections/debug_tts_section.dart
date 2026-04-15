// ignore_for_file: use_build_context_synchronously
import 'package:devocional_nuevo/debug/debug_flags.dart';
import 'package:devocional_nuevo/services/tts/voice_data_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Debug section for TTS: fallback toggle and voice explorer.
/// Single Responsibility: only handles TTS debug tooling.
class DebugTtsSection extends StatefulWidget {
  const DebugTtsSection({super.key});

  @override
  State<DebugTtsSection> createState() => _DebugTtsSectionState();
}

class _DebugTtsSectionState extends State<DebugTtsSection> {
  late String _explorerLang;
  List<Map<String, dynamic>> _explorerVoices = [];
  Map<String, String> _explorerGenders = {};
  int? _explorerPlayingIndex;
  bool _explorerLoading = false;
  final FlutterTts _explorerTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    // Use the first supported language from the registry, or default to 'en'
    _explorerLang = VoiceDataRegistry.supportedLanguages.isNotEmpty
        ? VoiceDataRegistry.supportedLanguages.first
        : 'en';
  }

  Future<void> _loadAllVoices(String lang) async {
    setState(() => _explorerLoading = true);
    final raw = await _explorerTts.getVoices;
    if (raw is List) {
      final filtered = raw
          .cast<Map>()
          .where((v) => (v['locale'] as String? ?? '')
              .toLowerCase()
              .startsWith(lang.toLowerCase()))
          .map((v) => {
                'name': v['name'] as String? ?? '',
                'locale': v['locale'] as String? ?? ''
              })
          .toList();
      setState(() {
        _explorerVoices = filtered;
        _explorerLoading = false;
      });
      debugPrint(
          '[VoiceExplorer] Found ${filtered.length} voices for lang=$lang');
    }
  }

  Future<void> _playSample(String name, String locale, int index) async {
    setState(() => _explorerPlayingIndex = index);
    await _explorerTts.setVoice({'name': name, 'locale': locale});
    await _explorerTts.speak('مرحبا، هذا صوت تجريبي. كيفك؟');
    setState(() => _explorerPlayingIndex = null);
  }

  void _tagGender(String voiceName, String gender) {
    setState(() => _explorerGenders[voiceName] = gender);
    debugPrint('[VoiceExplorer] Tagged: $voiceName → $gender');
  }

  void _exportToLogcat(BuildContext context) {
    final buffer =
        StringBuffer('[VoiceExplorer] ── EXPORT for $_explorerLang ──\n');
    for (final v in _explorerVoices) {
      final name = v['name'] as String;
      final locale = v['locale'] as String;
      final gender = _explorerGenders[name] ?? 'unknown';
      final genderIcon = gender == 'male'
          ? 'Icons.man_3_outlined'
          : gender == 'female'
              ? 'Icons.woman_outlined'
              : 'Icons.record_voice_over_outlined';
      buffer.writeln(
        "  '$name': VoiceMetadata(emoji: '', description: '$gender $locale', genderIcon: $genderIcon),",
      );
    }
    debugPrint(buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Exported to logcat — copy from Android Studio'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── TTS Fallback Toggle ──
        StatefulBuilder(
          builder: (context, setLocal) => ListTile(
            title: const Text('🎤 TTS Force Fallback (Testing)'),
            subtitle: const Text('Test voice fallback selection flow'),
            leading: Icon(
              Icons.mic,
              color: DebugFlags.forceFallbackForTesting
                  ? Colors.orange
                  : Colors.grey,
            ),
            trailing: Switch(
              value: DebugFlags.forceFallbackForTesting,
              onChanged: (value) {
                setLocal(() => DebugFlags.forceFallbackForTesting = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? '🎤 TTS Fallback enabled - voices will use fallback locales'
                        : '🎤 TTS Fallback disabled - voices will use premium only'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Voice Explorer ──
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.travel_explore, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text(
                      '🔬 TTS Voice Explorer',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _exportToLogcat(context),
                      child: const Text('📋 Export'),
                    ),
                  ],
                ),
                const Text(
                  'Discover all system voices — tag gender — export registry patch',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                // Language chips
                Wrap(
                  spacing: 6,
                  children: VoiceDataRegistry.supportedLanguages.map((lang) {
                    return ChoiceChip(
                      label: Text(lang),
                      selected: _explorerLang == lang,
                      onSelected: (_) {
                        setState(() {
                          _explorerLang = lang;
                          _explorerVoices = [];
                          _explorerGenders = {};
                        });
                        _loadAllVoices(lang);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Load button
                if (_explorerVoices.isEmpty && !_explorerLoading)
                  ElevatedButton.icon(
                    onPressed: () => _loadAllVoices(_explorerLang),
                    icon: const Icon(Icons.search),
                    label: Text('Load $_explorerLang voices'),
                  ),

                // Loading indicator
                if (_explorerLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),

                // Voice list
                if (_explorerVoices.isNotEmpty) _buildVoiceList(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_explorerVoices.length} voices found:',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        ...List.generate(_explorerVoices.length, (i) {
          final voice = _explorerVoices[i];
          final name = voice['name'] as String;
          final locale = voice['locale'] as String;
          final gender = _explorerGenders[name];
          final isPlaying = _explorerPlayingIndex == i;
          final cardColor = gender == 'male'
              ? Colors.blue.shade50
              : gender == 'female'
                  ? Colors.pink.shade50
                  : Colors.transparent;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              leading: IconButton(
                icon: isPlaying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                onPressed:
                    isPlaying ? null : () => _playSample(name, locale, i),
              ),
              title: Text(name,
                  style:
                      const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              subtitle: Text(locale, style: const TextStyle(fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GenderChip(
                    symbol: '♂',
                    active: gender == 'male',
                    activeColor: Colors.blue,
                    onTap: () => _tagGender(name, 'male'),
                  ),
                  const SizedBox(width: 4),
                  _GenderChip(
                    symbol: '♀',
                    active: gender == 'female',
                    activeColor: Colors.pink,
                    onTap: () => _tagGender(name, 'female'),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        if (_explorerGenders.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 Tagged: '
                  '♂ ${_explorerGenders.values.where((g) => g == 'male').length} male  '
                  '♀ ${_explorerGenders.values.where((g) => g == 'female').length} female',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ElevatedButton.icon(
                  onPressed: () => _exportToLogcat(context),
                  icon: const Icon(Icons.copy),
                  label: const Text('Export VoiceMetadata to logcat'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Reusable gender tag chip.
class _GenderChip extends StatelessWidget {
  final String symbol;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _GenderChip({
    required this.symbol,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          symbol,
          style: TextStyle(color: active ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
