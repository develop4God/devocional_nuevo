import 'dart:async';
import 'dart:developer' as developer;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:http/http.dart' as http;

/// Default timeout for HTTP operations. Tunable constant to control how
/// long we wait before aborting network requests.
const Duration _defaultTimeout = Duration(seconds: 5);

/// HTTP client adapter that implements the framework-agnostic [HttpClient] interface
/// using the `package:http` library.
///
/// This adapter bridges the bible_reader_core package with the Flutter app's
/// HTTP implementation.
///
/// Usage:
/// ```dart
/// final adapter = HttpClientAdapter(http.Client());
/// final response = await adapter.get('https://example.com/api');
/// ```
class HttpClientAdapter implements HttpClient {
  /// The underlying HTTP client.
  final http.Client _client;

  /// Creates an HTTP client adapter with the given HTTP client.
  HttpClientAdapter(this._client);

  @override
  Future<HttpResponse> get(String url) async {
    try {
      final response = await _client.get(Uri.parse(url), headers: {
        'User-Agent': 'devocional_nuevo/1.0 (Flutter)'
      }).timeout(_defaultTimeout);
      developer.log('[HttpClientAdapter] GET $url -> ${response.statusCode}',
          name: 'HttpClientAdapter');

      // Use bodyBytes to avoid decoding binary content to String (costly for binary files)
      final bytes = response.bodyBytes;
      final previewCount = bytes.length < 100 ? bytes.length : 100;
      final previewBytes = bytes.take(previewCount).toList();
      // Try to present a readable preview: if printable, show UTF8/latin1 decode, otherwise hex
      String preview;
      try {
        preview = String.fromCharCodes(previewBytes);
        // If contains replacement character, fallback to hex
        if (preview.contains('\uFFFD')) {
          throw const FormatException('Non-text bytes');
        }
      } catch (_) {
        preview = previewBytes
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(' ');
      }
      developer.log(
          '[HttpClientAdapter] First $previewCount bytes (preview): $preview',
          name: 'HttpClientAdapter');

      return HttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
        // expose bodyBytes so callers can avoid re-decoding if they need raw bytes
        bodyBytes: bytes,
      );
    } on TimeoutException {
      developer.log('[HttpClientAdapter] GET timeout: $url',
          name: 'HttpClientAdapter');
      rethrow;
    } on Exception catch (e) {
      developer.log('[HttpClientAdapter] GET error: $e',
          name: 'HttpClientAdapter');
      rethrow;
    }
  }

  /// Descarga optimizada: menos logs, descarga en memoria si es pequeño, throttling de logs en streaming.
  @override
  Stream<HttpDownloadProgress> downloadStream(String url,
      {int thresholdBytes = 10 * 1024 * 1024,
      int percentStep = 1, // Emitir actualizaciones cada 1% por defecto
      int throttleMs = 500}) async* {
    final request = http.Request('GET', Uri.parse(url));
    request.headers['User-Agent'] = 'devocional_nuevo/1.0 (Flutter)';
    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _client.send(request).timeout(_defaultTimeout);
    } catch (e) {
      developer.log('[HttpClientAdapter] downloadStream send error: $e',
          name: 'HttpClientAdapter');
      rethrow;
    }
    developer.log(
        '[HttpClientAdapter] downloadStream $url -> ${streamedResponse.statusCode}',
        name: 'HttpClientAdapter');
    final total = streamedResponse.contentLength;
    int downloaded = 0;
    int chunkCount = 0;
    int lastLoggedPercent = -1;

    // Always stream and emit per-chunk progress to provide responsive UI feedback,
    // even for small files. Throttle logging to avoid spam.
    await for (final chunk in streamedResponse.stream) {
      downloaded += chunk.length;
      chunkCount++;
      if (chunkCount == 1) {
        // Log only small preview for first chunk
        try {
          final preview = String.fromCharCodes(chunk.take(100).toList());
          developer.log(
              '[HttpClientAdapter] First chunk (max 100 bytes): $preview',
              name: 'HttpClientAdapter');
        } catch (_) {}
      }
      if (total != null && total > 0) {
        final percent = ((downloaded / total) * 100).floor();
        if (percent - lastLoggedPercent >= percentStep || percent == 100) {
          lastLoggedPercent = percent;
          developer.log(
              '[HttpClientAdapter] Download progress for ${request.url.pathSegments.last}: $percent%',
              name: 'HttpClientAdapter');
        }
      }
      yield HttpDownloadProgress(
        downloaded: downloaded,
        total: total,
        data: chunk,
      );
    }
    developer.log('[HttpClientAdapter] Guardado completo ($downloaded bytes)',
        name: 'HttpClientAdapter');
  }

  /// Creates a new adapter with a fresh HTTP client.
  factory HttpClientAdapter.create() {
    return HttpClientAdapter(http.Client());
  }

  /// Closes the underlying HTTP client.
  ///
  /// After calling close, the adapter should not be used anymore.
  void close() {
    _client.close();
  }
}
