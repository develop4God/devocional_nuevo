import 'package:firebase_auth/firebase_auth.dart';

abstract class IAuthService {
  String? get currentUserId;
}

class FirebaseAuthService implements IAuthService {
  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
}
