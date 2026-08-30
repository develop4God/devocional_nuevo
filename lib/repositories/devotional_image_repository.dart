// lib/repositories/devotional_image_repository.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:devocional_nuevo/utils/constants/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves devotional hero background images from a shared, generic image
/// pool at `images/devotionals/index.json` (not one image per devotional —
/// the pool is small and reused, so identity doesn't matter to the reader).
///
/// The devotional page is the app's home screen, so the first image must be
/// ready before the very first frame — [prepareInitial] is called once from
/// app startup, in parallel with other init work. Forward navigation always
/// has its next image pre-downloaded ([advance]); backward navigation picks
/// fresh on demand ([pickFresh]), since re-reading is rare and doesn't need
/// the same seamlessness guarantee.
///
/// Failures never blank an image already on screen — [advance] and
/// [pickFresh] keep [currentImageUrl] as-is when a new pick can't be made.
/// Only [prepareInitial] can leave it `null`, when the very first pick fails
/// before anything has ever been shown.
class DevotionalImageRepository {
  final http.Client httpClient;
  final BaseCacheManager cacheManager;
  final Random _random;

  static const String _indexCacheKey = 'devotional_image_index_cache';

  /// Fetched at most once per app session — reset on every cold start.
  static bool _indexFetchedThisSession = false;

  static const Duration _networkTimeout = Duration(seconds: 10);

  /// The image currently shown behind the verse card.
  String? currentImageUrl;

  String? _prefetchedNextUrl;

  /// Tracks whether a prefetch is currently in flight to prevent
  /// duplicate requests on rapid navigation taps.
  bool _prefetchInFlight = false;

  DevotionalImageRepository({
    required this.httpClient,
    required this.cacheManager,
    Random? random,
  }) : _random = random ?? Random();

  /// Fetches the list of available background image filenames (no extension).
  Future<List<String>> fetchIndex({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh && _indexFetchedThisSession) {
      final cached = prefs.getString(_indexCacheKey);
      if (cached != null) {
        return _parseIndex(jsonDecode(cached) as Map<String, dynamic>);
      }
    }

    try {
      final url = Constants.getDevotionalImagesIndexUrl();
      final response =
          await httpClient.get(Uri.parse(url)).timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final files = _parseIndex(json);
        await prefs.setString(_indexCacheKey, response.body);
        _indexFetchedThisSession = true;
        debugPrint(
          '🖼️ DevotionalImage: index fetched (${files.length} files)',
        );
        return files;
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('⚠️ DevotionalImage: Network error fetching index: $e');

      final cached = prefs.getString(_indexCacheKey);
      if (cached != null) {
        try {
          return _parseIndex(jsonDecode(cached) as Map<String, dynamic>);
        } catch (_) {
          developer.log(
            'Cached devotional image index corrupt',
            name: 'DevotionalImageRepository.fetchIndex',
          );
        }
      }
      return const [];
    }
  }

  List<String> _parseIndex(Map<String, dynamic> json) {
    final files = json['files'];
    if (files is List) {
      return files.whereType<String>().map((f) {
        return f.contains('.') ? f.substring(0, f.lastIndexOf('.')) : f;
      }).toList();
    }
    return const [];
  }

  Future<String?> _pickRandomUrl(List<String> files) async {
    if (files.isEmpty) return null;
    final filename = files[_random.nextInt(files.length)];
    return Constants.getDevotionalImageUrl(filename);
  }

  Future<void> _warm(String url) async {
    try {
      await cacheManager.downloadFile(url);
      debugPrint('🖼️ DevotionalImage: warmed $url');
    } catch (e) {
      debugPrint('⚠️ DevotionalImage: Failed to warm $url: $e');
    }
  }

  /// Called once at app startup, in parallel with other init work.
  ///
  /// Picks and downloads the image for the devotional the user lands on,
  /// then pre-picks and downloads a second image for whichever devotional
  /// they navigate to next. Never throws — on any failure, [currentImageUrl]
  /// simply stays null and the verse card renders with no background.
  Future<void> prepareInitial() async {
    try {
      final files = await fetchIndex();
      final url = await _pickRandomUrl(files);
      if (url == null) return;

      await _warm(url);
      currentImageUrl = url;
      debugPrint('🖼️ DevotionalImage: prepareInitial current=$url');

      final nextUrl = await _pickRandomUrl(files);
      if (nextUrl != null) {
        await _warm(nextUrl);
        _prefetchedNextUrl = nextUrl;
        debugPrint('🖼️ DevotionalImage: prepareInitial prefetched=$nextUrl');
      }
    } catch (e) {
      debugPrint('⚠️ DevotionalImage: prepareInitial failed: $e');
    }
  }

  /// Called when the user navigates forward. Promotes the already-downloaded
  /// pre-fetched image to current (instant — no network wait), then kicks off
  /// downloading a fresh one for the next forward navigation.
  ///
  /// When nothing was successfully pre-fetched (offline, or the previous
  /// prefetch failed), the currently shown image is kept rather than
  /// dropping to no background.
  ///
  /// On rapid navigation taps, avoids starting duplicate prefetch requests
  /// by checking [_prefetchInFlight] — if one is already running, skips it
  /// and returns immediately.
  Future<String?> advance() async {
    final promoted = _prefetchedNextUrl;
    if (promoted != null) {
      currentImageUrl = promoted;
      _prefetchedNextUrl = null;
      debugPrint('🖼️ DevotionalImage: advance promoted=$promoted');
    } else {
      debugPrint(
        '🖼️ DevotionalImage: advance had no prefetch, keeping $currentImageUrl',
      );
    }

    // Fire-and-forget: prepares the image for the navigation after this one.
    // Skip if a prefetch is already in flight (rapid navigation prevention).
    if (!_prefetchInFlight) {
      unawaited(_prefetchNext());
    } else {
      debugPrint(
        '🖼️ DevotionalImage: prefetch already in flight, skipping duplicate request',
      );
    }

    return currentImageUrl;
  }

  Future<void> _prefetchNext() async {
    _prefetchInFlight = true;
    try {
      final files = await fetchIndex();
      final url = await _pickRandomUrl(files);
      if (url == null) return;
      await _warm(url);
      _prefetchedNextUrl = url;
      debugPrint('🖼️ DevotionalImage: prefetch ready=$url');
    } catch (e) {
      debugPrint('⚠️ DevotionalImage: prefetch failed: $e');
    } finally {
      _prefetchInFlight = false;
    }
  }

  /// Picks a fresh image on demand — used for backward navigation and direct
  /// index jumps, where pre-warming isn't worth the bookkeeping.
  ///
  /// On failure or an empty pool, keeps whatever image is currently shown
  /// rather than dropping to no background.
  Future<String?> pickFresh({bool forceRefresh = false}) async {
    try {
      final files = await fetchIndex(forceRefresh: forceRefresh);
      final url = await _pickRandomUrl(files);
      if (url != null) {
        currentImageUrl = url;
        debugPrint('🖼️ DevotionalImage: pickFresh current=$url');
      }
      return currentImageUrl;
    } catch (e) {
      debugPrint('⚠️ DevotionalImage: pickFresh failed: $e');
      return currentImageUrl;
    }
  }
}
