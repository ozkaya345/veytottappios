import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthRepository {
  User? get currentUser;

  Stream<User?> authStateChanges();

  Future<UserCredential> signInAnonymously();

  Future<void> signOut();
}
