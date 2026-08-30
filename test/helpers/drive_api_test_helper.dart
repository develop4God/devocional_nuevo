// test/helpers/drive_api_test_helper.dart
//
// Builds a real drive.DriveApi backed by http.MockClient (package:http's
// testing seam), so GoogleDriveBackupService's Drive I/O paths can be
// exercised without a network call — no production code changes needed,
// since drive.DriveApi already takes an http.Client in its constructor.
//
// Covers the two request shapes GoogleDriveBackupService actually sends:
//   - JSON metadata requests (files.list, files.get metadata, files.get
//     ?alt=media) — driven by [DriveApiStub.jsonResponses] keyed on
//     "METHOD path".
//   - Multipart-upload requests (files.create / files.update with
//     uploadMedia) — googleapis' MultipartMediaUploader sends these as a
//     single multipart/related POST/PATCH with uploadType=multipart (no
//     resumable session, since the service never passes
//     ResumableUploadOptions). [DriveApiStub.uploadResponses] returns the
//     canned drive.File JSON for these.
//
// Companion to google_drive_backup_mock_helper.dart, which mocks
// IGoogleDriveAuthService's non-Drive-API dependencies.

import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A single canned HTTP response for [DriveApiStub].
class DriveApiResponse {
  final int statusCode;
  final Object? jsonBody;
  final List<int>? rawBody;
  final Map<String, String> headers;

  const DriveApiResponse.json(this.jsonBody, {this.statusCode = 200})
      : rawBody = null,
        headers = const {'content-type': 'application/json; charset=utf-8'};

  const DriveApiResponse.media(this.rawBody, {this.statusCode = 200})
      : jsonBody = null,
        headers = const {'content-type': 'application/octet-stream'};
}

/// Records one request the fake Drive API received, for tests that assert
/// on what was sent (e.g. which file id was updated).
class RecordedDriveRequest {
  final String method;
  final Uri url;
  final String body;

  const RecordedDriveRequest(this.method, this.url, this.body);
}

/// Builds a [drive.DriveApi] whose HTTP layer is entirely in-memory.
///
/// Usage:
/// ```dart
/// final stub = DriveApiStub()
///   ..onList(const DriveApiResponse.json({'files': []}))
///   ..onCreate(const DriveApiResponse.json({'id': 'new-file-id'}));
/// final driveApi = stub.build();
/// when(() => authService.getDriveApi()).thenAnswer((_) async => driveApi);
/// ```
class DriveApiStub {
  final List<RecordedDriveRequest> requests = [];

  DriveApiResponse? _listResponse;
  DriveApiResponse? _getMetadataResponse;
  DriveApiResponse? _getMediaResponse;
  DriveApiResponse? _createResponse;
  DriveApiResponse? _updateResponse;

  void onList(DriveApiResponse response) => _listResponse = response;

  void onGetMetadata(DriveApiResponse response) =>
      _getMetadataResponse = response;

  void onGetMedia(DriveApiResponse response) => _getMediaResponse = response;

  void onCreate(DriveApiResponse response) => _createResponse = response;

  void onUpdate(DriveApiResponse response) => _updateResponse = response;

  drive.DriveApi build() {
    final mockClient = MockClient.streaming((request, bodyStream) async {
      final bytes = await bodyStream.toBytes();
      requests.add(
        RecordedDriveRequest(request.method, request.url, utf8.decode(bytes)),
      );

      final response = _route(request);
      if (response == null) {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"error":{"message":"not stubbed"}}')),
          404,
          headers: {'content-type': 'application/json'},
        );
      }

      final payload = response.jsonBody != null
          ? utf8.encode(json.encode(response.jsonBody))
          : (response.rawBody ?? const <int>[]);

      return http.StreamedResponse(
        Stream.value(payload),
        response.statusCode,
        headers: {
          ...response.headers,
          'content-length': '${payload.length}',
        },
      );
    });

    return drive.DriveApi(mockClient);
  }

  DriveApiResponse? _route(http.BaseRequest request) {
    final isFilesCollection = request.url.path.endsWith('/files');
    final isSingleFile =
        !isFilesCollection && request.url.path.contains('/files/');

    if (request.method == 'GET' && isFilesCollection) return _listResponse;

    if (request.method == 'GET' && isSingleFile) {
      final isMedia = request.url.queryParameters['alt'] == 'media';
      return isMedia ? _getMediaResponse : _getMetadataResponse;
    }

    if (request.method == 'POST' && isFilesCollection) return _createResponse;

    if (request.method == 'PATCH' && isSingleFile) return _updateResponse;

    return null;
  }
}
