import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/app_user.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource();

  bool _isGoogleInitialized = false;

  AppUser? get currentUser {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    final user = FirebaseAuth.instance.currentUser;
    return user == null ? null : _mapUser(user);
  }

  Future<AppUser> signInWithGoogle() async {
    _ensureFirebaseReady();
    await _ensureGoogleInitialized();

    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw const AppFailure('Google did not return an identity token.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    return _requireUser(result.user);
  }

  Future<AppUser> signInWithApple() async {
    _ensureFirebaseReady();
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    if (appleCredential.identityToken == null) {
      throw const AppFailure('Apple did not return an identity token.');
    }

    final credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    return _requireUser(result.user);
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseReady();
    final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireUser(result.user);
  }

  Future<void> signOut() async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    await FirebaseAuth.instance.signOut();
    if (_isGoogleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_isGoogleInitialized) {
      return;
    }
    await GoogleSignIn.instance.initialize();
    _isGoogleInitialized = true;
  }

  void _ensureFirebaseReady() {
    if (Firebase.apps.isEmpty) {
      throw const AppFailure(
        'Firebase is not configured yet. Add firebase_options.dart and platform Firebase config files.',
      );
    }
  }

  AppUser _requireUser(User? user) {
    if (user == null) {
      throw const AppFailure('Authentication completed without a user.');
    }
    return _mapUser(user);
  }

  AppUser _mapUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
