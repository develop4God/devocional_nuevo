import 'package:firebase_auth/firebase_auth.dart';

abstract class IAuthService {
  String? get currentUserId;

  Stream<String?> get authStateChanges;
}

class FirebaseAuthService implements IAuthService {
  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Stream<String?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);
}
