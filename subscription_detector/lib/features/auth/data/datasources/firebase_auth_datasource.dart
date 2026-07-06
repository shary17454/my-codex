import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import 'auth_datasource.dart';

class FirebaseAuthDataSource implements AuthDataSource {
  FirebaseAuthDataSource({firebase.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance;

  final firebase.FirebaseAuth _firebaseAuth;

  @override
  AppUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      return null;
    }
    return AppUser(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
    );
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null || user.email == null) {
        throw const AppException('Firebase did not return a signed-in user.');
      }
      return AppUser(
        id: user.uid,
        email: user.email!,
        displayName: user.displayName,
      );
    } on firebase.FirebaseAuthException catch (error) {
      throw AppException(error.message ?? 'Firebase authentication failed.', cause: error);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw const AppException('Google Firebase sign-in requires platform OAuth configuration.');
  }

  @override
  Future<AppUser> signInWithApple() {
    throw const AppException('Apple Firebase sign-in requires Apple Sign In configuration.');
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}
