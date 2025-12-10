import 'dart:async';
import 'dart:developer' as developer;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:http/http.dart' as http;

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
    final response = await _client.get(
      Uri.parse(url),
      headers: {'User-Agent': 'devocional_nuevo/1.0 (Flutter)'},
    );
    developer.log('[HttpClientAdapter] GET $url -> ${response.statusCode}',
        name: 'HttpClientAdapter');
    final previewLength =
        response.body.length < 100 ? response.body.length : 100;
    final preview = response.body.substring(0, previewLength);
    developer.log('[HttpClientAdapter] First 100 bytes: $preview',
        name: 'HttpClientAdapter');
    return HttpResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: response.headers,
    );
  }

  /// Descarga optimizada: menos logs, descarga en memoria si es pequeño, throttling de logs en streaming.
  @override
  Stream<HttpDownloadProgress> downloadStream(String url,
      {int thresholdBytes = 10 * 1024 * 1024,
      int percentStep = 10, // Solo log cada 10%
      int throttleMs = 500}) async* {
    final request = http.Request('GET', Uri.parse(url));
    request.headers['User-Agent'] = 'devocional_nuevo/1.0 (Flutter)';
    final streamedResponse = await _client.send(request);
    developer.log(
        '[HttpClientAdapter] downloadStream $url -> ${streamedResponse.statusCode}',
        name: 'HttpClientAdapter');
    final total = streamedResponse.contentLength;
    int downloaded = 0;
    int chunkCount = 0;
    int lastLoggedPercent = -1;
    final chunks = <int>[];

    // Si el archivo es pequeño y el tamaño es conocido, descargar todo y emitir un solo progreso
    if (total != null && total > 0 && total <= thresholdBytes) {
      developer.log(
          '[HttpClientAdapter] Descargando en memoria (size=$total bytes) -> escribir de una vez',
          name: 'HttpClientAdapter');
      await for (final chunk in streamedResponse.stream) {
        chunks.addAll(chunk);
        downloaded += chunk.length;
      }
      yield HttpDownloadProgress(
        downloaded: downloaded,
        total: total,
        data: chunks,
      );
      developer.log('[HttpClientAdapter] Guardado completo ($downloaded bytes)',
          name: 'HttpClientAdapter');
      return;
    }

    // Streaming con throttled progress
    await for (final chunk in streamedResponse.stream) {
      downloaded += chunk.length;
      chunkCount++;
      // Log preview solo en el primer chunk
      if (chunkCount == 1) {
        final preview = String.fromCharCodes(chunk.take(100).toList());
        developer.log(
            '[HttpClientAdapter] First chunk (max 100 bytes): $preview',
            name: 'HttpClientAdapter');
      }
      // Calcular porcentaje si contentLength conocido
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
