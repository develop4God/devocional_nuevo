import 'dart:async';

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
    print('[HttpClientAdapter] GET $url -> ${response.statusCode}');
    print('[HttpClientAdapter] First 100 bytes: ' +
        response.body.substring(
            0, response.body.length > 100 ? 100 : response.body.length));
    return HttpResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: response.headers,
    );
  }

  @override
  Stream<HttpDownloadProgress> downloadStream(String url) async* {
    final request = http.Request('GET', Uri.parse(url));
    request.headers['User-Agent'] = 'devocional_nuevo/1.0 (Flutter)';
    final streamedResponse = await _client.send(request);
    print(
        '[HttpClientAdapter] downloadStream $url -> ${streamedResponse.statusCode}');
    int chunkCount = 0;
    final total = streamedResponse.contentLength;
    int downloaded = 0;
    final chunks = <int>[];

    await for (final chunk in streamedResponse.stream) {
      chunks.addAll(chunk);
      downloaded += chunk.length;
      if (chunkCount == 0) {
        final preview = String.fromCharCodes(chunk.take(100).toList());
        print('[HttpClientAdapter] First chunk (max 100 bytes): $preview');
      }
      chunkCount++;
      yield HttpDownloadProgress(
        downloaded: downloaded,
        total: total,
        data: chunk,
      );
    }
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
