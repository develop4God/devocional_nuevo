// lib/widgets/encounter/encounter_image_widget.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AVIF-first image widget with persisted PNG fallback.
///
/// Tries to load [baseFilename].avif for capable devices.
/// On codec failure, persists a flag to SharedPreferences keyed by
/// `img_fallback_{encounterId}_{imageVersion}` and rebuilds with .png.
///
/// The flag persists across sessions so subsequent launches skip the
/// failed AVIF attempt entirely — no wasted bandwidth.
///
/// When [imageVersion] bumps, the old flag key becomes irrelevant and
/// AVIF is tried again for the new version — this is intentional.
class EncounterImageWidget extends StatefulWidget {
  final String baseFilename; // no extension — e.g. "peter_intro"
  final String encounterId;
  final String imageVersion;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Color? fallbackColor;

  const EncounterImageWidget({
    super.key,
    required this.baseFilename,
    required this.encounterId,
    required this.imageVersion,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.fallbackColor,
  });

  @override
  State<EncounterImageWidget> createState() => _EncounterImageWidgetState();
}

class _EncounterImageWidgetState extends State<EncounterImageWidget> {
  bool _usePng = false;
  bool _initialized = false;

  String get _flagKey =>
      'img_fallback_${widget.encounterId}_${widget.imageVersion}';

  String get _avifUrl => Constants.getEncounterImageUrl(
        widget.baseFilename,
        encounterId: widget.encounterId,
        format: 'avif',
      );

  String get _pngUrl => Constants.getEncounterImageUrl(
        widget.baseFilename,
        encounterId: widget.encounterId,
        format: 'png',
      );

  String get _cacheKey =>
      '${widget.encounterId}_${widget.baseFilename}_${widget.imageVersion}';

  @override
  void initState() {
    super.initState();
    _loadFallbackFlag();
  }

  Future<void> _loadFallbackFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool(_flagKey) ?? false;
    if (mounted) {
      setState(() {
        _usePng = flag;
        _initialized = true;
      });
    }
  }

  Future<void> _persistFallback() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flagKey, true);
    debugPrint('📦 [EncounterImageWidget] Persisted PNG fallback: $_flagKey');
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(color: widget.fallbackColor ?? Colors.transparent);
    }

    final url = _usePng ? _pngUrl : _avifUrl;
    final cacheKey = _usePng ? '${_cacheKey}_png' : '${_cacheKey}_avif';

    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: cacheKey,
      fit: widget.fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: widget.placeholder,
      errorWidget: (context, url, error) {
        if (!_usePng) {
          debugPrint(
              '⚠️ [EncounterImageWidget] AVIF failed for ${widget.encounterId} — falling back to PNG');
          _persistFallback();
          // Rebuild with PNG
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _usePng = true);
          });
        }
        return Container(color: widget.fallbackColor ?? Colors.transparent);
      },
    );
  }
}
