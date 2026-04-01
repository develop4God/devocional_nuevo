import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/utils/network_error_utils.dart';

void main() {
  group('isTransientNetworkError', () {
    test('returns true for SocketException', () {
      expect(
        isTransientNetworkError(
          const SocketException(
              'Failed host lookup: raw.githubusercontent.com'),
        ),
        isTrue,
      );
    });

    test('returns true for ClientException wrapping SocketException', () {
      expect(
        isTransientNetworkError(
          Exception(
            'ClientException with SocketException: Failed host lookup, errno = 7',
          ),
        ),
        isTrue,
      );
    });

    test('returns true for connection refused', () {
      expect(
        isTransientNetworkError(Exception('Connection refused')),
        isTrue,
      );
    });

    test('returns true for network unreachable', () {
      expect(
        isTransientNetworkError(Exception('Network is unreachable')),
        isTrue,
      );
    });

    test('returns false for null pointer exception', () {
      expect(
        isTransientNetworkError(Exception('Null check operator on null value')),
        isFalse,
      );
    });

    test('returns false for format exception', () {
      expect(
        isTransientNetworkError(const FormatException('Bad JSON')),
        isFalse,
      );
    });

    test('returns false for generic state error', () {
      expect(
        isTransientNetworkError(StateError('Bad state: stream closed')),
        isFalse,
      );
    });

    test('returns true for PathNotFoundException (cache file deleted)', () {
      expect(
        isTransientNetworkError(
          PathNotFoundException(
            'Cannot open file',
            const OSError('No such file or directory', 2),
          ),
        ),
        isTrue,
      );
    });

    test('returns true for FileSystemException with errno 2', () {
      expect(
        isTransientNetworkError(
          const FileSystemException(
            'Cannot open file',
            '/cache/libCachedImageData/abc.png',
            OSError('No such file or directory', 2),
          ),
        ),
        isTrue,
      );
    });
  });
}
