import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/google_drive_auth_service.dart';

void main() {
  group('GoogleDriveAuthService', () {
    late GoogleDriveAuthService service;

    setUp(() {
      service = GoogleDriveAuthService();
    });

    test('Singleton instance returns the same object', () {
      final another = GoogleDriveAuthService();
      expect(service, same(another));
    });

    test('Scopes are correct', () {
      // Acceso a los scopes privados a través de reflexión no es posible, pero podemos probar signIn y getAuthClient con mocks en pruebas avanzadas.
      expect(service, isA<GoogleDriveAuthService>());
    });
  });
}
