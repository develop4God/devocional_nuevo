@Tags(['unit', 'services'])
library;

// test/unit/services/auth_service_test.dart

import 'package:devocional_nuevo/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// FirebaseAuthService is a thin passthrough to FirebaseAuth.instance with
/// no branching logic of its own — real behavioral coverage of "signed in
/// vs signed out" lives wherever IAuthService is consumed, using the
/// project's FakeAuthService (test/helpers/test_helpers.dart). Exercising
/// this class directly would require mocking Firebase Auth's static
/// instance, which needs the firebase_auth_mocks package — not justified
/// for a 2-property delegate. This test only pins the IAuthService contract.
void main() {
  group('IAuthService contract', () {
    test('FirebaseAuthService implements IAuthService', () {
      expect(FirebaseAuthService(), isA<IAuthService>());
    });
  });
}
