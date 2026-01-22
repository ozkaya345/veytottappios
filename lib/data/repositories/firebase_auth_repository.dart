import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../services/firebase_auth_service.dart';

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._service);

  final FirebaseAuthService _service;

  @override
  User? get currentUser => _service.currentUser;

  @override
  Stream<User?> authStateChanges() => _service.authStateChanges();

  @override
  Future<UserCredential> signInAnonymously() => _service.signInAnonymously();

  @override
  Future<void> signOut() => _service.signOut();
}
