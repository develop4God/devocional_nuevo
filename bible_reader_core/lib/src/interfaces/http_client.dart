/// Abstract HTTP client interface for framework-agnostic HTTP operations.
///
/// This interface allows the bible_reader_core package to perform HTTP operations
/// without depending on any specific HTTP library. The consuming application
/// provides its own implementation using its preferred HTTP library.
///
/// Example BLoC app implementation with package:http:
/// ```dart
/// class HttpClientAdapter implements HttpClient {
///   final http.Client _client;
///   HttpClientAdapter(this._client);
///
///   @override
///   Future<HttpResponse> get(String url) async {
///     final response = await _client.get(Uri.parse(url));
///     return HttpResponse(
///       statusCode: response.statusCode,
///       body: response.body,
///       headers: response.headers,
///     );
///   }
/// }
/// ```
abstract class HttpClient {
  /// Performs an HTTP GET request to the specified URL.
  ///
  /// Returns an [HttpResponse] containing the status code, body, and headers.
  /// Throws an exception if the request fails due to network issues.
  Future<HttpResponse> get(String url);

  /// Downloads a file from the specified URL with progress updates.
  ///
  /// Returns a [Stream] of [HttpDownloadProgress] events that can be used
  /// to track download progress in the UI.
  ///
  /// The stream emits events as data chunks are received, allowing
  /// real-time progress tracking.
  Stream<HttpDownloadProgress> downloadStream(String url);
}

/// Response from an HTTP request.
class HttpResponse {
  /// HTTP status code (e.g., 200, 404, 500).
  final int statusCode;

  /// Response body as a string.
  final String body;

  /// Response body as bytes (for binary files).
  final List<int>? bodyBytes;

  /// Response headers as a key-value map.
  final Map<String, String> headers;

  /// Creates an HTTP response with the given properties.
  const HttpResponse({
    required this.statusCode,
    required this.body,
    this.bodyBytes,
    required this.headers,
  });

  /// Returns true if the status code indicates success (2xx).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Progress information for an ongoing download.
class HttpDownloadProgress {
  /// Number of bytes downloaded so far.
  final int downloaded;

  /// Total size of the download in bytes, or null if unknown.
  final int? total;

  /// The chunk of data received in this progress event.
  /// May be empty if this is just a progress update.
  final List<int> data;

  /// Creates a download progress event.
  const HttpDownloadProgress({
    required this.downloaded,
    this.total,
    this.data = const [],
  });

  /// Returns the download progress as a value between 0.0 and 1.0.
  /// Returns 0.0 if the total size is unknown.
  double get progress =>
      total != null && total! > 0 ? downloaded / total! : 0.0;

  /// Returns true if the download is complete.
  bool get isComplete => total != null && downloaded >= total!;
}
