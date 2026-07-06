import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDataSource {
  const FirebaseAuthDataSource(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return credential.user!;
  }

  Future<User> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName);
    await user.reload();

    return _firebaseAuth.currentUser ?? user;
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}
